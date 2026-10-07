import 'dart:convert';

/// Lifecycle of an item. Values are persisted; never reorder.
enum ItemStatus { active, done, dropped }

/// Values are persisted as their index; never reorder.
enum ItemPriority { low, normal, high }

/// Values are persisted as their index; never reorder.
enum RepeatRule { none, daily, weekly, monthly, yearly }

/// Values are persisted as their index; never reorder (append only).
enum EventType {
  created,
  completed,
  dropped,
  snoozed,
  deleted,
  reopened,
  kept,
  spun,
  unlocked,
  moved,
}

/// What kind of thing an item is. One table, one model, many "shelves".
/// Persisted as index: append only.
enum ItemType { task, read, watch, wishlist, idea, person, capsule, future, app, podcast, course, game }

/// Per-type progress ("stage"). Persisted as an int whose meaning depends on
/// the [ItemType]; [ItemStages] is the single place that knows the mapping
/// between a stage and the generic [ItemStatus].
class ItemStages {
  const ItemStages._();

  // read
  static const unread = 0, reading = 1, read = 2, archived = 3;
  // watch
  static const unwatched = 0, watching = 1, watched = 2;
  // wishlist
  static const interested = 0, maybe = 1, bought = 2, notInterested = 3;
  // idea
  static const ideaNew = 0, thinking = 1, developing = 2, ideaArchived = 3, ideaDropped = 4;
  // capsule / future message
  static const sealed = 0, opened = 1;
  // apps to install later
  static const notInstalled = 0, wantInstall = 1, evaluating = 2, installed = 3, appNotWanted = 4;
  // podcasts
  static const notListened = 0, listening = 1, listenPaused = 2, listened = 3;
  // courses (learn)
  static const learnLater = 0, learning = 1, learnPaused = 2, learned = 3, learnAbandoned = 4;
  // games
  static const wantPlay = 0, playing = 1, playPaused = 2, gameFinished = 3, gameDropped = 4;

  /// All stages of [t] in display order.
  static List<int> of(ItemType t) => switch (t) {
        ItemType.read => const [unread, reading, read, archived],
        ItemType.watch => const [unwatched, watching, watched],
        ItemType.wishlist => const [interested, maybe, bought, notInterested],
        ItemType.idea => const [ideaNew, thinking, developing, ideaArchived, ideaDropped],
        ItemType.capsule || ItemType.future => const [sealed, opened],
        ItemType.app => const [notInstalled, wantInstall, evaluating, installed, appNotWanted],
        ItemType.podcast => const [notListened, listening, listenPaused, listened],
        ItemType.course => const [learnLater, learning, learnPaused, learned, learnAbandoned],
        ItemType.game => const [wantPlay, playing, playPaused, gameFinished, gameDropped],
        _ => const [0],
      };

  static ItemStatus statusFor(ItemType t, int stage) {
    switch (t) {
      case ItemType.read:
        return stage == read ? ItemStatus.done : (stage == archived ? ItemStatus.dropped : ItemStatus.active);
      case ItemType.watch:
        return stage == watched ? ItemStatus.done : ItemStatus.active;
      case ItemType.wishlist:
        return stage == bought ? ItemStatus.done : (stage == notInterested ? ItemStatus.dropped : ItemStatus.active);
      case ItemType.idea:
        return stage >= ideaArchived ? ItemStatus.dropped : ItemStatus.active;
      case ItemType.capsule:
      case ItemType.future:
        return stage == opened ? ItemStatus.done : ItemStatus.active;
      case ItemType.app:
        return stage == installed ? ItemStatus.done : (stage == appNotWanted ? ItemStatus.dropped : ItemStatus.active);
      case ItemType.podcast:
        return stage == listened ? ItemStatus.done : ItemStatus.active;
      case ItemType.course:
        return stage == learned ? ItemStatus.done : (stage == learnAbandoned ? ItemStatus.dropped : ItemStatus.active);
      case ItemType.game:
        return stage == gameFinished ? ItemStatus.done : (stage == gameDropped ? ItemStatus.dropped : ItemStatus.active);
      default:
        return ItemStatus.active;
    }
  }

