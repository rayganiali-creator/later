import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/pro.dart';
import '../app_scope.dart';
import '../item_actions.dart';
import '../sheets/item_detail_sheet.dart';
import '../sheets/media_sections.dart';
import '../type_info.dart';
import '../widgets/common.dart';
import '../widgets/item_image.dart';
import '../widgets/item_tile.dart';
import '../widgets/pro_gate.dart';

/// «امروز چی بازی کنم؟» — one game, three buttons. Free draws fairly at
/// random; Pro filters by time, genre, priority and status and keeps the
/// genres varied.
class GamePickerScreen extends StatefulWidget {
  const GamePickerScreen({super.key});

  @override
  State<GamePickerScreen> createState() => _GamePickerScreenState();
}

class _GamePickerScreenState extends State<GamePickerScreen> {
  LaterItem? _game;
  bool _spun = false;
  bool _busy = false;
  int? _minutes;
  ItemPriority? _priority;
  String? _genre;
  Set<int>? _stages;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    final app = context.appRead;
    final g = await app.pickGameNow(
      options: app.gameOptions(minutes: _minutes, priority: _priority, genre: _genre, stages: _stages),
    );
    if (!mounted) return;
    setState(() {
      _game = g;
      _spun = true;
      _busy = false;
    });
  }

  Future<void> _start(LaterItem g) async {
    final app = context.appRead;
    final l = context.l10n;
    if (g.stage == ItemStages.wantPlay || g.stage == ItemStages.playPaused) {
      await app.setStage(g.id, ItemStages.playing);
    }
    if (!mounted) return;
    if (g.url != null) await ItemActions.openLink(context, g.url);
    if (mounted) showAppSnack(context, l.gameStarted);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    final pro = app.access.has(ProFeature.gameTools);
    final color = TypeInfo.color(ItemType.game);
    var g = _game == null ? null : app.itemById(_game!.id);
    if (g != null && !g.isActive) g = null;

    void gate(VoidCallback f) => pro ? f() : showProSheet(context, featureName: l.gameProHint);

    Widget filters() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(l.rouletteFilters, trailing: pro ? null : const ProTag()),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.gameFreeTime, style: context.text.titleSmall),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final m in const [null, 15, 30, 45, 60, 120])
                  ChoiceChip(
                    label: Text(m == null ? l.anyTime : fmt.minutes(m)),
                    selected: _minutes == m,
                    onSelected: (_) => gate(() => setState(() => _minutes = m)),
                  ),
              ]),
              const SizedBox(height: 14),
              Text(l.priority, style: context.text.titleSmall),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceChip(label: Text(l.all), selected: _priority == null, onSelected: (_) => gate(() => setState(() => _priority = null))),
                for (final p in ItemPriority.values)
                  ChoiceChip(
                    label: Text(fmt.priority(p)),
                    selected: _priority == p,
                    onSelected: (_) => gate(() => setState(() => _priority = p)),
                  ),
              ]),
              const SizedBox(height: 14),
              Text(l.gameStatusFilter, style: context.text.titleSmall),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ChoiceChip(label: Text(l.all), selected: _stages == null, onSelected: (_) => gate(() => setState(() => _stages = null))),
                for (final st in const [ItemStages.wantPlay, ItemStages.playing, ItemStages.playPaused])
                  ChoiceChip(
                    label: Text(TypeInfo.stageLabel(l, ItemType.game, st)),
                    selected: _stages != null && _stages!.length == 1 && _stages!.contains(st),
                    onSelected: (_) => gate(() => setState(() => _stages = {st})),
                  ),
              ]),
              if (app.gameGenres().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(l.gameGenreFilter, style: context.text.titleSmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  ChoiceChip(label: Text(l.all), selected: _genre == null, onSelected: (_) => gate(() => setState(() => _genre = null))),
                  for (final ge in app.gameGenres())
                    ChoiceChip(
                      label: Text(ge),
                      selected: _genre == ge,
                      onSelected: (_) => gate(() => setState(() => _genre = ge)),
                    ),
                ]),
              ],
              if (!pro) ...[
                const SizedBox(height: 12),
                Text(l.gameProHint, style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
              ],
            ]),
          ),
        ]);

    Widget body;
    if (g != null) {
      final cur = g;
      body = Column(key: ValueKey('g_${cur.id}'), children: [
        const Spacer(),
        Text(l.gamePickLabel, style: context.text.titleMedium?.copyWith(color: color)),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.06)],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(children: [
            CoverThumb(item: cur, size: 150, radius: 24),
            const SizedBox(height: 14),
            Semantics(
              liveRegion: true,
              child: Text('«${cur.title}»', textAlign: TextAlign.center, style: context.text.headlineSmall),
            ),
            const SizedBox(height: 10),
            Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
              if (cur.genre.isNotEmpty) Pill(cur.genre, icon: Icons.category_outlined),
              for (final p in cur.platforms.take(2)) Pill(platformLabel(l, p)),
              Pill(TypeInfo.stageLabel(l, ItemType.game, cur.stage), color: color),
            ]),
            if (cur.estimatedMinutes != null) ...[
              const SizedBox(height: 10),
              Text(l.gameHowLong(fmt.num(cur.estimatedMinutes!)), style: context.text.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
            ],
          ]),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: () => _start(cur),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l.gameStart),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => showItemDetailSheet(context, cur.id), child: Text(l.gameLater))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton(onPressed: _busy ? null : _pick, child: Text(l.gameAnother))),
        ]),
      ]);
    } else if (_spun) {
      body = ListView(key: const ValueKey('none'), children: [
        const SizedBox(height: 24),
        EmptyStateInline(emoji: '🎮', title: l.gameEmptyTitle, body: l.gameEmptyBody),
        filters(),
        const SizedBox(height: 12),
        FilledButton(onPressed: _pick, child: Text(l.gamePickBtn)),
      ]);
    } else {
      body = ListView(key: const ValueKey('intro'), children: [
        const SizedBox(height: 12),
        Icon(Icons.sports_esports_rounded, size: 72, color: color),
        const SizedBox(height: 12),
        Text(l.gamePickTitle, textAlign: TextAlign.center, style: context.text.titleMedium),
        const SizedBox(height: 18),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: color),
          onPressed: _pick,
          icon: const Icon(Icons.casino_outlined),
          label: Text(l.gamePickBtn),
        ),
        filters(),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.gamePickTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: AnimatedSwitcher(duration: const Duration(milliseconds: 240), child: body),
        ),
      ),
    );
  }
}

