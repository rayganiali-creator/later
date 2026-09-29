import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/search_filter_sort.dart';
import '../app_scope.dart';
import '../item_actions.dart';
import '../widgets/common.dart';
import 'add_edit_sheet.dart';
import 'snooze_sheet.dart';

Future<void> showItemDetailSheet(BuildContext context, String itemId) {
  return showAppSheet<void>(context, builder: (ctx) => ItemDetailSheet(itemId: itemId, hostContext: context));
}

class ItemDetailSheet extends StatelessWidget {
  const ItemDetailSheet({super.key, required this.itemId, required this.hostContext});
  final String itemId;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final item = app.itemById(itemId);
    final s = context.scheme;
    final c = context.appColors;
    if (item == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: EmptyState(emoji: '🫥', title: l.itemNotFound),
      );
    }
    final now = app.now();
    final overdue = item.isActive && isOverdue(item, now);

    Widget row(IconData icon, String text, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 19, color: color ?? s.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: context.text.bodyMedium?.copyWith(color: color))),
          ]),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: c.lavender, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: Text(app.categoryEmoji(item.categoryId), style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(app.categoryName(item.categoryId), style: context.text.labelLarge?.copyWith(color: s.primary))),
            PopupMenuButton<String>(
              tooltip: l.edit,
              onSelected: (v) async {
                Navigator.pop(context);
                if (!hostContext.mounted) return;
                if (v == 'edit') await showAddEditSheet(hostContext, initial: item);
                if (v == 'delete' && hostContext.mounted) await ItemActions.delete(hostContext, item);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l.edit)),
                PopupMenuItem(value: 'delete', child: Text(l.delete, style: TextStyle(color: s.error))),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          SelectableText(item.title, style: context.text.headlineSmall),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(item.description, style: context.text.bodyLarge?.copyWith(color: s.onSurfaceVariant)),
          ],
          const SizedBox(height: 12),
          if (item.dueAt != null)
            row(Icons.event_rounded, '${fmt.due(item)}${overdue ? ' · ${l.overdue}' : ''}',
                color: overdue ? c.danger : null)
          else
            row(Icons.event_busy_rounded, l.noDate),
          if (item.reminderEnabled && item.dueAt != null)
            row(Icons.notifications_active_rounded,
                '${l.reminder}${item.repeat == RepeatRule.none ? '' : ' · ${fmt.repeat(item.repeat)}'}'),
          if (item.estimatedMinutes != null) row(Icons.timer_outlined, fmt.minutes(item.estimatedMinutes!)),
          row(Icons.flag_outlined, fmt.priority(item.priority)),
          if (item.snoozeCount > 0) row(Icons.schedule_rounded, l.snoozedTimes(fmt.num(item.snoozeCount))),
          row(Icons.history_rounded, l.createdOn(fmt.date(item.createdAt, omitCurrentYear: false))),
          if (item.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Wrap(spacing: 6, runSpacing: 6, children: [for (final t in item.tags) Pill('#$t')]),
            ),
          if (item.url != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ItemActions.openLink(hostContext, item.url),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(item.url!, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: s.surfaceContainer, borderRadius: BorderRadius.circular(16)),
              child: SelectableText(item.note, style: context.text.bodyMedium),
            ),
          ],
          const SizedBox(height: 20),
          if (item.isActive) ...[
            Row(children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ItemActions.complete(hostContext, item);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l.itemDone),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    showSnoozeSheet(hostContext, item);
                  },
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(l.itemSnooze),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ItemActions.drop(hostContext, item);
                },
                child: Text(l.itemDrop),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ItemActions.reopen(hostContext, item);
                },
                icon: const Icon(Icons.undo_rounded),
                label: Text(l.historyRestore),
              ),
            ),
        ]),
      ),
    );
  }
}
