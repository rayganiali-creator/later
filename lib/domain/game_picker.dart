import 'dart:math';

import 'models.dart';

/// What the user asked for when pressing "pick a game".
class GameOptions {
  const GameOptions({
    this.minutes,
    this.priority,
    this.genre,
    this.stages,
    this.recentIds = const [],
    this.recentGenres = const [],
    this.smart = false,
  });

  /// Free time the user has right now.
  final int? minutes;
  final ItemPriority? priority;
  final String? genre;

  /// Allowed [ItemStages] (default: want to play, playing, paused).
  final Set<int>? stages;
  final List<String> recentIds;
  final List<String> recentGenres;

  /// Pro: weighs priority, progress, time fit and genre variety. Without it
  /// the pick is a plain fair draw among the candidates.
  final bool smart;
}

class GamePicker {
  GamePicker({Random? random}) : _rng = random ?? Random();
  final Random _rng;

  static const defaultStages = {ItemStages.wantPlay, ItemStages.playing, ItemStages.playPaused};

  bool eligible(LaterItem i, GameOptions o) {
    if (i.type != ItemType.game || !i.isActive) return false;
    if (!(o.stages ?? defaultStages).contains(i.stage)) return false;
    if (o.priority != null && i.priority != o.priority) return false;
    final g = o.genre?.trim().toLowerCase();
    if (g != null && g.isNotEmpty && i.genre.trim().toLowerCase() != g) return false;
    final m = o.minutes;
    // A session longer than the free time does not fit; unknown lengths do.
    if (m != null && i.estimatedMinutes != null && i.estimatedMinutes! > m) return false;
    return true;
  }

  double weight(LaterItem i, GameOptions o) {
    if (!o.smart) return 1;
    var w = switch (i.priority) {
      ItemPriority.high => 3.0,
      ItemPriority.normal => 1.5,
      ItemPriority.low => 0.7,
    };
    if (i.stage == ItemStages.playing) w *= 2;
    if (i.stage == ItemStages.playPaused) w *= 1.4;
    final m = o.minutes, est = i.estimatedMinutes;
    if (m != null && est != null && est >= m * 0.5) w *= 1.5;
    if (i.genre.isNotEmpty && o.recentGenres.contains(i.genre)) w *= 0.4;
    return w;
  }

  /// One game, or null when nothing matches.
  LaterItem? pick(Iterable<LaterItem> items, GameOptions o) {
    var pool = [for (final i in items) if (eligible(i, o)) i];
    if (pool.isEmpty) return null;
    if (pool.length > 2 && o.recentIds.isNotEmpty) {
      final fresh = pool.where((i) => !o.recentIds.contains(i.id)).toList();
      if (fresh.isNotEmpty) pool = fresh;
    }
    final ws = [for (final i in pool) weight(i, o)];
    final total = ws.fold<double>(0, (a, b) => a + b);
    var r = _rng.nextDouble() * total;
    for (var k = 0; k < pool.length; k++) {
      r -= ws[k];
      if (r <= 0) return pool[k];
    }
    return pool.last;
  }
}
