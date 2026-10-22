import 'dart:math';

import '../core/util/dates.dart';
import 'models.dart';
import 'search_filter_sort.dart';

/// Available time choices for Smart Pick. `null` = "doesn't matter".
const List<int?> smartPickMinuteOptions = [5, 15, 30, 60, null];

class PickOptions {
  const PickOptions({
    this.availableMinutes,
    this.excludeIds = const {},
    this.advanced = false,
    this.categoryId,
    this.limit = 1,
  });

  final int? availableMinutes;
  final Set<String> excludeIds;

  /// Pro: also weighs priority and how often an item was snoozed and can be
  /// restricted to one category.
  final bool advanced;
  final String? categoryId;
  final int limit;
}

class ScoredItem {
  const ScoredItem(this.item, this.score);
  final LaterItem item;
  final double score;
}

/// Local, explainable "what should I do now?" engine. No network, no ML:
/// a weighted score plus a little randomness so the same item is not always
/// suggested.
class SmartPicker {
  SmartPicker({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  /// Items whose estimated duration is unknown are assumed to fit any window
  /// of at least this many minutes.
  static const int unknownDurationMinutes = 15;

  double score(LaterItem i, DateTime now, PickOptions o) {
    var s = 0.0;

    // Age: gently favors things that have waited longer (caps at 60 days).
    final age = daysWaiting(i, now);
    s += min(age / 30.0, 2.0);

    // Due date.
    if (isOverdue(i, now)) {
      s += 3.5;
    } else if (isDueToday(i, now)) {
      s += 4.0;
    } else {
      final due = effectiveDue(i, now);
      if (due != null) {
        final d = Dates.daysBetween(now, due);
        if (d <= 3) {
          s += 2.0;
        } else if (d <= 7) {
          s += 1.0;
        } else {
          s -= 1.0; // deliberately planned for later
        }
      }
    }

    // Fit to the time the user has.
    final avail = o.availableMinutes;
    if (avail != null) {
      final est = i.estimatedMinutes;
      if (est == null) {
        s += avail >= unknownDurationMinutes ? 0.5 : -0.5;
      } else {
        // Prefer items that use a good part of the window.
        final ratio = est / avail;
        s += 2.0 + ratio;
      }
    }

    if (o.advanced) {
      switch (i.priority) {
        case ItemPriority.high:
          s += 3.0;
        case ItemPriority.normal:
          s += 1.0;
        case ItemPriority.low:
          s += 0.0;
      }
      // Items snoozed repeatedly get a gentle nudge: decide or drop.
      s += min(i.snoozeCount, 4) * 0.5;
    }

    return s;
  }

  bool _eligible(LaterItem i, DateTime now, PickOptions o) {
    if (!i.isActive) return false;
    if (o.excludeIds.contains(i.id)) return false;
    if (o.advanced && o.categoryId != null && i.categoryId != o.categoryId) {
      return false;
    }
    final avail = o.availableMinutes;
    if (avail != null) {
      final est = i.estimatedMinutes;
      if (est != null && est > avail) return false;
      if (est == null && avail < 5) return false;
    }
    return true;
  }

  /// Returns up to [PickOptions.limit] suggestions, best first.
  List<ScoredItem> pick(Iterable<LaterItem> items, DateTime now, PickOptions o) {
    final scored = <ScoredItem>[];
    for (final i in items) {
      if (!_eligible(i, now, o)) continue;
      scored.add(ScoredItem(i, score(i, now, o) + _rng.nextDouble() * 1.5));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(o.limit).toList(growable: false);
  }
}
