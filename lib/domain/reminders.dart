import '../core/util/dates.dart';
import '../core/util/ids.dart';
import 'models.dart';

/// A reminder that should exist in the OS scheduler.
class PlannedReminder {
  const PlannedReminder({
    required this.notificationId,
    required this.itemId,
    required this.fireAt,
    required this.repeat,
    required this.title,
    required this.body,
    this.sealed = false,
  });

  /// Sealed-item notification: text must not reveal the content.
  final bool sealed;
  final int notificationId;
  final String itemId;

  /// Next firing instant (local wall clock).
  final DateTime fireAt;
  final RepeatRule repeat;
  final String title;
  final String body;

  @override
  String toString() => 'PlannedReminder($itemId @ $fireAt $repeat)';
}

/// Pure planning of which notifications must be scheduled. Separated from the
/// platform plugin so it can be unit tested exhaustively.
class ReminderPlanner {
  const ReminderPlanner();

  /// Base (first) firing time of the reminder, ignoring "now".
  static DateTime? baseTime(
    LaterItem i, {
    required int defaultMinutesOfDay,
  }) {
    if (!i.reminderEnabled) return null;
    final due = i.dueAt;
    if (due == null) return null;
    final base = i.hasTime
        ? due
        : Dates.withTime(due, defaultMinutesOfDay ~/ 60, defaultMinutesOfDay % 60);
    return base.subtract(Duration(minutes: i.reminderOffsetMinutes));
  }

  /// Next firing time strictly after [now] (or equal within a few seconds),
  /// considering repeat rules. Returns null if the reminder will never fire.
  static DateTime? nextFire(
    LaterItem i,
    DateTime now, {
    required int defaultMinutesOfDay,
    required bool allowRepeat,
  }) {
    final base = baseTime(i, defaultMinutesOfDay: defaultMinutesOfDay);
    if (base == null) return null;
    final cutoff = now.subtract(const Duration(seconds: 5));
    if (!base.isBefore(cutoff)) return base;
    if (i.repeat == RepeatRule.none || !allowRepeat) return null;
    var d = base;
    switch (i.repeat) {
      case RepeatRule.daily:
        final n = Dates.daysBetween(base, now);
        d = Dates.addDays(base, n);
        if (d.isBefore(cutoff)) d = Dates.addDays(d, 1);
      case RepeatRule.weekly:
        final n = Dates.daysBetween(base, now) ~/ 7;
        d = Dates.addDays(base, n * 7);
        if (d.isBefore(cutoff)) d = Dates.addDays(d, 7);
      case RepeatRule.monthly:
        var k = 0;
        while (d.isBefore(cutoff) && k < 2400) {
          k++;
          d = Dates.addMonths(base, k, CalendarSystem.gregorian);
        }
      case RepeatRule.yearly:
        var k = 0;
        while (d.isBefore(cutoff) && k < 200) {
          k++;
          d = Dates.addMonths(base, 12 * k, CalendarSystem.gregorian);
        }
      case RepeatRule.none:
        return null;
    }
    return d;
  }

  /// Full plan for all items, capped to the [max] soonest reminders.
  List<PlannedReminder> plan(
    Iterable<LaterItem> items,
    DateTime now, {
    required int defaultMinutesOfDay,
    required bool allowRepeat,
    required int max,
    required String Function(LaterItem) titleOf,
    required String Function(LaterItem) bodyOf,
    String Function(LaterItem)? unlockTitleOf,
    String Function(LaterItem)? unlockBodyOf,
  }) {
    final out = <PlannedReminder>[];
    final usedIds = <int>{};
    for (final i in items) {
      if (!i.isActive) continue;
      DateTime? at;
      var unlock = false;
      final ul = i.unlockAt;
      if (ul != null && (i.type == ItemType.capsule || i.type == ItemType.future)) {
        // Sealed things notify once, when they open (never before).
        if (!ul.isBefore(now.subtract(const Duration(seconds: 5)))) {
          at = ul;
          unlock = true;
        }
      } else {
        at = nextFire(i, now, defaultMinutesOfDay: defaultMinutesOfDay, allowRepeat: allowRepeat);
        // A sealed item must stay silent until it opens.
        if (at != null && ul != null && at.isBefore(ul)) at = null;
        if (at == null && ul != null && ul.isAfter(now) && i.reminderEnabled) {
          at = ul; // reminder time already passed while sealed: remind when it opens
          unlock = true;
        }
      }
      if (at == null) continue;
      var nid = stableHash31(i.id);
      while (!usedIds.add(nid)) {
        nid = (nid + 1) & 0x7fffffff; // resolve (very unlikely) collisions
      }
      out.add(PlannedReminder(
        notificationId: nid,
        itemId: i.id,
        fireAt: at,
        repeat: allowRepeat ? i.repeat : RepeatRule.none,
        title: unlock && unlockTitleOf != null ? unlockTitleOf(i) : titleOf(i),
        body: unlock && unlockBodyOf != null ? unlockBodyOf(i) : bodyOf(i),
        sealed: unlock,
      ));
    }
    out.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return out.length > max ? out.sublist(0, max) : out;
  }
}
