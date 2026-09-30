import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/universal_search.dart';
import '../app_scope.dart';
import '../sheets/item_detail_sheet.dart';
import '../type_info.dart';
import '../widgets/common.dart';
import '../widgets/pro_gate.dart';
import 'people_screens.dart';

/// Search across every shelf, people, and sealed things (which only show
/// that they exist).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final s = context.scheme;
    final q = _c.text.trim();
    final hits = q.isEmpty ? const <SearchHit>[] : app.search(q);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _c,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: l.searchEverywhereHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (q.isNotEmpty)
            IconButton(tooltip: l.clear, icon: const Icon(Icons.close_rounded), onPressed: () => setState(_c.clear)),
        ],
      ),
      body: q.isEmpty
          ? EmptyState(emoji: '🔎', title: l.searchStartTyping, body: l.searchEverywhere)
          : hits.isEmpty
              ? EmptyState(emoji: '🔍', title: l.searchNothing)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 40),
                  itemCount: hits.length + (app.isPro ? 0 : 1),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    if (i == hits.length) {
                      return ListTile(
                        title: Text(l.searchAdvancedHint, style: context.text.labelMedium?.copyWith(color: s.primary)),
                        onTap: () => showProSheet(context, featureName: l.searchAdvancedHint),
                      );
                    }
                    final h = hits[i];
                    final isPerson = h.kind == HitKind.person;
                    return ListTile(
                      leading: Icon(isPerson ? Icons.person_outline_rounded : TypeInfo.icon(h.type ?? ItemType.task)),
                      title: Text(h.locked ? l.stageSealed : h.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        [
                          if (isPerson) l.shelfPeopleTitle else TypeInfo.shelfTitle(l, h.type ?? ItemType.task),
                          if (h.status != ItemStatus.active) l.searchDone,
                        ].join(' · '),
                      ),
                      onTap: () {
                        if (isPerson) {
                          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PersonScreen(personId: h.id)));
                        } else if (!h.locked) {
                          showItemDetailSheet(context, h.id);
                        }
                      },
                    );
                  },
                ),
    );
  }
}
