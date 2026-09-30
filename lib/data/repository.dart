import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';
import '../domain/settings.dart';
import 'db/app_database.dart';

/// Everything the user owns (except Pro entitlement), as plain data.
class LaterSnapshot {
  const LaterSnapshot({
    required this.items,
    required this.categories,
    required this.events,
    required this.settings,
    this.people = const [],
    this.interactions = const [],
    this.collections = const [],
    this.attachments = const [],
    this.attachmentBytes = const {},
  });

  final List<LaterItem> items;
  final List<ItemCategory> categories;
  final List<ItemEvent> events;
  final Map<String, String> settings;
  final List<Person> people;
  final List<Interaction> interactions;
  final List<ItemCollection> collections;
  final List<Attachment> attachments;

  /// Attachment id -> bytes. Only filled when exporting/importing backups
  /// (in normal operation the bytes live in files).
  final Map<String, Uint8List> attachmentBytes;
}

class StatsData {
  const StatsData({
    required this.completed,
    required this.dropped,
    required this.deleted,
    required this.snoozed,
    required this.active,
    required this.avgDaysWaited,
    required this.topCategoryId,
    required this.completedThisWeek,
  });

  final int completed;
  final int dropped;
  final int deleted;
  final int snoozed;
  final int active;
  final double? avgDaysWaited;
  final String? topCategoryId;
  final int completedThisWeek;
}

/// SQLite persistence. All writes are transactional.
class LaterRepository {
  LaterRepository(this._adb);

  final AppDatabase _adb;
  Database get _db => _adb.db;

  // ------------------------------------------------------------------ load

  Future<LaterSnapshot> loadAll() async {
    final items = (await _db.query('items')).map(LaterItem.fromDb).toList();
    final cats = (await _db.query('categories', orderBy: 'sort_order, created_at'))
        .map(ItemCategory.fromDb)
        .toList();
    final events = (await _db.query('events', orderBy: 'id'))
        .map(ItemEvent.fromDb)
        .toList();
    return LaterSnapshot(
      items: items,
      categories: cats,
      events: events,
      settings: await loadSettingsMap(),
      people: (await _db.query('people', orderBy: 'created_at')).map(Person.fromDb).toList(),
      interactions: (await _db.query('interactions', orderBy: 'id')).map(Interaction.fromDb).toList(),
      collections: (await _db.query('collections', orderBy: 'sort_order, created_at'))
          .map(ItemCollection.fromDb)
          .toList(),
      attachments: (await _db.query('attachments', orderBy: 'created_at')).map(Attachment.fromDb).toList(),
    );
  }

  // ---------------------------------------------------------------- people

  Future<void> upsertPerson(Person p) =>
      _db.insert('people', p.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);

  /// Deletes a person, their interaction log; items keep existing but lose the link.
  Future<void> deletePerson(String id) => _db.transaction((txn) async {
        await txn.delete('people', where: 'id = ?', whereArgs: [id]);
        await txn.delete('interactions', where: 'person_id = ?', whereArgs: [id]);
        await txn.update('items', {'person_id': null}, where: 'person_id = ?', whereArgs: [id]);
      });

  Future<int> addInteraction(Interaction i) => _db.insert('interactions', i.toDb());

  Future<List<Interaction>> interactionsOf(String personId) async =>
      (await _db.query('interactions', where: 'person_id = ?', whereArgs: [personId], orderBy: 'at DESC'))
          .map(Interaction.fromDb)
          .toList();

  // ----------------------------------------------------------- collections

