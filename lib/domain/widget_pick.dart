import 'models.dart';
import 'search_filter_sort.dart';

enum WidgetPickKind { today, learn, listen, freeTime, game, waiting }

/// The one thing the home-screen widget suggests.
class WidgetPick {
  const WidgetPick(this.kind, this.item);
  final WidgetPickKind kind;
  final LaterItem item;
}

/// Chooses the suggestion from the user's own data, never at random:
/// what is due first, then what is already in progress, then something that
/// fits a free moment. In the evening, leisure shelves come before chores.
WidgetPick? widgetPick(Iterable<LaterItem> items, DateTime now) {
  final active = [for (final i in items) if (i.isActive && !i.isLockedAt(now) && !i.inbox) i];
  if (active.isEmpty) return null;

  LaterItem? firstOf(Iterable<LaterItem> l, [int Function(LaterItem, LaterItem)? cmp]) {
    final list = l.toList();
    if (list.isEmpty) return null;
    if (cmp != null) list.sort(cmp);
    return list.first;
  }

  WidgetPick? due(bool overdueOnly) {
    final l = active.where((i) =>
        (i.type == ItemType.task || i.type == ItemType.person) &&
        (isOverdue(i, now) || (!overdueOnly && isDueToday(i, now))));
    final i = firstOf(l, (a, b) {
      final c = b.priority.index.compareTo(a.priority.index);
      return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
    });
    return i == null ? null : WidgetPick(WidgetPickKind.today, i);
  }

  WidgetPick? learn() {
    final i = firstOf(active.where((i) => i.type == ItemType.course && i.stage == ItemStages.learning),
        (a, b) => b.updatedAt.compareTo(a.updatedAt));
    return i == null ? null : WidgetPick(WidgetPickKind.learn, i);
  }

  WidgetPick? listen() {
    final inProgress = firstOf(
        active.where((i) => i.type == ItemType.podcast && (i.stage == ItemStages.listening || i.stage == ItemStages.listenPaused)),
        (a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (inProgress != null) return WidgetPick(WidgetPickKind.listen, inProgress);
    final short = firstOf(
        active.where((i) => i.type == ItemType.podcast && i.estimatedMinutes != null && i.estimatedMinutes! <= 30),
        (a, b) => a.estimatedMinutes!.compareTo(b.estimatedMinutes!));
    return short == null ? null : WidgetPick(WidgetPickKind.freeTime, short);
  }

  WidgetPick? game() {
    final i = firstOf(
        active.where((i) =>
            i.type == ItemType.game &&
            i.stage != ItemStages.gameFinished &&
            (i.estimatedMinutes == null || i.estimatedMinutes! <= 30)),
        (a, b) => (b.stage == ItemStages.playing ? 1 : 0).compareTo(a.stage == ItemStages.playing ? 1 : 0));
    return i == null ? null : WidgetPick(WidgetPickKind.game, i);
  }

  WidgetPick? waiting() {
    final i = firstOf(
        active.where((i) => ItemStages.isMedia(i.type) || i.type == ItemType.task),
        (a, b) => (a.lastKeptAt ?? a.createdAt).compareTo(b.lastKeptAt ?? b.createdAt));
    return i == null ? null : WidgetPick(WidgetPickKind.waiting, i);
  }

  final evening = now.hour >= 19;
  final order = evening
      ? [() => due(true), game, listen, learn, () => due(false), waiting]
      : [() => due(false), learn, listen, game, waiting];
  for (final f in order) {
    final r = f();
    if (r != null) return r;
  }
  return null;
}
