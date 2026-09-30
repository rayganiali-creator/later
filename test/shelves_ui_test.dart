import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/config/pro_plans.dart';
import 'package:later/domain/models.dart';
import 'package:later/l10n/app_localizations_fa.dart';
import 'package:later/ui/screens/future_screen.dart';
import 'package:later/ui/screens/inbox_screen.dart';
import 'package:later/ui/screens/people_screens.dart';
import 'package:later/ui/screens/pro_screen.dart';
import 'package:later/ui/screens/search_screen.dart';
import 'package:later/ui/screens/shelf_screen.dart';

import 'harness.dart';
import 'helpers.dart';

final fa = AppL10nFa();
Finder text(String s) => find.text(s);

void main() {
  testWidgets('Home is a dashboard: shelves, no item list', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [
      item('a', title: 'کار معمولی یک'),
      item('b', title: 'مقاله‌ی من', type: ItemType.read),
    ]);
    await pumpApp(tester, env);
    expect(text(fa.dashRoulette), findsOneWidget);
    expect(text(fa.shelfReadTitle), findsOneWidget);
    expect(text(fa.shelfWishTitle), findsOneWidget);
    expect(text(fa.shelfIdeaTitle), findsOneWidget);
    expect(text(fa.shelfPeopleTitle), findsOneWidget);
    expect(text(fa.shelfFutureTitle), findsOneWidget);
    // Titles of items are not listed on the dashboard.
    expect(text('کار معمولی یک'), findsNothing);
    // ...but they are in the list tab.
    await tester.tap(text(fa.navList).last);
    await settle(tester);
    expect(text('کار معمولی یک'), findsOneWidget);
  });

  testWidgets('inbox: triage moves an item to the read shelf', (tester) async {
    final env = await createEnv(tester, settings: readySettings);
    await tester.runAsync(() => env.controller.init());
    await tester.runAsync(() => env.controller.quickAdd('چیز سریع'));
    await pumpApp(tester, env);
    expect(env.controller.inboxItems.length, 1);
    await tester.tap(text(fa.dashInbox));
    await settle(tester);
    expect(text('چیز سریع'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, fa.triageRead));
    await settle(tester);
    expect(env.controller.inboxItems, isEmpty);
    expect(env.controller.shelf(ItemType.read).length, 1);
  });

  testWidgets('inbox screen empty state', (tester) async {
    final env = await createEnv(tester, settings: readySettings);
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, env);
    Navigator.of(tester.element(find.byType(Scaffold).first)).push(MaterialPageRoute<void>(builder: (_) => const InboxScreen()));
    await settle(tester);
    expect(text(fa.inboxEmptyTitle), findsOneWidget);
  });

  testWidgets('shelf screen lists items and filters by stage', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [
      item('a', title: 'مقاله‌ی نخوانده', type: ItemType.read),
      item('b', title: 'مقاله‌ی در حال خواندن', type: ItemType.read, stage: ItemStages.reading),
    ]);
    await pumpApp(tester, env);
    Navigator.of(tester.element(find.byType(Scaffold).first))
        .push(MaterialPageRoute<void>(builder: (_) => const ShelfScreen(type: ItemType.read)));
    await settle(tester);
    expect(text('مقاله‌ی نخوانده'), findsOneWidget);
    expect(text('مقاله‌ی در حال خواندن'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, fa.stageReading));
    await settle(tester);
    expect(text('مقاله‌ی نخوانده'), findsNothing);
    expect(text('مقاله‌ی در حال خواندن'), findsOneWidget);
  });

  testWidgets('Free user: advanced shelf tools open the Pro sheet, not the feature', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [item('a', title: 'x', type: ItemType.wishlist)]);
    await pumpApp(tester, env);
    Navigator.of(tester.element(find.byType(Scaffold).first))
        .push(MaterialPageRoute<void>(builder: (_) => const ShelfScreen(type: ItemType.wishlist)));
    await settle(tester);
    await tester.tap(find.byTooltip(fa.shelfStatsTitle));
    await settle(tester);
    expect(text(fa.proLockedTitle), findsOneWidget);
  });

  testWidgets('people: add by name, mark talked', (tester) async {
    final env = await createEnv(tester, settings: readySettings);
    await pumpApp(tester, env);
    final p = (await tester.runAsync(() => env.controller.addPerson('سارا')))!;
    Navigator.of(tester.element(find.byType(Scaffold).first)).push(MaterialPageRoute<void>(builder: (_) => const PeopleScreen()));
    await settle(tester);
    expect(text('سارا'), findsOneWidget);
    await tester.tap(text('سارا'));
    await settle(tester);
    await tester.tap(text(fa.personTalked));
    await settle(tester);
    expect(env.controller.personById(p.id)!.lastInteractionAt, isNotNull);
  });

  testWidgets('future: locked capsule shows date, not its text', (tester) async {
    final env = await createEnv(tester, settings: readySettings);
    await tester.runAsync(() => env.controller.init());
    await pumpApp(tester, env);
    final when = env.controller.now().add(const Duration(days: 30));
    await tester.runAsync(() => env.controller.seal(title: 'کپسول من', body: 'متن مخفی', unlockAt: when));
    Navigator.of(tester.element(find.byType(Scaffold).first)).push(MaterialPageRoute<void>(builder: (_) => const FutureScreen()));
    await settle(tester);
    expect(text('کپسول من'), findsOneWidget);
    expect(text('متن مخفی'), findsNothing);
    expect(text(fa.stageSealed), findsWidgets);
  });

  testWidgets('universal search finds across shelves and people', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [
      item('a', title: 'کتاب فیزیک', type: ItemType.read),
      item('b', title: 'ایده‌ی فیزیکی', type: ItemType.idea),
    ]);
    await pumpApp(tester, env);
    await tester.runAsync(() => env.controller.addPerson('استاد فیزیک'));
    Navigator.of(tester.element(find.byType(Scaffold).first)).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'فیزیک');
    await settle(tester);
    expect(text('کتاب فیزیک'), findsOneWidget);
    expect(text('استاد فیزیک'), findsOneWidget);
  });

  testWidgets('Pro screen lists every Pro feature with a description', (tester) async {
    final env = await createEnv(tester, settings: readySettings);
    await pumpApp(tester, env);
    Navigator.of(tester.element(find.byType(Scaffold).first)).push(MaterialPageRoute<void>(builder: (_) => const ProScreen()));
    await settle(tester);
    final titles = [fa.proFT1, fa.proFT2, fa.proFT3, fa.proFT4, fa.proFT5, fa.proFT6];
    final list = find.byType(Scrollable).first;
    for (final t in titles) {
      await tester.scrollUntilVisible(text(t), 200, scrollable: list);
      expect(text(t), findsOneWidget);
    }
    await tester.scrollUntilVisible(text(fa.proFD12), 200, scrollable: list);
    expect(text(fa.proFD12), findsOneWidget);
    await tester.scrollUntilVisible(text(fa.proFreeList), 200, scrollable: list);
    expect(text(fa.proFreeList), findsOneWidget);
  });

  testWidgets('Pro grant unlocks roulette filters without the Pro sheet', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [item('a', title: 'x', minutes: 5)]);
    await pumpApp(tester, env);
    await tester.runAsync(() => env.controller.pro.applyPurchase(ProPlans.month1, purchasedAt: env.clockNow));
    env.controller.refreshProState();
    await settle(tester, rounds: 30);
    expect(env.controller.isPro, isTrue);
    expect(env.controller.rouletteOptions(minutes: 15).availableMinutes, 15);
  });
}
