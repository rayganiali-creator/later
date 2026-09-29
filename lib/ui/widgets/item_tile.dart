import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/search_filter_sort.dart';
import '../app_scope.dart';
import '../item_actions.dart';
import '../sheets/item_detail_sheet.dart';
import '../sheets/snooze_sheet.dart';
import 'common.dart';

/// One row of the list. Swipe → done, swipe the other way → snooze.
class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item, this.dismissible = true, this.onTap});
  final LaterItem item;
  final bool dismissible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    final c = context.appColors;
    final now = app.now();
    final overdue = item.isActive && isOverdue(item, now);
    final waiting = daysWaiting(item, now);
    final stale = item.isActive && isStale(item, now, app.settings.staleDays);

    final meta = <Widget>[
      if (item.dueAt != null)
        Pill(
          fmt.due(item),
          icon: overdue ? Icons.error_outline_rounded : Icons.event_rounded,
          color: overdue ? c.danger : s.onSurfaceVariant,
          background: overdue ? c.danger.withValues(alpha: 0.12) : null,
        ),
      if (item.reminderEnabled && item.dueAt != null)
        Pill('', icon: item.repeat == RepeatRule.none ? Icons.notifications_active_rounded : Icons.repeat_rounded),
      if (item.estimatedMinutes != null)
        Pill(fmt.minutesShort(item.estimatedMinutes!), icon: Icons.timer_outlined),
      if (item.priority == ItemPriority.high)
        Pill(l.priorityHigh, icon: Icons.flag_rounded, color: c.warning, background: c.warning.withValues(alpha: 0.13)),
      if (stale)
        Pill(l.waitingDays(fmt.num(waiting)), icon: Icons.hourglass_bottom_rounded, color: c.warning),
      for (final t in item.tags.take(2)) Pill('#$t'),
    ];

    final semantic = [
      item.title,
      app.categoryName(item.categoryId),
      if (item.dueAt != null) fmt.due(item),
      if (overdue) l.overdue,
    ].join('، ');

    final card = AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      semanticLabel: semantic,
      onTap: onTap ?? () => showItemDetailSheet(context, item.id),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: c.lavender, borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.center,
          child: Text(app.categoryEmoji(item.categoryId), style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall?.copyWith(
                  decoration: item.status == ItemStatus.active ? null : TextDecoration.lineThrough,
                  color: item.status == ItemStatus.active ? s.onSurface : s.onSurfaceVariant,
                )),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: meta),
            ],
          ]),
        ),
        if (item.isActive)
          IconButton(
            tooltip: l.itemDone,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              HapticFeedback.lightImpact();
              ItemActions.complete(context, item);
            },
            icon: Icon(Icons.radio_button_unchecked_rounded, color: s.primary),
          ),
      ]),
    );

    if (!dismissible || !item.isActive) return card;

    return Dismissible(
      key: ValueKey('tile_${item.id}'),
      background: _swipeBg(context, Icons.check_rounded, l.itemDone, c.success, AlignmentDirectional.centerStart),
      secondaryBackground: _swipeBg(context, Icons.schedule_rounded, l.itemSnooze, s.primary, AlignmentDirectional.centerEnd),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await ItemActions.complete(context, item);
        } else {
          await showSnoozeSheet(context, item);
        }
        return false; // the list rebuilds from the controller
      },
      child: card,
    );
  }

  Widget _swipeBg(BuildContext context, IconData icon, String label, Color color, AlignmentGeometry a) => Container(
        alignment: a,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(22)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color),
          Text(label, style: context.text.labelSmall?.copyWith(color: color)),
        ]),
      );
}
