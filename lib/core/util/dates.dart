import 'package:shamsi_date/shamsi_date.dart';

import 'text.dart';

enum CalendarSystem { jalali, gregorian }

/// Pure date helpers. All functions take explicit inputs (no hidden clock) so
/// they are trivially testable.
class Dates {
  const Dates._();

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days, d.hour, d.minute);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Number of whole calendar days from [a] to [b] (b - a), DST safe.
  static int daysBetween(DateTime a, DateTime b) {
    final ua = DateTime.utc(a.year, a.month, a.day);
    final ub = DateTime.utc(b.year, b.month, b.day);
    return ub.difference(ua).inDays;
  }

  /// [weekStart] uses [DateTime.monday]..[DateTime.sunday] constants.
  static DateTime startOfWeek(DateTime d, int weekStart) {
    final delta = (d.weekday - weekStart + 7) % 7;
    return startOfDay(addDays(d, -delta));
  }

  /// First day of the week *after* the one containing [d].
  static DateTime startOfNextWeek(DateTime d, int weekStart) =>
      addDays(startOfWeek(d, weekStart), 7);

  /// Next occurrence (strictly after today) of [weekday].
  static DateTime nextWeekday(DateTime d, int weekday) {
    var delta = (weekday - d.weekday + 7) % 7;
    if (delta == 0) delta = 7;
    return startOfDay(addDays(d, delta));
  }

  /// The weekend day used by the "this weekend" snooze: the coming [weekendDay]
  /// (today counts if it is that day).
  static DateTime thisWeekend(DateTime d, int weekendDay) {
    final delta = (weekendDay - d.weekday + 7) % 7;
    return startOfDay(addDays(d, delta));
  }

  /// Same day-of-month one calendar month later in [calendar], clamped to the
  /// length of the target month.
  static DateTime addMonths(DateTime d, int months, CalendarSystem calendar) {
    if (calendar == CalendarSystem.gregorian) {
      final total = d.year * 12 + (d.month - 1) + months;
      final y = total ~/ 12;
      final m = total % 12 + 1;
      final last = DateTime(y, m + 1, 0).day;
      return DateTime(y, m, d.day > last ? last : d.day, d.hour, d.minute);
    }
    final j = Jalali.fromDateTime(d);
    final total = j.year * 12 + (j.month - 1) + months;
    final y = total ~/ 12;
    final m = total % 12 + 1;
    final last = Jalali(y, m, 1).monthLength;
    final nj = Jalali(y, m, j.day > last ? last : j.day);
    final g = nj.toDateTime();
    return DateTime(g.year, g.month, g.day, d.hour, d.minute);
  }

  static DateTime withTime(DateTime day, int hour, int minute) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  // ---------------------------------------------------------------- Jalali

  static const jalaliMonths = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  static const gregorianMonthsFa = [
    'ژانویه', 'فوریه', 'مارس', 'آوریل', 'مه', 'ژوئن',
    'ژوئیه', 'اوت', 'سپتامبر', 'اکتبر', 'نوامبر', 'دسامبر',
  ];

  static const gregorianMonthsEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Weekday names indexed by [DateTime.weekday] - 1 (Mon..Sun).
  static const weekdaysFa = [
    'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه', 'یکشنبه',
  ];
  static const weekdaysEn = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
    'Sunday',
  ];

  static String monthName(int month, CalendarSystem cal, bool fa) {
    if (cal == CalendarSystem.jalali) return jalaliMonths[month - 1];
    return fa ? gregorianMonthsFa[month - 1] : gregorianMonthsEn[month - 1];
  }

  /// "۱۲ مهر ۱۴۰۵" / "12 Oct 2026". Year omitted when it equals [now]'s year
  /// in the chosen calendar and [omitCurrentYear] is true.
  static String formatDate(
    DateTime d,
    CalendarSystem cal, {
    required bool fa,
    DateTime? now,
    bool omitCurrentYear = false,
  }) {
    int y, m, day;
    int? cy;
    if (cal == CalendarSystem.jalali) {
      final j = Jalali.fromDateTime(d);
      y = j.year;
      m = j.month;
      day = j.day;
      if (now != null) cy = Jalali.fromDateTime(now).year;
    } else {
      y = d.year;
      m = d.month;
      day = d.day;
      cy = now?.year;
    }
    final showYear = !(omitCurrentYear && cy == y);
    final name = monthName(m, cal, fa);
    final s = showYear ? '$day $name $y' : '$day $name';
    return fa ? toFaDigits(s) : s;
  }

  static String formatTime(int hour, int minute, {required bool fa}) {
    final s =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    return fa ? toFaDigits(s) : s;
  }

  static String weekdayName(DateTime d, bool fa) =>
      (fa ? weekdaysFa : weekdaysEn)[d.weekday - 1];

  static ({int year, int month, int day}) parts(DateTime d, CalendarSystem cal) {
    if (cal == CalendarSystem.jalali) {
      final j = Jalali.fromDateTime(d);
      return (year: j.year, month: j.month, day: j.day);
    }
    return (year: d.year, month: d.month, day: d.day);
  }

  static int monthLength(int year, int month, CalendarSystem cal) {
    if (cal == CalendarSystem.jalali) return Jalali(year, month, 1).monthLength;
    return DateTime(year, month + 1, 0).day;
  }

  static DateTime fromParts(int year, int month, int day, CalendarSystem cal) {
    if (cal == CalendarSystem.jalali) {
      final g = Jalali(year, month, day).toDateTime();
      return DateTime(g.year, g.month, g.day);
    }
    return DateTime(year, month, day);
  }
}