  /// Stage to use when the generic "done" button is pressed.
  static int doneStage(ItemType t) => switch (t) {
        ItemType.read => read,
        ItemType.watch => watched,
        ItemType.wishlist => bought,
        ItemType.capsule || ItemType.future => opened,
        ItemType.app => installed,
        ItemType.podcast => listened,
        ItemType.course => learned,
        ItemType.game => gameFinished,
        _ => 0,
      };

  /// Stage to use for "let it go".
  static int dropStage(ItemType t) => switch (t) {
        ItemType.read => archived,
        ItemType.wishlist => notInterested,
        ItemType.idea => ideaDropped,
        ItemType.app => appNotWanted,
        ItemType.course => learnAbandoned,
        ItemType.game => gameDropped,
        _ => 0,
      };

  /// The "in progress" stage of a type (null when it has none).
  static int? activeStage(ItemType t) => switch (t) {
        ItemType.read => reading,
        ItemType.watch => watching,
        ItemType.podcast => listening,
        ItemType.course => learning,
        ItemType.game => playing,
        _ => null,
      };

  /// Types that are "done in a sitting" and can be picked by the roulette.
  static bool isMedia(ItemType t) =>
      t == ItemType.read || t == ItemType.watch || t == ItemType.podcast || t == ItemType.course || t == ItemType.game;
}

class LaterItem {
  const LaterItem({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.note = '',
    this.url,
    this.tags = const [],
    this.priority = ItemPriority.normal,
    this.estimatedMinutes,
    this.dueAt,
    this.hasTime = false,
    this.reminderEnabled = false,
    this.reminderOffsetMinutes = 0,
    this.repeat = RepeatRule.none,
    this.status = ItemStatus.active,
    this.completedAt,
    this.droppedAt,
    this.snoozeCount = 0,
    this.lastKeptAt,
    this.source,
    this.type = ItemType.task,
    this.stage = 0,
    this.inbox = false,
    this.unlockAt,
    this.personId,
    this.collectionId,
    this.lastReviewedAt,
    this.extra = const {},
  });

  final String id;
  final String title;
  final String description;
  final String note;
  final String categoryId;
  final String? url;
  final List<String> tags;
  final ItemPriority priority;
  final int? estimatedMinutes;

  /// Local wall-clock instant of the due date. When [hasTime] is false only
  /// the calendar day is meaningful (time part is 00:00).
  final DateTime? dueAt;
  final bool hasTime;
  final bool reminderEnabled;

  /// Minutes *before* the due time the reminder should fire (0 = at due time).
  final int reminderOffsetMinutes;
  final RepeatRule repeat;
  final ItemStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? droppedAt;
  final int snoozeCount;
  final DateTime? lastKeptAt;

  /// Where the item came from ("share", "manual", "widget"...). Informational.
  final String? source;

  /// Which shelf the item lives on.
  final ItemType type;

  /// Type specific progress, see [ItemStages].
  final int stage;

  /// True while the item has not been sorted yet (see the Inbox screen).
  final bool inbox;

  /// Until this instant the item is sealed: hidden from every list, from the
  /// roulette and from notifications (time capsule / future message).
  final DateTime? unlockAt;

  /// Person this item is about (people reminders).
  final String? personId;

  /// Optional user collection (extra wishlists, reading lists...).
  final String? collectionId;
  final DateTime? lastReviewedAt;

  /// Type specific JSON-safe fields (price, watch kind, idea score...).
  final Map<String, Object?> extra;

  bool get isActive => status == ItemStatus.active;

  bool isLockedAt(DateTime now) => unlockAt != null && unlockAt!.isAfter(now);

  // ---- typed accessors for [extra] --------------------------------------
  double? get price => (extra['price'] as num?)?.toDouble();
  String get currency => (extra['currency'] as String?) ?? '';
  double? get targetPrice => (extra['targetPrice'] as num?)?.toDouble();
  String get watchKind => (extra['watchKind'] as String?) ?? 'video';
  int? get score => (extra['score'] as num?)?.toInt();
  List<String> get links =>
      ((extra['links'] as List?) ?? const []).whereType<String>().toList(growable: false);

