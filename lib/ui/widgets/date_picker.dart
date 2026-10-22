import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/dates.dart';
import '../app_scope.dart';
import 'common.dart';

const _faInitials = {1: 'د', 2: 'س', 3: 'چ', 4: 'پ', 5: 'ج', 6: 'ش', 7: 'ی'};
const _enInitials = {1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'};

/// Result wrapper so "cleared" can be told apart from "dismissed".
class DatePickResult {
  const DatePickResult(this.date);
  final DateTime? date;
}

/// Calendar bottom sheet supporting Jalali and Gregorian calendars.
Future<DatePickResult?> showAppDatePicker(
  BuildContext context, {
  DateTime? initial,
  bool allowClear = false,
}) {
  return showAppSheet<DatePickResult>(
    context,
    builder: (_) => _DatePickerSheet(initial: initial, allowClear: allowClear),
  );
}

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({this.initial, required this.allowClear});
  final DateTime? initial;
  final bool allowClear;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late int _year;
  late int _month;
  DateTime? _selected;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final app = context.appRead;
    final base = widget.initial ?? app.now();
    final p = Dates.parts(base, app.settings.calendar);
    _year = p.year;
    _month = p.month;
    _selected = widget.initial == null ? null : Dates.startOfDay(widget.initial!);
  }

  void _shift(int delta) {
    setState(() {
      var m = _month + delta;
      var y = _year;
      while (m > 12) {
        m -= 12;
        y++;
      }
      while (m < 1) {
        m += 12;
        y--;
      }
      _year = y;
      _month = m;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.appRead;
    final l = context.l10n;
    final fmt = context.fmt;
    final cal = app.settings.calendar;
    final fa = fmt.fa;
    final weekStart = app.settings.weekStart;
    final today = Dates.startOfDay(app.now());
    final len = Dates.monthLength(_year, _month, cal);
    final first = Dates.fromParts(_year, _month, 1, cal);
    final offset = (first.weekday - weekStart + 7) % 7;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final monthTitle = '${Dates.monthName(_month, cal, fa)} ${fmt.num(_year)}';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              IconButton(
                tooltip: l.prevMonth,
                onPressed: () => _shift(-1),
                icon: Icon(rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(monthTitle,
                    textAlign: TextAlign.center, style: context.text.titleMedium),
              ),
              IconButton(
                tooltip: l.nextMonth,
                onPressed: () => _shift(1),
                icon: Icon(rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      (fa ? _faInitials : _enInitials)[(weekStart - 1 + i) % 7 + 1]!,
                      style: context.text.labelMedium?.copyWith(color: context.scheme.onSurfaceVariant),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 6),
            for (var row = 0; row < ((offset + len + 6) ~/ 7); row++)
              Row(children: [
                for (var col = 0; col < 7; col++)
                  Expanded(child: _cell(context, row * 7 + col - offset + 1, len, cal, today, fmt)),
              ]),
            const SizedBox(height: 12),
            Row(children: [
              if (widget.allowClear)
                TextButton(
                  onPressed: () => Navigator.pop(context, const DatePickResult(null)),
                  child: Text(l.clear),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context, DatePickResult(today)),
                child: Text(l.today),
              ),
              const Spacer(),
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, int day, int len, CalendarSystem cal, DateTime today, Fmt fmt) {
    if (day < 1 || day > len) return const SizedBox(height: 46);
    final d = Dates.fromParts(_year, _month, day, cal);
    final isSel = _selected != null && Dates.isSameDay(d, _selected!);
    final isToday = Dates.isSameDay(d, today);
    final s = context.scheme;
    return Semantics(
      button: true,
      selected: isSel,
      label: '${fmt.num(day)} ${Dates.monthName(_month, cal, fmt.fa)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: () => Navigator.pop(context, DatePickResult(d)),
        child: Container(
          height: 46,
          margin: const EdgeInsets.all(2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? s.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: isToday && !isSel ? Border.all(color: s.primary, width: 1.4) : null,
          ),
          child: ExcludeSemantics(
            child: Text(
              fmt.num(day),
              style: context.text.bodyMedium?.copyWith(
                color: isSel ? s.onPrimary : s.onSurface,
                fontWeight: isSel || isToday ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
