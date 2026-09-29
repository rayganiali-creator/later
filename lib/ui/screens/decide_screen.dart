import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../app_scope.dart';
import '../item_actions.dart';
import '../sheets/snooze_sheet.dart';
import '../widgets/common.dart';

/// "Don't decide" mode: one suggestion, three buttons.
class DecideScreen extends StatefulWidget {
  const DecideScreen({super.key, this.minutes});
  final int? minutes;

  @override
  State<DecideScreen> createState() => _DecideScreenState();
}

class _DecideScreenState extends State<DecideScreen> {
  final Set<String> _seen = {};
  LaterItem? _current;
  bool _exhausted = false;
  bool _celebrate = false;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      _next();
    }
  }

  void _next() {
    final app = context.appRead;
    var r = app.smartPick(minutes: widget.minutes, exclude: _seen, limit: 1);
    var exhausted = false;
    if (r.isEmpty && _seen.isNotEmpty) {
      // Everything was skipped once: start over rather than dead-end, but say so.
      exhausted = true;
      _seen.clear();
      r = app.smartPick(minutes: widget.minutes, limit: 1);
    }
    setState(() {
      _current = r.isEmpty ? null : r.first.item;
      _exhausted = exhausted;
      if (_current != null) _seen.add(_current!.id);
    });
    if (exhausted && mounted && _current != null) {
      showAppSnack(context, context.l10n.decideNoMore);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the item changes underneath us (e.g. completed elsewhere).
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    var item = _current == null ? null : app.itemById(_current!.id);
    if (item != null && !item.isActive) item = null;

    return Scaffold(
      appBar: AppBar(title: Text(l.decideTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: _celebrate
                ? EmptyState(key: const ValueKey('cheer'), emoji: '🎉', title: l.decideDoneToast)
                : item == null
                    ? EmptyState(
                        key: const ValueKey('none'),
                        emoji: '🌱',
                        title: l.decideNone,
                        body: l.decideNoneBody)
                    : _SuggestionCard(
                        key: ValueKey(item.id),
                        item: item,
                        exhausted: _exhausted,
                        onDo: () async {
                          HapticFeedback.mediumImpact();
                          await app.complete(item!.id);
                          if (!mounted) return;
                          setState(() => _celebrate = true);
                          await Future<void>.delayed(const Duration(milliseconds: 900));
                          if (mounted) {
                            setState(() => _celebrate = false);
                            _next();
                          }
                        },
                        onLater: () async {
                          final target = item!;
                          final before = target.snoozeCount;
                          final ctrl = context.appRead;
                          await showSnoozeSheet(context, target);
                          if (!mounted) return;
                          final after = ctrl.itemById(target.id);
                          if (after == null || after.snoozeCount != before) _next();
                        },
                        onAnother: _next,
                        fmt: fmt,
                        scheme: s,
                      ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    super.key,
    required this.item,
    required this.exhausted,
    required this.onDo,
    required this.onLater,
    required this.onAnother,
    required this.fmt,
    required this.scheme,
  });

  final LaterItem item;
  final bool exhausted;
  final VoidCallback onDo;
  final VoidCallback onLater;
  final VoidCallback onAnother;
  final Fmt fmt;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final app = context.appRead;
    return Column(children: [
      const Spacer(),
      Text(l.decideLabel, style: context.text.titleMedium?.copyWith(color: scheme.primary)),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [scheme.primaryContainer, context.appColors.lavender],
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(children: [
          Text(app.categoryEmoji(item.categoryId), style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Text(
              '«${item.title}»',
              textAlign: TextAlign.center,
              style: context.text.headlineSmall,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
            if (item.estimatedMinutes != null)
              Pill(l.decideAbout(fmt.num(item.estimatedMinutes!)), icon: Icons.timer_outlined),
            Pill(app.categoryName(item.categoryId)),
            if (item.dueAt != null) Pill(fmt.due(item), icon: Icons.event_rounded),
          ]),
          if (item.url != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ItemActions.openLink(context, item.url),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(l.itemOpenLink),
            ),
          ],
        ]),
      ),
      const Spacer(),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onDo,
          icon: const Icon(Icons.check_rounded),
          label: Text(l.decideDo),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: onLater, child: Text(l.decideLater))),
        const SizedBox(width: 10),
        Expanded(child: OutlinedButton(onPressed: onAnother, child: Text(l.decideAnother))),
      ]),
    ]);
  }
}
