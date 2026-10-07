import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:later/core/config/pro_plans.dart';
import 'package:later/data/backup/backup_codec.dart';
import 'package:later/data/controller.dart';
import 'package:later/domain/classifier.dart';
import 'package:later/domain/game_picker.dart';
import 'package:later/domain/learning.dart';
import 'package:later/domain/models.dart';
import 'package:later/domain/pro.dart';
import 'package:later/domain/transitions.dart';
import 'package:later/domain/widget_pick.dart';
import 'package:later/services/image_picker_gateway.dart';
import 'package:later/services/image_processor.dart';
import 'package:later/ui/type_info.dart';

import 'harness.dart';
import 'helpers.dart';

Future<TestEnv> env0({List<LaterItem> items = const [], bool pro = false}) async {
  final e = await TestEnv.create(settings: readySettings, items: items);
  await e.controller.init();
  if (pro) await e.controller.pro.applyPurchase(ProPlans.month1);
  return e;
}

LaterItem it(String id, ItemType t, {int stage = 0, String? title, int? minutes, Map<String, Object?> extra = const {}, DateTime? created, ItemPriority p = ItemPriority.normal}) =>
    item(id, title: title ?? 'x $id', minutes: minutes, created: created, priority: p)
        .copyWith(type: t, stage: stage, status: ItemStages.statusFor(t, stage), extra: extra);

Uint8List png(int w, int h, {bool alpha = false}) {
  final im = img.Image(width: w, height: h, numChannels: 4);
  final r = Random(1);
  for (final px in im) {
    px
      ..r = r.nextInt(256)
      ..g = r.nextInt(256)
      ..b = r.nextInt(256)
      ..a = alpha ? 90 : 255;
  }
  return Uint8List.fromList(img.encodePng(im));
}

