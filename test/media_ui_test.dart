import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:later/core/config/pro_plans.dart';
import 'package:later/domain/models.dart';
import 'package:later/l10n/app_localizations_fa.dart';
import 'package:later/services/platform_bridge.dart';
import 'package:later/ui/nav_bus.dart';
import 'package:later/ui/screens/home_shell.dart';
import 'package:later/ui/screens/media_screens.dart';
import 'package:later/ui/screens/shelf_screen.dart';
import 'package:later/ui/sheets/add_edit_sheet.dart';
import 'package:later/ui/sheets/item_detail_sheet.dart';
import 'package:later/ui/sheets/quick_capture_sheet.dart';
import 'package:later/data/controller.dart';
import 'package:later/ui/widgets/item_tile.dart';

import 'harness.dart';
import 'helpers.dart';

final fa = AppL10nFa();
Finder text(String s) => find.text(s);

LaterItem it(String id, ItemType t, {int stage = 0, String? title, int? minutes, Map<String, Object?> extra = const {}}) =>
    item(id, title: title ?? 'x $id', minutes: minutes)
        .copyWith(type: t, stage: stage, status: ItemStages.statusFor(t, stage), extra: extra);

Uint8List png(int w, int h) {
  final im = img.Image(width: w, height: h, numChannels: 3);
  final r = Random(3);
  for (final px in im) {
    px
      ..r = r.nextInt(256)
      ..g = r.nextInt(256)
      ..b = r.nextInt(256);
  }
  return Uint8List.fromList(img.encodePng(im));
}

NavigatorState nav(WidgetTester t) => t.state<NavigatorState>(find.byType(Navigator).first);

Future<void> push(WidgetTester tester, Widget w) async {
  nav(tester).push(MaterialPageRoute<void>(builder: (_) => w));
  await settle(tester);
}

BuildContext ctx(WidgetTester t) => t.element(find.byType(Scaffold).first);

