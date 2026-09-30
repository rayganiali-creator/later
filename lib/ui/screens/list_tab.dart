import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/search_filter_sort.dart';
import '../app_scope.dart';
import '../nav_bus.dart';
import '../type_info.dart';
import '../sheets/add_edit_sheet.dart';
import '../widgets/common.dart';
import '../widgets/item_tile.dart';
import '../widgets/pro_gate.dart';

class ListTab extends StatefulWidget {
  const ListTab({super.key});

  @override
  State<ListTab> createState() => _ListTabState();
}

class _ListTabState extends State<ListTab> {
  final _search = TextEditingController();
  final _focus = FocusNode();
  ItemFilter _filter = ItemFilter.all;
  SortMode _sort = SortMode.newest;
  int _lastFocusTick = 0;
  NavBus? _bus;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bus = NavScope.of(context);
    if (_bus != bus) {
      _bus = bus;
    }
    final pending = bus.takeFilter();
    if (pending != null) _filter = pending;
    if (bus.searchFocusTick != _lastFocusTick) {
      _lastFocusTick = bus.searchFocusTick;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final s = context.scheme;
    final items = app.query(filter: _filter, search: _search.text, sort: _sort);

    Widget chip(String label, ItemFilter f, {bool smart = false}) {
      final selected = _filter == f;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: FilterChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => setState(() => _filter = f),
        ),
      );
    }

    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            Expanded(child: Text(l.listTitle, style: context.text.headlineSmall)),
            IconButton(
              tooltip: l.sortTitle,
              onPressed: _showSort,
              icon: const Icon(Icons.sort_rounded),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _search,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l.searchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l.clear,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _search.clear,
                    ),
            ),
          ),
        ),
        if (_search.text.isNotEmpty && !app.isPro)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GestureDetector(
                onTap: () => showProSheet(context, featureName: l.searchAdvancedHint),
                child: Text(l.searchAdvancedHint,
                    style: context.text.labelSmall?.copyWith(color: s.primary)),
              ),
            ),
          ),
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              chip(l.filterAll, ItemFilter.all),
              chip(l.filterToday, const ItemFilter(FilterKind.today)),
              chip(l.filterWeek, const ItemFilter(FilterKind.thisWeek)),
              chip(l.filterNoDate, const ItemFilter(FilterKind.noDate)),
              chip(l.filterOverdue, const ItemFilter(FilterKind.overdue)),
              chip(l.filterHigh, const ItemFilter(FilterKind.highPriority)),
              chip(l.filterStale, const ItemFilter(FilterKind.stale)),
              chip(l.inboxTitle, const ItemFilter(FilterKind.inbox)),
              for (final t in const [ItemType.read, ItemType.watch, ItemType.wishlist, ItemType.idea])
                chip(TypeInfo.shelfTitle(l, t), ItemFilter(FilterKind.type, t.name)),
              for (final c in app.categories)
                chip('${c.emoji} ${app.categoryName(c.id)}', ItemFilter(FilterKind.category, c.id)),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? (app.activeItems.isEmpty
                  ? EmptyState(
                      emoji: '🌱',
                      title: l.homeEmptyTitle,
                      body: l.homeEmptyBody,
                      action: FilledButton.icon(
                        onPressed: () => addFlow(context),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l.homeEmptyCta),
                      ),
                    )
                  : EmptyState(emoji: '🔍', title: l.listEmptyFiltered, body: l.listEmptyFilteredBody))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => ItemTile(item: items[i]),
                ),
        ),
      ]),
    );
  }

  void _showSort() {
    final l = context.l10n;
    final entries = <(SortMode, String, IconData)>[
      (SortMode.newest, l.sortNewest, Icons.fiber_new_rounded),
      (SortMode.oldest, l.sortOldest, Icons.history_rounded),
      (SortMode.nearestDeadline, l.sortDeadline, Icons.event_available_rounded),
      (SortMode.priority, l.sortPriority, Icons.flag_rounded),
      (SortMode.shortest, l.sortShortest, Icons.timer_outlined),
      (SortMode.longest, l.sortLongest, Icons.hourglass_full_rounded),
    ];
    showAppSheet<void>(
      context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l.sortTitle, style: ctx.text.titleLarge),
            ),
          ),
          for (final e in entries)
            ListTile(
              leading: Icon(e.$3, color: ctx.scheme.primary),
              title: Text(e.$2),
              trailing: _sort == e.$1 ? Icon(Icons.check_rounded, color: ctx.scheme.primary) : null,
              onTap: () {
                setState(() => _sort = e.$1);
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}
