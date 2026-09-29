import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/search_filter_sort.dart';
import '../../domain/smart_pick.dart';
import '../app_scope.dart';
import '../nav_bus.dart';
import '../sheets/add_edit_sheet.dart';
import '../sheets/smart_pick_sheet.dart';
import '../widgets/common.dart';
import '../widgets/item_tile.dart';
import 'decide_screen.dart';
import 'stale_review_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    final counts = app.homeCounts();
    final nav = NavScope.read(context);
    final now = app.now();
    final todayItems = sortItems(
      app.activeItems.where((i) => isOverdue(i, now) || isDueToday(i, now)),
      SortMode.nearestDeadline,
      now: now,
    ).take(3).toList();

    if (counts.total == 0) {
      return SafeArea(
        child: Column(children: [
          _Header(),
          Expanded(
            child: EmptyState(
              emoji: '🌱',
              title: l.homeEmptyTitle,
              body: l.homeEmptyBody,
              action: FilledButton.icon(
                onPressed: () => showAddEditSheet(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(l.homeEmptyCta),
              ),
            ),
          ),
        ]),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        children: [
          _Header(),
          const SizedBox(height: 4),
          // Big headline number
          Semantics(
            header: true,
            child: Text(
              counts.total == 1 ? l.homeWaitingOne : l.homeWaiting(fmt.num(counts.total)),
              style: context.text.headlineMedium,
            ),
          ),
          const SizedBox(height: 16),
          _StatsRow(counts: counts),
          if (counts.stale > 0) ...[
            const SizedBox(height: 14),
            _StaleBanner(count: counts.stale),
          ],
          const SizedBox(height: 18),
          PressableScale(
            semanticLabel: l.pickCardTitle,
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DecideScreen())),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [s.primary, Color.lerp(s.primary, s.secondary, 0.7)!],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: s.primary.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.pickCardTitle,
                        style: context.text.titleLarge?.copyWith(color: s.onPrimary)),
                    const SizedBox(height: 4),
                    Text(l.pickCardSub,
                        style: context.text.bodyMedium?.copyWith(color: s.onPrimary.withValues(alpha: 0.85))),
                  ]),
                ),
                Icon(Icons.arrow_back_rounded, color: s.onPrimary.withValues(alpha: 0.9)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.timeCardTitle, style: context.text.titleSmall),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final m in smartPickMinuteOptions)
                  ActionChip(
                    label: Text(m == null ? l.anyTime : fmt.minutes(m)),
                    onPressed: () => showSmartPickSheet(context, initialMinutes: m, preselect: true),
                  ),
              ]),
            ]),
          ),
          if (todayItems.isNotEmpty) ...[
            SectionTitle(
              l.homeTodaySection,
              trailing: TextButton(
                onPressed: () => nav.showListWithFilter(const ItemFilter(FilterKind.today)),
                child: Text(l.homeSeeAll),
              ),
            ),
            for (final i in todayItems)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: ItemTile(item: i)),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.scheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [s.primary, s.secondary]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.history_toggle_off_rounded, color: s.onPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.appName, style: context.text.titleLarge),
            Text(l.tagline,
                style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        IconButton(
          tooltip: l.search,
          onPressed: () => NavScope.read(context).focusSearch(),
          icon: const Icon(Icons.search_rounded),
        ),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.counts});
  final dynamic counts;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final nav = NavScope.read(context);
    final c = context.appColors;
    Widget chip(String label, int n, ItemFilter f, {Color? color, IconData? icon}) {
      return Expanded(
        child: Semantics(
          button: true,
          label: '$label ${fmt.num(n)}',
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => nav.showListWithFilter(f),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: context.scheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.scheme.outlineVariant),
              ),
              child: ExcludeSemantics(
                child: Column(children: [
                  Text(fmt.num(n),
                      style: context.text.titleLarge?.copyWith(color: n > 0 ? color : context.scheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(color: context.scheme.onSurfaceVariant)),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      chip(l.statToday, counts.today as int, const ItemFilter(FilterKind.today), color: context.scheme.primary),
      const SizedBox(width: 8),
      chip(l.statWeek, counts.thisWeek as int, const ItemFilter(FilterKind.thisWeek), color: context.scheme.primary),
      const SizedBox(width: 8),
      chip(l.statNoDate, counts.noDate as int, const ItemFilter(FilterKind.noDate), color: context.scheme.onSurface),
      const SizedBox(width: 8),
      chip(l.statOverdue, counts.overdue as int, const ItemFilter(FilterKind.overdue), color: c.danger),
    ]);
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final c = context.appColors;
    return AppCard(
      color: c.warning.withValues(alpha: 0.10),
      borderColor: c.warning.withValues(alpha: 0.35),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const StaleReviewScreen())),
      semanticLabel: l.staleBannerTitle(fmt.num(count)),
      child: Row(children: [
        Icon(Icons.hourglass_bottom_rounded, color: c.warning),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.staleBannerTitle(fmt.num(count)), style: context.text.titleSmall),
            Text(l.staleBannerBody,
                style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant)),
          ]),
        ),
        Icon(Icons.chevron_left_rounded, color: context.scheme.onSurfaceVariant),
      ]),
    );
  }
}
