import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Priority;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln show Priority;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/models.dart';
import '../domain/reminders.dart';
import 'background_actions.dart';

/// Payload conventions for notifications: `item:<id>`.
class NotificationTap {
  const NotificationTap({required this.itemId, this.actionId});
  final String itemId;

  /// `done`, `tomorrow`, or null for a plain tap.
  final String? actionId;

  static const actionDone = 'done';
  static const actionTomorrow = 'tomorrow';

  static String payloadFor(String itemId) => 'item:$itemId';

  static NotificationTap? parse(String? payload, String? actionId) {
    if (payload == null || !payload.startsWith('item:')) return null;
    final id = payload.substring(5);
    if (id.isEmpty || id.length > 64) return null;
    return NotificationTap(
      itemId: id,
      actionId: (actionId == null || actionId.isEmpty) ? null : actionId,
    );
  }
}

/// Localized strings used when building notifications.
class NotificationTexts {
  const NotificationTexts({
    required this.channelName,
    required this.channelDescription,
    required this.actionDone,
    required this.actionTomorrow,
    required this.privateTitle,
    required this.privateBody,
    required this.testTitle,
    required this.testBody,
  });

  final String channelName;
  final String channelDescription;
  final String actionDone;
  final String actionTomorrow;
  final String privateTitle;
  final String privateBody;
  final String testTitle;
  final String testBody;
}

enum NotificationPermission { granted, denied }

/// Abstraction over the OS notification scheduler (real implementation uses
/// flutter_local_notifications + AlarmManager; tests use a fake).
abstract class NotificationGateway {
  Future<void> init({
    required void Function(NotificationTap tap) onTap,
    required NotificationTexts texts,
  });

  Future<NotificationTap?> launchTap();
  Future<NotificationPermission> permission();
  Future<NotificationPermission> requestPermission();
  Future<bool> exactAlarmsAllowed();
  Future<bool> requestExactAlarms();
  Future<void> cancelAll();
  Future<void> cancel(int id);
  Future<void> schedule(
    PlannedReminder r, {
    required bool exact,
    required bool privateMode,
    required NotificationTexts texts,
  });
  Future<Set<int>> pendingIds();
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
  Future<void> openSystemSettings();
}

const String kReminderChannelId = 'later_reminders';

/// Called by the plugin in a background isolate for actions that don't need
/// the UI (Done / Tomorrow buttons). Must be a top-level function.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  final tap = NotificationTap.parse(response.payload, response.actionId);
  if (tap == null) return;
  unawaited(applyBackgroundAction(tap));
}

class FlutterNotificationGateway implements NotificationGateway {
  FlutterNotificationGateway([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _tzReady = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<void> init({
    required void Function(NotificationTap tap) onTap,
    required NotificationTexts texts,
  }) async {
    await _ensureTimezone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/ic_notification'),
      ),
      onDidReceiveNotificationResponse: (r) {
        final tap = NotificationTap.parse(r.payload, r.actionId);
        if (tap != null) onTap(tap);
      },
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
    await _android?.createNotificationChannel(AndroidNotificationChannel(
      kReminderChannelId,
      texts.channelName,
      description: texts.channelDescription,
      importance: Importance.high,
    ));
  }

  /// (Re)reads the device timezone. Called on every sync so timezone changes
  /// are picked up the next time the app runs.
  Future<void> _ensureTimezone() async {
    if (!_tzReady) {
      tzdata.initializeTimeZones();
      _tzReady = true;
    }
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Unknown zone id: fall back to UTC offset of the device via UTC.
      tz.setLocalLocation(tz.UTC);
    }
  }

  @override
  Future<NotificationTap?> launchTap() async {
    final d = await _plugin.getNotificationAppLaunchDetails();
    if (d == null || !d.didNotificationLaunchApp) return null;
    return NotificationTap.parse(
        d.notificationResponse?.payload, d.notificationResponse?.actionId);
  }

  @override
  Future<NotificationPermission> permission() async {
    final ok = await _android?.areNotificationsEnabled();
    return ok == false ? NotificationPermission.denied : NotificationPermission.granted;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    final ok = await _android?.requestNotificationsPermission();
    if (ok == true) return NotificationPermission.granted;
    return permission();
  }

  @override
  Future<bool> exactAlarmsAllowed() async =>
      (await _android?.canScheduleExactNotifications()) ?? false;

  @override
  Future<bool> requestExactAlarms() async =>
      (await _android?.requestExactAlarmsPermission()) ?? false;

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<Set<int>> pendingIds() async =>
      (await _plugin.pendingNotificationRequests()).map((e) => e.id).toSet();

