import 'package:flutter/material.dart';

import '../../data/controller.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../app_scope.dart';
import '../sheets/item_detail_sheet.dart';
import '../type_info.dart';
import '../widgets/common.dart';
import '../widgets/pro_gate.dart';

/// Everything saved quickly (or shared from another app) waits here until the
/// user says where it belongs. Nothing is moved without a tap.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final items = app.inboxItems;
    return Scaffold(
      appBar: AppBar(title: Text(l.inboxTitle)),
      body: items.isEmpty
          ? EmptyState(emoji: '📭', title: l.inboxEmptyTitle, body: l.inboxEmptyBody)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.inboxIntro, style: context.text.bodyMedium?.copyWith(color: context.scheme.onSurfaceVariant)),
                    if (!app.isPro)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: GestureDetector(
                          onTap: () => showProSheet(context, featureName: l.inboxProHint),
                          child: Text(l.inboxProHint,
                              style: context.text.labelMedium?.copyWith(color: context.scheme.primary)),
                        ),
                      ),
                  ]);
                }
                return InboxCard(key: ValueKey(items[i - 1].id), item: items[i - 1]);
              },
            ),
    );
  }
}

String suggestWhat(AppL10n l, ItemType t) => switch (t) {
      ItemType.read => l.suggestWhatRead,
      ItemType.watch => l.suggestWhatWatch,
      ItemType.wishlist => l.suggestWhatWish,
      ItemType.idea => l.suggestWhatIdea,
      ItemType.person => l.suggestWhatPerson,
      _ => '',
    };

class InboxCard extends StatelessWidget {
  const InboxCard({super.key, required this.item});
  final LaterItem item;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final s = context.scheme;
    final sug = app.suggestionFor(item);
    final host = TypeInfo.host(item.url);

    Future<void> act(TriageChoice c) async {
      final undo = await app.triage(item.id, c);
      if (!context.mounted || undo == null) return;
      showAppSnack(context, _message(l, c), actionLabel: l.undo, onAction: undo);
    }

    Widget chip(String label, IconData icon, TriageChoice c, {bool danger = false}) => ActionChip(
          avatar: Icon(icon, size: 16, color: danger ? s.error : null),
          label: Text(label),
          onPressed: () => act(c),
        );

    return AppCard(
      onTap: () => showItemDetailSheet(context, item.id),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.title, style: context.text.titleMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
        if (host != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(l.linkHost(host), style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
          ),
        if (sug != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: s.primaryContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const ProTag(),
              const SizedBox(width: 8),
              Expanded(child: Text(l.inboxSuggest(suggestWhat(l, sug.type)), style: context.text.bodySmall)),
              TextButton(
                onPressed: () async {
                  final undo = await app.moveToType(item.id, sug.type);
                  if (context.mounted && undo != null) {
                    showAppSnack(context, l.movedTo(TypeInfo.shelfTitle(l, sug.type)), actionLabel: l.undo, onAction: undo);
                  }
                },
                child: Text(l.inboxSuggestYes),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 4, children: [
          chip(l.triageToday, Icons.today_rounded, TriageChoice.today),
          chip(l.triageWeek, Icons.date_range_rounded, TriageChoice.thisWeek),
          chip(l.triageNoDate, Icons.all_inclusive_rounded, TriageChoice.noDate),
          chip(l.triageRead, Icons.menu_book_rounded, TriageChoice.read),
          chip(l.triageWatch, Icons.play_circle_outline_rounded, TriageChoice.watch),
          chip(l.triageWish, Icons.shopping_bag_outlined, TriageChoice.wishlist),
          chip(l.triageIdea, Icons.lightbulb_outline_rounded, TriageChoice.idea),
          chip(l.triageDone, Icons.check_rounded, TriageChoice.done),
          chip(l.triageDelete, Icons.delete_outline_rounded, TriageChoice.delete, danger: true),
        ]),
      ]),
    );
  }

  static String _message(AppL10n l, TriageChoice c) => switch (c) {
        TriageChoice.done => l.toastDone,
        TriageChoice.delete => l.toastDeleted,
        _ => l.movedTo(_label(l, c)),
      };

  static String _label(AppL10n l, TriageChoice c) => switch (c) {
        TriageChoice.today => l.triageToday,
        TriageChoice.thisWeek => l.triageWeek,
        TriageChoice.noDate => l.triageNoDate,
        TriageChoice.read => l.shelfReadTitle,
        TriageChoice.watch => l.shelfWatchTitle,
        TriageChoice.wishlist => l.shelfWishTitle,
        TriageChoice.idea => l.shelfIdeaTitle,
        TriageChoice.done => l.triageDone,
        TriageChoice.delete => l.toastDeleted,
      };
}
