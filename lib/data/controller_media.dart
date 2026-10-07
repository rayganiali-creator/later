part of 'controller.dart';

/// Pictures and the media shelves (apps, podcasts, courses, games). Kept in
/// its own file so the controller stays readable; it shares the controller's
/// private state because it is part of the same library.
extension LaterMedia on LaterController {
  // ================================================================ pictures

  /// Pictures of an item, oldest first.
  List<Attachment> imagesOf(String itemId) => [
        for (final a in _attachments)
          if (a.itemId == itemId && a.role == AttachmentRole.image) a
      ];

  /// The picture shown in lists: the chosen cover, else the first one.
  String? coverImageId(LaterItem i) {
    final c = i.coverId;
    final imgs = imagesOf(i.id);
    if (imgs.isEmpty) return null;
    if (c != null && imgs.any((a) => a.id == c)) return c;
    return imgs.first.id;
  }

  Map<String, Attachment> get _thumbs {
    if (_thumbIndex == null || _thumbIndexRev != _rev) {
      _thumbIndex = {
        for (final a in _attachments)
          if (a.role == AttachmentRole.thumb && a.ref != null) a.ref!: a
      };
      _thumbIndexRev = _rev;
    }
    return _thumbIndex!;
  }

  Attachment? thumbOfImage(String imageId) => _thumbs[imageId];

  /// Small preview bytes of a picture (cached; thumbnails never change).
  Future<Uint8List?> thumbBytes(String imageId) async {
    final t = thumbOfImage(imageId);
    final id = t?.id ?? imageId;
    final hit = _thumbCache[id];
    if (hit != null) return hit;
    final b = await attachmentStore.read(id);
    if (b != null) {
      if (_thumbCache.length > 300) _thumbCache.remove(_thumbCache.keys.first);
      _thumbCache[id] = b;
    }
    return b;
  }

  Future<Uint8List?> imageBytes(String imageId) => attachmentStore.read(imageId);

  int get imageLimit =>
      access.has(ProFeature.galleryImages) ? ProLimits.proImagesPerItem : ProLimits.freeImagesPerItem;

  bool canAddImage(String itemId) => imagesOf(itemId).length < imageLimit;

  /// Shrinks and validates a picked picture (no storage yet).
  Future<ProcessedImage> processImage(Uint8List source) => imageProcessor.process(source);

  /// Stores a processed picture for [itemId]. The first one becomes the cover.
  Future<Attachment> attachProcessed(String itemId, ProcessedImage p, {String name = 'photo'}) async {
    final item = itemById(itemId);
    if (item == null) throw StateError('no item');
    if (!canAddImage(itemId)) throw StateError('limit');
    final n = now();
    final id = newId();
    final tid = newId();
    final img = Attachment(
      id: id,
      itemId: itemId,
      name: '${cleanText(name, 60).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.jpg',
      mime: 'image/jpeg',
      size: p.full.length,
      createdAt: n,
      role: AttachmentRole.image,
    );
    final th = Attachment(
      id: tid,
      itemId: itemId,
      name: 'thumb.jpg',
      mime: 'image/jpeg',
      size: p.thumb.length,
      createdAt: n,
      role: AttachmentRole.thumb,
      ref: id,
    );
    await attachmentStore.write(id, p.full);
    await attachmentStore.write(tid, p.thumb);
    await repo.upsertAttachment(img);
    await repo.upsertAttachment(th);
    _attachments = [..._attachments, img, th];
    final first = imagesOf(itemId).length == 1;
    if (first || item.coverId == null) {
      final upd = item.withExtra('cover', id).copyWith(updatedAt: n);
      await repo.upsertItem(upd);
      _replace(upd);
    }
    _afterItemsChanged();
    return img;
  }

  /// Picks (gallery or camera), processes and stores a picture in one go.
  Future<Attachment?> addImageFrom(String itemId, ImageOrigin origin) async {
    final bytes = await imagePicker.pick(origin);
    if (bytes == null) return null;
    final p = await processImage(bytes);
    return attachProcessed(itemId, p);
  }

  Future<void> setCover(String itemId, String imageId) async {
    final item = itemById(itemId);
    if (item == null || !imagesOf(itemId).any((a) => a.id == imageId)) return;
    final upd = item.withExtra('cover', imageId).copyWith(updatedAt: now());
    await repo.upsertItem(upd);
    _replace(upd);
    _afterItemsChanged();
  }

  Future<void> removeImage(String imageId) async {
    final img = _attachments.where((a) => a.id == imageId && a.role == AttachmentRole.image).firstOrNull;
    if (img == null) return;
    final doomed = [
      img,
      ..._attachments.where((a) => a.role == AttachmentRole.thumb && a.ref == imageId),
    ];
    for (final a in doomed) {
      await attachmentStore.delete(a.id);
      await repo.deleteAttachment(a.id);
      _thumbCache.remove(a.id);
    }
    _attachments = _attachments.where((a) => !doomed.any((d) => d.id == a.id)).toList();
    final item = itemById(img.itemId);
    if (item != null && item.coverId == imageId) {
      final rest = imagesOf(item.id);
      final upd = (rest.isEmpty ? item.withExtra('cover', null) : item.withExtra('cover', rest.first.id))
          .copyWith(updatedAt: now());
      await repo.upsertItem(upd);
      _replace(upd);
    }
    _afterItemsChanged();
  }

