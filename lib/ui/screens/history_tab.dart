import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/dates.dart';
import '../../domain/models.dart';
import '../../domain/pro.dart';
import '../app_scope.dart';
import '../widgets/common.dart';
import '../widgets/item_tile.dart';
import '../widgets/pro_gate.dart';
import 'stats_screen.dart';

enum _Period { today, week, month, all }

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  _Period _period = _Period.week;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final now = app.now();
    final pro = app.isPro;

    DateTime? since;
    switch (_period) {
      case _Period.today:
        since = Dates.startOfDay(now);
      case _Period.week:
        since = Dates.startOfWeek(now, app.settings.weekStart);
      case _Period.month:
        since = DateTime(now.year, now.month, 1);
      case _Period.all:
        since = null;
    }
    // Free tier only sees the last 7 days of history (Pro: everything).
    final freeLimit = Dates.startOfDay(now).subtract(const Duration(days: ProLimits.freeHistoryDays - 1));
    final items = app.historyItems.where((i) {
      final at = i.completedAt ?? i.droppedAt ?? i.updatedAt;
      if (since != null && at.isBefore(since)) return false;
      if (!pro && at.isBefore(freeLimit)) return false;
      return true;
    }).toList();

    ButtonSegment<_Period> seg(_Period p, String label, {bool locked = false}) => ButtonSegment<_Period>(
          value: p,
          label: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            if (locked) ...[const SizedBox(width: 4), const Icon(Icons.lock_outline_rounded, size: 13)],
          ]),
        );

    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(children: [
            Expanded(child: Text(l.historyTitle, style: context.text.headlineSmall)),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StatsScreen())),
              icon: const Icon(Icons.insights_rounded, size: 20),
              label: Text(l.statsTitle),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SegmentedButton<_Period>(
            showSelectedIcon: false,
            segments: [
              seg(_Period.today, l.periodToday),
              seg(_Period.week, l.periodWeek),
              seg(_Period.month, l.periodMonth, locked: !pro),
              seg(_Period.all, l.periodAll, locked: !pro),
            ],
            selected: {_period},
            onSelectionChanged: (v) {
              final p = v.first;
              if (!pro && (p == _Period.month || p == _Period.all)) {
                showProSheet(context, featureName: l.historyProNote);
                return;
              }
              setState(() => _period = p);
            },
          ),
        ),
        if (!app.settings.keepHistory)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Text(l.historyDisabled,
                style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant)),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? EmptyState(emoji: '🗂️', title: l.historyEmpty, body: l.historyEmptyBody)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  itemCount: items.length + (pro ? 0 : 1),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    if (i == items.length) {
                      return TextButton(
                        onPressed: () => showProSheet(context, featureName: l.historyProNote),
                        child: Text(l.historyProNote),
                      );
                    }
                    final it = items[i];
                    final at = it.completedAt ?? it.droppedAt ?? it.updatedAt;
                    final done = it.status == ItemStatus.done;
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ItemTile(item: it, dismissible: false),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                        child: Text(
                          done ? l.historyDoneAt(fmt.date(at)) : l.historyDroppedAt(fmt.date(at)),
                          style: context.text.labelSmall?.copyWith(
                            color: done ? context.appColors.success : context.scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ]);
                  },
                ),
        ),
      ]),
    );
  }
}
