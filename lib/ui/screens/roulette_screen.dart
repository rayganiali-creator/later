import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/pro.dart';
import '../../domain/roulette.dart';
import '../app_scope.dart';
import '../item_actions.dart';
import '../sheets/snooze_sheet.dart';
import '../type_info.dart';
import '../widgets/common.dart';
import '../widgets/pro_gate.dart';

/// «قرعه بعداً»: the app picks one thing for you. Free gets a fair random
/// pick; Pro can narrow it by time, priority, energy and category.
class RouletteScreen extends StatefulWidget {
  const RouletteScreen({super.key, this.minutes});
  final int? minutes;

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen> {
  LaterItem? _current;
  bool _spinning = false;
  bool _spun = false;
  bool _cheer = false;
  String _ticker = '';
  Timer? _timer;
  int? _minutes;
  ItemPriority? _priority;
  RouletteEnergy? _energy;
  Set<String> _cats = {};
  final Set<String> _skipped = {};

  @override
  void initState() {
    super.initState();
    _minutes = widget.minutes;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  RouletteOptions _options() {
    final app = context.appRead;
    final o = app.rouletteOptions(
      minutes: _minutes,
      priority: _priority,
      energy: _energy,
      categories: _cats.isEmpty ? null : _cats,
    );
    return RouletteOptions(
      availableMinutes: o.availableMinutes,
      categoryIds: o.categoryIds,
      priority: o.priority,
      energy: o.energy,
      recentIds: o.recentIds,
      excludeIds: {..._skipped},
    );
  }

  Future<void> _spin() async {
    if (_spinning) return;
    final app = context.appRead;
    final reduce = MediaQuery.of(context).disableAnimations;
    final titles = [for (final i in app.activeItems) if (Roulette.doableTypes.contains(i.type)) i.title];
    HapticFeedback.selectionClick();
    var pick = await app.spinRoulette(options: _options());
    if (pick == null && _skipped.isNotEmpty) {
      // Everything was skipped once: start over instead of a dead end.
      _skipped.clear();
      pick = await app.spinRoulette(options: _options());
    }
    if (!mounted) return;
    if (pick == null || titles.length < 2 || reduce) {
      setState(() {
        _current = pick;
        _spun = true;
        _spinning = false;
      });
      return;
    }
    var n = 0;
    setState(() {
      _spinning = true;
      _spun = true;
      _current = null;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (t) {
      n++;
      if (n >= 12) {
        t.cancel();
        if (mounted) {
          setState(() {
            _spinning = false;
            _current = pick;
          });
          HapticFeedback.mediumImpact();
        }
        return;
      }
      if (mounted) setState(() => _ticker = titles[(n * 7) % titles.length]);
    });
  }

  Future<void> _open(LaterItem item) async {
    HapticFeedback.mediumImpact();
    await ItemActions.openLink(context, item.url);
  }

  Future<void> _finish(LaterItem item) async {
    final app = context.appRead;
    final target = switch (item.type) {
      ItemType.read => ItemStages.read,
      ItemType.watch => ItemStages.watched,
      _ => null,
    };
    if (target != null) {
      await app.setStage(item.id, target);
    } else {
      await app.complete(item.id);
    }
    if (!mounted) return;
    setState(() {
      _cheer = true;
      _current = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _cheer = false);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final s = context.scheme;
    var item = _current == null ? null : app.itemById(_current!.id);
    if (item != null && !item.isActive) item = null;
    final pro = app.access.has(ProFeature.smartRoulette);

    Widget body;
    if (_cheer) {
      body = EmptyState(key: const ValueKey('cheer'), emoji: '🎉', title: l.decideDoneToast);
    } else if (_spinning) {
      body = Center(
        key: const ValueKey('spin'),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.casino_rounded, size: 56, color: s.primary),
          const SizedBox(height: 18),
          Text(l.rouletteSpinning, style: context.text.titleMedium),
          const SizedBox(height: 10),
          Text(_ticker,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyLarge?.copyWith(color: s.onSurfaceVariant)),
        ]),
      );
    } else if (item != null) {
      final cur = item;
      body = _Result(
        key: ValueKey('r_${cur.id}'),
        item: cur,
        onStart: () => cur.url != null && cur.type != ItemType.task ? _open(cur) : _finish(cur),
        onDone: cur.url != null && cur.type != ItemType.task ? () => _finish(cur) : null,
        onLater: () async {
          final target = cur;
          final before = target.snoozeCount;
          final ctrl = context.appRead;
          await showSnoozeSheet(context, target);
          if (!mounted) return;
          final after = ctrl.itemById(target.id);
          if (after == null || after.snoozeCount != before) {
            _skipped.add(target.id);
            unawaited(_spin());
          }
        },
        onAnother: () {
          _skipped.add(cur.id);
          unawaited(_spin());
        },
      );
    } else if (_spun) {
      body = EmptyState(key: const ValueKey('none'), emoji: '🌱', title: l.rouletteEmptyTitle, body: l.rouletteEmptyBody);
    } else {
      body = _Intro(
        key: const ValueKey('intro'),
        onSpin: _spin,
        pro: pro,
        minutes: _minutes,
        priority: _priority,
        energy: _energy,
        cats: _cats,
        onChanged: (m, p, e, c) => setState(() {
          _minutes = m;
          _priority = p;
          _energy = e;
          _cats = c;
        }),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.rouletteTitle),
        actions: [
          IconButton(
            tooltip: l.rouletteHistoryTitle,
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              if (!app.access.has(ProFeature.rouletteHistory)) {
                showProSheet(context, featureName: l.rouletteHistoryTitle);
                return;
              }
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RouletteHistoryScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: body,
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({
    super.key,
    required this.onSpin,
    required this.pro,
    required this.minutes,
    required this.priority,
    required this.energy,
    required this.cats,
    required this.onChanged,
  });
  final VoidCallback onSpin;
  final bool pro;
  final int? minutes;
  final ItemPriority? priority;
  final RouletteEnergy? energy;
  final Set<String> cats;
  final void Function(int?, ItemPriority?, RouletteEnergy?, Set<String>) onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final app = context.app;
    final s = context.scheme;

    void guardPro(VoidCallback f) => pro ? f() : showProSheet(context, featureName: l.rouletteFilters);

    return ListView(children: [
      const SizedBox(height: 12),
      Icon(Icons.casino_rounded, size: 72, color: s.primary),
      const SizedBox(height: 12),
      Text(l.decideIntro, textAlign: TextAlign.center, style: context.text.titleMedium),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onSpin,
          icon: const Icon(Icons.casino_outlined),
          label: Text(l.roulettePick),
        ),
      ),
      SectionTitle(l.rouletteFilters, trailing: pro ? null : const ProTag()),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.rouletteTime, style: context.text.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in const [null, 5, 15, 30, 60])
              ChoiceChip(
                label: Text(m == null ? l.anyTime : fmt.minutes(m)),
                selected: minutes == m,
                onSelected: (_) => guardPro(() => onChanged(m, priority, energy, cats)),
              ),
          ]),
          const SizedBox(height: 14),
          Text(l.priority, style: context.text.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
                label: Text(l.all),
                selected: priority == null,
                onSelected: (_) => guardPro(() => onChanged(minutes, null, energy, cats))),
            for (final p in ItemPriority.values)
              ChoiceChip(
                label: Text(fmt.priority(p)),
                selected: priority == p,
                onSelected: (_) => guardPro(() => onChanged(minutes, p, energy, cats)),
              ),
          ]),
          const SizedBox(height: 14),
          Text(l.rouletteEnergy, style: context.text.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
                label: Text(l.all),
                selected: energy == null,
                onSelected: (_) => guardPro(() => onChanged(minutes, priority, null, cats))),
            ChoiceChip(
                label: Text(l.energyLow),
                selected: energy == RouletteEnergy.low,
                onSelected: (_) => guardPro(() => onChanged(minutes, priority, RouletteEnergy.low, cats))),
            ChoiceChip(
                label: Text(l.energyHigh),
                selected: energy == RouletteEnergy.high,
                onSelected: (_) => guardPro(() => onChanged(minutes, priority, RouletteEnergy.high, cats))),
          ]),
          const SizedBox(height: 14),
          Text(l.rouletteCats, style: context.text.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in app.categories)
              FilterChip(
                label: Text('${c.emoji} ${app.categoryName(c.id)}'),
                selected: cats.contains(c.id),
                showCheckmark: false,
                onSelected: (v) => guardPro(() {
                  final n = {...cats};
                  v ? n.add(c.id) : n.remove(c.id);
                  onChanged(minutes, priority, energy, n);
                }),
              ),
          ]),
          if (!pro) ...[
            const SizedBox(height: 12),
            Text(l.rouletteProHint, style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
          ],
        ]),
      ),
    ]);
  }
}

