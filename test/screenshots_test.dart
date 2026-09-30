// Generates store screenshots:  SCREENSHOTS=1 flutter test test/screenshots_test.dart
// Output: store/assets/screenshots/*.png (real Vazirmatn font, real widgets).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/config/pro_plans.dart';
import 'package:later/domain/models.dart';
import 'package:later/l10n/app_localizations_fa.dart';
import 'package:later/ui/app.dart';

import 'harness.dart';

final fa = AppL10nFa();

void main() {
  final enabled = Platform.environment['SCREENSHOTS'] == '1';
  testWidgets('store screenshots', skip: !enabled, (tester) async {
    // flutter_test does not load app fonts by itself: load them for real glyphs.
    final vaz = FontLoader('Vazirmatn');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      vaz.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Vazirmatn-$w.ttf').readAsBytesSync())));
    }
    await vaz.load();
    final root = Platform.environment['FLUTTER_ROOT'] ?? '/opt/sdk/flutter';
    final icons = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(
          File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync())));
    await icons.load();
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
    final out = Directory('store/assets/screenshots')..createSync(recursive: true);
    final key = GlobalKey();
    Future<void> shot(String name) async {
      await settle(tester, rounds: 8);
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final img = await boundary.toImage(pixelRatio: 2.6);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File('${out.path}/$name.png').writeAsBytesSync(bytes!);
    }

    Future<void> show(TestEnv env) async {
      tester.view.physicalSize = const Size(412, 915) * 2;
      tester.view.devicePixelRatio = 2;
      await tester.pumpWidget(RepaintBoundary(key: key, child: LaterApp(controller: env.controller)));
      await settle(tester);
    }

    final env = await createEnv(tester, settings: readySettings, now: DateTime(2026, 9, 30, 10));
    await tester.runAsync(() async {
      await env.controller.init();
      await env.controller.debugSeed(10);
      final items = env.controller.allItems;
      await env.controller.update(items[0].copyWith(dueAt: DateTime(2026, 9, 30, 18), hasTime: true, reminderEnabled: true, priority: ItemPriority.high));
      await env.controller.update(items[2].copyWith(dueAt: DateTime(2026, 9, 30)));
      await env.controller.update(items[3].copyWith(dueAt: DateTime(2026, 9, 27)));
      await env.controller.complete(items[8].id);
      await env.controller.pro.applyPurchase(ProPlans.month1);
    });
    await tester.runAsync(() async {
      final c = env.controller;
      Future<void> add(String title, ItemType t, {String? url, int stage = 0, Map<String, Object?> extra = const {}, int ago = 3}) async {
        final n = c.now();
        final i = LaterItem(
          id: 's${title.hashCode}',
          title: title,
          categoryId: 'other',
          createdAt: n.subtract(Duration(days: ago)),
          updatedAt: n,
          type: t,
          stage: stage,
          url: url,
          extra: extra,
        );
        await c.saveNew(i);
      }

      await add('مقاله‌ی «قدرت عادت‌های کوچک»', ItemType.read, url: 'https://example.com/habits');
      await add('سخنرانی درباره‌ی تمرکز', ItemType.watch, url: 'https://www.youtube.com/watch?v=abc');
      await add('هدفون بی‌سیم', ItemType.wishlist, extra: {'price': 2400000, 'currency': 'تومان'}, ago: 40);
      await add('اپ یادآور آب‌خوردن', ItemType.idea, ago: 20);
      await c.quickAdd('کتاب فیزیک کوانتوم');
      await c.addPerson('سارا');
      await c.seal(title: 'نامه به خودِ یک‌ساله‌ی بعد', body: 'سلام', unlockAt: DateTime(2027, 6, 1));
    });
    await show(env);
    await shot('01_home');
    await tester.tap(find.text(fa.navList).last);
    await shot('02_list');
    await tester.tap(find.text(fa.navHome).last);
    await settle(tester);
    await tester.tap(find.text(fa.pickCardTitle));
    await settle(tester);
    await tester.tap(find.text(fa.roulettePick));
    await settle(tester, rounds: 30);
    await shot('03_roulette');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settle(tester);
    await tester.ensureVisible(find.text(fa.shelfWishTitle).first);
    await settle(tester);
    await tester.tap(find.text(fa.shelfWishTitle).first);
    await settle(tester);
    await shot('04_wishlist');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settle(tester);
    await tester.ensureVisible(find.text(fa.shelfFutureTitle).first);
    await settle(tester);
    await tester.tap(find.text(fa.shelfFutureTitle).first);
    await settle(tester);
    await shot('05_future');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settle(tester);
    await tester.tap(find.text(fa.dashInbox).first);
    await shot('06_inbox');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await settle(tester);
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await settle(tester);
    await tester.enterText(find.byType(TextFormField).first, 'این مقاله رو بخونم');
    await shot('07_add');
    await tester.tapAt(const Offset(200, 40));
    await settle(tester);
    await tester.tap(find.text(fa.navSettings).last);
    await shot('08_settings');
    expect(out.listSync().length, greaterThanOrEqualTo(8));
  });
}
