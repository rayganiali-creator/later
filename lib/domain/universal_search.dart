import '../core/util/text.dart';
import 'models.dart';
import 'search_filter_sort.dart';

enum HitKind { item, person }

/// One row of the universal search. Sealed content is redacted.
class SearchHit {
  const SearchHit({
    required this.kind,
    required this.id,
    required this.title,
    this.type,
    this.subtitle = '',
    this.locked = false,
    this.unlockAt,
    this.status = ItemStatus.active,
  });

  final HitKind kind;
  final String id;
  final String title;
  final ItemType? type;
  final String subtitle;

  /// Sealed capsule / message: [title] is empty on purpose.
  final bool locked;
  final DateTime? unlockAt;
  final ItemStatus status;
}

/// Searches every shelf at once: items of all types (also finished ones),
/// people, capsules and future messages (sealed ones only reveal that they
/// exist, never their text).
List<SearchHit> universalSearch({
  required Iterable<LaterItem> items,
  required Iterable<Person> people,
  required String query,
  required DateTime now,
  required bool advanced,
  String Function(String categoryId)? categoryName,
  int limit = 200,
}) {
  final q = SearchQuery(query, advanced: advanced);
  if (q.isEmpty) return const [];
  final hits = <SearchHit>[];
  for (final i in items) {
    if (i.isLockedAt(now)) {
      // Only match on the *type word*, never on hidden text.
      continue;
    }
    if (matchesSearch(i, q, categoryName: categoryName)) {
      hits.add(SearchHit(
        kind: HitKind.item,
        id: i.id,
        title: i.title,
        type: i.type,
        subtitle: i.url ?? i.description,
        status: i.status,
      ));
    }
  }
  for (final p in people) {
    final hay = normalizeForSearch('${p.name} ${p.note} ${p.group}');
    if (q.terms.every(hay.contains)) {
      hits.add(SearchHit(kind: HitKind.person, id: p.id, title: p.name, subtitle: p.note));
    }
  }
  // Active first, then by title; keeps results stable.
  hits.sort((a, b) {
    final s = a.status.index.compareTo(b.status.index);
    return s != 0 ? s : a.title.compareTo(b.title);
  });
  return hits.length > limit ? hits.sublist(0, limit) : hits;
}

/// Sealed items, for the "future" hub (shown as locked placeholders).
List<SearchHit> sealedPlaceholders(Iterable<LaterItem> items, DateTime now) => [
      for (final i in items)
        if (i.isLockedAt(now))
          SearchHit(
            kind: HitKind.item,
            id: i.id,
            title: '',
            type: i.type,
            locked: true,
            unlockAt: i.unlockAt,
          ),
    ];
