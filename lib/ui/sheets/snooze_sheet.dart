import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/snooze.dart';
import '../app_scope.dart';
import '../item_actions.dart';
import '../widgets/common.dart';

/// "Snooze until…" bottom sheet. Applies the choice and shows an undo toast.
Future<void> showSnoozeSheet(BuildContext context, LaterItem item) {
  return showAppSheet<void>(context, builder: (ctx) => _SnoozeSheet(item: item, hostContext: context));
}

class _SnoozeSheet extends StatelessWidget {
  const _SnoozeSheet({required this.item, required this.hostContext});
  final LaterItem item;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final app = context.appRead;
    final fmt = context.fmt;
    final calc = app.snoozeCalculator;

    Widget option(IconData icon, String label, SnoozeOption? o, {String? hint, VoidCallback? onTap}) {
      return ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: context.appColors.lavender, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: context.scheme.primary),
        ),
        title: Text(label),
        subtitle: hint == null ? null : Text(hint),
        onTap: onTap ??
            () {
              Navigator.pop(context);
              if (hostContext.mounted) ItemActions.snooze(hostContext, item, o!);
            },
      );
    }

    String hint(SnoozeOption o) {
      final t = calc.compute(o, app.now());
      if (t.dueAt == null) return '';
      final d = fmt.date(t.dueAt!);
      return t.hasTime ? '$d · ${fmt.time(t.dueAt!)}' : '${fmt.weekday(t.dueAt!)} · $d';
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l.snoozeTitle, style: context.text.titleLarge),
            ),
          ),
          option(Icons.nights_stay_rounded, l.snoozeTonight, SnoozeOption.tonight, hint: hint(SnoozeOption.tonight)),
          option(Icons.wb_sunny_rounded, l.snoozeTomorrow, SnoozeOption.tomorrow, hint: hint(SnoozeOption.tomorrow)),
          option(Icons.weekend_rounded, l.snoozeWeekend, SnoozeOption.weekend, hint: hint(SnoozeOption.weekend)),
          option(Icons.next_week_rounded, l.snoozeNextWeek, SnoozeOption.nextWeek, hint: hint(SnoozeOption.nextWeek)),
          option(Icons.calendar_month_rounded, l.snoozeNextMonth, SnoozeOption.nextMonth, hint: hint(SnoozeOption.nextMonth)),
          option(Icons.edit_calendar_rounded, l.snoozeCustom, null, onTap: () async {
            Navigator.pop(context);
            if (hostContext.mounted) await ItemActions.snoozeCustom(hostContext, item);
          }),
          option(Icons.all_inclusive_rounded, l.snoozeNoDate, SnoozeOption.noDate),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}