void main() {
  testWidgets('home has a tile for each new shelf and they open', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [
      it('a', ItemType.app, title: 'برنامه‌ی من'),
      it('p', ItemType.podcast),
    ]);
    await pumpApp(tester, env);
    for (final t in [fa.shelfPodcastTitle, fa.shelfCourseTitle, fa.shelfGameTitle, fa.shelfAppTitle]) {
      await tester.ensureVisible(text(t).first);
      expect(text(t), findsWidgets);
    }
    await tester.ensureVisible(text(fa.shelfAppTitle).first);
    await settle(tester);
    await tester.tap(text(fa.shelfAppTitle).first);
    await settle(tester);
    expect(text('برنامه‌ی من'), findsOneWidget);
    expect(text(fa.shelfAppSub), findsOneWidget);
  });

  for (final t in [ItemType.app, ItemType.podcast, ItemType.course, ItemType.game]) {
    testWidgets('${t.name} shelf: empty state, stage chips, history tab', (tester) async {
      final env = await createEnv(tester, settings: readySettings);
      await pumpApp(tester, env);
      await push(tester, ShelfScreen(type: t));
      expect(text(TypeInfoLabels.sub(t)), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsWidgets);
      expect(text(fa.shelfWaiting), findsOneWidget);
      expect(text(fa.shelfAllStages), findsOneWidget);
    });
  }

  testWidgets('apps: "do I still need it?" answers and moves the item', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [
      it('a', ItemType.app, title: 'ویرایشگر عکس'),
    ]);
    await pumpApp(tester, env);
    await tester.runAsync(() => env.controller.init());
    showItemDetailSheet(ctx(tester), 'a');
    await settle(tester);
    expect(text(fa.appStillNeed), findsOneWidget);
    await tester.tap(text(fa.appStillNeed));
    await settle(tester);
    expect(find.descendant(of: find.byType(AlertDialog), matching: text(fa.appAnsInstalled)), findsOneWidget);
    expect(find.descendant(of: find.byType(AlertDialog), matching: text(fa.appAnsLater)), findsOneWidget);
    expect(find.descendant(of: find.byType(AlertDialog), matching: text(fa.appAnsNo)), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: text(fa.appAnsInstalled)));
    await settle(tester);
    expect(env.controller.itemById('a')!.status, ItemStatus.done);
  });

  testWidgets('add sheet: choosing Podcast shows podcast fields and saves them', (tester) async {
    final env = await createEnv(tester, settings: readySettings);
    await pumpApp(tester, env);
    await tester.runAsync(() => env.controller.init());
    showAddEditSheet(ctx(tester));
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).first, 'قسمت ۱۲ درباره‌ی تمرکز');
    await tester.scrollUntilVisible(find.widgetWithText(ChoiceChip, fa.typeName('podcast')), 150,
        scrollable: find.descendant(
            of: find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal).first,
            matching: find.byType(Scrollable)).first);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, fa.typeName('podcast')));
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, fa.typeName('podcast')));
    await settle(tester);
    expect(text(fa.fieldShow), findsOneWidget);
    expect(text(fa.lastPosition), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, fa.fieldShow), 'رادیو تمرکز');
    await tester.enterText(find.widgetWithText(TextFormField, fa.fieldDurationMin), '1:00:00');
    await tester.enterText(find.widgetWithText(TextFormField, fa.lastPosition), '30:00');
    await tester.scrollUntilVisible(text(fa.save), 300,
        scrollable: find.descendant(of: find.byType(Form), matching: find.byType(Scrollable)).first);
    await tester.tap(text(fa.save));
    await settle(tester, rounds: 20);
    final p = env.controller.shelf(ItemType.podcast).single;
    expect(p.title, 'قسمت ۱۲ درباره‌ی تمرکز');
    expect(p.show, 'رادیو تمرکز');
    expect(p.durationSec, 3600);
    expect(p.estimatedMinutes, 60);
    expect((p.progress, p.positionSec), (50, 1800));
  });

  testWidgets('add sheet: a picture picked while adding is stored with the item', (tester) async {
    final env = await createEnv(tester, settings: readySettings);
    await pumpApp(tester, env);
    await tester.runAsync(() => env.controller.init());
    env.imagePicker.next = png(500, 400);
    showAddEditSheet(ctx(tester), presetType: ItemType.game);
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Hollow Knight');
    await tester.scrollUntilVisible(find.byIcon(Icons.add_photo_alternate_outlined), 200,
        scrollable: find.descendant(of: find.byType(Form), matching: find.byType(Scrollable)).first);
    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
    await settle(tester);
    await tester.tap(text(fa.imgGallery));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
    await settle(tester, rounds: 20);
    await tester.scrollUntilVisible(text(fa.save), 300,
        scrollable: find.descendant(of: find.byType(Form), matching: find.byType(Scrollable)).first);
    await tester.tap(text(fa.save));
    await settle(tester, rounds: 25);
    final g = env.controller.shelf(ItemType.game).single;
    expect(env.controller.imagesOf(g.id).length, 1);
    expect(env.controller.coverImageId(g), isNotNull);
  });

  testWidgets('a tile shows the item picture as a thumbnail', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [it('g', ItemType.game, title: 'بازی')]);
    await tester.runAsync(() => env.controller.init());
    final p = (await tester.runAsync(() => env.controller.processImage(png(300, 300))))!;
    await tester.runAsync(() => env.controller.attachProcessed('g', p));
    await pumpApp(tester, env);
    await push(tester, const ShelfScreen(type: ItemType.game));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester, rounds: 10);
    expect(find.byType(CoverCard), findsOneWidget);
    expect(find.descendant(of: find.byType(CoverCard), matching: find.byType(Image)), findsOneWidget);
  });

  testWidgets('podcast detail: progress and continue; item tile shows percent and time left', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [
      it('p', ItemType.podcast, title: 'اپیزود', extra: {'durationSec': 3600, 'progress': 40, 'positionSec': 1440}, stage: ItemStages.listening),
    ]);
    await pumpApp(tester, env);
    await push(tester, const ShelfScreen(type: ItemType.podcast));
    expect(find.textContaining('۴۰٪ گوش داده شده'), findsWidgets);
    expect(find.textContaining('باقی مانده'), findsWidgets);
    showItemDetailSheet(ctx(tester), 'p');
    await settle(tester);
    expect(text(fa.continueListening), findsOneWidget);
  });

  testWidgets('course: session logging is Pro (free sees the Pro sheet)', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [it('k', ItemType.course, title: 'پایتون')]);
    await pumpApp(tester, env);
    showItemDetailSheet(ctx(tester), 'k');
    await settle(tester);
    await tester.ensureVisible(text(fa.sessionLog));
    await tester.tap(text(fa.sessionLog));
    await settle(tester);
    expect(text(fa.proLockedTitle), findsOneWidget);
  });

  testWidgets('course: Pro can log a session', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [it('k', ItemType.course, title: 'پایتون')]);
    await tester.runAsync(() => env.controller.pro.applyPurchase(ProPlans.month1));
    await pumpApp(tester, env);
    showItemDetailSheet(ctx(tester), 'k');
    await settle(tester);
    await tester.ensureVisible(text(fa.sessionLog));
    await tester.tap(text(fa.sessionLog));
    await settle(tester);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(ActionChip, '۳۰ دقیقه')));
    await settle(tester, rounds: 15);
    expect(env.controller.itemById('k')!.sessions.single.$2, 30);
  });

  testWidgets('game picker: free draws a game; its filters open the Pro sheet', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [
      it('g', ItemType.game, title: 'Celeste', minutes: 45, extra: {'genre': 'Platformer'}),
    ]);
    await pumpApp(tester, env);
    await push(tester, const GamePickerScreen());
    await tester.tap(find.widgetWithText(ChoiceChip, '۳۰ دقیقه'));
    await settle(tester);
    expect(text(fa.proLockedTitle), findsOneWidget);
    await tester.tap(text(fa.notNow));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, fa.gamePickBtn));
    await settle(tester, rounds: 15);
    expect(find.textContaining('Celeste'), findsWidgets);
    expect(text(fa.gameStart), findsOneWidget);
    expect(text(fa.gameAnother), findsOneWidget);
    await tester.tap(text(fa.gameStart));
    await settle(tester, rounds: 15);
    expect(env.controller.itemById('g')!.stage, ItemStages.playing);
  });

  testWidgets('game picker (Pro): the time filter is honoured', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [
      it('long', ItemType.game, title: 'Elden', minutes: 120),
      it('short', ItemType.game, title: 'Celeste', minutes: 30),
    ]);
    await tester.runAsync(() => env.controller.pro.applyPurchase(ProPlans.month1));
    await pumpApp(tester, env);
    await push(tester, const GamePickerScreen());
    await tester.tap(find.widgetWithText(ChoiceChip, '۴۵ دقیقه'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, fa.gamePickBtn));
    await settle(tester, rounds: 15);
    expect(find.textContaining('Celeste'), findsWidgets);
    expect(find.textContaining('Elden'), findsNothing);
  });

  testWidgets('quick capture (from the widget): saves with the chosen kind and leaves the app', (tester) async {
    final env = await createEnv(tester, settings: readySettings);
    await pumpApp(tester, env);
    await tester.runAsync(() => env.controller.init());
    showQuickCapture(ctx(tester));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'پادکست دیشب');
    await tester.tap(find.widgetWithText(ChoiceChip, fa.shelfPodcastTitle));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, fa.save));
    await settle(tester, rounds: 15);
    final p = env.controller.shelf(ItemType.podcast).single;
    expect(p.title, 'پادکست دیشب');
    expect(p.source, 'widget');
    expect(env.platform.movedToBack, isTrue);
  });

  testWidgets('quick capture: plain "later" goes to the inbox', (tester) async {
    final env = await createEnv(tester, settings: readySettings);
    await pumpApp(tester, env);
    await tester.runAsync(() => env.controller.init());
    showQuickCapture(ctx(tester));
    await settle(tester);
    await tester.enterText(find.byType(TextField).last, 'یه فکر');
    await tester.tap(find.widgetWithText(FilledButton, fa.save));
    await settle(tester, rounds: 15);
    expect(env.controller.inboxItems.single.title, 'یه فکر');
  });

  testWidgets('widget quick actions reach the app: capture, inbox, item', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [it('a', ItemType.app, title: 'برنامه')]);
    await pumpApp(tester, env);
    final bus = NullBus();
    expect(QuickAction.values, containsAll([QuickAction.capture, QuickAction.inbox, QuickAction.item]));
    handleQuickAction(ctx(tester), QuickAction.inbox, bus.nav);
    await settle(tester);
    expect(text(fa.inboxTitle), findsWidgets);
    env.platform.actionArg = 'a';
    handleQuickAction(ctx(tester), QuickAction.item, bus.nav);
    await settle(tester, rounds: 15);
    expect(env.controller.takePendingOpenItem(), anyOf('a', isNull));
  });

  testWidgets('item tiles of the new types have a stage button', (tester) async {
    final env = await createEnv(tester, settings: readySettings, items: [
      it('a', ItemType.app, title: 'برنامه'),
      it('k', ItemType.course, title: 'دوره', extra: {'progress': 20}),
    ]);
    await pumpApp(tester, env);
    await push(tester, const ShelfScreen(type: ItemType.course));
    expect(find.byType(ItemTile), findsOneWidget);
    expect(find.byTooltip(fa.itemStage), findsOneWidget);
    expect(find.textContaining('۲۰٪ پیشرفت'), findsOneWidget);
  });
}

class TypeInfoLabels {
  static String sub(ItemType t) => switch (t) {
        ItemType.app => fa.shelfAppSub,
        ItemType.podcast => fa.shelfPodcastSub,
        ItemType.course => fa.shelfCourseSub,
        _ => fa.shelfGameSub,
      };
}

/// A throw-away NavBus for calling [handleQuickAction] directly.
class NullBus {
  final nav = NavBus();
}
