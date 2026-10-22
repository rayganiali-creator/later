import '../core/util/dates.dart';
import 'models.dart';

/// Numbers derived from study / play sessions the user logged by hand.
class SessionStats {
  const SessionStats({
    required this.totalMinutes,
    required this.weekMinutes,
    required this.monthMinutes,
    required this.streakDays,
    required this.sessionCount,
  });
  final int totalMinutes, weekMinutes, monthMinutes, streakDays, sessionCount;
}

SessionStats sessionStats(Iterable<LaterItem> items, DateTime now, {required int weekStart, ItemType? type}) {
  final all = <(DateTime, int)>[
    for (final i in items)
      if (type == null || i.type == type) ...i.sessions,
  ];
  return statsOfSessions(all, now, weekStart: weekStart);
}

SessionStats statsOfSessions(List<(DateTime, int)> all, DateTime now, {required int weekStart}) {
  final week = Dates.startOfWeek(now, weekStart);
  final month = DateTime(now.year, now.month, 1);
  var total = 0, w = 0, m = 0;
  final days = <DateTime>{};
  for (final s in all) {
    total += s.$2;
    if (!s.$1.isBefore(week)) w += s.$2;
    if (!s.$1.isBefore(month)) m += s.$2;
    days.add(Dates.startOfDay(s.$1));
  }
  return SessionStats(
    totalMinutes: total,
    weekMinutes: w,
    monthMinutes: m,
    streakDays: streak(days, now),
    sessionCount: all.length,
  );
}

/// Consecutive days with at least one session, ending today (or yesterday:
/// the streak is not broken until a whole day has passed without a session).
int streak(Set<DateTime> days, DateTime now) {
  final today = Dates.startOfDay(now);
  var d = days.contains(today) ? today : Dates.addDays(today, -1);
  var n = 0;
  while (days.contains(d)) {
    n++;
    d = Dates.addDays(d, -1);
  }
  return n;
}