  // ---- apps / podcasts / courses / games -----------------------------------
  /// Platforms ("android", "windows", ...). Free keeps one, Pro several.
  List<String> get platforms =>
      ((extra['platforms'] as List?) ?? const []).whereType<String>().toList(growable: false);
  String get creator => (extra['creator'] as String?) ?? '';
  String get show => (extra['show'] as String?) ?? '';
  String get genre => (extra['genre'] as String?) ?? '';
  String get goal => (extra['goal'] as String?) ?? '';
  String get level => (extra['level'] as String?) ?? '';
  int? get durationSec => (extra['durationSec'] as num?)?.toInt();

  /// Manual progress, 0..100.
  int get progress => ((extra['progress'] as num?)?.toInt() ?? 0).clamp(0, 100);
  int? get positionSec => (extra['positionSec'] as num?)?.toInt();
  String? get coverId => extra['cover'] as String?;
  DateTime? get goalDate {
    final v = extra['goalDate'];
    return v is num ? DateTime.fromMillisecondsSinceEpoch(v.toInt()) : null;
  }

  int? get weeklyGoalMinutes => (extra['weeklyGoal'] as num?)?.toInt();

  /// Seconds still to go, when the duration is known.
  int? get remainingSec {
    final d = durationSec;
    if (d == null || d <= 0) return null;
    final pos = positionSec ?? (d * progress / 100).round();
    return (d - pos).clamp(0, d);
  }

  /// Study / play sessions logged by the user: [(day, minutes)].
  List<(DateTime, int)> get sessions {
    final raw = extra['sessions'];
    if (raw is! List) return const [];
    final out = <(DateTime, int)>[];
    for (final e in raw) {
      if (e is List && e.length == 2 && e[0] is num && e[1] is num) {
        out.add((DateTime.fromMillisecondsSinceEpoch((e[0] as num).toInt()), (e[1] as num).toInt()));
      }
    }
    return out;
  }

  /// Stage changes: [(when, stage)], newest last.
  List<(DateTime, int)> get stageHistory {
    final raw = extra['history'];
    if (raw is! List) return const [];
    final out = <(DateTime, int)>[];
    for (final e in raw) {
      if (e is List && e.length == 2 && e[0] is num && e[1] is num) {
        out.add((DateTime.fromMillisecondsSinceEpoch((e[0] as num).toInt()), (e[1] as num).toInt()));
      }
    }
    return out;
  }

  /// Price history recorded by the user: [(epochMs, price)].
  List<(DateTime, double)> get priceHistory {
    final raw = extra['priceHistory'];
    if (raw is! List) return const [];
    final out = <(DateTime, double)>[];
    for (final e in raw) {
      if (e is List && e.length == 2 && e[0] is num && e[1] is num) {
        out.add((DateTime.fromMillisecondsSinceEpoch((e[0] as num).toInt()), (e[1] as num).toDouble()));
      }
    }
    return out;
  }

