import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repository.dart';
import '../app_scope.dart';
import '../widgets/common.dart';
import '../widgets/pro_gate.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Future<StatsData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.appRead.stats();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final pro = app.isPro;

    return Scaffold(
      appBar: AppBar(title: Text(l.statsTitle)),
      body: FutureBuilder<StatsData>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(
              emoji: '⚠️',
              title: l.errorLoad,
              action: FilledButton(
                onPressed: () => setState(() => _future = app.stats()),
                child: Text(l.retry),
              ),
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final d = snap.data!;
          Widget tile(String label, String value, {bool locked = false, IconData? icon}) {
            final child = AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (icon != null) Icon(icon, size: 18, color: context.scheme.primary),
                  const Spacer(),
                  if (locked) const ProTag(),
                ]),
                const SizedBox(height: 8),
                Text(value, style: context.text.headlineSmall),
                const SizedBox(height: 2),
                Text(label, style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant)),
              ]),
            );
            if (!locked) return child;
            return GestureDetector(
              onTap: () => showProSheet(context, featureName: l.statsProLocked),
              child: Opacity(opacity: 0.55, child: AbsorbPointer(child: child)),
            );
          }

          final topCat = d.topCategoryId == null ? l.statsNoData : '${app.categoryEmoji(d.topCategoryId!)} ${app.categoryName(d.topCategoryId!)}';
          final tiles = [
            tile(l.statsActive, fmt.num(d.active), icon: Icons.inbox_rounded),
            tile(l.statsDone, fmt.num(d.completed), icon: Icons.check_circle_outline_rounded),
            tile(l.statsDropped, fmt.num(d.dropped), locked: !pro, icon: Icons.spa_outlined),
            tile(l.statsDeleted, fmt.num(d.deleted), locked: !pro, icon: Icons.delete_outline_rounded),
            tile(l.statsSnoozed, fmt.num(d.snoozed), locked: !pro, icon: Icons.schedule_rounded),
            tile(l.statsThisWeek, fmt.num(d.completedThisWeek), locked: !pro, icon: Icons.date_range_rounded),
            tile(l.statsAvgWait, d.avgDaysWaited == null ? l.statsNoData : l.statsDaysValue(fmt.num(d.avgDaysWaited!.round())),
                locked: !pro, icon: Icons.hourglass_bottom_rounded),
            tile(l.statsTopCategory, topCat, locked: !pro, icon: Icons.category_outlined),
          ];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: tiles,
              ),
              if (!pro)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: () => showProSheet(context, featureName: l.statsProLocked),
                    child: Text(l.statsProLocked),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