  // ======================================================== shared helpers

  static const _platformIds = {'android', 'windows', 'macos', 'linux', 'ios', 'web', 'other'};
  static const _levels = {'beginner', 'intermediate', 'advanced'};

  /// Cleans the type-specific fields of an item before it is saved.
  LaterItem _sanitizeExtra(LaterItem i) {
    if (i.extra.isEmpty) return i;
    final e = Map<String, Object?>.from(i.extra);
    String? str(String k, int max) {
      final v = e[k];
      if (v is! String) return null;
      final c = cleanText(v, max);
      return c.isEmpty ? null : c;
    }

    for (final k in const ['creator', 'show', 'genre']) {
      final v = str(k, 200);
      v == null ? e.remove(k) : e[k] = v;
    }
    final g = str('goal', 500);
    g == null ? e.remove('goal') : e['goal'] = g;
    if (!_levels.contains(e['level'])) e.remove('level');
    final plats = (e['platforms'] is List ? (e['platforms'] as List).whereType<String>() : const <String>[])
        .where(_platformIds.contains)
        .toSet()
        .toList();
    final maxPlat = access.has(ProFeature.appTools) ? _platformIds.length : ProLimits.maxPlatformsFree;
    if (plats.isEmpty) {
      e.remove('platforms');
    } else {
      e['platforms'] = plats.take(maxPlat).toList();
    }
    if (e['progress'] is num) e['progress'] = (e['progress'] as num).toInt().clamp(0, 100);
    for (final k in const ['durationSec', 'positionSec']) {
      final v = e[k];
      if (v is num && v >= 0 && v < 60 * 60 * 24 * 30) {
        e[k] = v.toInt();
      } else {
        e.remove(k);
      }
    }
    return i.copyWith(extra: e);
  }

  // ================================================================== apps

  /// Platforms a program is for. Free keeps one, Pro any number.
  Future<void> setPlatforms(String id, List<String> platforms) async {
    final cur = itemById(id);
    if (cur == null) return;
    await update(cur.withExtra('platforms', platforms));
  }

  /// "Do I still need this app?" — four honest answers.
  Future<void> answerAppReview(String id, AppAnswer a) async {
    final cur = itemById(id);
    if (cur == null) return;
    final n = now();
    switch (a) {
      case AppAnswer.installed:
        await setStage(id, ItemStages.installed);
      case AppAnswer.still:
        final r = Transitions.review(cur, n);
        await _commit(cur, Transition(Transitions.track(r.item.copyWith(stage: ItemStages.wantInstall), n), r.event));
      case AppAnswer.later:
        // Ask again in a week, not at the usual interval.
        final back = max(0, _settings.staleDays - 7);
        final r = Transitions.review(cur, n);
        await _commit(
            cur, Transition(r.item.copyWith(lastKeptAt: n.subtract(Duration(days: back)), lastReviewedAt: n), r.event));
      case AppAnswer.no:
        await setStage(id, ItemStages.appNotWanted);
    }
  }

  // ============================================================== podcasts

  /// Sets progress by percent or by position (seconds); keeps both in sync
  /// when the length is known, and moves the status along.
  Future<void> setProgress(String id, {int? percent, int? positionSec}) async {
    final cur = itemById(id);
    if (cur == null) return;
    var item = cur;
    final dur = cur.durationSec;
    if (positionSec != null) {
      var pos = positionSec.clamp(0, dur ?? positionSec);
      item = item.withExtra('positionSec', pos);
      if (dur != null && dur > 0) percent = (pos * 100 / dur).round();
    }
    if (percent != null) {
      final p = percent.clamp(0, 100);
      item = item.withExtra('progress', p);
      if (positionSec == null) {
        item = dur != null && dur > 0 ? item.withExtra('positionSec', (dur * p / 100).round()) : item;
      }
    }
    final n = now();
    final p = item.progress;
    if (p >= 100) {
      await _commit(cur, Transitions.setStage(item, ItemStages.doneStage(cur.type), n));
      return;
    }
    if (p > 0 && cur.stage == (cur.type == ItemType.course ? ItemStages.learnLater : ItemStages.notListened)) {
      await _commit(cur, Transitions.setStage(item, ItemStages.activeStage(cur.type)!, n));
      return;
    }
    await repo.upsertItem(item.copyWith(updatedAt: n));
    _replace(item.copyWith(updatedAt: n));
    _afterItemsChanged();
  }

