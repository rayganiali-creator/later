import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/config/pro_plans.dart';
import 'package:later/core/util/dates.dart';
import 'package:later/data/backup/backup_codec.dart';
import 'package:later/data/controller.dart';
import 'package:later/data/db/app_database.dart';
import 'package:later/data/repository.dart';
import 'package:later/domain/classifier.dart';
import 'package:later/domain/models.dart';
import 'package:later/domain/pro.dart';
import 'package:later/domain/reminders.dart';
import 'package:later/domain/roulette.dart';
import 'package:later/domain/settings.dart';
import 'package:later/domain/transitions.dart';
import 'package:later/domain/universal_search.dart';
import 'package:later/services/platform_bridge.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'harness.dart';
import 'helpers.dart';

Future<TestEnv> env0({List<LaterItem> items = const [], AppSettings? settings, bool pro = false}) async {
  final e = await TestEnv.create(settings: settings ?? readySettings, items: items);
  await e.controller.init();
  if (pro) await e.controller.pro.applyPurchase(ProPlans.month1);
  return e;
}

LaterItem typed(String id, ItemType t, {int stage = 0, DateTime? unlock, String? title, DateTime? created, bool inbox = false, String? url}) =>
    item(id, title: title, created: created).copyWith(type: t, stage: stage, unlockAt: unlock, inbox: inbox, url: url);