class _Result extends StatelessWidget {
  const _Result({
    super.key,
    required this.item,
    required this.onStart,
    required this.onLater,
    required this.onAnother,
    this.onDone,
  });
  final LaterItem item;
  final VoidCallback onStart, onLater, onAnother;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final app = context.appRead;
    final fmt = context.fmt;
    final s = context.scheme;
    final opensLink = item.url != null && item.type != ItemType.task;
    return Column(children: [
      const Spacer(),
      Text(l.decideLabel, style: context.text.titleMedium?.copyWith(color: s.primary)),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [s.primaryContainer, context.appColors.lavender],
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(children: [
          item.type == ItemType.task
              ? Text(app.categoryEmoji(item.categoryId), style: const TextStyle(fontSize: 44))
              : Icon(TypeInfo.icon(item.type), size: 44, color: s.primary),
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Text('«${item.title}»', textAlign: TextAlign.center, style: context.text.headlineSmall),
          ),
          const SizedBox(height: 12),
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
            if (item.type != ItemType.task) Pill(TypeInfo.shelfTitle(l, item.type)),
            if (item.estimatedMinutes != null)
              Pill(l.decideAbout(fmt.num(item.estimatedMinutes!)), icon: Icons.timer_outlined),
            Pill(app.categoryName(item.categoryId)),
            if (item.dueAt != null) Pill(fmt.due(item), icon: Icons.event_rounded),
          ]),
        ]),
      ),
      const Spacer(),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onStart,
          icon: Icon(opensLink ? Icons.open_in_new_rounded : Icons.check_rounded),
          label: Text(opensLink ? l.rouletteOpenLink : l.decideDo),
        ),
      ),
      if (onDone != null) ...[
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onDone,
            icon: const Icon(Icons.check_rounded),
            label: Text(TypeInfo.doneLabel(l, item.type)),
          ),
        ),
      ],
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: onLater, child: Text(l.rouletteLater))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton(onPressed: onAnother, child: Text(l.rouletteAgain))),
      ]),
    ]);
  }
}

class RouletteHistoryScreen extends StatelessWidget {
  const RouletteHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.appRead;
    final l = context.l10n;
    final fmt = context.fmt;
    return Scaffold(
      appBar: AppBar(title: Text(l.rouletteHistoryTitle)),
      body: FutureBuilder<List<(ItemEvent, LaterItem?)>>(
        future: app.rouletteHistory(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snap.data!;
          if (rows.isEmpty) return EmptyState(emoji: '🎲', title: l.rouletteHistoryEmpty);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final (e, it) = rows[i];
              return ListTile(
                leading: Icon(it == null ? Icons.help_outline_rounded : TypeInfo.icon(it.type)),
                title: Text(it?.title ?? '—'),
                subtitle: Text('${fmt.date(e.at.toLocal())} · ${fmt.time(e.at.toLocal())}'),
              );
            },
          );
        },
      ),
    );
  }
}