  LaterItem copyWith({
    String? title,
    String? description,
    String? note,
    String? categoryId,
    Object? url = _unset,
    List<String>? tags,
    ItemPriority? priority,
    Object? estimatedMinutes = _unset,
    Object? dueAt = _unset,
    bool? hasTime,
    bool? reminderEnabled,
    int? reminderOffsetMinutes,
    RepeatRule? repeat,
    ItemStatus? status,
    DateTime? updatedAt,
    Object? completedAt = _unset,
    Object? droppedAt = _unset,
    int? snoozeCount,
    Object? lastKeptAt = _unset,
    Object? source = _unset,
    ItemType? type,
    int? stage,
    bool? inbox,
    Object? unlockAt = _unset,
    Object? personId = _unset,
    Object? collectionId = _unset,
    Object? lastReviewedAt = _unset,
    Map<String, Object?>? extra,
  }) {
    return LaterItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      url: identical(url, _unset) ? this.url : url as String?,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      estimatedMinutes: identical(estimatedMinutes, _unset)
          ? this.estimatedMinutes
          : estimatedMinutes as int?,
      dueAt: identical(dueAt, _unset) ? this.dueAt : dueAt as DateTime?,
      hasTime: hasTime ?? this.hasTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderOffsetMinutes: reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      repeat: repeat ?? this.repeat,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: identical(completedAt, _unset) ? this.completedAt : completedAt as DateTime?,
      droppedAt: identical(droppedAt, _unset) ? this.droppedAt : droppedAt as DateTime?,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      lastKeptAt: identical(lastKeptAt, _unset) ? this.lastKeptAt : lastKeptAt as DateTime?,
      source: identical(source, _unset) ? this.source : source as String?,
      type: type ?? this.type,
      stage: stage ?? this.stage,
      inbox: inbox ?? this.inbox,
      unlockAt: identical(unlockAt, _unset) ? this.unlockAt : unlockAt as DateTime?,
      personId: identical(personId, _unset) ? this.personId : personId as String?,
      collectionId: identical(collectionId, _unset) ? this.collectionId : collectionId as String?,
      lastReviewedAt: identical(lastReviewedAt, _unset) ? this.lastReviewedAt : lastReviewedAt as DateTime?,
      extra: extra ?? this.extra,
    );
  }

  /// Returns a copy with one [extra] key set (null removes it).
  LaterItem withExtra(String key, Object? value) {
    final m = Map<String, Object?>.from(extra);
    if (value == null) {
      m.remove(key);
    } else {
      m[key] = value;
    }
    return copyWith(extra: m);
  }

  Map<String, Object?> toDb() => {
        'id': id,
        'title': title,
        'description': description,
        'note': note,
        'category_id': categoryId,
        'url': url,
        'tags': jsonEncode(tags),
        'priority': priority.index,
        'est_minutes': estimatedMinutes,
        'due_at': dueAt?.millisecondsSinceEpoch,
        'has_time': hasTime ? 1 : 0,
        'reminder_enabled': reminderEnabled ? 1 : 0,
        'reminder_offset_min': reminderOffsetMinutes,
        'repeat_rule': repeat.index,
        'status': status.index,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'completed_at': completedAt?.millisecondsSinceEpoch,
        'dropped_at': droppedAt?.millisecondsSinceEpoch,
        'snooze_count': snoozeCount,
        'last_kept_at': lastKeptAt?.millisecondsSinceEpoch,
        'source': source,
        'item_type': type.index,
        'stage': stage,
        'inbox': inbox ? 1 : 0,
        'unlock_at': unlockAt?.millisecondsSinceEpoch,
        'person_id': personId,
        'collection_id': collectionId,
        'last_reviewed_at': lastReviewedAt?.millisecondsSinceEpoch,
        'extra': jsonEncode(extra),
      };

  factory LaterItem.fromDb(Map<String, Object?> m) {
    DateTime? d(Object? v) => v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);
    List<String> tags = const [];
    try {
      final raw = jsonDecode((m['tags'] as String?) ?? '[]');
      if (raw is List) tags = raw.whereType<String>().toList(growable: false);
    } catch (_) {}
    var extra = <String, Object?>{};
    try {
      final raw = jsonDecode((m['extra'] as String?) ?? '{}');
      if (raw is Map) extra = raw.cast<String, Object?>();
    } catch (_) {}
    return LaterItem(
      id: m['id'] as String,
      title: m['title'] as String,
      description: (m['description'] as String?) ?? '',
      note: (m['note'] as String?) ?? '',
      categoryId: m['category_id'] as String,
      url: m['url'] as String?,
      tags: tags,
      priority: ItemPriority.values[_clamp(m['priority'] as int?, 0, 2, 1)],
      estimatedMinutes: m['est_minutes'] as int?,
      dueAt: d(m['due_at']),
      hasTime: (m['has_time'] as int? ?? 0) == 1,
      reminderEnabled: (m['reminder_enabled'] as int? ?? 0) == 1,
      reminderOffsetMinutes: m['reminder_offset_min'] as int? ?? 0,
      repeat: RepeatRule.values[_clamp(m['repeat_rule'] as int?, 0, RepeatRule.values.length - 1, 0)],
      status: ItemStatus.values[_clamp(m['status'] as int?, 0, 2, 0)],
      createdAt: d(m['created_at'])!,
      updatedAt: d(m['updated_at'])!,
      completedAt: d(m['completed_at']),
      droppedAt: d(m['dropped_at']),
      snoozeCount: m['snooze_count'] as int? ?? 0,
      lastKeptAt: d(m['last_kept_at']),
      source: m['source'] as String?,
      type: ItemType.values[_clamp(m['item_type'] as int?, 0, ItemType.values.length - 1, 0)],
      stage: m['stage'] as int? ?? 0,
      inbox: (m['inbox'] as int? ?? 0) == 1,
      unlockAt: d(m['unlock_at']),
      personId: m['person_id'] as String?,
      collectionId: m['collection_id'] as String?,
      lastReviewedAt: d(m['last_reviewed_at']),
      extra: extra,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LaterItem && other.id == id && other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, updatedAt);
}

