import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/config/pro_plans.dart';
import 'package:later/domain/models.dart';
import 'package:later/domain/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:later/l10n/app_localizations_fa.dart';

import 'harness.dart';
import 'helpers.dart';

Future<TestEnv> env0(List<LaterItem> items, {bool pro = true}) async {
  final e = await TestEnv.create(settings: readySettings, items: items, now: DateTime(2026, 10, 7, 8));
  await e.controller.init();
  if (pro) await e.controller.pro.applyPurchase(ProPlans.month6, purchasedAt: DateTime(2026, 10, 7, 8));
  return e;
}

DateTime _nextFire(TestEnv e, String id) =>
    e.gateway.scheduled.values.firstWhere((s) => s.reminder.itemId == id).reminder.fireAt;

void main() {
  final fa = AppL10nFa();

  group('Repeating reminders stay in the list when done', () {
    test('daily: done today -> still active, next date tomorrow, no history, notification moves to tomorrow', () async {
      final e = await env0([
        item('a', due: DateTime(2026, 10, 7, 9), hasTime: true, reminder: true).copyWith(repeat: RepeatRule.daily),
      ]);
      final c = e.controller;
      await c.syncReminders();
      expect(_nextFire(e, 'a'), DateTime(2026, 10, 7, 9));
      expect(c.completesRepeating(c.itemById('a')!), isTrue);
      await c.complete('a');
      final a = c.itemById('a')!;
      expect(a.status, ItemStatus.active, reason: 'it must not go to the history');
      expect(a.dueAt, DateTime(2026, 10, 8, 9));
      expect(c.historyItems.where((i) => i.id == 'a'), isEmpty);
      await c.syncReminders();
      expect(_nextFire(e, 'a'), DateTime(2026, 10, 8, 9), reason: 'no more notification today, tomorrow still comes');
      expect((await c.stats()).completed, greaterThanOrEqualTo(1));
    });

    test('weekly: done keeps the same weekday a week later', () async {
      final e = await env0([
        item('w', due: DateTime(2026, 10, 7, 9), hasTime: true, reminder: true).copyWith(repeat: RepeatRule.weekly),
      ]);
      await e.controller.complete('w');
      expect(e.controller.itemById('w')!.dueAt, DateTime(2026, 10, 14, 9));
      expect(e.controller.itemById('w')!.status, ItemStatus.active);
    });

    test('monthly and yearly keep their day', () async {
      final e = await env0([
        item('m', due: DateTime(2026, 10, 7, 9), hasTime: true, reminder: true).copyWith(repeat: RepeatRule.monthly),
        item('y', due: DateTime(2026, 10, 7, 9), hasTime: true, reminder: true).copyWith(repeat: RepeatRule.yearly),
      ]);
      await e.controller.complete('m');
      await e.controller.complete('y');
      expect(e.controller.itemById('m')!.dueAt, DateTime(2026, 11, 7, 9));
      expect(e.controller.itemById('y')!.dueAt, DateTime(2027, 10, 7, 9));
    });

    test('an overdue daily item done today continues from tomorrow (missed days are not piled up)', () async {
      final e = await env0([
        item('o', due: DateTime(2026, 10, 1, 9), hasTime: true, reminder: true).copyWith(repeat: RepeatRule.daily),
      ]);
      await e.controller.complete('o');
      expect(e.controller.itemById('o')!.dueAt, DateTime(2026, 10, 8, 9));
    });

    test('undo brings back the previous date and removes the done event', () async {
      final e = await env0([
        item('a', due: DateTime(2026, 10, 7, 9), hasTime: true, reminder: true).copyWith(repeat: RepeatRule.daily),
      ]);
      final undo = await e.controller.complete('a');
      expect(e.controller.itemById('a')!.dueAt, DateTime(2026, 10, 8, 9));
      await undo!();
      expect(e.controller.itemById('a')!.dueAt, DateTime(2026, 10, 7, 9));
      expect(e.controller.itemById('a')!.status, ItemStatus.active);
    });

    test('a normal (non-repeating) item still goes to the history', () async {
      final e = await env0([item('n', due: DateTime(2026, 10, 7, 9), hasTime: true, reminder: true)]);
      expect(e.controller.completesRepeating(e.controller.itemById('n')!), isFalse);
      await e.controller.complete('n');
      expect(e.controller.itemById('n')!.status, ItemStatus.done);
    });

    test('without Pro a repeating item behaves like a normal one (repeats are a Pro feature)', () async {
      final e = await env0([
        item('a', due: DateTime(2026, 10, 7, 9), hasTime: true, reminder: true).copyWith(repeat: RepeatRule.daily),
      ], pro: false);
      await e.controller.complete('a');
      expect(e.controller.itemById('a')!.status, ItemStatus.done);
    });
  });

  group('Exit rating prompt', () {
    testWidgets('back on home asks for a rating; "exit" leaves, and it asks again next time', (tester) async {
      final exits = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
        exits.add(c);
        return null;
      });
      final env = await createEnv(tester, settings: readySettings.copyWith(reviewDone: false));
      await pumpApp(tester, env);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text(fa.reviewTitle), findsOneWidget);
      await tester.tap(find.text(fa.reviewExit));
      await settle(tester);
      expect(exits.any((c) => c.method == 'SystemNavigator.pop'), isTrue);
      expect(env.controller.settings.reviewDone, isFalse, reason: 'not rated => keeps asking');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('rate opens the store; the app then asks whether it was sent; "yes" stops the prompt for good', (tester) async {
      final env = await createEnv(tester, settings: readySettings.copyWith(reviewDone: false));
      await pumpApp(tester, env);
      await tester.binding.handlePopRoute();
      await settle(tester);
      await tester.tap(find.text(fa.reviewRate));
      await settle(tester);
      expect(env.platform.reviewOpens, 1);
      for (final st in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused, AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
        tester.binding.handleAppLifecycleStateChanged(st);
      }
      await settle(tester);
      expect(find.text(fa.reviewDoneTitle), findsOneWidget);
      await tester.tap(find.text(fa.reviewDoneYes));
      await settle(tester);
      expect(env.controller.settings.reviewDone, isTrue);
      // next back press does not ask
      final exits = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
        exits.add(c);
        return null;
      });
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text(fa.reviewTitle), findsNothing);
      expect(exits.any((c) => c.method == 'SystemNavigator.pop'), isTrue);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('"not yet" after rating keeps asking on the next exit', (tester) async {
      final env = await createEnv(tester, settings: readySettings.copyWith(reviewDone: false));
      await pumpApp(tester, env);
      await tester.binding.handlePopRoute();
      await settle(tester);
      await tester.tap(find.text(fa.reviewRate));
      await settle(tester);
      for (final st in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused, AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
        tester.binding.handleAppLifecycleStateChanged(st);
      }
      await settle(tester);
      await tester.tap(find.text(fa.reviewDoneNo));
      await settle(tester);
      expect(env.controller.settings.reviewDone, isFalse);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text(fa.reviewTitle), findsOneWidget);
    });
  });

  test('the three new theme colours exist and are stored by name', () {
    expect(AccentPalette.values.map((a) => a.name), containsAll(['emerald', 'violet', 'sky', 'coral', 'magenta', 'cocoa', 'navy']));
    const s = AppSettings(accent: AccentPalette.violet);
    expect(AppSettings.fromMap(s.toMap()).accent, AccentPalette.violet);
  });
}