void main() {
  group('Stages of the new shelves', () {
    test('apps', () {
      expect(ItemStages.statusFor(ItemType.app, ItemStages.notInstalled), ItemStatus.active);
      expect(ItemStages.statusFor(ItemType.app, ItemStages.wantInstall), ItemStatus.active);
      expect(ItemStages.statusFor(ItemType.app, ItemStages.evaluating), ItemStatus.active);
      expect(ItemStages.statusFor(ItemType.app, ItemStages.installed), ItemStatus.done);
      expect(ItemStages.statusFor(ItemType.app, ItemStages.appNotWanted), ItemStatus.dropped);
    });
    test('podcasts, courses, games', () {
      expect(ItemStages.statusFor(ItemType.podcast, ItemStages.listenPaused), ItemStatus.active);
      expect(ItemStages.statusFor(ItemType.podcast, ItemStages.listened), ItemStatus.done);
      expect(ItemStages.statusFor(ItemType.course, ItemStages.learnPaused), ItemStatus.active);
      expect(ItemStages.statusFor(ItemType.course, ItemStages.learned), ItemStatus.done);
      expect(ItemStages.statusFor(ItemType.course, ItemStages.learnAbandoned), ItemStatus.dropped);
      expect(ItemStages.statusFor(ItemType.game, ItemStages.playing), ItemStatus.active);
      expect(ItemStages.statusFor(ItemType.game, ItemStages.gameFinished), ItemStatus.done);
      expect(ItemStages.statusFor(ItemType.game, ItemStages.gameDropped), ItemStatus.dropped);
    });
    test('every stage of every type maps to a status and a label', () {
      for (final t in ItemType.values) {
        for (final s in ItemStages.of(t)) {
          expect(ItemStages.statusFor(t, s), isA<ItemStatus>());
        }
      }
    });
    test('finishing a podcast sets 100% and records history', () {
      final p = it('p', ItemType.podcast, extra: {'progress': 40});
      final t = Transitions.setStage(p, ItemStages.listened, t0);
      expect(t.item.progress, 100);
      expect(t.item.stageHistory.last.$2, ItemStages.listened);
    });
  });

  group('Classifier knows the new shelves', () {
    for (final (url, type) in [
      ('https://play.google.com/store/apps/details?id=x', ItemType.app),
      ('https://cafebazaar.ir/app/ir.x', ItemType.app),
      ('https://open.spotify.com/episode/abc', ItemType.podcast),
      ('https://podcasts.apple.com/us/podcast/x', ItemType.podcast),
      ('https://www.udemy.com/course/python/', ItemType.course),
      ('https://maktabkhooneh.org/course/x', ItemType.course),
      ('https://store.steampowered.com/app/1', ItemType.game),
      ('https://www.youtube.com/watch?v=1', ItemType.watch),
      ('https://example.com/post', ItemType.read),
    ]) {
      test(url, () => expect(ItemClassifier.classify('t', url: url).type, type));
    }
  });

  group('Clock text', () {
    test('format and parse', () {
      expect(TypeInfo.clock(1112), '18:32');
      expect(TypeInfo.clock(3930), '1:05:30');
      expect(TypeInfo.parseClock('18:32'), 1112);
      expect(TypeInfo.parseClock('۱۸:۳۲'), 1112);
      expect(TypeInfo.parseClock('45'), 2700);
      expect(TypeInfo.parseClock('1:05:30'), 3930);
      expect(TypeInfo.parseClock('abc'), isNull);
      expect(TypeInfo.parseClock(''), isNull);
    });
  });

  group('Game picker', () {
    final games = [
      it('a', ItemType.game, minutes: 30, extra: {'genre': 'RPG'}),
      it('b', ItemType.game, minutes: 90, extra: {'genre': 'RPG'}),
      it('c', ItemType.game, minutes: 20, extra: {'genre': 'Puzzle'}, p: ItemPriority.high),
      it('d', ItemType.game, stage: ItemStages.gameFinished),
      it('e', ItemType.watch),
    ];
    test('only open games are eligible', () {
      final p = GamePicker(random: Random(1));
      final seen = <String>{};
      for (var i = 0; i < 100; i++) {
        seen.add(p.pick(games, const GameOptions())!.id);
      }
      expect(seen, {'a', 'b', 'c'});
    });
    test('time filter drops games that do not fit', () {
      final p = GamePicker(random: Random(2));
      for (var i = 0; i < 50; i++) {
        expect(['a', 'c'], contains(p.pick(games, const GameOptions(minutes: 45))!.id));
      }
      expect(p.pick(games, const GameOptions(minutes: 5)), isNull);
    });
    test('genre and priority filters', () {
      final p = GamePicker(random: Random(3));
      expect(p.pick(games, const GameOptions(genre: 'puzzle'))!.id, 'c');
      expect(p.pick(games, const GameOptions(priority: ItemPriority.high))!.id, 'c');
      expect(p.pick(games, const GameOptions(genre: 'Racing')), isNull);
    });
    test('smart pick keeps genres varied and prefers games in progress', () {
      final p = GamePicker(random: Random(4));
      final mixed = [
        it('r1', ItemType.game, extra: {'genre': 'RPG'}),
        it('r2', ItemType.game, extra: {'genre': 'RPG'}),
        it('pz', ItemType.game, extra: {'genre': 'Puzzle'}),
      ];
      var puzzles = 0;
      for (var i = 0; i < 300; i++) {
        if (p.pick(mixed, const GameOptions(smart: true, recentGenres: ['RPG']))!.id == 'pz') puzzles++;
      }
      expect(puzzles, greaterThan(150)); // far above the 1/3 of a plain draw
      final playing = [
        it('x', ItemType.game),
        it('y', ItemType.game, stage: ItemStages.playing),
      ];
      var y = 0;
      for (var i = 0; i < 300; i++) {
        if (p.pick(playing, const GameOptions(smart: true))!.id == 'y') y++;
      }
      expect(y, greaterThan(170));
    });
    test('does not repeat the last picks while others remain', () {
      final p = GamePicker(random: Random(5));
      for (var i = 0; i < 40; i++) {
        expect(p.pick(games, const GameOptions(recentIds: ['a', 'b']))!.id, 'c');
      }
    });
  });

  group('Learning numbers', () {
    test('week, month, total and streak', () {
      final now = DateTime(2026, 9, 30, 12); // Wednesday
      final s = [
        (DateTime(2026, 9, 30, 9), 30),
        (DateTime(2026, 9, 29, 9), 20),
        (DateTime(2026, 9, 28, 9), 10),
        (DateTime(2026, 9, 20, 9), 60),
      ];
      final st = statsOfSessions(s, now, weekStart: 6);
      expect(st.totalMinutes, 120);
      expect(st.monthMinutes, 120);
      expect(st.weekMinutes, 60);
      expect(st.streakDays, 3);
    });
    test('a streak survives until a whole day is missed', () {
      final now = DateTime(2026, 9, 30, 12);
      expect(statsOfSessions([(DateTime(2026, 9, 29, 8), 5)], now, weekStart: 6).streakDays, 1);
      expect(statsOfSessions([(DateTime(2026, 9, 27, 8), 5)], now, weekStart: 6).streakDays, 0);
    });
  });

  group('Widget suggestion is based on real data', () {
    final morning = DateTime(2026, 9, 30, 9);
    final evening = DateTime(2026, 9, 30, 21);
    test('nothing -> null; inbox items are never suggested', () {
      expect(widgetPick(const [], morning), isNull);
      expect(widgetPick([it('i', ItemType.task).copyWith(inbox: true)], morning), isNull);
    });
    test('due today beats everything in the morning', () {
      final r = widgetPick([
        it('l', ItemType.course, stage: ItemStages.learning),
        it('t', ItemType.task).copyWith(dueAt: DateTime(2026, 9, 30)),
      ], morning)!;
      expect((r.kind, r.item.id), (WidgetPickKind.today, 't'));
    });
    test('learning in progress, then a podcast in progress', () {
      expect(widgetPick([it('l', ItemType.course, stage: ItemStages.learning)], morning)!.kind, WidgetPickKind.learn);
      expect(widgetPick([it('p', ItemType.podcast, stage: ItemStages.listening)], morning)!.kind, WidgetPickKind.listen);
    });
    test('a short episode for spare time, a short game when there is time', () {
      final p = widgetPick([it('p', ItemType.podcast, minutes: 24), it('q', ItemType.podcast, minutes: 90)], morning)!;
      expect((p.kind, p.item.id), (WidgetPickKind.freeTime, 'p'));
      expect(widgetPick([it('g', ItemType.game, minutes: 30)], morning)!.kind, WidgetPickKind.game);
    });
    test('in the evening leisure comes before chores (unless overdue)', () {
      final r = widgetPick([
        it('t', ItemType.task).copyWith(dueAt: DateTime(2026, 9, 30)),
        it('g', ItemType.game, minutes: 30),
      ], evening)!;
      expect(r.kind, WidgetPickKind.game);
      final overdue = widgetPick([
        it('t', ItemType.task).copyWith(dueAt: DateTime(2026, 9, 20)),
        it('g', ItemType.game, minutes: 30),
      ], evening)!;
      expect(overdue.kind, WidgetPickKind.today);
    });
    test('deterministic: same data, same answer', () {
      final data = [it('a', ItemType.read), it('b', ItemType.read, created: DateTime(2026, 8, 1))];
      expect(widgetPick(data, morning)!.item.id, widgetPick(data, morning)!.item.id);
    });
  });

  group('Controller: podcasts, courses, apps, games', () {
    test('progress by percent and by position stay in sync and move the status', () async {
      final e = await env0(items: [it('p', ItemType.podcast, extra: {'durationSec': 3600})]);
      final c = e.controller;
      await c.setProgress('p', percent: 42);
      var p = c.itemById('p')!;
      expect((p.progress, p.positionSec, p.stage), (42, 1512, ItemStages.listening));
      expect(p.remainingSec, 3600 - 1512);
      await c.setProgress('p', positionSec: 1800);
      p = c.itemById('p')!;
      expect((p.progress, p.positionSec), (50, 1800));
      await c.setProgress('p', percent: 100);
      p = c.itemById('p')!;
      expect((p.stage, p.status, p.progress), (ItemStages.listened, ItemStatus.done, 100));
      expect(c.inProgress(ItemType.podcast), isEmpty);
    });

    test('a podcast without a known length still keeps a percentage', () async {
      final e = await env0(items: [it('p', ItemType.podcast)]);
      await e.controller.setProgress('p', percent: 30);
      expect(e.controller.itemById('p')!.progress, 30);
      expect(e.controller.itemById('p')!.remainingSec, isNull);
    });

    test('continue list is most recent first; queue follows the time you have (Pro data, free API)', () async {
      final e = await env0(items: [
        it('a', ItemType.podcast, minutes: 60),
        it('b', ItemType.podcast, minutes: 15),
        it('c', ItemType.podcast, minutes: 25, stage: ItemStages.listening),
      ]);
      final c = e.controller;
      expect(c.inProgress(ItemType.podcast).map((i) => i.id), ['c']);
      expect(c.podcastQueue().map((i) => i.id), ['c', 'b', 'a']);
      expect(c.podcastQueue(minutes: 30).map((i) => i.id), ['c', 'b']);
    });

    test('sessions are Pro; free users cannot log them', () async {
      final e = await env0(items: [it('k', ItemType.course), it('g', ItemType.game)]);
      expect(await e.controller.logSession('k', 30), isFalse);
      expect(await e.controller.logSession('g', 30), isFalse);
      expect(e.controller.itemById('k')!.sessions, isEmpty);
    });

    test('Pro: sessions are logged, set the course in progress, and feed stats', () async {
      final e = await env0(items: [it('k', ItemType.course), it('g', ItemType.game)], pro: true);
      final c = e.controller;
      expect(await c.logSession('k', 40), isTrue);
      expect(c.itemById('k')!.stage, ItemStages.learning);
      expect(await c.logSession('k', 20, at: e.clockNow.subtract(const Duration(days: 1))), isTrue);
      expect(await c.logSession('g', 45), isTrue);
      expect(c.itemById('g')!.stage, ItemStages.playing);
      final st = c.sessionStatsFor(ItemType.course);
      expect((st.totalMinutes, st.streakDays, st.sessionCount), (60, 2, 2));
      expect(await c.logSession('k', 0), isFalse);
      expect(await c.logSession('k', 99999), isFalse);
      expect(await c.logSession('missing', 5), isFalse);
    });

    test('learning goal text is free; date and weekly target are Pro', () async {
      final free = await env0(items: [it('k', ItemType.course)]);
      await free.controller.setLearnGoal('k', goal: 'Python برای AI', goalDate: DateTime(2027, 1, 1), weeklyMinutes: 120);
      var k = free.controller.itemById('k')!;
      expect(k.goal, 'Python برای AI');
      expect(k.goalDate, isNull);
      expect(k.weeklyGoalMinutes, isNull);
      final pro = await env0(items: [it('k', ItemType.course)], pro: true);
      await pro.controller.setLearnGoal('k', goal: 'g', goalDate: DateTime(2027, 1, 1), weeklyMinutes: 120);
      k = pro.controller.itemById('k')!;
      expect(k.goalDate, DateTime(2027, 1, 1));
      expect(k.weeklyGoalMinutes, 120);
    });

    test('platforms: one for free, many for Pro, junk is dropped', () async {
      final free = await env0(items: [it('a', ItemType.app)]);
      await free.controller.setPlatforms('a', ['android', 'ios', 'bogus']);
      expect(free.controller.itemById('a')!.platforms, ['android']);
      final pro = await env0(items: [it('a', ItemType.app)], pro: true);
      await pro.controller.setPlatforms('a', ['android', 'ios', 'bogus', 'web']);
      expect(pro.controller.itemById('a')!.platforms, ['android', 'ios', 'web']);
    });

    test('free text fields are cleaned and capped', () async {
      final e = await env0(items: [it('g', ItemType.game)]);
      await e.controller.update(e.controller.itemById('g')!.copyWith(extra: {
        'genre': '  RPG  ',
        'creator': 'x' * 5000,
        'level': 'wizard',
        'progress': 400,
        'durationSec': -5,
      }));
      final g = e.controller.itemById('g')!;
      expect(g.genre, 'RPG');
      expect(g.creator.length, lessThanOrEqualTo(200));
      expect(g.level, '');
      expect(g.progress, 100);
      expect(g.durationSec, isNull);
    });

    test('app review: the four answers', () async {
      final e = await env0(items: [
        for (final id in ['a', 'b', 'c', 'd']) it(id, ItemType.app, created: DateTime(2026, 8, 1)),
      ]);
      final c = e.controller;
      await c.answerAppReview('a', AppAnswer.installed);
      expect(c.itemById('a')!.status, ItemStatus.done);
      await c.answerAppReview('b', AppAnswer.still);
      expect((c.itemById('b')!.stage, c.itemById('b')!.status), (ItemStages.wantInstall, ItemStatus.active));
      expect(c.itemById('b')!.lastReviewedAt, isNotNull);
      await c.answerAppReview('c', AppAnswer.later);
      expect(c.itemById('c')!.isActive, isTrue);
      // "ask me later" keeps it waiting (it is not finished, dropped or moved).
      expect(c.itemById('c')!.stage, ItemStages.notInstalled);
      await c.answerAppReview('d', AppAnswer.no);
      expect(c.itemById('d')!.status, ItemStatus.dropped);
      expect(c.itemById('d')!.stage, ItemStages.appNotWanted);
    });

    test('status history is kept for every change', () async {
      final e = await env0(items: [it('a', ItemType.app)]);
      final c = e.controller;
      await c.setStage('a', ItemStages.wantInstall);
      await c.setStage('a', ItemStages.evaluating);
      await c.setStage('a', ItemStages.installed);
      expect(c.itemById('a')!.stageHistory.map((e) => e.$2), [1, 2, 3]);
    });

    test('game pick: free = plain draw (filters ignored), Pro = filters honoured', () async {
      final games = [
        it('a', ItemType.game, minutes: 30, extra: {'genre': 'RPG'}),
        it('b', ItemType.game, minutes: 120, extra: {'genre': 'Puzzle'}),
      ];
      final free = await env0(items: games);
      final seen = <String>{};
      for (var i = 0; i < 40; i++) {
        seen.add((await free.controller.pickGameNow(options: free.controller.gameOptions(minutes: 10, genre: 'RPG')))!.id);
      }
      expect(seen, {'a', 'b'}); // the Pro filters did nothing
      final pro = await env0(items: games, pro: true);
      for (var i = 0; i < 20; i++) {
        expect((await pro.controller.pickGameNow(options: pro.controller.gameOptions(minutes: 45)))!.id, 'a');
      }
      expect(await pro.controller.pickGameNow(options: pro.controller.gameOptions(minutes: 5)), isNull);
      expect(pro.controller.gameGenres(), ['Puzzle', 'RPG']);
    });

    test('roulette can draw podcasts, courses and games but not apps', () async {
      final e = await env0(items: [
        it('p', ItemType.podcast), it('k', ItemType.course), it('g', ItemType.game), it('a', ItemType.app),
      ]);
      final seen = <String>{};
      for (var i = 0; i < 200; i++) {
        seen.add((await e.controller.spinRoulette())!.id);
      }
      expect(seen, {'p', 'k', 'g'});
    });

    test('dashboard counts and widget snapshot carry the new shelves', () async {
      final e = await env0(items: [
        it('p', ItemType.podcast), it('k', ItemType.course), it('g', ItemType.game), it('a', ItemType.app),
        it('x', ItemType.course, stage: ItemStages.learned),
      ]);
      final d = e.controller.dashboardCounts();
      expect((d.podcasts, d.courses, d.games, d.apps), (1, 1, 1, 1));
      e.controller.refreshProState();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final w = e.platform.lastWidget!;
      expect(w.counts['learn'], 1);
      expect(w.counts['podcasts'], 1);
      expect(w.counts['games'], 1);
      expect(w.smartText, isNotNull);
      expect(w.strings['tagline'], isNotEmpty);
    });
  });

  group('Widget: today', () {
    test('todayItems lists every shelf, overdue first, and reaches the widget', () async {
      final e = await env0(items: [
        it('p', ItemType.podcast),
      ]);
      final n = e.controller.now();
      final day = DateTime(n.year, n.month, n.day, 12);
      await e.controller.saveNew(item('t1', title: 'امروز', due: day));
      await e.controller.saveNew(item('t2', title: 'دیروز', due: day.subtract(const Duration(days: 2))));
      await e.controller.saveNew(item('t3', title: 'فردا', due: day.add(const Duration(days: 3))));
      await e.controller.saveNew(it('g', ItemType.game, title: 'بازی امروز').copyWith(dueAt: day));
      final today = e.controller.todayItems();
      expect(today.map((i) => i.id).toList().first, 't2');
      expect(today.map((i) => i.id).toSet(), {'t1', 't2', 'g'});
      expect(e.controller.dashboardCounts().today, 3);
      e.controller.refreshProState();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final w = e.platform.lastWidget!;
      expect(w.todayItems.length, 3);
      expect(w.todayItems.first['overdue'], true);
      expect(w.todayItems.first['title'], 'دیروز');
      expect(w.toMap()['today'], isA<List<Object?>>());
    });

    test('the widget offer is remembered and pinning goes through the bridge', () async {
      final e = await env0(items: []);
      await e.controller.updateSettings((s) => s.copyWith(widgetOffered: false));
      expect(e.controller.settings.widgetOffered, false);
      await e.controller.updateSettings((s) => s.copyWith(widgetOffered: true));
      expect(e.controller.settings.widgetOffered, true);
      expect(await e.controller.addWidgetToHome(), true);
      expect(e.platform.pinRequests, 1);
    });
  });

  group('Pictures', () {
    testWidgets('a big photo is shrunk, re-encoded as JPEG without metadata, with a thumbnail', (tester) async {
      final src = png(3000, 2000);
      final p = (await tester.runAsync(() => const DefaultImageProcessor().process(src)))!;
      expect(sniffImageType(p.full), 'image/jpeg');
      expect(sniffImageType(p.thumb), 'image/jpeg');
      expect(max(p.width, p.height), 1600);
      final dec = img.decodeJpg(p.full)!;
      expect(dec.width, 1600);
      expect(dec.height, 1067);
      final th = img.decodeJpg(p.thumb)!;
      expect(max(th.width, th.height), 320);
      expect(p.full.length, lessThan(src.length));
      // No EXIF block (APP1 "Exif") may survive the re-encode.
      expect(latin1.decode(p.full, allowInvalid: true).contains('Exif'), isFalse);
    });

    testWidgets('a small picture is not enlarged; transparency is flattened', (tester) async {
      final p = (await tester.runAsync(() => const DefaultImageProcessor().process(png(200, 100, alpha: true))))!;
      expect((p.width, p.height), (200, 100));
    });

    testWidgets('invalid and oversized input is refused', (tester) async {
      Future<ImageError?> err(Uint8List b) async {
        try {
          await const DefaultImageProcessor().process(b);
          return null;
        } on ImageException catch (e) {
          return e.kind;
        }
      }

      expect((await tester.runAsync(() => err(Uint8List.fromList([1, 2, 3, 4]))))!, ImageError.invalid);
      expect((await tester.runAsync(() => err(Uint8List(0))))!, ImageError.invalid);
      // A "PNG" header followed by garbage must not crash.
      final fake = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3, 4, 5, 6, 7, 8]);
      expect((await tester.runAsync(() => err(fake)))!, ImageError.invalid);
      final huge = Uint8List(ProLimits.maxImageSourceBytes + 1)..setRange(0, 3, [0xFF, 0xD8, 0xFF]);
      expect((await tester.runAsync(() => err(huge)))!, ImageError.tooLarge);
    });

    test('type sniffing ignores names and trusts bytes', () {
      expect(sniffImageType(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])), 'image/jpeg');
      expect(sniffImageType(Uint8List.fromList(utf8.encode('<svg></svg>'))), isNull);
      expect(sniffImageType(Uint8List.fromList(utf8.encode('#!/bin/sh'))), isNull);
    });

    testWidgets('free: one picture (the cover); Pro: a gallery with a chosen cover', (tester) async {
      final e = (await tester.runAsync(() => env0(items: [it('a', ItemType.wishlist)])))!;
      final c = e.controller;
      final p = (await tester.runAsync(() => c.processImage(png(400, 300))))!;
      final first = (await tester.runAsync(() => c.attachProcessed('a', p)))!;
      expect(c.imagesOf('a').length, 1);
      expect(c.coverImageId(c.itemById('a')!), first.id);
      expect(c.canAddImage('a'), isFalse);
      await expectLater(() => c.attachProcessed('a', p), throwsStateError);
      expect(c.thumbOfImage(first.id), isNotNull);
      expect(await tester.runAsync(() => c.thumbBytes(first.id)), isNotNull);

      await tester.runAsync(() => c.pro.applyPurchase(ProPlans.month1));
      c.refreshProState();
      expect(c.canAddImage('a'), isTrue);
      final second = (await tester.runAsync(() => c.attachProcessed('a', p)))!;
      expect(c.imagesOf('a').length, 2);
      expect(c.coverImageId(c.itemById('a')!), first.id);
      await tester.runAsync(() => c.setCover('a', second.id));
      expect(c.coverImageId(c.itemById('a')!), second.id);
      // Removing the cover promotes the other picture; thumbnails go with it.
      await tester.runAsync(() => c.removeImage(second.id));
      expect(c.imagesOf('a').length, 1);
      expect(c.coverImageId(c.itemById('a')!), first.id);
      expect(c.thumbOfImage(second.id), isNull);
      expect(await tester.runAsync(() => c.imageBytes(second.id)), isNull);
      await tester.runAsync(() => c.removeImage(first.id));
      expect(c.imagesOf('a'), isEmpty);
      expect(c.coverImageId(c.itemById('a')!), isNull);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('the picker gateway feeds the controller; cancel and bad files are handled', (tester) async {
      final e = (await tester.runAsync(() => env0(items: [it('a', ItemType.app)])))!;
      final fake = e.imagePicker;
      fake.next = null;
      expect(await tester.runAsync(() => e.controller.addImageFrom('a', ImageOrigin.gallery)), isNull);
      fake.next = png(64, 64);
      expect(await tester.runAsync(() => e.controller.addImageFrom('a', ImageOrigin.camera)), isNotNull);
      expect(e.controller.imagesOf('a').length, 1);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('pictures survive backup and restore, thumbnails included', (tester) async {
      final a = (await tester.runAsync(() => env0(items: [it('a', ItemType.game, extra: {'genre': 'RPG', 'sessions': [[1, 30]]})], pro: true)))!;
      final p = (await tester.runAsync(() => a.controller.processImage(png(300, 200))))!;
      final img1 = (await tester.runAsync(() => a.controller.attachProcessed('a', p)))!;
      final fullBefore = await tester.runAsync(() => a.controller.imageBytes(img1.id));
      final bytes = (await tester.runAsync(() => a.controller.buildBackupBytes()))!;

      final b = (await tester.runAsync(() => env0()))!;
      await tester.runAsync(() => b.controller.restore(b.controller.inspectBackup(bytes)));
      final r = b.controller;
      expect(r.imagesOf('a').length, 1);
      final restored = r.imagesOf('a').single;
      expect(restored.role, AttachmentRole.image);
      expect(await tester.runAsync(() => r.imageBytes(restored.id)), fullBefore);
      expect(r.thumbOfImage(restored.id), isNotNull);
      expect(await tester.runAsync(() => r.thumbBytes(restored.id)), isNotNull);
      expect(r.coverImageId(r.itemById('a')!), restored.id);
      expect(r.itemById('a')!.genre, 'RPG');
      expect(r.itemById('a')!.sessions.single.$2, 30);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('deleting an item and sweeping removes its pictures', (tester) async {
      final e = (await tester.runAsync(() => env0(items: [it('a', ItemType.app)])))!;
      final c = e.controller;
      final p = (await tester.runAsync(() => c.processImage(png(80, 80))))!;
      final i1 = (await tester.runAsync(() => c.attachProcessed('a', p)))!;
      await tester.runAsync(() => c.delete('a'));
      await tester.runAsync(() => c.sweepAttachments());
      expect(await tester.runAsync(() => c.imageBytes(i1.id)), isNull);
      expect(c.imagesOf('a'), isEmpty);
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Backup v3', () {
    test('a v2 backup (attachments without a role) restores as plain files', () {
      final migrated = BackupMigrator.builtinSteps[2]!({
        'data': {
          'attachments': [
            {'id': 'a1', 'item_id': 'i1', 'name': 'n', 'mime': 'image/png', 'size': 1, 'created_at': 1, 'data': 'AA=='}
          ]
        }
      });
      final att = ((migrated['data']! as Map)['attachments']! as List).single as Map;
      expect(att['role'], 'file');
    });

    test('hostile extra fields are cleaned on restore', () async {
      final e = await TestEnv.create(settings: readySettings, items: [
        it('a', ItemType.podcast, extra: {
          'platforms': ['android', '../../etc'],
          'cover': '../../x',
          'progress': 9999,
          'sessions': [
            [1, 5],
            'junk',
            [2]
          ],
          'level': 'evil',
        }),
      ]);
      await e.controller.init();
      final bytes = await e.controller.buildBackupBytes();
      final d = e.controller.inspectBackup(bytes);
      final x = d.snapshot.items.single;
      expect(x.platforms, ['android']);
      expect(x.coverId, isNull);
      expect(x.progress, 100);
      expect(x.sessions.length, 1);
      expect(x.level, '');
    });
  });
}