int _clamp(int? v, int lo, int hi, int fallback) {
  if (v == null || v < lo || v > hi) return fallback;
  return v;
}

const Object _unset = Object();

class ItemCategory {
  const ItemCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.sortOrder,
    this.builtin = false,
    required this.createdAt,
  });

  final String id;

  /// Display name. For [builtin] categories this is empty and the UI looks up
  /// the localized name by [id].
  final String name;
  final String emoji;
  final bool builtin;
  final int sortOrder;
  final DateTime createdAt;

  Map<String, Object?> toDb() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'builtin': builtin ? 1 : 0,
        'sort_order': sortOrder,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory ItemCategory.fromDb(Map<String, Object?> m) => ItemCategory(
        id: m['id'] as String,
        name: m['name'] as String,
        emoji: m['emoji'] as String,
        builtin: (m['builtin'] as int? ?? 0) == 1,
        sortOrder: m['sort_order'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );

  ItemCategory copyWith({String? name, String? emoji, int? sortOrder}) =>
      ItemCategory(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        builtin: builtin,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );
}

/// Built-in category ids (stable, persisted, referenced by localization).
class BuiltinCategories {
  const BuiltinCategories._();

  static const work = 'work';
  static const read = 'read';
  static const watch = 'watch';
  static const buy = 'buy';
  static const idea = 'idea';
  static const link = 'link';
  static const people = 'people';
  static const other = 'other';

  static const ordered = [work, read, watch, buy, idea, link, people, other];

  static const emojis = {
    work: '📌',
    read: '📚',
    watch: '🎬',
    buy: '🛒',
    idea: '💡',
    link: '🔗',
    people: '💬',
    other: '📦',
  };

  static List<ItemCategory> create(DateTime now) => [
        for (var i = 0; i < ordered.length; i++)
          ItemCategory(
            id: ordered[i],
            name: '',
            emoji: emojis[ordered[i]]!,
            builtin: true,
            sortOrder: i,
            createdAt: now,
          ),
      ];
}

/// A history/statistics record. Kept even when the item itself is deleted so
/// aggregate statistics stay correct.
class ItemEvent {
  const ItemEvent({
    this.id,
    required this.itemId,
    required this.type,
    required this.at,
    this.categoryId,
    this.daysWaited,
  });

  final int? id;
  final String itemId;
  final EventType type;
  final DateTime at;
  final String? categoryId;
  final int? daysWaited;

  Map<String, Object?> toDb() => {
        if (id != null) 'id': id,
        'item_id': itemId,
        'type': type.index,
        'at': at.millisecondsSinceEpoch,
        'category_id': categoryId,
        'days_waited': daysWaited,
      };

  factory ItemEvent.fromDb(Map<String, Object?> m) => ItemEvent(
        id: m['id'] as int?,
        itemId: m['item_id'] as String,
        type: EventType.values[_clamp(
            m['type'] as int?, 0, EventType.values.length - 1, 0)],
        at: DateTime.fromMillisecondsSinceEpoch(m['at'] as int),
        categoryId: m['category_id'] as String?,
        daysWaited: m['days_waited'] as int?,
      );
}

