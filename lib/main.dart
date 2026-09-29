import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'core/config/app_config.dart';
import 'data/controller.dart';
import 'data/db/app_database.dart';
import 'data/pro/pro_service.dart';
import 'data/repository.dart';
import 'services/file_gateway.dart';
import 'services/notification_service.dart';
import 'services/platform_bridge.dart';
import 'services/purchase_gateway.dart';
import 'ui/app.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Never log user content: only the error type in release builds.
    FlutterError.onError = (details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      } else {
        debugPrint('flutter error: ${details.exception.runtimeType}');
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('uncaught: ${error.runtimeType}');
      return true;
    };

    final info = await PackageInfo.fromPlatform();
    final controller = await _compose(info.version);
    runApp(LaterApp(controller: controller));
  }, (error, stack) {
    debugPrint('zone error: ${error.runtimeType}');
  });
}

/// Composition root: wires real platform implementations together.
Future<LaterController> _compose(String version) async {
  final adb = await AppDatabase.open();
  final gateway = FlutterNotificationGateway();
  return LaterController(
    repo: LaterRepository(adb),
    pro: ProService(vault: SecureVault()),
    notifications: gateway,
    reminderService: ReminderService(gateway),
    platform: MethodChannelPlatformBridge(),
    files: SystemFileGateway(),
    // QA builds "buy" instantly; the store build talks to Cafe Bazaar.
    purchases: AppConfig.testToolsEnabled ? SimulatedPurchaseGateway() : BazaarPurchaseGateway(),
    appVersion: version,
  );
}
