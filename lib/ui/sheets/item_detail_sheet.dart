import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/pro.dart';
import '../../domain/search_filter_sort.dart';
import '../app_scope.dart';
import '../item_actions.dart';
import '../screens/reveal_screen.dart';
import '../type_info.dart';
import '../widgets/common.dart';
import '../widgets/pro_gate.dart';
import 'add_edit_sheet.dart';
import 'seal_sheets.dart';
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
    final sealedType = item.type == ItemType.capsule || item.type == ItemType.future;

    Widget row(IconData icon, String text, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 19, color: color ?? s.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: context.text.bodyMedium?.copyWith(color: color))),
          ]),
        );

    Widget stageChips() => Wrap(spacing: 8, runSpacing: 8, children: [
          for (final st in ItemStages.of(item.type))
            ChoiceChip(
              label: Text(TypeInfo.stageLabel(l, item.type, st)),
              selected: item.stage == st,
              onSelected: (_) => guarded(hostContext, () => app.setStage(item.id, st)),
            ),
        ]);

    final person = item.personId == null ? null : app.personById(item.personId!);

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
              child: (item.type == ItemType.task || item.type == ItemType.person)
                  ? Text(app.categoryEmoji(item.categoryId), style: const TextStyle(fontSize: 24))
                  : Icon(TypeInfo.icon(item.type), color: s.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.type == ItemType.task ? app.categoryName(item.categoryId) : TypeInfo.shelfTitle(l, item.type),
                style: context.text.labelLarge?.copyWith(color: s.primary),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l.edit,
              onSelected: (v) async {
                Navigator.pop(context);
                if (!hostContext.mounted) return;
                switch (v) {
                  case 'edit':
                    await showAddEditSheet(hostContext, initial: item);
                  case 'move':
                    await showMoveSheet(hostContext, item);
                  case 'seal':
                    await showSealItemSheet(hostContext, item);
                  case 'delete':
                    await ItemActions.delete(hostContext, item);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l.edit)),
                if (!sealedType) PopupMenuItem(value: 'move', child: Text(l.moveToShelf)),
                if (item.isActive && !sealedType) PopupMenuItem(value: 'seal', child: Text(l.sealThisItem)),
                PopupMenuItem(value: 'delete', child: Text(l.delete, style: TextStyle(color: s.error))),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          SelectableText(item.title, style: context.text.headlineSmall),
          if (item.description.isNotEmpty && !item.isLockedAt(now)) ...[
            const SizedBox(height: 8),
            SelectableText(item.description, style: context.text.bodyLarge?.copyWith(color: s.onSurfaceVariant)),
          ],
          const SizedBox(height: 12),
          if (item.type != ItemType.task && item.type != ItemType.person && !sealedType) ...[
            Text(l.itemStage, style: context.text.labelLarge?.copyWith(color: s.onSurfaceVariant)),
            const SizedBox(height: 8),
            stageChips(),
            const SizedBox(height: 10),
          ],
          if (item.type == ItemType.wishlist) ..._wishlist(context, item),
          if (item.type == ItemType.idea) ..._idea(context, item),
          if (item.type == ItemType.watch)
            row(Icons.smart_display_outlined, {
              'movie': l.kindMovie,
              'series': l.kindSeries,
              'other': l.kindOther,
            }[item.watchKind] ?? l.kindVideo),
          if (item.unlockAt != null)
            row(item.isLockedAt(now) ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                item.isLockedAt(now) ? l.lockedUntil(fmt.date(item.unlockAt!, omitCurrentYear: false)) : l.stageOpened),
          if (person != null)
            row(Icons.person_outline_rounded, person.name),
          if (item.dueAt != null)
            row(Icons.event_rounded, '${fmt.due(item)}${overdue ? ' · ${l.overdue}' : ''}',
                color: overdue ? c.danger : null)
          else if (item.type == ItemType.task)
            row(Icons.event_busy_rounded, l.noDate),
          if (item.reminderEnabled && item.dueAt != null)
            row(Icons.notifications_active_rounded,
                '${l.reminder}${item.repeat == RepeatRule.none ? '' : ' · ${fmt.repeat(item.repeat)}'}'),
          if (item.estimatedMinutes != null)
            row(Icons.timer_outlined,
                item.type == ItemType.read || item.type == ItemType.watch
                    ? l.readTimeEstimate(fmt.num(item.estimatedMinutes!))
                    : fmt.minutes(item.estimatedMinutes!)),
          if (item.type == ItemType.task || item.type == ItemType.person) row(Icons.flag_outlined, fmt.priority(item.priority)),
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
              label: Text(item.url!, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr),
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
          if (sealedType && item.isActive && !item.isLockedAt(now))
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(hostContext).push(MaterialPageRoute<void>(builder: (_) => RevealScreen(itemId: item.id)));
                },
                icon: const Icon(Icons.lock_open_rounded),
                label: Text(l.openIt),
              ),
            )
          else if (item.isActive && !sealedType && item.type != ItemType.idea) ...[
            Row(children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ItemActions.complete(hostContext, item);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: Text(TypeInfo.doneLabel(l, item.type)),
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
          ] else if (!item.isActive)
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

  List<Widget> _wishlist(BuildContext context, LaterItem item) {
    final l = context.l10n;
    final fmt = context.fmt;
    final app = context.app;
    final s = context.scheme;
    final pro = app.access.has(ProFeature.advancedShelves);
    final cur = item.currency.isEmpty ? l.currencyDefault : item.currency;
    final target = item.targetPrice;
    final reached = pro && target != null && item.price != null && item.price! <= target;
    return [
      Row(children: [
        Icon(Icons.sell_outlined, size: 19, color: s.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.price == null ? '—' : '${l.priceNow}: ${fmt.money(item.price!)} $cur',
            style: context.text.titleSmall,
          ),
        ),
        TextButton(
          onPressed: () => showPriceDialog(hostContext, item),
          child: Text(l.priceSetNew),
        ),
      ]),
      if (pro && target != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            reached ? l.priceTargetReached : '${l.priceTarget}: ${fmt.money(target)} $cur',
            style: context.text.bodySmall?.copyWith(color: reached ? context.appColors.success : s.onSurfaceVariant),
          ),
        ),
      if (pro && item.priceHistory.length > 1) ...[
        const SizedBox(height: 6),
        Text(l.priceHistoryTitle, style: context.text.labelLarge?.copyWith(color: s.onSurfaceVariant)),
        for (final e in item.priceHistory.reversed.take(6))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Expanded(child: Text(fmt.date(e.$1, omitCurrentYear: false), style: context.text.bodySmall)),
              Text('${fmt.money(e.$2)} $cur', style: context.text.bodySmall),
            ]),
          ),
      ],
      if (!pro)
        GestureDetector(
          onTap: () => showProSheet(hostContext, featureName: l.wishProHint),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const ProTag(),
              const SizedBox(width: 8),
              Expanded(child: Text(l.wishProHint, style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant))),
            ]),
          ),
        ),
    ];
  }

  List<Widget> _idea(BuildContext context, LaterItem item) {
    final l = context.l10n;
    final fmt = context.fmt;
    final app = context.app;
    final s = context.scheme;
    final pro = app.access.has(ProFeature.ideaTools);
    final linked = app.linkedItems(item);
    return [
      Text(
        item.lastReviewedAt == null ? l.ideaNeverReviewed : l.ideaLastReviewed(fmt.ago(item.lastReviewedAt!)),
        style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant),
      ),
      const SizedBox(height: 8),
      if (pro) ...[
        Row(children: [
          Text(l.ideaScore, style: context.text.labelLarge),
          Expanded(
            child: Slider(
              value: (item.score ?? 0).toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: fmt.num(item.score ?? 0),
              onChanged: (v) => guarded(hostContext, () => app.update(item.withExtra('score', v.round()))),
            ),
          ),
          SizedBox(width: 28, child: Text(fmt.num(item.score ?? 0))),
        ]),
        if (linked.isNotEmpty) ...[
          Text(l.ideaLinks, style: context.text.labelLarge?.copyWith(color: s.onSurfaceVariant)),
          Wrap(spacing: 6, children: [
            for (final o in linked)
              InputChip(
                label: Text(o.title, overflow: TextOverflow.ellipsis),
                onDeleted: () => app.unlinkItems(item.id, o.id),
                onPressed: () {
                  Navigator.pop(context);
                  showItemDetailSheet(hostContext, o.id);
                },
              ),
          ]),
        ],
        Row(children: [
          TextButton.icon(
            onPressed: () async {
              final other = await _pickIdea(hostContext, item);
              if (other != null) await app.linkItems(item.id, other);
            },
            icon: const Icon(Icons.link_rounded, size: 18),
            label: Text(l.ideaAddLink),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final undo = await app.convertIdeaToTask(item.id);
              if (undo != null && hostContext.mounted) showAppSnack(hostContext, l.ideaConverted, actionLabel: l.undo, onAction: undo);
            },
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: Text(l.ideaToTask),
          ),
        ]),
      ] else
        GestureDetector(
          onTap: () => showProSheet(hostContext, featureName: l.ideaProHint),
          child: Row(children: [
            const ProTag(),
            const SizedBox(width: 8),
            Expanded(child: Text(l.ideaProHint, style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant))),
          ]),
        ),
    ];
  }

  Future<String?> _pickIdea(BuildContext context, LaterItem item) {
    final app = context.appRead;
    final ideas = [for (final i in app.shelf(ItemType.idea)) if (i.id != item.id && !item.links.contains(i.id)) i];
    return showAppSheet<String>(
      context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final i in ideas)
              ListTile(title: Text(i.title, maxLines: 2, overflow: TextOverflow.ellipsis), onTap: () => Navigator.pop(ctx, i.id)),
          ],
        ),
      ),
    );
  }
}