/// Someone the user wants to keep in touch with. The address-book entry is
/// only *referenced* (never copied or uploaded): [contactUri] is the system
/// lookup URI returned by the Android contact picker.
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.contactUri,
    this.note = '',
    this.group = '',
    this.lastInteractionAt,
  });

  final String id;
  final String name;
  final String? contactUri;
  final String note;

  /// Free-text group ("family", "work"...). Custom groups are a Pro feature.
  final String group;
  final DateTime? lastInteractionAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Person copyWith({
    String? name,
    Object? contactUri = _unset,
    String? note,
    String? group,
    Object? lastInteractionAt = _unset,
    DateTime? updatedAt,
  }) =>
      Person(
        id: id,
        name: name ?? this.name,
        contactUri: identical(contactUri, _unset) ? this.contactUri : contactUri as String?,
        note: note ?? this.note,
        group: group ?? this.group,
        lastInteractionAt:
            identical(lastInteractionAt, _unset) ? this.lastInteractionAt : lastInteractionAt as DateTime?,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toDb() => {
        'id': id,
        'name': name,
        'contact_uri': contactUri,
        'note': note,
        'group_name': group,
        'last_interaction_at': lastInteractionAt?.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Person.fromDb(Map<String, Object?> m) => Person(
        id: m['id'] as String,
        name: m['name'] as String,
        contactUri: m['contact_uri'] as String?,
        note: (m['note'] as String?) ?? '',
        group: (m['group_name'] as String?) ?? '',
        lastInteractionAt: m['last_interaction_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(m['last_interaction_at'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int),
      );
}

/// One logged contact with a person (Pro: full history).
class Interaction {
  const Interaction({this.id, required this.personId, required this.at, this.note = ''});
  final int? id;
  final String personId;
  final DateTime at;
  final String note;

  Map<String, Object?> toDb() => {
        if (id != null) 'id': id,
        'person_id': personId,
        'at': at.millisecondsSinceEpoch,
        'note': note,
      };

  factory Interaction.fromDb(Map<String, Object?> m) => Interaction(
        id: m['id'] as int?,
        personId: m['person_id'] as String,
        at: DateTime.fromMillisecondsSinceEpoch(m['at'] as int),
        note: (m['note'] as String?) ?? '',
      );
}

/// A named group of items of one type (extra wishlists, reading lists...).
class ItemCollection {
  const ItemCollection({
    required this.id,
    required this.name,
    required this.type,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String name;
  final ItemType type;
  final int sortOrder;
  final DateTime createdAt;

  Map<String, Object?> toDb() => {
        'id': id,
        'name': name,
        'item_type': type.index,
        'sort_order': sortOrder,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory ItemCollection.fromDb(Map<String, Object?> m) => ItemCollection(
        id: m['id'] as String,
        name: m['name'] as String,
        type: ItemType.values[_clamp(m['item_type'] as int?, 0, ItemType.values.length - 1, 0)],
        sortOrder: m['sort_order'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
}

/// A small file attached to a future message (bytes live in private storage).
class Attachment {
  const Attachment({
    required this.id,
    required this.itemId,
    required this.name,
    required this.mime,
    required this.size,
    required this.createdAt,
    this.role = AttachmentRole.file,
    this.ref,
  });

  final String id;
  final String itemId;
  final String name;
  final String mime;
  final int size;
  final DateTime createdAt;

  /// `file` (message attachment), `image` (gallery picture) or `thumb`
  /// (small preview of the image whose id is [ref]).
  final String role;
  final String? ref;

  bool get isImage => mime.startsWith('image/');
  bool get isThumb => role == AttachmentRole.thumb;

  Map<String, Object?> toDb() => {
        'id': id,
        'item_id': itemId,
        'name': name,
        'mime': mime,
        'size': size,
        'created_at': createdAt.millisecondsSinceEpoch,
        'role': role,
        'ref': ref,
      };

  factory Attachment.fromDb(Map<String, Object?> m) => Attachment(
        id: m['id'] as String,
        itemId: m['item_id'] as String,
        name: m['name'] as String,
        mime: (m['mime'] as String?) ?? 'application/octet-stream',
        size: m['size'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        role: (m['role'] as String?) ?? AttachmentRole.file,
        ref: m['ref'] as String?,
      );
}

class AttachmentRole {
  const AttachmentRole._();
  static const file = 'file', image = 'image', thumb = 'thumb';
  static const all = {file, image, thumb};
}
