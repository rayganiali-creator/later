import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/config/pro_plans.dart';
import 'package:later/data/controller.dart';
import 'package:later/data/db/app_database.dart';
import 'package:later/data/pro/pro_service.dart';
import 'package:later/data/repository.dart';
import 'package:later/domain/models.dart';
import 'package:later/domain/settings.dart';
import 'package:later/services/file_gateway.dart';
import 'package:later/services/image_picker_gateway.dart';
import 'package:later/services/notification_service.dart';
import 'package:later/services/platform_bridge.dart';
import 'package:later/services/purchase_gateway.dart';
import 'package:later/ui/app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeFileGateway implements FileGateway {
  final Map<String, Uint8List> saved = {};
  PickedFile? toPick;
  Object? pickError;
  late final Directory dir = Directory.systemTemp.createTempSync('later_test_');

  @override
  Future<bool> saveBackup(String fileName, Uint8List bytes, {required String dialogTitle}) async {
    saved[fileName] = bytes;
    return true;
  }

  @override
  Future<PickedFile?> pickBackup({required String dialogTitle}) async {
    if (pickError != null) throw pickError!;
    return toPick;
  }

  @override
  Future<Directory> internalBackupDir() async => dir;
}

class FakePurchaseGateway implements PurchaseGateway {
  PurchaseStatus next = PurchaseStatus.success;
  List<PurchaseResult> pending = [];
  final List<String> consumed = [];
  DateTime? purchaseTime;

  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<PurchaseResult> purchase(ProPlan plan) async => PurchaseResult(next,
      plan: plan, token: 'tok_${plan.sku}', purchasedAt: purchaseTime);
  @override
  Future<List<PurchaseResult>> pendingPurchases() async => pending;
  @override
  Future<void> consume(String token) async => consumed.add(token);
}

class TestEnv {
  TestEnv._(this.controller, this.gateway, this.platform, this.files, this.purchases, this.vault, this.adb, this.imagePicker);

  final LaterController controller;
  final FakeNotificationGateway gateway;
  final NullPlatformBridge platform;
  final FakeFileGateway files;
  final FakePurchaseGateway purchases;
  final MemoryVault vault;
  final AppDatabase adb;
  final FakeImagePicker imagePicker;
  DateTime clockNow = DateTime(2026, 9, 30, 10);

  static Future<TestEnv> create({
    AppSettings? settings,
    List<LaterItem> items = const [],
    DateTime? now,
    MemoryVault? vault,
    String proKey = 'test-key',
  }) async {
    sqfliteFfiInit();
    final start = now ?? DateTime(2026, 9, 30, 10);
    final adb = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi, now: () => start, singleInstance: false);
    final repo = LaterRepository(adb);
    if (settings != null) await repo.saveSettings(settings);
    if (items.isNotEmpty) await repo.upsertItems(items);
    final gw = FakeNotificationGateway();
    final platform = NullPlatformBridge();
    final files = FakeFileGateway();
    final purchases = FakePurchaseGateway();
    final v = vault ?? MemoryVault();
    late TestEnv env;
    final picker = FakeImagePicker();
    final c = LaterController(
      imagePicker: picker,
      repo: repo,
      pro: ProService(vault: v, clock: () => env.clockNow, backupSigningKey: proKey),
      notifications: gw,
      reminderService: ReminderService(gw),
      platform: platform,
      files: files,
      purchases: purchases,
      appVersion: '1.0.0',
      clock: () => env.clockNow,
    );
    env = TestEnv._(c, gw, platform, files, purchases, v, adb, picker);
    env.clockNow = start;
    return env;
  }

  /// The in-memory database is left to the GC: closing it needs real async.
  void dispose() => controller.dispose();
}

/// Creates the environment with real async I/O (sqflite ffi isolates).
Future<TestEnv> createEnv(
  WidgetTester tester, {
  AppSettings? settings,
  List<LaterItem> items = const [],
  DateTime? now,
  MemoryVault? vault,
  String proKey = 'test-key',
}) async {
  final env = (await tester.runAsync(() =>
      TestEnv.create(settings: settings, items: items, now: now, vault: vault, proKey: proKey)))!;
  addTearDown(env.dispose);
  return env;
}

const AppSettings readySettings = AppSettings(onboardingDone: true, termsAcceptedVersion: 1, privacyAcceptedVersion: 1);

/// Lets real async work (sqflite ffi isolates, timers) progress while pumping.
Future<void> settle(WidgetTester tester, {int rounds = 12}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> pumpApp(WidgetTester tester, TestEnv env, {Size size = const Size(412, 915)}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(LaterApp(controller: env.controller));
  await settle(tester);
}
