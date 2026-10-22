import 'dart:math';

import '../core/util/dates.dart';
import 'models.dart';
import 'search_filter_sort.dart';

/// Options for one spin.
class RouletteOptions {
  const RouletteOptions({
    this.availableMinutes,
    this.categoryIds,
    this.priority,
    this.energy,
    this.recentIds = const [],
    this.excludeIds = const {},
  });

  /// Pro: only items that fit this many minutes.
  final int? availableMinutes;

  /// Categories allowed into the roulette (null/empty = all).
  final Set<String>? categoryIds;

  /// Pro: only this priority.
  final ItemPriority? priority;

  /// Pro: how much energy the user has right now.
  final RouletteEnergy? energy;

  /// Recently drawn ids: avoided unless nothing else is left.
  final List<String> recentIds;
  final Set<String> excludeIds;
}

enum RouletteEnergy { low, high }

/// Weighted random pick ("قرعه بعداً"). Unlike Smart Pick (best score wins),
/// every eligible item has a chance proportional to its weight, so the result
/// is never predictable and never always the same item.
class Roulette {
  Roulette({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  /// Item types that can be "done right now".
  static const doableTypes = {
    ItemType.task,
    ItemType.read,
    ItemType.watch,
    ItemType.person,
    ItemType.podcast,
    ItemType.course,
    ItemType.game,
  };

  bool eligible(LaterItem i, DateTime now, RouletteOptions o) {
    if (!i.isActive || !doableTypes.contains(i.type)) return false;
    if (i.isLockedAt(now)) return false;
    if (o.excludeIds.contains(i.id)) return false;
    final cats = o.categoryIds;
    if (cats != null && cats.isNotEmpty && !cats.contains(i.categoryId)) return false;
    if (o.priority != null && i.priority != o.priority) return false;
    final avail = o.availableMinutes;
    if (avail != null && i.estimatedMinutes != null && i.estimatedMinutes! > avail) return false;
    return true;
  }

  double weight(LaterItem i, DateTime now, RouletteOptions o) {
    var w = 1.0;
    w *= switch (i.priority) {
      ItemPriority.high => 3.0,
      ItemPriority.normal => 1.5,
      ItemPriority.low => 0.7,
    };
    final due = effectiveDue(i, now);
    if (due != null) {
      if (isOverdue(i, now)) {
        w *= 2.5;
      } else {
        final d = Dates.daysBetween(now, due);
        if (d <= 0) {
          w *= 3.0;
        } else if (d <= 3) {
          w *= 1.8;
        } else if (d > 14) {
          w *= 0.5;
        }
      }
    }
    // Things that have waited a long time get a bigger share (capped).
    final age = daysWaiting(i, now);
    w *= 1 + (age / 30).clamp(0, 2) * 0.5;
    // Repeatedly snoozed items get a gentle nudge.
    w *= 1 + i.snoozeCount.clamp(0, 5) * 0.15;

    final est = i.estimatedMinutes;
    final avail = o.availableMinutes;
    if (avail != null && est != null) w *= 1.4;
    switch (o.energy) {
      case RouletteEnergy.low:
        if (est == null || est <= 15) {
          w *= 1.5;
        } else if (est >= 45) {
          w *= 0.3;
        }
      case RouletteEnergy.high:
        if (est != null && est >= 30) w *= 1.6;
      case null:
        break;
    }
    return w;
  }

  /// Draws one item, or null if nothing is eligible.
  LaterItem? spin(Iterable<LaterItem> items, DateTime now, RouletteOptions o) {
    var pool = [for (final i in items) if (eligible(i, now, o)) i];
    if (pool.isEmpty) return null;
    if (pool.length > 3 && o.recentIds.isNotEmpty) {
      final fresh = pool.where((i) => !o.recentIds.contains(i.id)).toList();
      if (fresh.isNotEmpty) pool = fresh;
    }
    final weights = [for (final i in pool) weight(i, now, o)];
    final total = weights.fold<double>(0, (a, b) => a + b);
    var r = _rng.nextDouble() * total;
    for (var k = 0; k < pool.length; k++) {
      r -= weights[k];
      if (r <= 0) return pool[k];
    }
    return pool.last;
  }
}
