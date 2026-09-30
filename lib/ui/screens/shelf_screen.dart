import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/pro.dart';
import '../../domain/search_filter_sort.dart';
import '../../l10n/app_localizations.dart';
import '../app_scope.dart';
import '../sheets/add_edit_sheet.dart';
import '../type_info.dart';
import '../widgets/common.dart';
import '../widgets/item_tile.dart';
import '../widgets/pro_gate.dart';
import 'idea_review_screen.dart';
import 'wishlist_review_screen.dart';

enum _ShelfSort { newest, oldest, price, score, time }

/// One shelf (read / watch / wishlist / ideas): its own stages, its own
/// stats, its own history. Free covers the basics, Pro adds the tools.
class ShelfScreen extends StatefulWidget {
  const ShelfScreen({super.key, required this.type});
  final ItemType type;

  @override
  State<ShelfScreen> createState() => _ShelfScreenState();
}

class _ShelfScreenState extends State<ShelfScreen> {
  int? _stage; // null = all
  bool _history = false;
  bool _stats = false;
  String? _collection;
  _ShelfSort _sort = _ShelfSort.newest;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int get _stageCount => switch (widget.type) {
        ItemType.read => 4,
        ItemType.watch => 3,
        ItemType.wishlist => 4,
        ItemType.idea => 5,
        _ => 0,
      };

  String _emptyTitle(AppL10n l) => switch (widget.type) {
        ItemType.read => l.shelfEmptyReadTitle,
        ItemType.watch => l.shelfEmptyWatchTitle,
        ItemType.wishlist => l.shelfEmptyWishTitle,
        _ => l.shelfEmptyIdeaTitle,
      };

  String _emptyBody(AppL10n l) => switch (widget.type) {
        ItemType.read => l.shelfEmptyReadBody,
        ItemType.watch => l.shelfEmptyWatchBody,
        ItemType.wishlist => l.shelfEmptyWishBody,
        _ => l.shelfEmptyIdeaBody,
      };

  List<LaterItem> _visible(BuildContext context) {
    final app = context.app;
    final t = widget.type;
    Iterable<LaterItem> src = _history ? app.shelfHistory(t) : app.shelf(t, collectionId: _collection);
    if (_stage != null) src = src.where((i) => i.stage == _stage);
    final q = _search.text.trim();
    if (q.isNotEmpty) {
      final sq = SearchQuery(q, advanced: app.isPro);
      src = src.where((i) => matchesSearch(i, sq, categoryName: app.categoryName));
    }
    final list = src.toList();
    int cmpNum(num? a, num? b, {bool desc = false}) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return desc ? b.compareTo(a) : a.compareTo(b);
    }

