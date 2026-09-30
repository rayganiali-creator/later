import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/controller.dart';
import '../../domain/models.dart';
import '../app_scope.dart';
import '../type_info.dart';
import '../widgets/common.dart';
import 'seal_sheets.dart';

/// Shown after something is shared into the app: "where should I keep it?".
/// The item is already saved in the inbox, so dismissing loses nothing.
Future<void> showShareDestinationSheet(BuildContext context, LaterItem item) {
  final l = context.l10n;
  final app = context.appRead;
  final sug = app.suggestionFor(item);

  Future<void> moveTo(BuildContext ctx, ItemType t) async {
    Navigator.pop(ctx);
    final undo = await app.moveToType(item.id, t);
    if (context.mounted && undo != null) {
      showAppSnack(context, l.movedTo(TypeInfo.shelfTitle(l, t)), actionLabel: l.undo, onAction: undo);
    }
  }

  final shelves = <(ItemType, String)>[
    (ItemType.read, l.triageRead),
    (ItemType.watch, l.triageWatch),
    (ItemType.wishlist, l.triageWish),
    (ItemType.idea, l.triageIdea),
  ];

  return showAppSheet<void>(
    context,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
            child: Text(l.shareWhere, style: ctx.text.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: ctx.text.bodyMedium?.copyWith(color: ctx.scheme.onSurfaceVariant)),
          ),
          for (final (t, label) in shelves)
            ListTile(
              leading: Icon(TypeInfo.icon(t), color: ctx.scheme.primary),
              title: Text(label),
              trailing: sug?.type == t ? Pill(l.shareSuggested, color: ctx.scheme.primary, background: ctx.scheme.primaryContainer) : null,
              onTap: () => moveTo(ctx, t),
            ),
          ListTile(
            leading: Icon(Icons.today_rounded, color: ctx.scheme.primary),
            title: Text(l.triageToday),
            onTap: () async {
              Navigator.pop(ctx);
              await app.triage(item.id, TriageChoice.today);
            },
          ),
          ListTile(
            leading: Icon(Icons.hourglass_top_rounded, color: ctx.scheme.primary),
            title: Text(l.sealThisItem),
            onTap: () {
              Navigator.pop(ctx);
              showSealItemSheet(context, item);
            },
          ),
          ListTile(
            leading: Icon(Icons.move_to_inbox_rounded, color: ctx.scheme.onSurfaceVariant),
            title: Text(l.shareInbox),
            subtitle: Text(l.shareSavedInbox),
            onTap: () => Navigator.pop(ctx),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    ),
  );
}