/// A compact empty message for places that are already inside a list.
class EmptyStateInline extends StatelessWidget {
  const EmptyStateInline({super.key, required this.emoji, required this.title, this.body});
  final String emoji, title;
  final String? body;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 44)),
        const SizedBox(height: 8),
        Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
        if (body != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(body!,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: context.scheme.onSurfaceVariant)),
          ),
      ]);
}

/// Pro: the next episodes for the time you have.
class PodcastQueueScreen extends StatefulWidget {
  const PodcastQueueScreen({super.key});

  @override
  State<PodcastQueueScreen> createState() => _PodcastQueueScreenState();
}

class _PodcastQueueScreenState extends State<PodcastQueueScreen> {
  int? _minutes;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final q = app.podcastQueue(minutes: _minutes);
    return Scaffold(
      appBar: AppBar(title: Text(l.podcastQueueTitle)),
      body: Column(children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              for (final m in const [null, 15, 30, 60])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(m == null ? l.all : (m == 30 ? l.shortEpisodes : fmt.minutes(m))),
                    selected: _minutes == m,
                    onSelected: (_) => setState(() => _minutes = m),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: q.isEmpty
              ? EmptyState(emoji: '🎧', title: l.queueEmpty)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  itemCount: q.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => ItemTile(key: ValueKey(q[i].id), item: q[i]),
                ),
        ),
      ]),
    );
  }
}

/// Horizontal "pick up where you left off" strip for podcasts and courses.
class ContinueStrip extends StatelessWidget {
  const ContinueStrip({super.key, required this.type});
  final ItemType type;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final color = TypeInfo.color(type);
    final items = app.inProgress(type).take(6).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
        child: Text(l.continueSection, style: context.text.titleSmall),
      ),
      SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final it = items[i];
            return SizedBox(
              width: 250,
              child: AppCard(
                padding: const EdgeInsets.all(10),
                onTap: () => showItemDetailSheet(context, it.id),
                child: Row(children: [
                  CoverThumb(item: it, size: 56, radius: 12),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(it.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: it.progress / 100,
                        minHeight: 4,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.15),
                      ),
                      Text(
                        it.remainingSec != null
                            ? l.podcastRemaining(fmt.num(TypeInfo.clock(it.remainingSec!)))
                            : l.learnProgress(fmt.num(it.progress)),
                        style: context.text.labelSmall?.copyWith(color: context.scheme.onSurfaceVariant),
                      ),
                    ]),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

/// A game / cover-first card for grids.
class CoverCard extends StatelessWidget {
  const CoverCard({super.key, required this.item});
  final LaterItem item;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = TypeInfo.color(item.type);
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => showItemDetailSheet(context, item.id),
      semanticLabel: item.title,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => CoverThumb(item: item, size: box.maxWidth, radius: 0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
            const SizedBox(height: 4),
            Row(children: [
              Flexible(
                child: Pill(TypeInfo.stageLabel(l, item.type, item.stage), color: color),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
