import '../core/util/dates.dart';
import '../core/util/text.dart';
import 'models.dart';

enum FilterKind {
  all,
  today,
  thisWeek,
  noDate,
  overdue,
  highPriority,
  stale,
  category,
}

class ItemFilter {
  const ItemFilter(this.kind, [this.categoryId]);

  static const ItemFilter all = ItemFilter(FilterKind.all);

  final FilterKind kind;
  final String? categoryId;

  @override
  bool operator ==(Object other) =>
      other is ItemFilter &&
      other.kind == kind &&
      other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(kind, categoryId);
}

enum SortMode {
  newest,
  oldest,
  nearestDeadline,
  priority,
  shortest,
  longest,
}

/// Due date as it should be treated *now*: for repeating items the next
/// occurrence on/after today, otherwise the stored date.
DateTime? effectiveDue(LaterItem i, DateTime now) {
  final due = i.dueAt;
  if (due == null) return null;
  if (i.repeat == RepeatRule.none) return due;
  final today = Dates.startOfDay(now);
  var d = due;
  if (!d.isBefore(today)) return d;
  switch (i.repeat) {
    case RepeatRule.daily:
      final n = Dates.daysBetween(d, today);
      return Dates.addDays(d, n);
    case RepeatRule.weekly:
      final n = (Dates.daysBetween(d, today) + 6) ~/ 7;
      return Dates.addDays(d, n * 7);
    case RepeatRule.monthly:
      var k = 0;
      while (d.isBefore(today) && k < 2400) {
        k++;
        d = Dates.addMonths(due, k, CalendarSystem.gregorian);
      }
      return d;
    case RepeatRule.none:
      return d;
  }
}

bool isOverdue(LaterItem i, DateTime now) {
  final due = effectiveDue(i, now);
  if (due == null) return false;
  if (i.hasTime && i.repeat == RepeatRule.none) return due.isBefore(now);
  return due.isBefore(Dates.startOfDay(now));
}

bool isDueToday(LaterItem i, DateTime now) {
  final due = effectiveDue(i, now);
  return due != null && Dates.isSameDay(due, now);
}

bool isDueThisWeek(LaterItem i, DateTime now, int weekStart) {
  final due = effectiveDue(i, now);
  if (due == null) return false;
  final start = Dates.startOfWeek(now, weekStart);
  final end = Dates.addDays(start, 7);
  return !due.isBefore(start) && due.isBefore(end);
}

/// Stale = waiting a long time with no upcoming plan. See product spec
/// "بعداً، نه هیچ‌وقت".
bool isStale(LaterItem i, DateTime now, int staleDays) {
  if (!i.isActive) return false;
  final due = i.dueAt;
  if (due != null && i.repeat == RepeatRule.none && !isOverdue(i, now)) {
    return false; // scheduled in the future
  }
  final anchor = i.lastKeptAt ?? i.createdAt;
  return Dates.daysBetween(anchor, now) >= staleDays;
}

int daysWaiting(LaterItem i, DateTime now) =>
    Dates.daysBetween(i.createdAt, now).clamp(0, 1 << 30);

bool matchesFilter(
  LaterItem i,
  ItemFilter f,
  DateTime now, {
  required int weekStart,
  required int staleDays,
}) {
  switch (f.kind) {
    case FilterKind.all:
      return true;
    case FilterKind.today:
      return isDueToday(i, now);
    case FilterKind.thisWeek:
      return isDueThisWeek(i, now, weekStart);
    case FilterKind.noDate:
      return i.dueAt == null;
    case FilterKind.overdue:
      return isOverdue(i, now);
    case FilterKind.highPriority:
      return i.priority == Priority.high;
    case FilterKind.stale:
      return isStale(i, now, staleDays);
    case FilterKind.category:
      return i.categoryId == f.categoryId;
  }
}

/// Search scope. Basic search (free tier) covers title & description;
/// advanced search (Pro) also covers tags, note, URL and category name.
class SearchQuery {
  SearchQuery(String raw, {this.advanced = false})
      : terms = normalizeForSearch(raw)
            .split(' ')
            .where((t) => t.isNotEmpty)
            .toList(growable: false);

  final List<String> terms;
  final bool advanced;

  bool get isEmpty => terms.isEmpty;
}

/// [categoryName] resolves a category id to its display name (advanced only).
bool matchesSearch(
  LaterItem i,
  SearchQuery q, {
  String Function(String categoryId)? categoryName,
}) {
  if (q.isEmpty) return true;
  final b = StringBuffer()
    ..write(normalizeForSearch(i.title))
    ..write(' ')
    ..write(normalizeForSearch(i.description));
  if (q.advanced) {
    b
      ..write(' ')
      ..write(normalizeForSearch(i.note))
      ..write(' ')
      ..write(normalizeForSearch(i.url ?? ''))
      ..write(' ')
      ..write(normalizeForSearch(i.tags.join(' ')));
    if (categoryName != null) {
      b
        ..write(' ')
        ..write(normalizeForSearch(categoryName(i.categoryId)));
    }
  }
  final hay = b.toString();
  for (final t in q.terms) {
    final term = t.startsWith('#') ? t.substring(1) : t;
    if (!hay.contains(term)) return false;
  }
  return true;
}

int _cmpNullsLast<T extends Comparable>(T? a, T? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

/// Returns a new sorted list; stable for equal keys (falls back to newest).
List<LaterItem> sortItems(Iterable<LaterItem> items, SortMode mode,
    {DateTime? now}) {
  final list = items.toList();
  int byNewest(LaterItem a, LaterItem b) => b.createdAt.compareTo(a.createdAt);
  int Function(LaterItem, LaterItem) cmp;
  switch (mode) {
    case SortMode.newest:
      cmp = byNewest;
    case SortMode.oldest:
      cmp = (a, b) => a.createdAt.compareTo(b.createdAt);
    case SortMode.nearestDeadline:
      cmp = (a, b) {
        final n = now ?? DateTime.now();
        final c = _cmpNullsLast<DateTime>(effectiveDue(a, n), effectiveDue(b, n));
        return c != 0 ? c : byNewest(a, b);
      };
    case SortMode.priority:
      cmp = (a, b) {
        final c = b.priority.index.compareTo(a.priority.index);
        return c != 0 ? c : byNewest(a, b);
      };
    case SortMode.shortest:
      cmp = (a, b) {
        final c = _cmpNullsLast<num>(a.estimatedMinutes, b.estimatedMinutes);
        return c != 0 ? c : byNewest(a, b);
      };
    case SortMode.longest:
      cmp = (a, b) {
        final x = a.estimatedMinutes, y = b.estimatedMinutes;
        if (x == null && y == null) return byNewest(a, b);
        if (x == null) return 1;
        if (y == null) return -1;
        final c = y.compareTo(x);
        return c != 0 ? c : byNewest(a, b);
      };
  }
  list.sort(cmp);
  return list;
}
