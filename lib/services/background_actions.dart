import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/util/ids.dart';
import '../data/db/app_database.dart';
import '../data/repository.dart';
import '../domain/models.dart';
import '../domain/snooze.dart';
import '../domain/transitions.dart';
import 'notification_service.dart';

/// Applies a notification button (Done / Tomorrow) without opening the UI.
/// Runs in the plugin's background isolate, so it builds its own database
/// connection and applies exactly the same [Transitions] as the app does.
Future<void> applyBackgroundAction(NotificationTap tap) async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    final adb = await AppDatabase.open();
    final repo = LaterRepository(adb);
    final items = await repo.loadItems();
    LaterItem? item;
    for (final i in items) {
      if (i.id == tap.itemId) item = i;
    }
    if (item == null || !item.isActive) return;
    final settings = await repo.loadSettings();
    final now = DateTime.now();

    Transition t;
    switch (tap.actionId) {
      case NotificationTap.actionDone:
        t = Transitions.complete(item, now);
      case NotificationTap.actionTomorrow:
        final calc = SnoozeCalculator(
          weekStart: settings.weekStart,
          weekendDay: settings.weekendDay,
          calendar: settings.calendar,
        );
        t = Transitions.snooze(item, calc.compute(SnoozeOption.tomorrow, now), now);
      default:
        return;
    }
    if (tap.actionId == NotificationTap.actionDone && !settings.keepHistory) {
      await repo.deleteItemWithEvent(item.id, t.event);
    } else {
      await repo.upsertItemWithEvent(t.item, t.event);
    }
    // Repeating reminders would otherwise keep firing for a finished item.
    await FlutterLocalNotificationsPlugin().cancel(id: stableHash31(item.id));
    // The DB is intentionally left open: the native connection is shared
    // with the UI isolate. The UI re-reads from disk on resume.
  } catch (_) {
    // Nothing to report to; the next app launch re-syncs everything.
  }
}
