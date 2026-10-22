import '../core/config/app_config.dart';
import '../core/util/dates.dart';

enum SnoozeOption { tonight, tomorrow, weekend, nextWeek, nextMonth, noDate }

class SnoozeTarget {
  const SnoozeTarget(this.dueAt, this.hasTime);

  /// null means "no date".
  final DateTime? dueAt;
  final bool hasTime;
}

/// Calculates where a snoozed item should land.
class SnoozeCalculator {
  const SnoozeCalculator({
    required this.weekStart,
    required this.weekendDay,
    required this.calendar,
  });

  /// Uses [DateTime.monday]..[DateTime.sunday].
  final int weekStart;
  final int weekendDay;
  final CalendarSystem calendar;

  SnoozeTarget compute(SnoozeOption option, DateTime now) {
    switch (option) {
      case SnoozeOption.tonight:
        final tonight = Dates.withTime(now, AppConfig.tonightHour, 0);
        // If it is already past the evening slot, roll to a later moment
        // today rather than the past: two hours from now (still today) or,
        // if that spills over midnight, tomorrow evening.
        if (tonight.isAfter(now.add(const Duration(minutes: 5)))) {
          return SnoozeTarget(tonight, true);
        }
        final later = now.add(const Duration(hours: 2));
        if (Dates.isSameDay(later, now)) {
          return SnoozeTarget(
              DateTime(later.year, later.month, later.day, later.hour, 0), true);
        }
        return SnoozeTarget(
            Dates.withTime(Dates.addDays(now, 1), AppConfig.tonightHour, 0),
            true);
      case SnoozeOption.tomorrow:
        return SnoozeTarget(Dates.startOfDay(Dates.addDays(now, 1)), false);
      case SnoozeOption.weekend:
        var d = Dates.thisWeekend(now, weekendDay);
        if (Dates.isSameDay(d, now)) d = Dates.addDays(d, 7);
        return SnoozeTarget(d, false);
      case SnoozeOption.nextWeek:
        return SnoozeTarget(Dates.startOfNextWeek(now, weekStart), false);
      case SnoozeOption.nextMonth:
        return SnoozeTarget(
            Dates.startOfDay(Dates.addMonths(now, 1, calendar)), false);
      case SnoozeOption.noDate:
        return const SnoozeTarget(null, false);
    }
  }
}
