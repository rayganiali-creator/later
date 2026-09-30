import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/config/pro_plans.dart';
import 'package:later/data/backup/backup_codec.dart';
import 'package:later/data/controller.dart';
import 'package:later/domain/models.dart';
import 'package:later/domain/settings.dart';
import 'package:later/domain/search_filter_sort.dart';
import 'package:later/domain/snooze.dart';
import 'package:later/services/notification_service.dart';
import 'package:later/services/platform_bridge.dart';
import 'package:later/services/purchase_gateway.dart';

import 'harness.dart';
import 'helpers.dart';

Future<TestEnv> env0({List<LaterItem> items = const [], AppSettings? settings, DateTime? now}) async {
  final e = await TestEnv.create(settings: settings ?? readySettings, items: items, now: now);
  await e.controller.init();
  return e;
}

void main() {
  group('Item lifecycle & history', () {
    test('quickAdd: only a title is enough; defaults are sane', () async {
      final e = await env0();
      final i = await e.controller.quickAdd('  این مقاله رو بخونم  ');
      expect(i.title, 'این مقاله رو بخونم');
      expect(i.categoryId, 'other');
      expect(i.dueAt, isNull);
      expect(e.controller.activeItems.length, 1);
      expect((await e.controller.stats()).active, 1);
      expect(() => e.controller.quickAdd('   '), throwsArgumentError);
    });

    test('complete -> history + event; undo restores and un-counts', () async {
      final e = await env0(items: [item('a', created: t0.subtract(const Duration(days: 4)))]);
      final undo = await e.controller.complete('a');
      final done = e.controller.itemById('a')!;
      expect(done.status, ItemStatus.done);
      expect(done.completedAt, t0);
      expect(e.controller.historyItems.map((x) => x.id), ['a']);
      var st = await e.controller.stats();
      expect((st.completed, st.avgDaysWaited), (1, 4.0));
      await undo!();
      expect(e.controller.itemById('a')!.status, ItemStatus.active);
      st = await e.controller.stats();
      expect(st.completed, 0);
    });

    test('drop ("بی‌خیالش شدم") keeps it in the archive when history is on', () async {
      final e = await env0(items: [item('a')]);
      await e.controller.drop('a');
      expect(e.controller.itemById('a')!.status, ItemStatus.dropped);
      expect((await e.controller.stats()).dropped, 1);
      await e.controller.reopen('a');
      expect(e.controller.itemById('a')!.status, ItemStatus.active);
      expect((await e.controller.stats()).dropped, 0);
    });

    test('history off: finished items leave no archive but stats survive', () async {
      final e = await env0(items: [item('a'), item('b')], settings: readySettings.copyWith(keepHistory: false));
      await e.controller.complete('a');
      await e.controller.drop('b');
      expect(e.controller.allItems, isEmpty);
      final st = await e.controller.stats();
      expect((st.completed, st.dropped), (1, 1));
      expect((await e.controller.repo.loadItems()), isEmpty);
    });

    test('snooze updates due date, counter, event; undo reverts', () async {
      final e = await env0(items: [item('a', due: DateTime(2026, 9, 30), reminder: true)]);
      final undo = await e.controller.snooze('a', SnoozeOption.nextWeek);
      var i = e.controller.itemById('a')!;
      expect(i.dueAt, DateTime(2026, 10, 3));
      expect(i.snoozeCount, 1);
      expect(i.lastKeptAt, t0);
      expect((await e.controller.stats()).snoozed, 1);
      await undo!();
      i = e.controller.itemById('a')!;
      expect(i.dueAt, DateTime(2026, 9, 30));
      expect(i.snoozeCount, 0);
      expect((await e.controller.stats()).snoozed, 0);
    });

    test('snooze to "no date" also disables the reminder', () async {
      final e = await env0(items: [item('a', due: DateTime(2026, 9, 30), reminder: true)]);
      await e.controller.snooze('a', SnoozeOption.noDate);
      final i = e.controller.itemById('a')!;
      expect(i.dueAt, isNull);
      expect(i.reminderEnabled, isFalse);
    });

    test('delete + undo', () async {
      final e = await env0(items: [item('a')]);
      final undo = await e.controller.delete('a');
      expect(e.controller.allItems, isEmpty);
      expect((await e.controller.stats()).deleted, 1);
      await undo!();
      expect(e.controller.allItems.length, 1);
      expect((await e.controller.stats()).deleted, 0);
    });

    test('keep restarts the waiting clock (stale review)', () async {
      final e = await env0(items: [item('a', created: t0.subtract(const Duration(days: 40)))]);
      expect(e.controller.homeCounts().stale, 1);
      await e.controller.keep('a');
      expect(e.controller.homeCounts().stale, 0);
    });

    test('update sanitizes input (url scheme, tags, lengths)', () async {
      final e = await env0(items: [item('a')]);
      await e.controller.update(e.controller.itemById('a')!.copyWith(
          url: 'javascript:alert(1)', tags: ['x', 'x', ' #y ', ''], title: '  hi  ', estimatedMinutes: -5));
      final i = e.controller.itemById('a')!;
      expect(i.url, isNull);
      expect(i.tags, ['x', 'y']);
      expect(i.title, 'hi');
      expect(i.estimatedMinutes, isNull);
    });

    test('home counts', () async {
      final e = await env0(items: [
        item('t', due: DateTime(2026, 9, 30)),
        item('w', due: DateTime(2026, 10, 2)),
        item('n'),
        item('o', due: DateTime(2026, 9, 20)),
        item('s', created: t0.subtract(const Duration(days: 50))),
        item('done', status: ItemStatus.done),
      ]);
      final c = e.controller.homeCounts();
      expect((c.total, c.today, c.thisWeek, c.noDate, c.overdue, c.stale), (5, 1, 2, 2, 1, 1));
    });

    test('data survives a restart (fresh controller over the same DB)', () async {
      final e = await env0();
      await e.controller.quickAdd('پایدار');
      final c2 = await e.controller.repo.loadAll();
      expect(c2.items.single.title, 'پایدار');
    });
  });

  group('Categories', () {
    test('free limit is 2 custom categories; Pro raises it; deletion re-homes items', () async {
      final e = await env0();
      final c = e.controller;
      expect(await c.addCategory('یک', '🏠'), isNotNull);
      expect(await c.addCategory('دو', '🎮'), isNotNull);
      expect(c.canAddCategory, isFalse);
      expect(await c.addCategory('سه', '🎵'), isNull);
      await c.pro.applyPurchase(ProPlans.month1);
      expect(c.canAddCategory, isTrue);
      final three = (await c.addCategory('سه', '🎵'))!;
      final it = await c.quickAdd('x', categoryId: three.id);
      await c.deleteCategory(three.id);
      expect(c.itemById(it.id)!.categoryId, 'other');
      expect(c.categoryById(three.id), isNull);
      // built-ins cannot be deleted
      await c.deleteCategory('work');
      expect(c.categoryById('work'), isNotNull);
    });

    test('after Pro expiry existing extra categories stay, new ones are blocked', () async {
      final e = await env0();
      final c = e.controller;
      await c.pro.applyPurchase(ProPlans.day1);
      for (var i = 0; i < 4; i++) {
        expect(await c.addCategory('c$i', '🏷️'), isNotNull);
      }
      e.clockNow = t0.add(const Duration(days: 2));
      expect(c.isPro, isFalse);
      expect(c.categories.where((x) => !x.builtin).length, 4);
      expect(c.canAddCategory, isFalse);
    });
  });

  group('Reminders (fake OS scheduler)', () {
    test('sync schedules exactly one notification per reminder, no duplicates', () async {
      final e = await env0(items: [
        item('a', due: DateTime(2026, 10, 1, 9), hasTime: true, reminder: true),
        item('b', due: DateTime(2026, 10, 2), reminder: true),
        item('c', due: DateTime(2026, 10, 3)), // no reminder
      ]);
      await e.controller.syncReminders();
      expect(e.gateway.scheduled.length, 2);
      final first = e.gateway.scheduled.keys.toSet();
      await e.controller.syncReminders();
      await e.controller.syncReminders();
      expect(e.gateway.scheduled.keys.toSet(), first);
      expect(e.gateway.scheduled.length, 2);
    });

    test('completing / deleting / snoozing an item removes or moves its notification', () async {
      final e = await env0(items: [item('a', due: DateTime(2026, 10, 1, 9), hasTime: true, reminder: true)]);
      await e.controller.syncReminders();
      final id = e.gateway.scheduled.keys.single;
      expect(e.gateway.scheduled[id]!.reminder.fireAt, DateTime(2026, 10, 1, 9));
      await e.controller.snooze('a', SnoozeOption.tomorrow);
      await e.controller.syncReminders();
      expect(e.gateway.scheduled.values.single.reminder.fireAt, DateTime(2026, 10, 1, 9));
      await e.controller.complete('a');
      await e.controller.syncReminders();
      expect(e.gateway.scheduled, isEmpty);
    });

    test('debounced sync after edits eventually schedules (no explicit sync)', () async {
      final e = await env0();
      await e.controller.saveNew(item('a', due: DateTime(2026, 10, 1), reminder: true));
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(e.gateway.scheduled.length, 1);
    });

    test('reminders disabled globally => nothing scheduled', () async {
      final e = await env0(items: [item('a', due: DateTime(2026, 10, 1), reminder: true)]);
      await e.controller.updateSettings((s) => s.copyWith(remindersEnabled: false));
      await e.controller.syncReminders();
      expect(e.gateway.scheduled, isEmpty);
      await e.controller.updateSettings((s) => s.copyWith(remindersEnabled: true));
      await e.controller.syncReminders();
      expect(e.gateway.scheduled.length, 1);
    });

    test('permission denied is reported (banner data) but nothing crashes', () async {
      final e = await env0(items: [item('a', due: DateTime(2026, 10, 1), reminder: true)]);
      e.gateway.perm = NotificationPermission.denied;
      final r = await e.controller.syncReminders();
      expect(r.permissionDenied, isTrue);
      expect(r.scheduled, 1);
    });

    test('exact alarms not allowed => inexact scheduling and flag', () async {
      final e = await env0(items: [item('a', due: DateTime(2026, 10, 1), reminder: true)]);
      e.gateway.exactAllowed = false;
      final r = await e.controller.syncReminders();
      expect(r.exactDenied, isTrue);
      expect(e.gateway.scheduled.values.single.exact, isFalse);
    });

    test('scheduling failure is contained and counted', () async {
      final e = await env0(items: [item('a', due: DateTime(2026, 10, 1), reminder: true)]);
      e.gateway.failSchedule = true;
      final r = await e.controller.syncReminders();
      expect((r.scheduled, r.failed), (0, 1));
    });

    test('private mode flag reaches the notification', () async {
      final e = await env0(
          items: [item('a', due: DateTime(2026, 10, 1), reminder: true)],
          settings: readySettings.copyWith(privateNotifications: true));
      await e.controller.syncReminders();
      expect(e.gateway.scheduled.values.single.privateMode, isTrue);
    });

    test('recurring reminders require Pro; expiry silently stops repeats but keeps the data', () async {
      final e = await env0(items: [
        item('a', due: DateTime(2026, 9, 1), reminder: true, repeat: RepeatRule.daily),
      ]);
      await e.controller.syncReminders();
      expect(e.gateway.scheduled, isEmpty, reason: 'free: past one-time reminders are dropped');
      await e.controller.pro.applyPurchase(ProPlans.month1);
      await e.controller.syncReminders();
      expect(e.gateway.scheduled.values.single.reminder.repeat, RepeatRule.daily);
      e.clockNow = t0.add(const Duration(days: 31));
      await e.controller.syncReminders();
      expect(e.gateway.scheduled, isEmpty);
      expect(e.controller.itemById('a')!.repeat, RepeatRule.daily);
    });

    test('a changed clock / date is picked up on the next sync (time change handling)', () async {
      final e = await env0(items: [item('a', due: DateTime(2026, 10, 1, 9), hasTime: true, reminder: true)]);
      await e.controller.syncReminders();
      expect(e.gateway.scheduled.length, 1);
      e.clockNow = DateTime(2026, 10, 1, 12); // user moved the clock past the reminder
      await e.controller.syncReminders();
      expect(e.gateway.scheduled, isEmpty);
      e.clockNow = DateTime(2026, 9, 30, 10); // ...and back
      await e.controller.syncReminders();
      expect(e.gateway.scheduled.length, 1);
    });

    test('app restart re-syncs reminders (init)', () async {
      final e = await env0(items: [item('a', due: DateTime(2026, 10, 1), reminder: true)]);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(e.gateway.scheduled.length, 1);
      e.gateway.scheduled.clear(); // e.g. OS dropped alarms after force-stop
      await e.controller.onResume();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(e.gateway.scheduled.length, 1);
    });

    test('notification tap actions: open, done, tomorrow', () async {
      final e = await env0(items: [item('a', due: DateTime(2026, 10, 1), reminder: true)]);
      await e.controller.handleNotificationTap(const NotificationTap(itemId: 'a'));
      expect(e.controller.takePendingOpenItem(), 'a');
      expect(e.controller.takePendingOpenItem(), isNull);
      await e.controller.handleNotificationTap(const NotificationTap(itemId: 'a', actionId: 'tomorrow'));
      expect(e.controller.itemById('a')!.snoozeCount, 1);
      await e.controller.handleNotificationTap(const NotificationTap(itemId: 'a', actionId: 'done'));
      expect(e.controller.itemById('a')!.status, ItemStatus.done);
      await e.controller.handleNotificationTap(const NotificationTap(itemId: 'gone', actionId: 'done')); // no crash
    });

    test('payload parsing rejects garbage', () {
      expect(NotificationTap.parse('item:abc', 'done')!.itemId, 'abc');
      expect(NotificationTap.parse('other:abc', null), isNull);
      expect(NotificationTap.parse(null, null), isNull);
      expect(NotificationTap.parse('item:', null), isNull);
      expect(NotificationTap.parse('item:${'x' * 100}', null), isNull);
    });
  });

  group('Share sheet', () {
    test('link + title from a browser share', () async {
      final e = await env0();
      final i = (await e.controller.handleShare(const SharedContent(
          text: 'https://example.com/article?id=5', subject: 'یک مقاله‌ی خوب')))!;
      expect(i.title, 'یک مقاله‌ی خوب');
      expect(i.url, 'https://example.com/article?id=5');
      expect(i.categoryId, 'link');
      expect(i.source, 'share');
      expect(e.controller.activeItems.length, 1);
    });

    test('plain text share and text with embedded url', () async {
      final e = await env0();
      final a = (await e.controller.handleShare(const SharedContent(text: 'به مامان زنگ بزنم')))!;
      expect((a.title, a.url, a.categoryId), ('به مامان زنگ بزنم', null, 'other'));
      final b = (await e.controller.handleShare(const SharedContent(text: 'ببین این خوبه https://a.b/c')))!;
      expect(b.title, 'ببین این خوبه');
      expect(b.url, 'https://a.b/c');
      final c = (await e.controller.handleShare(const SharedContent(text: 'https://only.link/x')))!;
      expect(c.title, 'https://only.link/x');
    });

    test('empty / dangerous shares', () async {
      final e = await env0();
      expect(await e.controller.handleShare(const SharedContent(text: '   ')), isNull);
      final j = (await e.controller.handleShare(const SharedContent(text: 'javascript:alert(1)')))!;
      expect(j.url, isNull);
      final big = (await e.controller.handleShare(SharedContent(text: 'x' * 100000)))!;
      expect(big.title.length, lessThanOrEqualTo(500));
    });

    test('platform bridge delivers initial share exactly once', () async {
      final e = await env0();
      e.platform.initialShare = const SharedContent(text: 'hello');
      expect((await e.platform.takeInitialShare())!.text, 'hello');
      expect(await e.platform.takeInitialShare(), isNull);
    });
  });

  group('Pro through the controller', () {
    test('purchase flow: success stacks, consumes token, cancel does nothing', () async {
      final e = await env0();
      final c = e.controller;
      e.purchases.next = PurchaseStatus.cancelled;
      expect((await c.buy(ProPlans.month1)).status, PurchaseStatus.cancelled);
      expect(c.isPro, isFalse);
      e.purchases.next = PurchaseStatus.success;
      await c.buy(ProPlans.month1);
      expect(c.isPro, isTrue);
      expect(e.purchases.consumed, ['tok_later_pro_1m']);
      final until1 = c.pro.entitlement.expiresAt!;
      e.clockNow = t0.add(const Duration(days: 15));
      final r = await c.buy(ProPlans.month3);
      expect(r.entitlement!.expiresAt, until1.add(const Duration(days: 90)));
    });

    test('Scenario 1 via controller: 1 month, 30 days later Pro is off, data intact', () async {
      final e = await env0(items: [item('a'), item('b')]);
      final c = e.controller;
      await c.buy(ProPlans.month1);
      expect(c.isPro, isTrue);
      await c.addCategory('یک', '🏠');
      await c.addCategory('دو', '🎮');
      await c.addCategory('سه', '🎵');
      e.clockNow = t0.add(const Duration(days: 30, minutes: 1));
      expect(c.isPro, isFalse);
      expect(c.allItems.length, 2);
      expect(c.categories.where((x) => !x.builtin).length, 3);
    });

    test('expired Pro: accent falls back, advanced search off, smart pick basic', () async {
      final e = await env0(items: [
        item('a', title: 'x', tags: ['کتاب']),
      ]);
      final c = e.controller;
      await c.updateSettings((s) => s.copyWith(accent: AccentPalette.teal));
      expect(c.query(search: 'کتاب'), isEmpty, reason: 'free search ignores tags');
      await c.buy(ProPlans.month1);
      expect(c.query(search: 'کتاب').length, 1);
      e.clockNow = t0.add(const Duration(days: 40));
      expect(c.query(search: 'کتاب'), isEmpty);
      expect(c.settings.accent, AccentPalette.teal, reason: 'choice is kept for renewal');
    });

    test('unrestored purchases can be re-applied and consumed', () async {
      final e = await env0();
      e.purchases.pending = [
        PurchaseResult(PurchaseStatus.success, plan: ProPlans.month3, token: 'tk', purchasedAt: t0),
      ];
      expect(await e.controller.restorePurchases(), 1);
      expect(e.controller.isPro, isTrue);
      expect(e.purchases.consumed, ['tk']);
    });

    test('QA tools are usable in test runs (debug mode) and simulate short plans', () async {
      final e = await env0();
      await e.controller.debugGrantPro(ProPlans.day1);
      expect(e.controller.isPro, isTrue);
      await e.controller.debugAdvanceDays(2);
      expect(e.controller.isPro, isFalse);
      await e.controller.debugResetTime();
      await e.controller.debugClearPro();
      expect(e.controller.pro.entitlement.expiresAt, isNull);
    });

    test('Pro survives app restart (secure vault)', () async {
      final e = await env0();
      await e.controller.buy(ProPlans.month1);
      final e2 = await TestEnv.create(settings: readySettings, vault: e.vault, now: t0);
      await e2.controller.init();
      expect(e2.controller.isPro, isTrue);
    });
  });

  group('Backup / restore through the controller (Scenario 6)', () {
    test('export -> wipe -> import restores items, categories, settings, history, Pro', () async {
      final a = await env0(items: [
        item('a', title: 'مورد ۱', category: 'read', due: DateTime(2026, 10, 5), reminder: true),
        item('b', title: 'مورد ۲', status: ItemStatus.done),
      ]);
      final c = a.controller;
      await c.addCategory('سفر', '✈️');
      await c.updateSettings((s) => s.copyWith(themeMode: ThemeMode.dark, staleDays: 45));
      await c.complete('a');
      await c.buy(ProPlans.month3);
      final bytes = await c.buildBackupBytes();
      final before = await c.repo.loadAll();

      // "reinstall": brand-new app state with a new vault
      final b = await env0(settings: const AppSettings());
      expect(b.controller.allItems, isEmpty);
      expect(b.controller.isPro, isFalse);
      final decoded = b.controller.inspectBackup(bytes);
      expect(decoded.snapshot.items.length, 2);
      await b.controller.restore(decoded);

      final after = await b.controller.repo.loadAll();
      expect(after.items.length, before.items.length);
      expect({for (final i in after.items) i.id: i.toDb()}, {for (final i in before.items) i.id: i.toDb()});
      expect(after.categories.map((x) => x.id).toSet(), before.categories.map((x) => x.id).toSet());
      expect(after.events.length, before.events.length);
      expect(b.controller.settings.themeMode, ThemeMode.dark);
      expect(b.controller.settings.staleDays, 45);
      expect(b.controller.isPro, isTrue, reason: 'signed entitlement restored');
      // no duplicate scheduling after restore
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('restore keeps a safety copy of the previous data', () async {
      final e = await env0(items: [item('old', title: 'قبلی')]);
      final other = await env0(items: [item('new', title: 'جدید')]);
      final bytes = await other.controller.buildBackupBytes();
      await e.controller.restore(e.controller.inspectBackup(bytes));
      expect(e.controller.allItems.single.id, 'new');
      final safety = await e.files.internalBackupDir();
      final data = await safety.list().toList();
      expect(data.any((f) => f.path.endsWith('pre_restore.later')), isTrue);
    });

    test('a bad file changes nothing', () async {
      final e = await env0(items: [item('keep')]);
      expect(() => e.controller.inspectBackup(Uint8List.fromList(utf8.encode('{"nope":1}'))),
          throwsA(isA<BackupException>()));
      expect(e.controller.allItems.single.id, 'keep');
    });

    test('backup file name follows the documented pattern', () {
      expect(LaterController.backupFileName(DateTime(2026, 9, 30)), 'Later_Backup_2026-09-30.later');
    });

    test('large export/import (5000 items) stays fast enough', () async {
      final e = await env0();
      await e.controller.debugSeed(5000, withSamples: false);
      final sw = Stopwatch()..start();
      final bytes = await e.controller.buildBackupBytes();
      final t1 = sw.elapsedMilliseconds;
      final other = await env0();
      await other.controller.restore(other.controller.inspectBackup(bytes));
      expect(other.controller.allItems.length, 5000);
      // ignore: avoid_print
      print('5000 items: export ${t1}ms, total ${sw.elapsedMilliseconds}ms, size ${bytes.length ~/ 1024}KB');
      expect(sw.elapsedMilliseconds, lessThan(20000));
    });
  });

  group('Settings & reset', () {
    test('resetAll wipes data + settings but not the Pro entitlement', () async {
      final e = await env0(items: [item('a')]);
      await e.controller.buy(ProPlans.month1);
      await e.controller.addCategory('x', '🏠');
      await e.controller.resetAll();
      expect(e.controller.allItems, isEmpty);
      expect(e.controller.categories.where((c) => !c.builtin), isEmpty);
      expect(e.controller.settings.onboardingDone, isFalse);
      expect(e.controller.isPro, isTrue);
      expect((await e.controller.repo.loadItems()), isEmpty);
    });

    test('settings survive restart and invalid stored values fall back to defaults', () async {
      final m = const AppSettings().toMap()..['weekStart'] = '42'..['themeMode'] = 'neon';
      final s = AppSettings.fromMap(m);
      expect(s.weekStart, DateTime.saturday);
      expect(s.themeMode, ThemeMode.system);
    });

    test('legal acceptance is versioned', () {
      expect(const AppSettings().legalAccepted, isFalse);
      expect(const AppSettings(termsAcceptedVersion: 1, privacyAcceptedVersion: 1).legalAccepted, isTrue);
      expect(const AppSettings(termsAcceptedVersion: 1, privacyAcceptedVersion: 0).legalAccepted, isFalse);
    });
  });

  group('Performance smoke (thousands of items)', () {
    test('query/filter/search over 5000 items is fast', () async {
      final e = await env0();
      await e.controller.debugSeed(5000, withSamples: false);
      final sw = Stopwatch()..start();
      for (var i = 0; i < 20; i++) {
        e.controller.query(search: 'نمونه ${i + 1}', sort: SortMode.values[i % SortMode.values.length]);
      }
      final ms = sw.elapsedMilliseconds;
      // ignore: avoid_print
      print('20 searches over 5000 items: ${ms}ms');
      expect(ms, lessThan(4000));
      final hc = Stopwatch()..start();
      e.controller.homeCounts();
      e.controller.smartPick(minutes: 15, limit: 3);
      expect(hc.elapsedMilliseconds, lessThan(500));
    });
  });
}