    switch (_sort) {
      case _ShelfSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _ShelfSort.oldest:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case _ShelfSort.price:
        list.sort((a, b) => cmpNum(a.price, b.price));
      case _ShelfSort.score:
        list.sort((a, b) => cmpNum(a.score, b.score, desc: true));
      case _ShelfSort.time:
        list.sort((a, b) => cmpNum(a.estimatedMinutes, b.estimatedMinutes));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    final t = widget.type;
    final items = _visible(context);
    final pro = app.access.has(ProFeature.advancedShelves);
    final cols = app.collectionsOf(t);
    final review = t == ItemType.wishlist
        ? app.wishlistToReview().length
        : t == ItemType.idea
            ? app.ideasToReview().length
            : 0;

    Widget stageChip(String label, int? st) => Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: FilterChip(
            label: Text(label),
            selected: _stage == st,
            showCheckmark: false,
            onSelected: (_) => setState(() => _stage = st),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(TypeInfo.shelfTitle(l, t)),
        actions: [
          IconButton(
            tooltip: l.shelfStatsTitle,
            icon: Icon(_stats ? Icons.bar_chart_rounded : Icons.insights_outlined),
            onPressed: () => pro ? setState(() => _stats = !_stats) : showProSheet(context, featureName: l.shelfStatsTitle),
          ),
          PopupMenuButton<_ShelfSort>(
            tooltip: l.sortTitle,
            icon: const Icon(Icons.sort_rounded),
            onSelected: (v) {
              if (v != _ShelfSort.newest && v != _ShelfSort.oldest && !pro) {
                showProSheet(context, featureName: l.shelfAdvancedFilters);
                return;
              }
              setState(() => _sort = v);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: _ShelfSort.newest, child: Text(l.sortNewest)),
              PopupMenuItem(value: _ShelfSort.oldest, child: Text(l.sortOldest)),
              if (t == ItemType.wishlist) PopupMenuItem(value: _ShelfSort.price, child: Text('${l.sortByPrice}  PRO')),
              if (t == ItemType.idea) PopupMenuItem(value: _ShelfSort.score, child: Text('${l.sortByScore}  PRO')),
              if (t == ItemType.read || t == ItemType.watch)
                PopupMenuItem(value: _ShelfSort.time, child: Text('${l.sortByTime}  PRO')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l.semAdd,
        onPressed: () => addFlow(context, presetType: t),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l.clear,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(_search.clear)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(l.shelfWaiting)),
              ButtonSegment(value: true, label: Text(l.shelfHistory)),
            ],
            selected: {_history},
            onSelectionChanged: (v) {
              if (v.first && !app.access.has(ProFeature.fullHistory) && !pro) {
                showProSheet(context, featureName: l.shelfHistoryPro);
                return;
              }
              setState(() => _history = v.first);
            },
          ),
        ),
        if (_stageCount > 0)
          SizedBox(
            height: 54,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                stageChip(l.shelfAllStages, null),
                for (var i = 0; i < _stageCount; i++) stageChip(TypeInfo.stageLabel(l, t, i), i),
              ],
            ),
          ),
        SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              children: [
                if (cols.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(l.shelfCollectionMain),
                      selected: _collection == null,
                      onSelected: (_) => setState(() => _collection = null),
                    ),
                  ),
                for (final c in cols)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(c.name),
                      selected: _collection == c.id,
                      onSelected: (_) => setState(() => _collection = c.id),
                    ),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.create_new_folder_outlined, size: 18),
                  label: Text(pro ? l.collectionNew : l.collectionProHint),
                  onPressed: () async {
                    if (!app.canAddCollection(t)) {
                      await showProSheet(context, featureName: l.collectionProHint);
                      return;
                    }
                    final name = await _askName(context, l.collectionName);
                    if (name != null && name.trim().isNotEmpty) await app.addCollection(name, t);
                  },
                ),
              ],
            ),
          ),
        if (_stats) _StatsCard(type: t),
        if (review > 0 && !_history)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: AppCard(
              color: context.appColors.warning.withValues(alpha: 0.10),
              borderColor: context.appColors.warning.withValues(alpha: 0.35),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => t == ItemType.wishlist ? const WishlistReviewScreen() : const IdeaReviewScreen())),
              child: Row(children: [
                Icon(t == ItemType.wishlist ? Icons.shopping_bag_outlined : Icons.lightbulb_outline_rounded,
                    color: context.appColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      t == ItemType.wishlist ? l.wishReviewTitle : l.ideaReviewBanner(fmt.num(review)),
                      style: context.text.titleSmall),
                ),
                Icon(Icons.chevron_left_rounded, color: s.onSurfaceVariant),
              ]),
            ),
          ),
        Expanded(
          child: items.isEmpty
              ? EmptyState(
                  emoji: '🗂️',
                  title: _search.text.isNotEmpty ? l.listEmptyFiltered : _emptyTitle(l),
                  body: _search.text.isNotEmpty ? l.listEmptyFilteredBody : _emptyBody(l))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => ItemTile(key: ValueKey(items[i].id), item: items[i], dismissible: !_history),
                ),
        ),
      ]),
    );
  }
}

Future<String?> _askName(BuildContext context, String label) {
  return showDialog<String>(context: context, builder: (_) => _NameDialog(label: label));
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.label});
  final String label;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.label),
      content: TextField(controller: _c, autofocus: true, maxLength: 40),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, _c.text), child: Text(l.save)),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.type});
  final ItemType type;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final st = app.shelfStats(type);
    Widget cell(String label, String v) => Expanded(
          child: Column(children: [
            Text(v, style: context.text.titleMedium),
            Text(label,
                textAlign: TextAlign.center,
                style: context.text.labelSmall?.copyWith(color: context.scheme.onSurfaceVariant)),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: AppCard(
        child: Column(children: [
          Row(children: [
            cell(l.statsWaiting, fmt.num(st.waiting)),
            cell(l.statsFinished, fmt.num(st.finished)),
            cell(l.statsThisWeek, fmt.num(st.finishedThisWeek)),
            cell(l.statsThisMonth, fmt.num(st.finishedThisMonth)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            if (type == ItemType.read || type == ItemType.watch)
              cell(l.statsMinutesWaiting, fmt.minutes(st.minutesWaiting)),
            if (st.avgDaysToFinish != null)
              cell(l.statsAvgFinish, l.statsDaysValue(fmt.num(st.avgDaysToFinish!.round()))),
            if (type == ItemType.wishlist) cell(l.statsTotalPrice, fmt.money(st.totalPrice)),
          ]),
        ]),
      ),
    );
  }
}