/// Dialog to record a new price.
Future<void> showPriceDialog(BuildContext context, LaterItem item) async {
  final app = context.appRead;
  final r = await showDialog<double?>(
    context: context,
    builder: (_) => _PriceDialog(initial: item.price, currency: item.currency),
  );
  if (r != null && context.mounted) await guarded(context, () => app.setPrice(item.id, r));
}

class _PriceDialog extends StatefulWidget {
  const _PriceDialog({this.initial, required this.currency});
  final double? initial;
  final String currency;

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final TextEditingController _c = TextEditingController(text: widget.initial == null ? '' : widget.initial!.round().toString());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.priceSetNew),
      content: TextField(
        controller: _c,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(hintText: l.priceHint, suffixText: widget.currency.isEmpty ? l.currencyDefault : widget.currency),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, parsePrice(_c.text)), child: Text(l.ok)),
      ],
    );
  }
}

/// Accepts Persian/Arabic digits and thousands separators.
double? parsePrice(String raw) {
  final t = raw
      .replaceAll(RegExp(r'[٬,،\s]'), '')
      .split('')
      .map((c) {
        const fa = '۰۱۲۳۴۵۶۷۸۹';
        const ar = '٠١٢٣٤٥٦٧٨٩';
        final i = fa.indexOf(c);
        final j = ar.indexOf(c);
        return i >= 0 ? '$i' : (j >= 0 ? '$j' : c);
      })
      .join();
  final v = double.tryParse(t);
  if (v == null || v < 0 || v > 1e12) return null;
  return v;
}