void main() {
  group('Stages map to generic status', () {
    test('read / watch / wishlist / idea / sealed', () {
      expect(ItemStages.statusFor(ItemType.read, ItemStages.unread), ItemStatus.active);
      expect(ItemStages.statusFor(ItemType.read, ItemStages.reading), ItemStatus.active);
      expect(ItemStages.statusFor(ItemType.read, ItemStages.read), ItemStatus.done);
      expect(ItemStages.statusFor(ItemType.read, ItemStages.archived), ItemStatus.dropped);
      expect(ItemStages.statusFor(ItemType.watch, ItemStages.watched), ItemStatus.done);
      expect(ItemStages.statusFor(ItemType.wishlist, ItemStages.bought), ItemStatus.done);
      expect(ItemStages.statusFor(ItemType.wishlist, ItemStages.maybe), ItemStatus.active);
      expect(ItemStages.statusFor(ItemType.wishlist, ItemStages.notInterested), ItemStatus.dropped);
      expect(ItemStages.statusFor(ItemType.idea, ItemStages.developing), ItemStatus.active);
      expect(ItemStages.statusFor(ItemType.idea, ItemStages.ideaArchived), ItemStatus.dropped);
      expect(ItemStages.statusFor(ItemType.idea, ItemStages.ideaDropped), ItemStatus.dropped);
      expect(ItemStages.statusFor(ItemType.capsule, ItemStages.opened), ItemStatus.done);
      expect(ItemStages.statusFor(ItemType.future, ItemStages.sealed), ItemStatus.active);
    });

    test('setStage keeps status, timestamps and events consistent', () {
      final i = typed('a', ItemType.read);
      final t = Transitions.setStage(i, ItemStages.read, t0);
      expect((t.item.status, t.item.completedAt, t.event.type), (ItemStatus.done, t0, EventType.completed));
      final back = Transitions.setStage(t.item, ItemStages.unread, t0);
      expect((back.item.status, back.item.completedAt, back.event.type), (ItemStatus.active, null, EventType.reopened));
      final mid = Transitions.setStage(i, ItemStages.reading, t0);
      expect(mid.event.type, EventType.moved);
    });

    test('complete/drop use the right stage per type', () {
      expect(Transitions.complete(typed('a', ItemType.wishlist), t0).item.stage, ItemStages.bought);
      expect(Transitions.complete(typed('a', ItemType.watch), t0).item.stage, ItemStages.watched);
      expect(Transitions.drop(typed('a', ItemType.idea), t0).item.stage, ItemStages.ideaDropped);
      expect(Transitions.drop(typed('a', ItemType.read), t0).item.stage, ItemStages.archived);
    });
  });

  group('Classifier (suggestions only)', () {
    test('urls', () {
      expect(ItemClassifier.classify('x', url: 'https://www.youtube.com/watch?v=1').type, ItemType.watch);
      expect(ItemClassifier.classify('x', url: 'https://youtu.be/abc').type, ItemType.watch);
      expect(ItemClassifier.classify('x', url: 'https://www.aparat.com/v/x').type, ItemType.watch);
      expect(ItemClassifier.classify('x', url: 'https://www.digikala.com/product/dkp-1/').type, ItemType.wishlist);
      expect(ItemClassifier.classify('x', url: 'https://blog.example.com/post').type, ItemType.read);
      expect(ItemClassifier.classify('https://blog.example.com/post').type, ItemType.read);
    });
    test('text', () {
      expect(ItemClassifier.classify('ایده‌ای دارم برای ساخت یه اپ').type, ItemType.idea);
      expect(ItemClassifier.classify('بعداً به علی زنگ بزنم').type, ItemType.person);
      expect(ItemClassifier.classify('شیر بخرم').type, ItemType.task);
      expect(ItemClassifier.classify('شیر بخرم').isDefault, isTrue);
    });
  });

  group('Roulette', () {
    final t = t0;
    final items = [
      item('hi', priority: ItemPriority.high, due: DateTime(2026, 9, 30), created: t.subtract(const Duration(days: 20)), minutes: 10),
      item('lo', priority: ItemPriority.low, created: t, minutes: 60),
      item('mid', created: t.subtract(const Duration(days: 5)), minutes: 25),
    ];

    test('every eligible item can win; heavier ones win more often', () {
      final r = Roulette(random: Random(42));
      final wins = <String, int>{};
      for (var k = 0; k < 3000; k++) {
        final w = r.spin(items, t, const RouletteOptions())!;
        wins[w.id] = (wins[w.id] ?? 0) + 1;
      }
      expect(wins.keys.toSet(), {'hi', 'lo', 'mid'});
      expect(wins['hi']!, greaterThan(wins['mid']!));
      expect(wins['mid']!, greaterThan(wins['lo']!));
    });

    test('not predictable: different seeds give different first picks', () {
      final firsts = {for (var s = 0; s < 40; s++) Roulette(random: Random(s)).spin(items, t, const RouletteOptions())!.id};
      expect(firsts.length, greaterThan(1));
    });

    test('recent picks are avoided when the pool is big enough', () {
      final many = [for (var i = 0; i < 8; i++) item('i$i', created: t)];
      final r = Roulette(random: Random(1));
      for (var k = 0; k < 200; k++) {
        final w = r.spin(many, t, const RouletteOptions(recentIds: ['i0', 'i1', 'i2']))!;
        expect(['i0', 'i1', 'i2'].contains(w.id), isFalse);
      }
      // tiny pool: still returns something
      expect(r.spin(items, t, const RouletteOptions(recentIds: ['hi', 'lo', 'mid'])), isNotNull);
    });

    test('filters: time, category, priority, energy; only doable active unlocked items', () {
      final r = Roulette(random: Random(3));
      final mixed = [
        item('long', minutes: 90, category: 'work'),
        item('short', minutes: 5, category: 'read'),
        typed('idea', ItemType.idea),
        typed('wish', ItemType.wishlist),
        typed('sealed', ItemType.capsule, unlock: t.add(const Duration(days: 9))),
        item('done', status: ItemStatus.done),
        typed('read', ItemType.read, title: 'r').copyWith(categoryId: 'read', estimatedMinutes: null),
      ];
      Set<String> pool(RouletteOptions o) => {
            for (var k = 0; k < 200; k++) r.spin(mixed, t, o)!.id,
          };
      expect(pool(const RouletteOptions()), {'long', 'short', 'read'});
      expect(pool(const RouletteOptions(availableMinutes: 15)), {'short', 'read'});
      expect(pool(const RouletteOptions(categoryIds: {'work'})), {'long'});
      expect(r.spin(mixed, t, const RouletteOptions(priority: ItemPriority.high)), isNull);
      expect(r.spin(const [], t, const RouletteOptions()), isNull);
    });
  });

  group('Sealed items (time capsule / future message)', () {
    test('hidden from lists, roulette and counts until they open', () async {
      final e = await env0(items: [
        typed('cap', ItemType.capsule, unlock: t0.add(const Duration(days: 30)), title: 'secret'),
        item('normal'),
      ]);
      final c = e.controller;
      expect(c.activeItems.map((i) => i.id), ['normal']);
      expect(c.sealedItems.map((i) => i.id), ['cap']);
      expect(c.homeCounts().total, 1);
      expect((await c.spinRoulette())!.id, 'normal');
      expect(c.search('secret'), isEmpty, reason: 'sealed text must not be searchable');
      e.clockNow = t0.add(const Duration(days: 31));
      expect(c.activeItems.map((i) => i.id).toSet(), {'normal', 'cap'});
      expect(c.sealedItems, isEmpty);
    });

    test('planner: one notification at the opening time, never before', () {
      const p = ReminderPlanner();
      final cap = typed('cap', ItemType.capsule, unlock: DateTime(2027, 3, 21, 9)).copyWith(
          reminderEnabled: true, dueAt: DateTime(2026, 10, 5));
      final plan = p.plan([cap], t0,
          defaultMinutesOfDay: 540, allowRepeat: true, max: 10, titleOf: (i) => 'T', bodyOf: (i) => 'B',
          unlockTitleOf: (i) => 'UNLOCK', unlockBodyOf: (i) => 'UB');
      expect(plan.single.fireAt, DateTime(2027, 3, 21, 9));
      expect(plan.single.title, 'UNLOCK');
      expect(plan.single.sealed, isTrue);
      // A normal item sealed for later: its own earlier reminder is suppressed.
      final it = item('n', due: DateTime(2026, 10, 5), reminder: true).copyWith(unlockAt: DateTime(2026, 12, 1, 9));
      final p2 = p.plan([it], t0,
          defaultMinutesOfDay: 540, allowRepeat: true, max: 10, titleOf: (i) => 'T', bodyOf: (i) => 'B');
      expect(p2.single.fireAt, DateTime(2026, 12, 1, 9));
    });

    test('create, limits (free 2) and Pro unlimited; date must be in the future', () async {
      final e = await env0();
      final c = e.controller;
      final soon = t0.add(const Duration(days: 100));
      expect(await c.seal(title: 'a', unlockAt: soon), isNotNull);
      expect(await c.seal(title: 'b', unlockAt: soon), isNotNull);
      expect(c.canSeal(messages: false), isFalse);
      expect(await c.seal(title: 'c', unlockAt: soon), isNull);
      expect(await c.seal(title: 'm', unlockAt: soon, message: true), isNotNull);
      expect(() => c.seal(title: 'x', unlockAt: t0.subtract(const Duration(days: 1)), message: true), throwsArgumentError);
      await c.pro.applyPurchase(ProPlans.month1);
      expect(await c.seal(title: 'c', unlockAt: soon), isNotNull);
    });

    test('opening: marks it done and logs the event; unlocked-only', () async {
      final e = await env0();
      final c = e.controller;
      final m = (await c.seal(title: 'note', body: 'hello me', unlockAt: t0.add(const Duration(days: 10)), message: true))!;
      expect(await c.openSealed(m.id), isNull, reason: 'still sealed');
      e.clockNow = t0.add(const Duration(days: 11));
      final opened = await c.openSealed(m.id);
      expect(opened!.description, 'hello me');
      expect(c.itemById(m.id)!.status, ItemStatus.done);
      expect(c.itemById(m.id)!.stage, ItemStages.opened);
      expect(c.timeline(messages: true).single.id, m.id);
    });

    test('Pro repeating message re-arms itself yearly', () async {
      final e = await env0(pro: true);
      final c = e.controller;
      final m = (await c.seal(title: 'y', unlockAt: t0.add(const Duration(days: 5)), message: true, repeat: RepeatRule.yearly))!;
      e.clockNow = t0.add(const Duration(days: 6));
      await c.openSealed(m.id);
      final again = c.itemById(m.id)!;
      expect(again.status, ItemStatus.active);
      expect(again.unlockAt!.year, t0.year + 1);
      expect(again.isLockedAt(e.clockNow), isTrue);
    });

    test('free users cannot repeat / tag (Pro only), notification scheduled for unlock', () async {
      final e = await env0();
      final c = e.controller;
      final m = (await c.seal(title: 'free', unlockAt: t0.add(const Duration(days: 40)), repeat: RepeatRule.yearly, tags: ['x']))!;
      expect(m.repeat, RepeatRule.none);
      expect(m.tags, isEmpty);
      await c.syncReminders();
      final s = e.gateway.scheduled.values.where((v) => v.reminder.itemId == m.id).single;
      expect(s.reminder.fireAt, t0.add(const Duration(days: 40)));
      expect(s.reminder.sealed, isTrue);
    });

    test('seal an existing item', () async {
      final e = await env0(items: [item('a')]);
      final r = await e.controller.sealExisting('a', t0.add(const Duration(days: 3)));
      expect(r!.unlockAt, isNotNull);
      expect(e.controller.activeItems, isEmpty);
    });
  });

  group('Inbox & triage', () {
    test('quick add lands in the inbox; triage sorts it', () async {
      final e = await env0();
      final c = e.controller;
      final a = await c.quickAdd('این مقاله رو بخونم');
      expect(a.inbox, isTrue);
      expect(c.inboxItems.length, 1);
      expect(c.dashboardCounts().inbox, 1);
      await c.triage(a.id, TriageChoice.today);
      expect(c.itemById(a.id)!.inbox, isFalse);
      expect(c.itemById(a.id)!.dueAt, Dates.startOfDay(t0));
      final b = await c.quickAdd('b');
      await c.triage(b.id, TriageChoice.read);
      expect(c.itemById(b.id)!.type, ItemType.read);
      expect(c.inboxItems, isEmpty);
      final d = await c.quickAdd('d');
      final undo = await c.triage(d.id, TriageChoice.wishlist);
      expect(c.itemById(d.id)!.type, ItemType.wishlist);
      await undo!();
      expect(c.itemById(d.id)!.type, ItemType.task);
      expect(c.itemById(d.id)!.inbox, isTrue);
    });

    test('this week / no date / done / delete', () async {
      final e = await env0();
      final c = e.controller;
      final a = await c.quickAdd('a');
      await c.triage(a.id, TriageChoice.thisWeek);
      expect(isDueThisWeekX(c.itemById(a.id)!, c), isTrue);
      final b = await c.quickAdd('b');
      await c.triage(b.id, TriageChoice.noDate);
      expect(c.itemById(b.id)!.dueAt, isNull);
      final d = await c.quickAdd('d');
      await c.triage(d.id, TriageChoice.done);
      expect(c.itemById(d.id)!.status, ItemStatus.done);
      final x = await c.quickAdd('x');
      await c.triage(x.id, TriageChoice.delete);
      expect(c.itemById(x.id), isNull);
    });

    test('share saves to the inbox first (nothing lost)', () async {
      final e = await env0();
      final i = (await e.controller.handleShare(SharedContent(text: 'https://youtu.be/xyz', subject: 'یه ویدیو')))!;
      expect(i.inbox, isTrue);
      expect(i.url, 'https://youtu.be/xyz');
    });

    test('Smart Inbox suggestions are Pro only and never applied automatically', () async {
      final e = await env0();
      final c = e.controller;
      final v = await c.quickAdd('x', url: 'https://youtu.be/1');
      expect(c.suggestionFor(v), isNull);
      await c.pro.applyPurchase(ProPlans.month1);
      expect(c.suggestionFor(c.itemById(v.id)!)!.type, ItemType.watch);
      expect(c.itemById(v.id)!.type, ItemType.task, reason: 'suggestion must not change the item');
      final plain = await c.quickAdd('شیر بخرم');
      expect(c.suggestionFor(plain), isNull);
    });
  });

  group('Dashboard & shelves', () {
    test('counts per shelf; sealed and unopened messages count as future', () async {
      final e = await env0(items: [
        item('t', due: DateTime(2026, 9, 30)),
        typed('r1', ItemType.read),
        typed('r2', ItemType.read),
        typed('w', ItemType.watch),
        typed('s', ItemType.wishlist),
        typed('i', ItemType.idea),
        typed('c', ItemType.capsule, unlock: t0.add(const Duration(days: 9))),
        typed('f', ItemType.future),
        typed('done', ItemType.read, stage: ItemStages.read).copyWith(status: ItemStatus.done),
      ]);
      e.controller.addPerson('علی');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final d = e.controller.dashboardCounts();
      expect((d.today, d.read, d.watch, d.wishlist, d.ideas, d.future), (1, 2, 1, 1, 1, 2));
      expect(d.people, 1);
    });

    test('shelf stats', () async {
      final e = await env0(items: [
        typed('a', ItemType.read, created: t0.subtract(const Duration(days: 10))).copyWith(estimatedMinutes: 20),
        typed('b', ItemType.read, created: t0.subtract(const Duration(days: 4)), stage: ItemStages.read)
            .copyWith(status: ItemStatus.done, completedAt: t0),
      ]);
      final s = e.controller.shelfStats(ItemType.read);
      expect((s.waiting, s.finished, s.finishedThisWeek, s.minutesWaiting), (1, 1, 1, 20));
      expect(s.avgDaysToFinish, 4);
    });

    test('marking read moves it to history; reopen brings it back', () async {
      final e = await env0(items: [typed('a', ItemType.read)]);
      final c = e.controller;
      await c.setStage('a', ItemStages.read);
      expect(c.shelf(ItemType.read), isEmpty);
      expect(c.shelfHistory(ItemType.read).length, 1);
      await c.setStage('a', ItemStages.unread);
      expect(c.shelf(ItemType.read).length, 1);
    });
  });

  group('Wishlist', () {
    test('price history is recorded on change; target price is Pro', () async {
      final e = await env0(items: [typed('w', ItemType.wishlist)]);
      final c = e.controller;
      await c.setPrice('w', 1000000);
      await c.setPrice('w', 900000);
      await c.setPrice('w', 900000);
      expect(c.itemById('w')!.price, 900000);
      expect(c.itemById('w')!.priceHistory.map((e) => e.$2), [1000000, 900000]);
      await c.setTargetPrice('w', 800000);
      expect(c.itemById('w')!.targetPrice, isNull, reason: 'free');
      await c.pro.applyPurchase(ProPlans.month1);
      await c.setTargetPrice('w', 800000);
      expect(c.itemById('w')!.targetPrice, 800000);
    });

    test('"still want it?" after the configured days; three answers', () async {
      final e = await env0(items: [
        typed('old', ItemType.wishlist, created: t0.subtract(const Duration(days: 40))),
        typed('new', ItemType.wishlist, created: t0.subtract(const Duration(days: 3))),
      ]);
      final c = e.controller;
      expect(c.wishlistToReview().map((i) => i.id), ['old']);
      expect(c.homeCounts().stale, 1);
      await c.answerWishlist('old', WishAnswer.still);
      expect(c.wishlistToReview(), isEmpty);
      await c.answerWishlist('new', WishAnswer.unsure);
      expect(c.itemById('new')!.stage, ItemStages.maybe);
      await c.answerWishlist('new', WishAnswer.no);
      expect(c.itemById('new')!.stage, ItemStages.notInterested);
      expect(c.itemById('new')!.status, ItemStatus.dropped);
    });
  });

  group('Ideas', () {
    test('review, score and links are Pro; convert to task', () async {
      final e = await env0(items: [
        typed('a', ItemType.idea, created: t0.subtract(const Duration(days: 45))),
        typed('b', ItemType.idea, created: t0),
      ]);
      final c = e.controller;
      expect(c.ideasToReview().map((i) => i.id), ['a']);
      expect(c.homeCounts().stale, 0, reason: 'ideas have their own review');
      await c.linkItems('a', 'b');
      expect(c.itemById('a')!.links, isEmpty, reason: 'free');
      expect(await c.convertIdeaToTask('a'), isNull);
      await c.pro.applyPurchase(ProPlans.month1);
      await c.linkItems('a', 'b');
      expect(c.itemById('a')!.links, ['b']);
      expect(c.itemById('b')!.links, ['a']);
      await c.reviewIdea('a', stage: ItemStages.thinking, score: 8);
      expect((c.itemById('a')!.score, c.itemById('a')!.stage), (8, ItemStages.thinking));
      expect(c.ideasToReview(), isEmpty);
      await c.convertIdeaToTask('a');
      expect(c.itemById('a')!.type, ItemType.task);
    });

    test('monthly review reminder is a Pro system reminder', () async {
      final e = await env0(items: [typed('a', ItemType.idea)],
          settings: readySettings.copyWith(ideaReviewReminder: true));
      final c = e.controller;
      await c.syncReminders();
      expect(e.gateway.scheduled, isEmpty, reason: 'free');
      await c.pro.applyPurchase(ProPlans.month1);
      await c.syncReminders();
      final r = e.gateway.scheduled.values.single.reminder;
      expect((r.itemId, r.repeat), ('sys:idea_review', RepeatRule.monthly));
    });
  });

  group('People', () {
    test('add, talk, reminders, delete keeps items', () async {
      final e = await env0();
      final c = e.controller;
      final p = await c.addPerson('علی', contactUri: 'content://com.android.contacts/contacts/lookup/x/1');
      expect(c.nextReminderOf(p.id), isNull);
      final r = await c.addPersonReminder(p.id, title: 'بهش پیام بده', dueAt: DateTime(2026, 10, 1));
      expect(r.type, ItemType.person);
      expect(c.nextReminderOf(p.id), DateTime(2026, 10, 1));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(e.gateway.scheduled.length, 1);
      await c.logInteraction(p.id);
      expect(c.personById(p.id)!.lastInteractionAt, t0);
      expect((await c.interactionsOf(p.id)), isEmpty, reason: 'history is Pro');
      await c.deletePerson(p.id);
      expect(c.people, isEmpty);
      expect(c.itemById(r.id)!.personId, isNull);
    });

    test('Pro: history, follow-up reminder, groups, "time to reach out"', () async {
      final e = await env0(pro: true);
      final c = e.controller;
      final p = await c.addPerson('سارا', group: 'خانواده');
      expect(p.group, 'خانواده');
      await c.logInteraction(p.id, note: 'تماس', followUpDays: 10);
      expect((await c.interactionsOf(p.id)).single.note, 'تماس');
      expect(c.nextReminderOf(p.id), Dates.startOfDay(Dates.addDays(t0, 10)));
      expect(c.peopleDue(days: 30), isEmpty);
      e.clockNow = t0.add(const Duration(days: 40));
      expect(c.peopleDue(days: 30).map((x) => x.id), [p.id]);
    });

    test('free users cannot set groups', () async {
      final e = await env0();
      final p = await e.controller.addPerson('x', group: 'g');
      expect(p.group, '');
    });
  });

  group('Collections (Pro)', () {
    test('free cannot create, Pro can, deleting keeps items', () async {
      final e = await env0(items: [typed('w', ItemType.wishlist)]);
      final c = e.controller;
      expect(c.canAddCollection(ItemType.wishlist), isFalse);
      expect(await c.addCollection('لیست دوم', ItemType.wishlist), isNull);
      await c.pro.applyPurchase(ProPlans.month1);
      final col = (await c.addCollection('لیست دوم', ItemType.wishlist))!;
      await c.setCollection('w', col.id);
      expect(c.shelf(ItemType.wishlist, collectionId: col.id).length, 1);
      await c.deleteCollection(col.id);
      expect(c.itemById('w')!.collectionId, isNull);
    });
  });

  group('Attachments (Pro)', () {
    test('size and count limits, storage, removal, orphan sweep', () async {
      final e = await env0(pro: true);
      final c = e.controller;
      final m = (await c.seal(title: 'm', unlockAt: t0.add(const Duration(days: 9)), message: true))!;
      final a = (await c.addAttachment(m.id, 'p.png', 'image/png', Uint8List.fromList([1, 2, 3])))!;
      expect((await c.attachmentBytes(a.id))!.length, 3);
      expect(() => c.addAttachment(m.id, 'big', 'image/png', Uint8List(ProLimits.maxAttachmentBytes + 1)), throwsArgumentError);
      await c.addAttachment(m.id, 'b', 'image/png', Uint8List(2));
      await c.addAttachment(m.id, 'c', 'image/png', Uint8List(2));
      expect(() => c.addAttachment(m.id, 'd', 'image/png', Uint8List(2)), throwsStateError);
      await c.delete(m.id);
      await c.sweepAttachments();
      expect(c.attachments, isEmpty);
      expect((await c.attachmentBytes(a.id)), isNull);
    });

    test('free users cannot attach', () async {
      final e = await env0();
      final m = (await e.controller.seal(title: 'm', unlockAt: t0.add(const Duration(days: 9)), message: true))!;
      expect(await e.controller.addAttachment(m.id, 'p', 'image/png', Uint8List(3)), isNull);
    });
  });

  group('Roulette in the controller', () {
    test('free ignores Pro filters; Pro applies them; history is logged', () async {
      final e = await env0(items: [
        item('a', category: 'work', minutes: 90),
        item('b', category: 'read', minutes: 5),
      ]);
      final c = e.controller;
      final freeOpts = c.rouletteOptions(minutes: 10, categories: {'work'});
      expect(freeOpts.availableMinutes, isNull);
      expect(freeOpts.categoryIds, isNull);
      await c.pro.applyPurchase(ProPlans.month1);
      final o = c.rouletteOptions(minutes: 10);
      expect(o.availableMinutes, 10);
      for (var k = 0; k < 20; k++) {
        expect((await c.spinRoulette(options: o))!.id, 'b');
      }
      final h = await c.rouletteHistory();
      expect(h.length, 20);
      expect(h.first.$2!.id, 'b');
    });

    test('category selection from settings is Pro', () async {
      final e = await env0(
          items: [item('a', category: 'work'), item('b', category: 'read')],
          settings: readySettings.copyWith(rouletteCategories: {'read'}));
      final c = e.controller;
      expect(c.rouletteOptions().categoryIds, isNull);
      await c.pro.applyPurchase(ProPlans.month1);
      expect(c.rouletteOptions().categoryIds, {'read'});
    });
  });

  group('Universal search', () {
    test('finds every shelf and people; sealed content stays hidden', () {
      final items = [
        typed('r', ItemType.read, title: 'مقاله‌ی نور'),
        typed('w', ItemType.watch, title: 'ویدیوی نور'),
        typed('c', ItemType.capsule, unlock: t0.add(const Duration(days: 9)), title: 'نورِ محرمانه'),
        typed('d', ItemType.read, title: 'نور تموم‌شده').copyWith(status: ItemStatus.done),
      ];
      final people = [Person(id: 'p', name: 'نورا', createdAt: t0, updatedAt: t0)];
      final hits = universalSearch(items: items, people: people, query: 'نور', now: t0, advanced: false);
      expect(hits.where((h) => h.kind == HitKind.item).map((h) => h.id).toSet(), {'r', 'w', 'd'});
      expect(hits.any((h) => h.kind == HitKind.person), isTrue);
      expect(hits.first.status, ItemStatus.active, reason: 'active before finished');
      expect(sealedPlaceholders(items, t0).single.title, '');
    });
  });

  group('Backup v2 through the controller', () {
    test('people, collections, typed items, attachments and settings survive export -> wipe -> restore', () async {
      final a = await env0(pro: true, items: [typed('w', ItemType.wishlist)]);
      final c = a.controller;
      final p = await c.addPerson('علی', contactUri: 'content://com.android.contacts/contacts/lookup/x/1');
      await c.logInteraction(p.id, note: 'x');
      await c.addPersonReminder(p.id, title: 'پیام', dueAt: DateTime(2026, 10, 2));
      final col = (await c.addCollection('دوم', ItemType.wishlist))!;
      await c.setCollection('w', col.id);
      await c.setPrice('w', 1500000);
      final m = (await c.seal(title: 'm', body: 'b', unlockAt: t0.add(const Duration(days: 200)), message: true))!;
      await c.addAttachment(m.id, 'p.png', 'image/png', Uint8List.fromList([9, 8, 7]));
      await c.updateSettings((s) => s.copyWith(themeMode: ThemeMode.dark, rouletteCategories: {'read'}));
      final bytes = await c.buildBackupBytes();

      final b = await env0();
      await b.controller.restore(b.controller.inspectBackup(bytes));
      final r = b.controller;
      expect(r.people.single.name, 'علی');
      expect((await r.interactionsOf(p.id)).length, 1);
      expect(r.collections.single.name, 'دوم');
      expect(r.itemById('w')!.collectionId, col.id);
      expect(r.itemById('w')!.price, 1500000);
      expect(r.itemById(m.id)!.type, ItemType.future);
      expect(r.itemById(m.id)!.isLockedAt(b.clockNow), isTrue);
      final att = r.attachmentsOf(m.id).single;
      expect(await r.attachmentBytes(att.id), Uint8List.fromList([9, 8, 7]));
      expect(r.settings.rouletteCategories, {'read'});
      expect(r.settings.themeMode, ThemeMode.dark);
    });

    test('a real v1 backup file (from the first release) still restores', () async {
      // Built exactly like the v1 codec did: no people/collections/attachments,
      // items without the v2 columns.
      final data = <String, Object?>{
        'items': [
          {
            'id': 'old1', 'title': 'قدیمی', 'description': '', 'note': '', 'category_id': 'read', 'url': null,
            'tags': '[]', 'priority': 1, 'est_minutes': null, 'due_at': null, 'has_time': 0, 'reminder_enabled': 0,
            'reminder_offset_min': 0, 'repeat_rule': 0, 'status': 0, 'created_at': t0.millisecondsSinceEpoch,
            'updated_at': t0.millisecondsSinceEpoch, 'completed_at': null, 'dropped_at': null, 'snooze_count': 0,
            'last_kept_at': null, 'source': 'manual',
          }
        ],
        'categories': [],
        'events': [],
        'settings': const AppSettings(onboardingDone: true).toMap(),
      };
      final checksum = sha256.convert(utf8.encode(jsonEncode(data))).toString();
      final file = utf8.encode(jsonEncode({
        'format': 'later-backup', 'schemaVersion': 1, 'appVersion': '1.0.0',
        'createdAt': t0.millisecondsSinceEpoch, 'checksum': checksum, 'data': data,
      }));
      final decoded = BackupCodec().decode(Uint8List.fromList(file));
      expect(decoded.sourceSchemaVersion, 1);
      final i = decoded.snapshot.items.single;
      expect((i.type, i.stage, i.inbox), (ItemType.task, 0, false));
      expect(i.extra, isEmpty);
      expect(decoded.snapshot.people, isEmpty);
    });
  });

  group('Database migration v1 -> v2', () {
    test('an existing v1 database keeps its rows and gains the new columns/tables', () async {
      sqfliteFfiInit();
      final dir = await databaseFactoryFfi.getDatabasesPath();
      final path = '$dir/v1_${DateTime.now().microsecondsSinceEpoch}.db';
      final v1 = await databaseFactoryFfi.openDatabase(path,
          options: OpenDatabaseOptions(version: 1, onCreate: (db, _) async {
            await db.execute('''CREATE TABLE items (id TEXT PRIMARY KEY, title TEXT NOT NULL, description TEXT NOT NULL DEFAULT '',
              note TEXT NOT NULL DEFAULT '', category_id TEXT NOT NULL, url TEXT, tags TEXT NOT NULL DEFAULT '[]',
              priority INTEGER NOT NULL DEFAULT 1, est_minutes INTEGER, due_at INTEGER, has_time INTEGER NOT NULL DEFAULT 0,
              reminder_enabled INTEGER NOT NULL DEFAULT 0, reminder_offset_min INTEGER NOT NULL DEFAULT 0,
              repeat_rule INTEGER NOT NULL DEFAULT 0, status INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL, completed_at INTEGER, dropped_at INTEGER, snooze_count INTEGER NOT NULL DEFAULT 0,
              last_kept_at INTEGER, source TEXT)''');
            await db.execute('CREATE TABLE categories (id TEXT PRIMARY KEY, name TEXT NOT NULL, emoji TEXT NOT NULL, builtin INTEGER NOT NULL DEFAULT 0, sort_order INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL)');
            await db.execute('CREATE TABLE events (id INTEGER PRIMARY KEY AUTOINCREMENT, item_id TEXT NOT NULL, type INTEGER NOT NULL, at INTEGER NOT NULL, category_id TEXT, days_waited INTEGER)');
            await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
            await db.insert('items', {'id': 'legacy', 'title': 'از نسخه‌ی ۱', 'category_id': 'other', 'created_at': 1, 'updated_at': 1});
            await db.insert('categories', {'id': 'other', 'name': '', 'emoji': '📦', 'builtin': 1, 'sort_order': 0, 'created_at': 1});
          }));
      await v1.close();
      final adb = await AppDatabase.open(path: path, factory: databaseFactoryFfi, singleInstance: false);
      final repo = LaterRepository(adb);
      final items = await repo.loadItems();
      expect(items.single.title, 'از نسخه‌ی ۱');
      expect((items.single.type, items.single.stage, items.single.inbox), (ItemType.task, 0, false));
      expect(items.single.extra, isEmpty);
      await repo.upsertPerson(Person(id: 'p', name: 'x', createdAt: t0, updatedAt: t0));
      expect((await repo.loadAll()).people.length, 1);
      expect(await adb.db.getVersion(), 3);
      // v3 added picture roles to attachments.
      await adb.db.insert('attachments', {
        'id': 'img1', 'item_id': 'legacy', 'name': 'a.jpg', 'mime': 'image/jpeg', 'size': 1,
        'created_at': 1, 'role': 'image',
      });
      final att = await repo.loadAll();
      expect(att.attachments.single.role, 'image');
      await adb.close();
      await databaseFactoryFfi.deleteDatabase(path);
    });
  });
}

bool isDueThisWeekX(LaterItem i, LaterController c) {
  final n = c.now();
  final start = Dates.startOfWeek(n, c.settings.weekStart);
  return i.dueAt != null && !i.dueAt!.isBefore(start) && i.dueAt!.isBefore(Dates.addDays(start, 7));
}