  /// Episodes (and courses) the user is in the middle of, most recent first.
  List<LaterItem> inProgress(ItemType t) {
    final stages = {ItemStages.activeStage(t), if (t == ItemType.podcast) ItemStages.listenPaused};
    if (t == ItemType.course) stages.add(ItemStages.learnPaused);
    if (t == ItemType.game) stages.add(ItemStages.playPaused);
    final l = [
      for (final i in activeItems)
        if (i.type == t && stages.contains(i.stage)) i
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return l;
  }

  /// Pro: the next episodes to listen to, for the time the user has.
  List<LaterItem> podcastQueue({int? minutes}) {
    final l = [
      for (final i in activeItems)
        if (i.type == ItemType.podcast &&
            (minutes == null || i.estimatedMinutes == null || i.estimatedMinutes! <= minutes))
          i
    ];
    int rank(LaterItem i) => i.stage == ItemStages.listening ? 0 : (i.stage == ItemStages.listenPaused ? 1 : 2);
    l.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      final p = b.priority.index.compareTo(a.priority.index);
      if (p != 0) return p;
      return (a.estimatedMinutes ?? 1 << 20).compareTo(b.estimatedMinutes ?? 1 << 20);
    });
    return l;
  }

  // ======================================================== courses / games

  /// Logs a study or play session (Pro).
  Future<bool> logSession(String id, int minutes, {DateTime? at}) async {
    final cur = itemById(id);
    if (cur == null || minutes <= 0 || minutes > 24 * 60) return false;
    if (cur.type == ItemType.course && !access.has(ProFeature.learnTools)) return false;
    if (cur.type == ItemType.game && !access.has(ProFeature.gameTools)) return false;
    if (cur.type != ItemType.course && cur.type != ItemType.game) return false;
    final when = at ?? now();
    final list = [
      for (final s in cur.sessions) [s.$1.millisecondsSinceEpoch, s.$2],
      [when.millisecondsSinceEpoch, minutes],
    ];
    final cut = list.length > 2000 ? list.sublist(list.length - 2000) : list;
    var item = cur.withExtra('sessions', cut);
    // Working on it means it is in progress.
    if (cur.stage == ItemStages.learnLater || cur.stage == ItemStages.wantPlay) {
      await _commit(cur, Transitions.setStage(item, ItemStages.activeStage(cur.type)!, now()));
    } else {
      await update(item);
    }
    return true;
  }

  /// Pro: goal date and weekly target for a course.
  Future<void> setLearnGoal(String id, {String? goal, DateTime? goalDate, int? weeklyMinutes}) async {
    final cur = itemById(id);
    if (cur == null || cur.type != ItemType.course) return;
    var item = cur;
    if (goal != null) item = item.withExtra('goal', goal.trim().isEmpty ? null : goal);
    if (access.has(ProFeature.learnTools)) {
      item = item.withExtra('goalDate', goalDate?.millisecondsSinceEpoch);
      item = item.withExtra('weeklyGoal', weeklyMinutes != null && weeklyMinutes > 0 ? weeklyMinutes : null);
    }
    await update(item);
  }

  SessionStats sessionStatsFor(ItemType t) =>
      sessionStats(_items, now(), weekStart: _settings.weekStart, type: t);

  /// Genres the user has among games that are still open.
  List<String> gameGenres() {
    final s = <String>{
      for (final i in activeItems)
        if (i.type == ItemType.game && i.genre.trim().isNotEmpty) i.genre.trim()
    };
    return s.toList()..sort();
  }

  GameOptions gameOptions({int? minutes, ItemPriority? priority, String? genre, Set<int>? stages}) {
    final pro = access.has(ProFeature.gameTools);
    return GameOptions(
      minutes: pro ? minutes : null,
      priority: pro ? priority : null,
      genre: pro ? genre : null,
      stages: pro ? stages : null,
      recentIds: List.of(_recentGames),
      recentGenres: List.of(_recentGenres),
      smart: pro,
    );
  }

  /// "What should I play today?" Free: a fair random draw. Pro: filters by
  /// time, genre, priority and status, and keeps the genres varied.
  Future<LaterItem?> pickGameNow({GameOptions? options}) async {
    final o = options ?? gameOptions();
    final g = gamePicker.pick(activeItems, o);
    if (g == null) return null;
    _recentGames.add(g.id);
    while (_recentGames.length > 3) {
      _recentGames.removeAt(0);
    }
    if (g.genre.isNotEmpty) {
      _recentGenres.add(g.genre);
      while (_recentGenres.length > 2) {
        _recentGenres.removeAt(0);
      }
    }
    await repo.addEvent(ItemEvent(itemId: g.id, type: EventType.spun, at: now(), categoryId: g.categoryId));
    return g;
  }

  // ================================================================ widgets

  WidgetPick? get widgetSuggestion => widgetPick(_items, now());

  Map<String, int> widgetCounts() {
    final d = dashboardCounts();
    return {
      'inbox': d.inbox,
      'today': d.today,
      'learn': d.courses,
      'podcasts': d.podcasts,
      'games': d.games,
      'wishlist': d.wishlist,
      'ideas': d.ideas,
      'read': d.read,
      'watch': d.watch,
      'apps': d.apps,
    };
  }
}

enum AppAnswer { installed, still, later, no }
