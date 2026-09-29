import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/smart_pick.dart';
import '../app_scope.dart';
import '../screens/decide_screen.dart';
import '../widgets/common.dart';
import '../widgets/item_tile.dart';
import '../widgets/pro_gate.dart';

/// Smart Pick: choose the time you have, get a few fitting suggestions.
Future<void> showSmartPickSheet(BuildContext context, {int? initialMinutes, bool preselect = false}) {
  return showAppSheet<void>(
    context,
    full: true,
    builder: (_) => _SmartPickSheet(initialMinutes: initialMinutes, preselect: preselect),
  );
}

class _SmartPickSheet extends StatefulWidget {
  const _SmartPickSheet({this.initialMinutes, required this.preselect});
  final int? initialMinutes;
  final bool preselect;

  @override
  State<_SmartPickSheet> createState() => _SmartPickSheetState();
}

class _SmartPickSheetState extends State<_SmartPickSheet> {
  bool _chosen = false;
  int? _minutes;
  String? _category;
  int _seed = 0;

  @override
  void initState() {
    super.initState();
    _chosen = widget.preselect;
    _minutes = widget.initialMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;

    final results = _chosen
        ? app.smartPick(minutes: _minutes, categoryId: _category, limit: 3)
        : const <ScoredItem>[];
    // `_seed` only exists to re-roll the random tie-breaker on demand.
    assert(_seed >= 0);

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(l.smartPickHeader, style: context.text.titleLarge),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in smartPickMinuteOptions)
              ChoiceChip(
                label: Text(m == null ? l.anyTime : fmt.minutes(m)),
                selected: _chosen && _minutes == m,
                onSelected: (_) => setState(() {
                  _chosen = true;
                  _minutes = m;
                  _seed++;
                }),
              ),
          ]),
          const SizedBox(height: 12),
          _CategoryFilter(
            selected: _category,
            onChanged: (c) {
              if (!app.isPro) {
                showProSheet(context, featureName: l.smartPickProHint);
                return;
              }
              setState(() {
                _category = c;
                _seed++;
              });
            },
          ),
          if (!app.isPro)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                const ProTag(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l.smartPickProHint,
                      style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                ),
              ]),
            ),
          const SizedBox(height: 16),
          if (_chosen) ...[
            Row(children: [
              Expanded(
                child: Text(
                  _minutes == null ? l.smartPickResultsAny : l.smartPickResultsFor(fmt.minutes(_minutes!)),
                  style: context.text.titleMedium,
                ),
              ),
              if (results.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _seed++),
                  icon: const Icon(Icons.casino_outlined, size: 18),
                  label: Text(l.decideAnother),
                ),
            ]),
            const SizedBox(height: 8),
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: EmptyState(emoji: '🌱', title: l.smartPickEmpty),
              )
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Column(
                  key: ValueKey('${_minutes}_${_category}_$_seed'),
                  children: [
                    for (final r in results)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ItemTile(item: r.item, dismissible: false),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DecideScreen(minutes: _minutes)));
              },
              icon: const Icon(Icons.my_location_rounded),
              label: Text(l.pickCardTitle.replaceAll('🎯 ', '')),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.selected, required this.onChanged});
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    return SizedBox(
      height: 42,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: ChoiceChip(
            label: Text(l.smartPickAllCategories),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
        ),
        for (final c in app.categories)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text('${c.emoji} ${app.categoryName(c.id)}'),
              selected: selected == c.id,
              onSelected: (_) => onChanged(c.id),
            ),
          ),
      ]),
    );
  }
}
