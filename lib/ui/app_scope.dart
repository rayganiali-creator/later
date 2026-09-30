import 'package:flutter/material.dart';

import '../core/util/dates.dart';
import '../core/util/text.dart';
import '../data/controller.dart';
import '../domain/models.dart';
import '../domain/search_filter_sort.dart';
import '../l10n/app_localizations.dart';

/// Provides the [LaterController] to the widget tree and rebuilds dependents
/// whenever it notifies.
class AppScope extends InheritedNotifier<LaterController> {
  const AppScope({super.key, required LaterController controller, required super.child})
      : super(notifier: controller);

  /// Subscribes the caller to controller changes.
  static LaterController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads the controller without subscribing (use in callbacks).
  static LaterController read(BuildContext context) =>
      (context.getInheritedWidgetOfExactType<AppScope>()!).notifier!;
}

extension AppContext on BuildContext {
  LaterController get app => AppScope.of(this);
  LaterController get appRead => AppScope.read(this);
  AppL10n get l10n => AppL10n.of(this);
  Fmt get fmt => Fmt(AppScope.of(this), AppL10n.of(this));
}

/// Formatting helpers that depend on user settings (calendar, language).
class Fmt {
  const Fmt(this.app, this.l);
  final LaterController app;
  final AppL10n l;

  bool get fa => app.settings.languageCode == 'fa';

  String num(Object n) => fa ? toFaDigits(n) : '$n';

  String date(DateTime d, {bool omitCurrentYear = true}) => Dates.formatDate(
        d,
        app.settings.calendar,
        fa: fa,
        now: app.now(),
        omitCurrentYear: omitCurrentYear,
      );

  String time(DateTime d) => Dates.formatTime(d.hour, d.minute, fa: fa);
  String minutesOfDay(int m) => Dates.formatTime(m ~/ 60, m % 60, fa: fa);

  String weekday(DateTime d) => Dates.weekdayName(d, fa);

  String minutes(int n) {
    if (n == 60) return l.hourOne;
    if (n > 60 && n % 60 == 0) return fa ? '${num(n ~/ 60)} ساعت' : '${n ~/ 60} h';
    return l.minutesN(num(n));
  }

  String minutesShort(int n) => l.minutesShort(num(n));

  /// Human due label: "امروز", "فردا ۹:۰۰", "۱۲ مهر".
  String due(LaterItem i) {
    final d = i.dueAt;
    if (d == null) return l.noDate;
    final eff = effectiveDue(i, app.now()) ?? d;
    final today = Dates.startOfDay(app.now());
    final diff = Dates.daysBetween(today, eff);
    String base;
    if (diff == 0) {
      base = l.dueToday;
    } else if (diff == 1) {
      base = l.dueTomorrow;
    } else {
      base = date(eff);
    }
    if (i.hasTime) base = '$base · ${time(eff)}';
    return base;
  }

  String repeat(RepeatRule r) => switch (r) {
        RepeatRule.none => l.repeatNone,
        RepeatRule.daily => l.repeatDaily,
        RepeatRule.weekly => l.repeatWeekly,
        RepeatRule.monthly => l.repeatMonthly,
        RepeatRule.yearly => l.repeatYearly,
      };

  String priority(ItemPriority p) => switch (p) {
        ItemPriority.high => l.priorityHigh,
        ItemPriority.normal => l.priorityNormal,
        ItemPriority.low => l.priorityLow,
      };
}