  NotificationDetails _details(NotificationTexts t, {required bool privateMode}) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          kReminderChannelId,
          t.channelName,
          channelDescription: t.channelDescription,
          importance: Importance.high,
          priority: fln.Priority.high,
          category: AndroidNotificationCategory.reminder,
          visibility: privateMode
              ? NotificationVisibility.private
              : NotificationVisibility.public,
          autoCancel: true,
          actions: privateMode
              ? null
              : [
                  AndroidNotificationAction(
                    NotificationTap.actionDone,
                    t.actionDone,
                    cancelNotification: true,
                  ),
                  AndroidNotificationAction(
                    NotificationTap.actionTomorrow,
                    t.actionTomorrow,
                    cancelNotification: true,
                  ),
                ],
        ),
      );

  @override
  Future<void> schedule(
    PlannedReminder r, {
    required bool exact,
    required bool privateMode,
    required NotificationTexts texts,
  }) async {
    await _ensureTimezone();
    final at = r.fireAt;
    final when = tz.TZDateTime(tz.local, at.year, at.month, at.day, at.hour, at.minute);
    DateTimeComponents? match;
    switch (r.repeat) {
      case RepeatRule.none:
        match = null;
      case RepeatRule.daily:
        match = DateTimeComponents.time;
      case RepeatRule.weekly:
        match = DateTimeComponents.dayOfWeekAndTime;
      case RepeatRule.monthly:
        match = DateTimeComponents.dayOfMonthAndTime;
    }
    await _plugin.zonedSchedule(
      id: r.notificationId,
      title: privateMode ? texts.privateTitle : r.title,
      body: privateMode ? texts.privateBody : r.body,
      scheduledDate: when,
      notificationDetails: _details(texts, privateMode: privateMode),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: NotificationTap.payloadFor(r.itemId),
      matchDateTimeComponents: match,
    );
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) =>
      _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            kReminderChannelId,
            'Later',
            importance: Importance.high,
            priority: fln.Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        payload: payload,
      );

  @override
  Future<void> openSystemSettings() async {
    await _android?.openAppNotificationSettings();
  }
}

/// In-memory gateway used by tests.
class FakeNotificationGateway implements NotificationGateway {
  final Map<int, ({PlannedReminder reminder, bool exact, bool privateMode})> scheduled = {};
  NotificationPermission perm = NotificationPermission.granted;
  bool exactAllowed = true;
  NotificationTap? launch;
  void Function(NotificationTap)? onTap;
  int cancelAllCalls = 0;
  bool failSchedule = false;
  final List<String> shown = [];

  @override
  Future<void> init({required void Function(NotificationTap tap) onTap, required NotificationTexts texts}) async {
    this.onTap = onTap;
  }

  @override
  Future<NotificationTap?> launchTap() async => launch;
  @override
  Future<NotificationPermission> permission() async => perm;
  @override
  Future<NotificationPermission> requestPermission() async => perm;
  @override
  Future<bool> exactAlarmsAllowed() async => exactAllowed;
  @override
  Future<bool> requestExactAlarms() async => exactAllowed;
  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled.clear();
  }

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);

  @override
  Future<void> schedule(PlannedReminder r,
      {required bool exact, required bool privateMode, required NotificationTexts texts}) async {
    if (failSchedule) throw StateError('scheduling failed');
    scheduled[r.notificationId] = (reminder: r, exact: exact, privateMode: privateMode);
  }

  @override
  Future<Set<int>> pendingIds() async => scheduled.keys.toSet();

  @override
  Future<void> showNow({required int id, required String title, required String body, String? payload}) async {
    shown.add(title);
  }

  @override
  Future<void> openSystemSettings() async {}
}

/// Result of a full reminder synchronization.
class ReminderSyncResult {
  const ReminderSyncResult({
    required this.scheduled,
    required this.permissionDenied,
    required this.exactDenied,
    this.failed = 0,
  });

  final int scheduled;
  final bool permissionDenied;
  final bool exactDenied;
  final int failed;

  static const empty = ReminderSyncResult(
      scheduled: 0, permissionDenied: false, exactDenied: false);
}

/// Keeps the OS scheduler in sync with the items: computes the plan, then
/// replaces *all* pending notifications (cancel-all + schedule), which makes
/// the operation idempotent and duplicate-free by construction.
class ReminderService {
  ReminderService(this._gateway, {this._planner = const ReminderPlanner()});

  final NotificationGateway _gateway;
  final ReminderPlanner _planner;

  Future<ReminderSyncResult> sync({
    required Iterable<LaterItem> items,
    required DateTime now,
    required bool remindersEnabled,
    required bool allowRepeat,
    required bool privateMode,
    required int defaultMinutesOfDay,
    required int maxScheduled,
    required NotificationTexts texts,
    required String Function(LaterItem) titleOf,
    required String Function(LaterItem) bodyOf,
  }) async {
    try {
      await _gateway.cancelAll();
      if (!remindersEnabled) return ReminderSyncResult.empty;
      final plan = _planner.plan(
        items,
        now,
        defaultMinutesOfDay: defaultMinutesOfDay,
        allowRepeat: allowRepeat,
        max: maxScheduled,
        titleOf: titleOf,
        bodyOf: bodyOf,
      );
      if (plan.isEmpty) return ReminderSyncResult.empty;
      final perm = await _gateway.permission();
      final exact = await _gateway.exactAlarmsAllowed();
      var ok = 0;
      var failed = 0;
      for (final r in plan) {
        try {
          await _gateway.schedule(r, exact: exact, privateMode: privateMode, texts: texts);
          ok++;
        } catch (e) {
          failed++;
          if (kDebugMode) debugPrint('reminder schedule failed: ${e.runtimeType}');
        }
      }
      return ReminderSyncResult(
        scheduled: ok,
        permissionDenied: perm == NotificationPermission.denied,
        exactDenied: !exact,
        failed: failed,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('reminder sync failed: ${e.runtimeType}');
      return const ReminderSyncResult(
          scheduled: 0, permissionDenied: false, exactDenied: false, failed: 1);
    }
  }
}
