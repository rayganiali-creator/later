import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/config/pro_plans.dart';
import 'package:later/domain/models.dart';
import 'package:later/l10n/app_localizations_fa.dart';
import 'package:later/ui/widgets/item_tile.dart';

import 'harness.dart';
import 'helpers.dart';

final fa = AppL10nFa();

Finder text(String s) => find.text(s);

void main() {
  group('First run', () {
    testWidgets('onboarding -> legal acceptance -> home', (tester) async {
      final env = await createEnv(tester);
      await pumpApp(tester, env);

      // Onboarding page 1
      expect(text(fa.onb1Title), findsOneWidget);
      // swipe through with "next"
      for (var i = 0; i < 4; i++) {
        await tester.tap(text(fa.next));
        await settle(tester, rounds: 6);
      }
      expect(text(fa.onb5Title), findsOneWidget);
      await tester.tap(text(fa.onbStart));
      await settle(tester);

      // Legal gate: cannot continue until accepted
      expect(text(fa.legalTitle), findsOneWidget);
      final cont = find.widgetWithText(FilledButton, fa.legalContinue);
      expect(tester.widget<FilledButton>(cont).onPressed, isNull);
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      expect(tester.widget<FilledButton>(cont).onPressed, isNotNull);
      await tester.tap(cont);
      await settle(tester);

      // Home (empty state)
      expect(text(fa.homeEmptyTitle), findsOneWidget);
      expect(env.controller.settings.legalAccepted, isTrue);
      expect(env.controller.settings.onboardingDone, isTrue);
    });

    testWidgets('onboarding can be skipped', (tester) async {
      final env = await createEnv(tester);
      await pumpApp(tester, env);
      await tester.tap(text(fa.skip));
      await settle(tester);
      expect(text(fa.legalTitle), findsOneWidget);
    });
  });

  group('Core flows', () {
    testWidgets('add (title only) -> appears in list -> complete -> undo', (tester) async {
      final env = await createEnv(tester, settings: readySettings);
      await pumpApp(tester, env);

      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await settle(tester);
      await tester.enterText(find.byType(TextFormField).first, 'این مقاله رو بخونم');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);

      expect(env.controller.activeItems.length, 1);
      expect(env.controller.activeItems.first.title, 'این مقاله رو بخونم');
      expect(env.controller.activeItems.first.categoryId, 'other');
      expect(text(fa.toastAdded), findsOneWidget);

      // go to list tab
      await tester.tap(text(fa.navList).last);
      await settle(tester);
      expect(text('این مقاله رو بخونم'), findsOneWidget);

      // complete via the check button
      await tester.tap(find.byTooltip(fa.itemDone).first);
      await settle(tester);
      expect(env.controller.activeItems, isEmpty);
      expect(env.controller.historyItems.length, 1);
      expect(text(fa.toastDone), findsOneWidget);

      // undo
      await tester.tap(text(fa.undo));
      await settle(tester);
      expect(env.controller.activeItems.length, 1);
      final st = (await tester.runAsync(() => env.controller.stats()))!;
      expect(st.completed, 0, reason: 'undo must not leave a completed event');
    });

    testWidgets('empty title is rejected', (tester) async {
      final env = await createEnv(tester, settings: readySettings);
      await pumpApp(tester, env);
      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, fa.save));
      await settle(tester);
      expect(text(fa.titleRequired), findsOneWidget);
      expect(env.controller.allItems, isEmpty);
    });

    testWidgets('edit an item', (tester) async {
      final env = await createEnv(tester, settings: readySettings, items: [item('a', title: 'قدیمی', created: t0)]);
      await pumpApp(tester, env);
      await tester.tap(text(fa.navList).last);
      await settle(tester);
      await tester.tap(text('قدیمی'));
      await settle(tester);
      await tester.tap(find.byTooltip(fa.edit));
      await settle(tester);
      await tester.tap(text(fa.edit).last);
      await settle(tester);
      await tester.enterText(find.byType(TextFormField).first, 'جدید');
      await tester.tap(find.widgetWithText(FilledButton, fa.save));
      await settle(tester);
      expect(env.controller.itemById('a')!.title, 'جدید');
    });

    testWidgets('delete with confirmation and undo', (tester) async {
      final env = await createEnv(tester, settings: readySettings, items: [item('a', title: 'حذفی', created: t0)]);
      await pumpApp(tester, env);
      await tester.tap(text(fa.navList).last);
      await settle(tester);
      await tester.tap(text('حذفی'));
      await settle(tester);
      await tester.tap(find.byTooltip(fa.edit));
      await settle(tester);
      await tester.tap(text(fa.delete).last);
      await settle(tester);
      // confirm dialog
      expect(text(fa.confirmDeleteTitle), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: text(fa.delete)));
      await settle(tester);
      expect(env.controller.allItems, isEmpty);
      expect(((await tester.runAsync(() => env.controller.stats()))!).deleted, 1);
      await tester.tap(text(fa.undo));
      await settle(tester);
      expect(env.controller.allItems.length, 1);
      expect(((await tester.runAsync(() => env.controller.stats()))!).deleted, 0);
    });

    testWidgets('snooze to tomorrow via sheet', (tester) async {
      final env = await createEnv(tester, settings: readySettings, items: [item('a', title: 'برای فردا', created: t0)]);
      await pumpApp(tester, env);
      await tester.tap(text(fa.navList).last);
      await settle(tester);
      await tester.tap(text('برای فردا'));
      await settle(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, fa.itemSnooze));
      await settle(tester);
      await tester.tap(text(fa.snoozeTomorrow));
      await settle(tester);
      final i = env.controller.itemById('a')!;
      expect(i.dueAt, DateTime(2026, 10, 1));
      expect(i.snoozeCount, 1);
      expect(((await tester.runAsync(() => env.controller.stats()))!).snoozed, 1);
    });

    testWidgets('search finds by title and filters', (tester) async {
      final env = await createEnv(tester, settings: readySettings, items: [
        item('a', title: 'خرید هدفون', category: 'buy', created: t0),
        item('b', title: 'دیدن فیلم', category: 'watch', created: t0),
      ]);
      await pumpApp(tester, env);
      await tester.tap(text(fa.navList).last);
      await settle(tester);
      expect(find.byType(ItemTile), findsNWidgets(2));
      await tester.enterText(find.byType(TextField).first, 'هدفون');
      await settle(tester, rounds: 4);
      expect(find.byType(ItemTile), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'چیز ناموجود');
      await settle(tester, rounds: 4);
      expect(text(fa.listEmptyFiltered), findsOneWidget);
    });

    testWidgets('decide mode suggests one item; another; do it', (tester) async {
      final env = await createEnv(tester, settings: readySettings, items: [
        item('a', title: 'اولی', minutes: 5, created: t0),
        item('b', title: 'دومی', minutes: 5, created: t0),
      ]);
      await pumpApp(tester, env);
      await tester.tap(text(fa.pickCardTitle));
      await settle(tester);
      expect(text(fa.decideLabel), findsOneWidget);
      final firstShown = find.textContaining('«').evaluate().length;
      expect(firstShown, 1);
      await tester.tap(text(fa.decideAnother));
      await settle(tester);
      expect(find.textContaining('«').evaluate().length, 1);
      await tester.tap(text(fa.decideDo));
      await settle(tester, rounds: 22);
      expect(env.controller.activeItems.length, 1);
    });

    testWidgets('stale review: keep / drop', (tester) async {
      final old = t0.subtract(const Duration(days: 45));
      final env = await createEnv(tester, settings: readySettings, items: [
        item('a', title: 'قدیمی یک', created: old),
        item('b', title: 'قدیمی دو', created: old.subtract(const Duration(days: 1))),
      ]);
      await pumpApp(tester, env);
      expect(env.controller.homeCounts().stale, 2);
      await tester.tap(find.textContaining(fa.staleBannerBody));
      await settle(tester);
      expect(text(fa.staleTitle), findsOneWidget);
      // oldest first: "قدیمی دو"
      expect(find.textContaining('قدیمی دو'), findsOneWidget);
      await tester.tap(text(fa.staleKeep));
      await settle(tester);
      expect(env.controller.itemById('b')!.lastKeptAt, isNotNull);
      expect(find.textContaining('قدیمی یک'), findsOneWidget);
      await tester.tap(text(fa.staleDrop));
      await settle(tester);
      expect(env.controller.itemById('a')!.status, ItemStatus.dropped);
      expect(text(fa.staleAllDone), findsOneWidget);
    });
  });

  group('Settings & theme', () {
    testWidgets('dark theme, RTL direction, and Pro tag rendering', (tester) async {
      final env = await createEnv(tester, settings: readySettings.copyWith(themeMode: ThemeMode.dark));
      await pumpApp(tester, env);
      final ctx = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(ctx).brightness, Brightness.dark);
      expect(Directionality.of(ctx), TextDirection.rtl);
      expect(Localizations.localeOf(ctx).languageCode, 'fa');
    });

    testWidgets('reset app requires typing the confirmation word', (tester) async {
      final env = await createEnv(tester, settings: readySettings, items: [item('a', created: t0)]);
      await pumpApp(tester, env);
      await tester.tap(text(fa.navSettings).last);
      await settle(tester);
      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await settle(tester, rounds: 4);
      await tester.tap(text(fa.resetApp));
      await settle(tester);
      final confirm = find.widgetWithText(TextButton, fa.resetAction);
      expect(tester.widget<TextButton>(confirm).onPressed, isNull);
      await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), fa.resetWord);
      await tester.pump();
      expect(tester.widget<TextButton>(confirm).onPressed, isNotNull);
      await tester.tap(confirm);
      await settle(tester);
      expect(env.controller.allItems, isEmpty);
      expect(env.controller.settings.onboardingDone, isFalse);
    });
  });

  group('Pro gating in the UI', () {
    testWidgets('free user tapping a locked history period sees the Pro sheet', (tester) async {
      final env = await createEnv(tester, settings: readySettings);
      await pumpApp(tester, env);
      await tester.tap(text(fa.navHistory).last);
      await settle(tester);
      await tester.tap(text(fa.periodAll));
      await settle(tester);
      expect(text(fa.proLockedTitle), findsOneWidget);
    });

    testWidgets('Pro user can open all history periods', (tester) async {
      final env = await createEnv(tester, settings: readySettings);
      await tester.runAsync(() => env.controller.pro.applyPurchase(ProPlans.month1));
      await pumpApp(tester, env);
      await tester.tap(text(fa.navHistory).last);
      await settle(tester);
      await tester.tap(text(fa.periodAll));
      await settle(tester);
      expect(text(fa.proLockedTitle), findsNothing);
    });
  });

  group('Layouts', () {
    for (final size in const [Size(320, 640), Size(412, 915), Size(800, 1280)]) {
      testWidgets('home renders without overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
        final env = await createEnv(tester, settings: readySettings, items: [
          for (var i = 0; i < 6; i++)
            item('i$i', title: 'مورد ${i * 11} با یک عنوان نسبتاً بلند برای بررسی سرریز متن', due: i == 0 ? DateTime(2026, 9, 30) : null, created: t0.subtract(Duration(days: i * 10))),
        ]);
          await pumpApp(tester, env, size: size);
        expect(tester.takeException(), isNull);
        for (final tab in [fa.navList, fa.navHistory, fa.navSettings, fa.navHome]) {
          await tester.tap(text(tab).last);
          await settle(tester, rounds: 5);
          expect(tester.takeException(), isNull, reason: '$tab @ $size');
        }
      });
    }

    testWidgets('large system font scale does not overflow', (tester) async {
      final env = await createEnv(tester, settings: readySettings, items: [item('a', title: 'عنوان', created: t0)]);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, env, size: const Size(360, 740));
      expect(tester.takeException(), isNull);
      for (final tab in [fa.navList, fa.navHistory, fa.navSettings]) {
        await tester.tap(text(tab).last);
        await settle(tester, rounds: 5);
        expect(tester.takeException(), isNull, reason: tab);
      }
    });
  });
}
