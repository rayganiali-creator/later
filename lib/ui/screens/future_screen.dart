import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../app_scope.dart';
import '../sheets/item_detail_sheet.dart';
import '../sheets/seal_sheets.dart';
import '../widgets/common.dart';
import '../widgets/pro_gate.dart';
import 'reveal_screen.dart';

/// Time capsules and messages to your future self: sealed, then returned on
/// the chosen day. Locked content is never shown before its date.
class FutureScreen extends StatelessWidget {
  const FutureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        final tabs = DefaultTabController.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(l.futureTitle),
            bottom: TabBar(tabs: [Tab(text: l.futureTabCapsules), Tab(text: l.futureTabMessages)]),
          ),
          floatingActionButton: ListenableBuilder(
            listenable: tabs,
            builder: (context, _) {
              final message = tabs.index == 1;
              final app = context.app;
              return FloatingActionButton.extended(
                onPressed: () {
                  if (!app.canSeal(messages: message)) {
                    showProSheet(context, featureName: l.sealProHint);
                    return;
                  }
                  showSealCreateSheet(context, message: message);
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(message ? l.messageNew : l.capsuleNew),
              );
            },
          ),
          body: const TabBarView(children: [_FutureList(messages: false), _FutureList(messages: true)]),
        );
      }),
    );
  }
}

class _FutureList extends StatelessWidget {
  const _FutureList({required this.messages});
  final bool messages;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final now = app.now();
    final all = app.timeline(messages: messages);
    if (all.isEmpty) {
      return EmptyState(
        emoji: messages ? '✉️' : '⏳',
        title: messages ? l.messageEmptyTitle : l.capsuleEmptyTitle,
        body: messages ? l.messageEmptyBody : l.capsuleEmptyBody,
      );
    }
    final locked = [for (final i in all) if (i.isLockedAt(now) && i.status == ItemStatus.active) i];
    final returned = [for (final i in all) if (!i.isLockedAt(now) && i.status == ItemStatus.active) i];
    final opened = [for (final i in all) if (i.status != ItemStatus.active) i].reversed.toList();

    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 110), children: [
      if (returned.isNotEmpty) ...[
        SectionTitle(messages ? l.messageReturnedTitle : l.returnedTitle),
        for (final i in returned) _Card(item: i, kind: _Kind.returned),
      ],
      if (locked.isNotEmpty) ...[
        SectionTitle(l.stageSealed),
        for (final i in locked) _Card(item: i, kind: _Kind.locked),
      ],
      if (opened.isNotEmpty) ...[
        SectionTitle(l.stageOpened),
        for (final i in opened) _Card(item: i, kind: _Kind.opened),
      ],
      if (!app.isPro)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: GestureDetector(
            onTap: () => showProSheet(context, featureName: l.sealProHint),
            child: Text(l.sealProHint, style: context.text.labelMedium?.copyWith(color: context.scheme.primary)),
          ),
        ),
    ]);
  }
}

enum _Kind { locked, returned, opened }

class _Card extends StatelessWidget {
  const _Card({required this.item, required this.kind});
  final LaterItem item;
  final _Kind kind;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    final date = item.unlockAt == null ? '' : fmt.date(item.unlockAt!.toLocal(), omitCurrentYear: false);
    final (icon, sub) = switch (kind) {
      _Kind.locked => (Icons.lock_outline_rounded, l.lockedUntil(date)),
      _Kind.returned => (Icons.lock_open_rounded, l.returnedBannerBody),
      _Kind.opened => (Icons.mark_email_read_outlined, l.timelineOpened(date)),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        color: kind == _Kind.returned ? s.primaryContainer.withValues(alpha: 0.5) : null,
        onTap: () {
          switch (kind) {
            case _Kind.locked:
              showAppSnack(context, l.lockedUntil(date));
            case _Kind.returned:
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RevealScreen(itemId: item.id)));
            case _Kind.opened:
              showItemDetailSheet(context, item.id);
          }
        },
        child: Row(children: [
          Icon(icon, color: kind == _Kind.locked ? s.onSurfaceVariant : s.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: context.text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(sub, style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
            ]),
          ),
        ]),
      ),
    );
  }
}