  Future<void> upsertCollection(ItemCollection c) =>
      _db.insert('collections', c.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> deleteCollection(String id) => _db.transaction((txn) async {
        await txn.update('items', {'collection_id': null}, where: 'collection_id = ?', whereArgs: [id]);
        await txn.delete('collections', where: 'id = ?', whereArgs: [id]);
      });

  // ----------------------------------------------------------- attachments

  Future<void> upsertAttachment(Attachment a) =>
      _db.insert('attachments', a.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> deleteAttachment(String id) =>
      _db.delete('attachments', where: 'id = ?', whereArgs: [id]);

  Future<List<LaterItem>> loadItems() async =>
      (await _db.query('items')).map(LaterItem.fromDb).toList();

  Future<List<ItemCategory>> loadCategories() async => (await _db
          .query('categories', orderBy: 'sort_order, created_at'))
      .map(ItemCategory.fromDb)
      .toList();

  Future<Map<String, String>> loadSettingsMap() async {
    final rows = await _db.query('settings');
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  Future<AppSettings> loadSettings() async =>
      AppSettings.fromMap(await loadSettingsMap());

  // ----------------------------------------------------------------- items

  Future<void> upsertItem(LaterItem item) => _db.insert(
        'items',
        item.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> upsertItems(Iterable<LaterItem> items) async {
    final b = _db.batch();
    for (final i in items) {
      b.insert('items', i.toDb(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await b.commit(noResult: true);
  }

  Future<void> deleteItem(String id) =>
      _db.delete('items', where: 'id = ?', whereArgs: [id]);

  Future<void> addEvent(ItemEvent e) => _db.insert('events', e.toDb());

  /// Removes the most recent event of [type] for [itemId] (used by undo and
  /// re-open so statistics are not double counted).
  Future<void> removeLastEvent(String itemId, EventType type) => _db.rawDelete(
      'DELETE FROM events WHERE id = (SELECT MAX(id) FROM events WHERE item_id = ? AND type = ?)',
      [itemId, type.index]);

  /// Atomically writes an item change together with its history event.
  Future<void> upsertItemWithEvent(LaterItem item, ItemEvent? event) =>
      _db.transaction((txn) async {
        await txn.insert('items', item.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        if (event != null) await txn.insert('events', event.toDb());
      });

  Future<void> deleteItemWithEvent(String id, ItemEvent? event) =>
      _db.transaction((txn) async {
        await txn.delete('items', where: 'id = ?', whereArgs: [id]);
        if (event != null) await txn.insert('events', event.toDb());
      });

  // ------------------------------------------------------------ categories

  Future<void> upsertCategory(ItemCategory c) => _db.insert(
        'categories',
        c.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  /// Deletes a custom category, moving its items to [fallbackId].
  Future<void> deleteCategory(String id, String fallbackId) =>
      _db.transaction((txn) async {
        await txn.update('items', {'category_id': fallbackId},
            where: 'category_id = ?', whereArgs: [id]);
        await txn.delete('categories', where: 'id = ? AND builtin = 0', whereArgs: [id]);
      });

  // -------------------------------------------------------------- settings

  Future<void> saveSettings(AppSettings s) => saveSettingsMap(s.toMap());

  Future<void> saveSettingsMap(Map<String, String> m) async {
    final b = _db.batch();
    b.delete('settings');
    for (final e in m.entries) {
      b.insert('settings', {'key': e.key, 'value': e.value});
    }
    await b.commit(noResult: true);
  }

  // ---------------------------------------------------------------- events

  Future<List<ItemEvent>> events({int? sinceMs, EventType? type}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (sinceMs != null) {
      where.add('at >= ?');
      args.add(sinceMs);
    }
    if (type != null) {
      where.add('type = ?');
      args.add(type.index);
    }
    final rows = await _db.query('events',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args,
        orderBy: 'at DESC');
    return rows.map(ItemEvent.fromDb).toList();
  }

  Future<StatsData> stats({required int weekStartMs}) async {
    Future<int> count(EventType t) async {
      final r = await _db.rawQuery(
          'SELECT COUNT(*) c FROM events WHERE type = ?', [t.index]);
      return (r.first['c'] as int?) ?? 0;
    }

    final avg = await _db.rawQuery(
        'SELECT AVG(days_waited) a FROM events WHERE type = ? AND days_waited IS NOT NULL',
        [EventType.completed.index]);
    final top = await _db.rawQuery(
        'SELECT category_id c, COUNT(*) n FROM events WHERE type = ? AND category_id IS NOT NULL GROUP BY category_id ORDER BY n DESC, c LIMIT 1',
        [EventType.created.index]);
    final active = await _db.rawQuery(
        'SELECT COUNT(*) c FROM items WHERE status = ?',
        [ItemStatus.active.index]);
    final week = await _db.rawQuery(
        'SELECT COUNT(*) c FROM events WHERE type = ? AND at >= ?',
        [EventType.completed.index, weekStartMs]);
    return StatsData(
      completed: await count(EventType.completed),
      dropped: await count(EventType.dropped),
      deleted: await count(EventType.deleted),
      snoozed: await count(EventType.snoozed),
      active: (active.first['c'] as int?) ?? 0,
      avgDaysWaited: (avg.first['a'] as num?)?.toDouble(),
      topCategoryId: top.isEmpty ? null : top.first['c'] as String?,
      completedThisWeek: (week.first['c'] as int?) ?? 0,
    );
  }

  // --------------------------------------------------------------- restore

  /// Replaces *all* user data in a single transaction. Either everything is
  /// restored or nothing changes.
  Future<void> replaceAll(LaterSnapshot s) => _db.transaction((txn) async {
        await txn.delete('items');
        await txn.delete('events');
        await txn.delete('categories');
        await txn.delete('settings');
        await txn.delete('people');
        await txn.delete('interactions');
        await txn.delete('collections');
        await txn.delete('attachments');
        final b = txn.batch();
        for (final c in s.categories) {
          b.insert('categories', c.toDb());
        }
        for (final p in s.people) {
          b.insert('people', p.toDb());
        }
        for (final i in s.interactions) {
          b.insert('interactions', i.toDb());
        }
        for (final c in s.collections) {
          b.insert('collections', c.toDb());
        }
        for (final a in s.attachments) {
          b.insert('attachments', a.toDb());
        }
        for (final i in s.items) {
          b.insert('items', i.toDb());
        }
        for (final e in s.events) {
          b.insert('events', e.toDb());
        }
        for (final e in s.settings.entries) {
          b.insert('settings', {'key': e.key, 'value': e.value});
        }
        await b.commit(noResult: true);
      });

  Future<void> wipe(DateTime now) => _adb.wipe(now);
}
