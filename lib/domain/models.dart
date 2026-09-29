import 'dart:convert';

/// Lifecycle of an item. Values are persisted; never reorder.
enum ItemStatus { active, done, dropped }

/// Values are persisted as their index; never reorder.
enum Priority { low, normal, high }

/// Values are persisted as their index; never reorder.
enum RepeatRule { none, daily, weekly, monthly }

/// Values are persisted as their index; never reorder.
enum EventType { created, completed, dropped, snoozed, deleted, reopened, kept }

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
    this.priority = Priority.normal,
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
  });

  final String id;
  final String title;
  final String description;
  final String note;
  final String categoryId;
  final String? url;
  final List<String> tags;
  final Priority priority;
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

  bool get isActive => status == ItemStatus.active;

  LaterItem copyWith({
    String? title,
    String? description,
    String? note,
    String? categoryId,
    Object? url = _unset,
    List<String>? tags,
    Priority? priority,
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
      reminderOffsetMinutes:
          reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      repeat: repeat ?? this.repeat,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: identical(completedAt, _unset)
          ? this.completedAt
          : completedAt as DateTime?,
      droppedAt: identical(droppedAt, _unset)
          ? this.droppedAt
          : droppedAt as DateTime?,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      lastKeptAt: identical(lastKeptAt, _unset)
          ? this.lastKeptAt
          : lastKeptAt as DateTime?,
      source: identical(source, _unset) ? this.source : source as String?,
    );
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
      };

  factory LaterItem.fromDb(Map<String, Object?> m) {
    DateTime? d(Object? v) =>
        v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);
    List<String> tags = const [];
    try {
      final raw = jsonDecode((m['tags'] as String?) ?? '[]');
      if (raw is List) tags = raw.whereType<String>().toList(growable: false);
    } catch (_) {}
    return LaterItem(
      id: m['id'] as String,
      title: m['title'] as String,
      description: (m['description'] as String?) ?? '',
      note: (m['note'] as String?) ?? '',
      categoryId: m['category_id'] as String,
      url: m['url'] as String?,
      tags: tags,
      priority: Priority.values[_clamp(m['priority'] as int?, 0, 2, 1)],
      estimatedMinutes: m['est_minutes'] as int?,
      dueAt: d(m['due_at']),
      hasTime: (m['has_time'] as int? ?? 0) == 1,
      reminderEnabled: (m['reminder_enabled'] as int? ?? 0) == 1,
      reminderOffsetMinutes: m['reminder_offset_min'] as int? ?? 0,
      repeat: RepeatRule.values[_clamp(m['repeat_rule'] as int?, 0, 3, 0)],
      status: ItemStatus.values[_clamp(m['status'] as int?, 0, 2, 0)],
      createdAt: d(m['created_at'])!,
      updatedAt: d(m['updated_at'])!,
      completedAt: d(m['completed_at']),
      droppedAt: d(m['dropped_at']),
      snoozeCount: m['snooze_count'] as int? ?? 0,
      lastKeptAt: d(m['last_kept_at']),
      source: m['source'] as String?,
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
