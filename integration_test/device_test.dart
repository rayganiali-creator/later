// Runs on a real Android device / emulator:
//   flutter test integration_test --flavor qa -d <device>
// Exercises the real platform pieces: SQLite, Android Keystore, AlarmManager
// notifications, backup round trip. (Share sheet / reboot scenarios are driven
// by tool/ci/android_scenarios.sh with adb.)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:later/core/config/pro_plans.dart';
import 'package:later/data/controller.dart';
import 'package:later/data/db/app_database.dart';
import 'package:later/data/pro/pro_service.dart';
import 'package:later/data/repository.dart';
import 'package:later/domain/models.dart';
import 'package:later/domain/reminders.dart';
import 'package:later/services/file_gateway.dart';
import 'package:later/services/notification_service.dart';
import 'package:later/services/platform_bridge.dart';
import 'package:later/services/purchase_gateway.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

Future<LaterController> makeController(String dbName, {Vault? vault}) async {
  final path = p.join(await getDatabasesPath(), dbName);
  final adb = await AppDatabase.open(path: path, singleInstance: false);
  final gw = FlutterNotificationGateway();
  final c = LaterController(
    repo: LaterRepository(adb),
    pro: ProService(vault: vault ?? SecureVault(), backupSigningKey: 'device-test-key'),
    notifications: gw,
    reminderService: ReminderService(gw),
    platform: NullPlatformBridge(),
    files: SystemFileGateway(),
    purchases: SimulatedPurchaseGateway(),
    appVersion: 'test',
  );
  await c.init();
  return c;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SQLite on device: CRUD + persistence across re-open', (tester) async {
    final name = 'it_${DateTime.now().microsecondsSinceEpoch}.db';
    var c = await makeController(name);
    await c.quickAdd('device item');
    c.dispose();
    c = await makeController(name);
    expect(c.allItems.single.title, 'device item');
    c.dispose();
  });

  testWidgets('Keystore-backed Pro entitlement persists and is tamper checked', (tester) async {
    final v = SecureVault();
    final a = ProService(vault: v, backupSigningKey: 'k');
    await a.clear();
    await a.applyPurchase(ProPlans.month1);
    final b = ProService(vault: v, backupSigningKey: 'k');
    await b.load();
    expect(b.isActive(), isTrue);
    await v.write('pro.record.v1', 'garbage');
    final c = ProService(vault: v, backupSigningKey: 'k');
    await c.load();
    expect(c.isActive(), isFalse);
    await c.clear();
  });

  testWidgets('Notifications: schedule, no duplicates, cancel, recurring', (tester) async {
    final gw = FlutterNotificationGateway();
    const texts = NotificationTexts(
      channelName: 'Reminders', channelDescription: 'd', actionDone: 'Done',
      actionTomorrow: 'Tomorrow', privateTitle: 'Later', privateBody: 'b',
      testTitle: 'Test', testBody: 'Body');
    await gw.init(onTap: (_) {}, texts: texts);
    final perm = await gw.requestPermission();
    // ignore: avoid_print
    print('NOTIF_PERMISSION=$perm EXACT=${await gw.exactAlarmsAllowed()}');
    await gw.cancelAll();
    final svc = ReminderService(gw);
    final now = DateTime.now();
    final soon = now.add(const Duration(minutes: 2));
    final items = [
      LaterItem(id: 'n1', title: 'One-shot', categoryId: 'other', createdAt: now, updatedAt: now,
          dueAt: DateTime(soon.year, soon.month, soon.day, soon.hour, soon.minute), hasTime: true, reminderEnabled: true),
      LaterItem(id: 'n2', title: 'Daily', categoryId: 'other', createdAt: now, updatedAt: now,
          dueAt: DateTime(soon.year, soon.month, soon.day, soon.hour, soon.minute).add(const Duration(minutes: 1)),
          hasTime: true, reminderEnabled: true, repeat: RepeatRule.daily),
    ];
    Future<ReminderSyncResult> sync() => svc.sync(
        items: items, now: DateTime.now(), remindersEnabled: true, allowRepeat: true, privateMode: false,
        defaultMinutesOfDay: 540, maxScheduled: 300, texts: texts, titleOf: (i) => i.title, bodyOf: (i) => 'b');
    final r1 = await sync();
    final r2 = await sync();
    final r3 = await sync();
    final pending = await gw.pendingIds();
    // ignore: avoid_print
    print('NOTIF_SCHEDULED r1=${r1.scheduled} r2=${r2.scheduled} pending=${pending.length}');
    if (perm == NotificationPermission.granted) {
      expect(r3.failed, 0);
      expect(pending.length, 2, reason: 'repeated syncs must not create duplicates');
    }
    await gw.cancelAll();
    expect(await gw.pendingIds(), isEmpty);
    // Leave one real alarm behind for the adb scenario script to inspect.
    await sync();
    // ignore: avoid_print
    print('NOTIF_READY_FOR_ADB');
  });

  testWidgets('Backup -> wipe -> restore round trip on device (1000 items)', (tester) async {
    final name = 'bk_${DateTime.now().microsecondsSinceEpoch}.db';
    final c = await makeController(name);
    await c.pro.clear();
    await c.pro.applyPurchase(ProPlans.month3);
    await c.debugSeed(1000, withSamples: false);
    await c.addCategory('سفر', '✈️');
    final before = await c.repo.loadAll();
    final bytes = await c.buildBackupBytes();
    final dir = await c.files.internalBackupDir();
    await BackupFiles.write(dir.path, 'roundtrip.later', bytes);
    await c.repo.wipe(DateTime.now());
    expect((await c.repo.loadItems()), isEmpty);
    await c.pro.clear();
    final back = File(p.join(dir.path, 'roundtrip.later')).readAsBytesSync();
    await c.restore(c.inspectBackup(back));
    final after = await c.repo.loadAll();
    expect(after.items.length, before.items.length);
    expect(after.categories.length, before.categories.length);
    expect(c.isPro, isTrue);
    c.dispose();
  });

  testWidgets('Timezone-aware scheduling accepts local wall-clock times', (tester) async {
    final gw = FlutterNotificationGateway();
    const texts = NotificationTexts(
      channelName: 'R', channelDescription: 'd', actionDone: 'D', actionTomorrow: 'T',
      privateTitle: 'L', privateBody: 'b', testTitle: 't', testBody: 'b');
    await gw.init(onTap: (_) {}, texts: texts);
    await gw.cancelAll();
    final at = DateTime.now().add(const Duration(days: 1));
    await gw.schedule(
      PlannedReminder(notificationId: 777, itemId: 'tz', fireAt: at, repeat: RepeatRule.weekly, title: 't', body: 'b'),
      exact: false, privateMode: true, texts: texts);
    expect((await gw.pendingIds()).contains(777), isTrue);
    await gw.cancelAll();
  });
}
