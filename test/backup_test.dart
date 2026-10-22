import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/config/app_config.dart';
import 'package:later/data/backup/backup_codec.dart';
import 'package:later/data/db/app_database.dart';
import 'package:later/data/repository.dart';
import 'package:later/domain/models.dart';
import 'package:later/domain/settings.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers.dart';

LaterSnapshot sampleSnapshot(int n) {
  final cats = BuiltinCategories.create(t0) +
      [ItemCategory(id: 'c_custom', name: 'سفر ✈️', emoji: '✈️', sortOrder: 20, createdAt: t0)];
  final items = <LaterItem>[
    for (var i = 0; i < n; i++)
      item('item$i',
          title: 'مورد شماره $i — with "quotes" & emoji 🎯\nخط دوم',
          category: i % 9 == 8 ? 'c_custom' : BuiltinCategories.ordered[i % 8],
          created: t0.subtract(Duration(days: i % 90, minutes: i)),
          due: i % 3 == 0 ? t0.add(Duration(days: i % 20)) : null,
          hasTime: i % 6 == 0,
          priority: ItemPriority.values[i % 3],
          minutes: i % 4 == 0 ? 5 + i % 50 : null,
          status: ItemStatus.values[i % 10 == 0 ? 1 : (i % 17 == 0 ? 2 : 0)],
          snooze: i % 5,
          tags: i % 2 == 0 ? ['تگ$i', 'x'] : const [],
          description: 'توضیح $i',
          note: 'یادداشت $i',
          url: i % 7 == 0 ? 'https://example.com/p/$i' : null,
          reminder: i % 6 == 0,
          offset: (i % 3) * 10,
          repeat: RepeatRule.values[i % 5]).copyWith(
        type: ItemType.values[i % ItemType.values.length],
        stage: i % 3,
        inbox: i % 11 == 0,
        unlockAt: i % 13 == 0 ? t0.add(const Duration(days: 400)) : null,
        personId: i % 8 == 0 ? 'p1' : null,
        collectionId: i % 9 == 0 ? 'col1' : null,
        lastReviewedAt: i % 4 == 0 ? t0 : null,
        extra: i % 3 == 0
            ? {'price': 1200000 + i, 'currency': 'تومان', 'watchKind': 'movie', 'score': i % 10, 'links': ['item1'], 'priceHistory': [[t0.millisecondsSinceEpoch, 1100000.0]]}
            : const {},
      ),
  ];
  final events = [
    for (var i = 0; i < n; i++)
      ItemEvent(itemId: 'item$i', type: EventType.values[i % EventType.values.length], at: t0.subtract(Duration(hours: i)), categoryId: 'read', daysWaited: i % 30),
  ];
  final att = Attachment(id: 'att1', itemId: 'item1', name: 'a.png', mime: 'image/png', size: 5, createdAt: t0);
  return LaterSnapshot(
    items: items,
    categories: cats,
    events: events,
    settings: const AppSettings(onboardingDone: true, keepHistory: false, staleDays: 45, rouletteCategories: {'read', 'buy'}).toMap(),
    people: [
      Person(id: 'p1', name: 'علی', contactUri: 'content://com.android.contacts/contacts/lookup/abc/1', note: 'دوست', group: 'خانواده', lastInteractionAt: t0, createdAt: t0, updatedAt: t0),
    ],
    interactions: [Interaction(personId: 'p1', at: t0, note: 'تماس')],
    collections: [ItemCollection(id: 'col1', name: 'فهرست دوم', type: ItemType.wishlist, sortOrder: 0, createdAt: t0)],
    attachments: n > 1 ? [att] : const [],
    attachmentBytes: n > 1 ? {'att1': Uint8List.fromList([1, 2, 3, 4, 5])} : const {},
  );
}

void expectSameSnapshot(LaterSnapshot a, LaterSnapshot b, {bool bytes = true}) {
  expect(b.items.length, a.items.length);
  final bm = {for (final i in b.items) i.id: i};
  for (final i in a.items) {
    expect(bm[i.id]!.toDb(), i.toDb(), reason: i.id);
  }
  expect(b.categories.map((c) => c.toDb()).toList()..sort((x, y) => (x['id']! as String).compareTo(y['id']! as String)),
      a.categories.map((c) => c.toDb()).toList()..sort((x, y) => (x['id']! as String).compareTo(y['id']! as String)));
  expect(b.events.length, a.events.length);
  for (var k = 0; k < a.events.length; k++) {
    final x = a.events[k].toDb()..remove('id');
    final y = b.events[k].toDb()..remove('id');
    expect(y, x);
  }
  expect(b.settings, a.settings);
  expect(b.people.map((x) => x.toDb()).toList(), a.people.map((x) => x.toDb()).toList());
  expect(b.interactions.map((x) => (x.toDb()..remove('id'))).toList(), a.interactions.map((x) => (x.toDb()..remove('id'))).toList());
  expect(b.collections.map((x) => x.toDb()).toList(), a.collections.map((x) => x.toDb()).toList());
  expect(b.attachments.map((x) => x.toDb()).toList(), a.attachments.map((x) => x.toDb()).toList());
  if (bytes) expect(b.attachmentBytes.keys.toSet(), a.attachmentBytes.keys.toSet());
}

LaterSnapshot withBytes(LaterSnapshot s, Map<String, Uint8List> bytes) => LaterSnapshot(
      items: s.items,
      categories: s.categories,
      events: s.events,
      settings: s.settings,
      people: s.people,
      interactions: s.interactions,
      collections: s.collections,
      attachments: s.attachments,
      attachmentBytes: bytes,
    );

Uint8List _reencode(Map<String, Object?> doc) => Uint8List.fromList(utf8.encode(jsonEncode(doc)));

void main() {
  sqfliteFfiInit();
  final codec = BackupCodec();

  Uint8List encode(LaterSnapshot s) => codec.encode(s, now: t0, appVersion: '1.0.0');

  group('BackupCodec', () {
    test('round trip preserves every field', () {
      final s = sampleSnapshot(200);
      final d = codec.decode(encode(s));
      expectSameSnapshot(s, d.snapshot);
      expect(d.sourceSchemaVersion, AppConfig.backupSchemaVersion);
      expect(d.createdAt, DateTime.fromMillisecondsSinceEpoch(t0.millisecondsSinceEpoch));
    });

    test('empty backup (no items) is valid and restores built-in categories', () {
      final s = LaterSnapshot(items: const [], categories: const [], events: const [], settings: const {});
      final d = codec.decode(encode(s));
      expect(d.snapshot.items, isEmpty);
      expect(d.snapshot.categories.map((c) => c.id), containsAll(BuiltinCategories.ordered));
    });

    test('zero-byte file', () {
      expect(() => codec.decode(Uint8List(0)),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.empty)));
    });

    test('truncated file', () {
      final b = encode(sampleSnapshot(20));
      expect(() => codec.decode(b.sublist(0, b.length ~/ 2)),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.notJson)));
    });

    test('random garbage / binary', () {
      expect(() => codec.decode(Uint8List.fromList(List.generate(300, (i) => i * 7 % 256))),
          throwsA(isA<BackupException>()));
      expect(() => codec.decode(Uint8List.fromList(utf8.encode('[1,2,3]'))),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.notABackup)));
      expect(() => codec.decode(Uint8List.fromList(utf8.encode('{"hello":1}'))),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.notABackup)));
    });

    test('incomplete: missing sections / fields', () {
      final doc = jsonDecode(utf8.decode(encode(sampleSnapshot(3)))) as Map<String, Object?>;
      final d1 = Map<String, Object?>.from(doc)..remove('data');
      expect(() => codec.decode(_reencode(d1)),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.missingFields)));
      final d2 = Map<String, Object?>.from(doc)..remove('checksum');
      expect(() => codec.decode(_reencode(d2)),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.missingFields)));
    });

    test('edited content fails checksum', () {
      final text = utf8.decode(encode(sampleSnapshot(5))).replaceFirst('شماره 1 ', 'شماره 9 ');
      expect(() => codec.decode(Uint8List.fromList(utf8.encode(text))),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.checksumMismatch)));
    });

    test('future schema version is refused with a clear error', () {
      final doc = jsonDecode(utf8.decode(encode(sampleSnapshot(3)))) as Map<String, Object?>;
      doc['schemaVersion'] = AppConfig.backupSchemaVersion + 1;
      expect(() => codec.decode(_reencode(doc)),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.futureVersion)));
    });

    test('old schema version is migrated (v3 -> v5 chain)', () {
      // Simulates future app versions: schema 3 renamed "title" -> "name" then
      // "name" -> "title" back.
      final migrator = BackupMigrator(target: 5, steps: {
        3: (doc) {
          final data = Map<String, Object?>.from(doc['data']! as Map);
          data['items'] = [
            for (final i in data['items']! as List)
              (Map<String, Object?>.from(i as Map)
                ..['name'] = i['title']
                ..remove('title'))
          ];
          return {...doc, 'data': data};
        },
        4: (doc) {
          final data = Map<String, Object?>.from(doc['data']! as Map);
          data['items'] = [
            for (final i in data['items']! as List)
              (Map<String, Object?>.from(i as Map)
                ..['title'] = i['name']
                ..remove('name'))
          ];
          return {...doc, 'data': data};
        },
      });
      final c = BackupCodec(migrator: migrator);
      final s = sampleSnapshot(10);
      final d = c.decode(encode(s));
      expect(d.sourceSchemaVersion, 3);
      expectSameSnapshot(s, d.snapshot);
    });

    test('missing migration step => unsupportedVersion', () {
      final c = BackupCodec(migrator: BackupMigrator(target: 4, steps: const {}));
      expect(() => c.decode(encode(sampleSnapshot(1))),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.unsupportedVersion)));
    });

    test('throwing migration => migrationFailed', () {
      final c = BackupCodec(migrator: BackupMigrator(target: 4, steps: {3: (d) => throw StateError('boom')}));
      expect(() => c.decode(encode(sampleSnapshot(1))),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.migrationFailed)));
    });

    Uint8List withData(void Function(Map<String, Object?> data) mutate) {
      final doc = jsonDecode(utf8.decode(encode(sampleSnapshot(3)))) as Map<String, Object?>;
      final data = doc['data']! as Map<String, Object?>;
      mutate(data);
      // Recompute checksum so we exercise the *validation*, not the checksum.
      final json = jsonEncode(data);
      doc['checksum'] = _sha(json);
      return _reencode(doc);
    }

    test('malicious content is rejected or sanitized', () {
      // path traversal / weird ids
      expect(() => codec.decode(withData((d) => ((d['items']! as List).first as Map)['id'] = '../../etc/passwd')),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.invalidData)));
      // wrong types
      expect(() => codec.decode(withData((d) => ((d['items']! as List).first as Map)['title'] = 12345)),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.invalidData)));
      expect(() => codec.decode(withData((d) => d['items'] = 'nope')),
          throwsA(isA<BackupException>()));
      // out-of-range enum
      expect(() => codec.decode(withData((d) => ((d['items']! as List).first as Map)['status'] = 99)),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.invalidData)));
      // bad timestamps
      expect(() => codec.decode(withData((d) => ((d['items']! as List).first as Map)['created_at'] = -5)),
          throwsA(isA<BackupException>()));
      // duplicate ids
      expect(() => codec.decode(withData((d) {
            final l = d['items']! as List;
            (l[1] as Map)['id'] = (l[0] as Map)['id'];
          })),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.invalidData)));
      // dangerous URL is dropped, giant text clamped, unknown category re-homed
      final d = codec.decode(withData((d) {
        final m = (d['items']! as List).first as Map;
        m['url'] = 'javascript:alert(1)';
        m['description'] = 'x' * 100000;
        m['category_id'] = 'does_not_exist';
      }));
      final first = d.snapshot.items.first;
      expect(first.url, isNull);
      expect(first.description.length, AppConfig.maxTextLength);
      expect(first.categoryId, BuiltinCategories.other);
    });

    test('oversized file is rejected before parsing', () {
      expect(() => codec.decode(Uint8List(AppConfig.maxBackupBytes + 1)),
          throwsA(isA<BackupException>().having((e) => e.error, 'error', BackupError.tooLarge)));
    });

    test('deeply nested / hostile json does not crash the parser', () {
      final nested = '${'[' * 2000000}${']' * 2000000}';
      expect(() => codec.decode(Uint8List.fromList(utf8.encode(nested))),
          throwsA(isA<BackupException>()));
    });

    test('unknown settings keys and invalid values are dropped', () {
      final d = codec.decode(withData((d) {
        (d['settings']! as Map)['evil'] = 'x';
        (d['settings']! as Map)['weekStart'] = '99';
      }));
      expect(d.snapshot.settings.containsKey('evil'), isFalse);
      expect(d.snapshot.settings['weekStart'], '${DateTime.saturday}');
    });
  });

  group('Backup + database (create -> export -> wipe -> import -> verify)', () {
    late AppDatabase adb;
    late LaterRepository repo;

    setUp(() async {
      adb = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi, now: () => t0, singleInstance: false);
      repo = LaterRepository(adb);
    });
    tearDown(() => adb.close());

    for (final n in [100, 500, 1000, 5000]) {
      test('$n items round trip through SQLite and file', () async {
        final s = sampleSnapshot(n);
        await repo.replaceAll(s);
        final sw = Stopwatch()..start();
        final bytes = encode(withBytes(await repo.loadAll(), s.attachmentBytes));
        final exportMs = sw.elapsedMilliseconds;
        await repo.wipe(t0); // "delete app data"
        expect((await repo.loadItems()), isEmpty);
        sw.reset();
        final decoded = codec.decode(bytes);
        await repo.replaceAll(decoded.snapshot);
        final importMs = sw.elapsedMilliseconds;
        final back = await repo.loadAll();
        expectSameSnapshot(s, back, bytes: false);
        // ignore: avoid_print
        print('n=$n size=${(bytes.length / 1024).toStringAsFixed(0)}KB export=${exportMs}ms import=${importMs}ms');
        expect(exportMs + importMs, lessThan(15000));
      });
    }

    test('duplicate import is idempotent', () async {
      final s = sampleSnapshot(50);
      final bytes = encode(s);
      await repo.replaceAll(codec.decode(bytes).snapshot);
      await repo.replaceAll(codec.decode(bytes).snapshot);
      expectSameSnapshot(s, await repo.loadAll(), bytes: false);
    });

    test('failed restore leaves current data untouched', () async {
      final s = sampleSnapshot(30);
      await repo.replaceAll(s);
      final bad = LaterSnapshot(
        items: [item('dup'), item('dup')], // primary key violation inside txn
        categories: BuiltinCategories.create(t0),
        events: const [],
        settings: const {},
      );
      await expectLater(repo.replaceAll(bad), throwsA(anything));
      expectSameSnapshot(s, await repo.loadAll(), bytes: false);
    });

    test('stats aggregate from events', () async {
      final now = t0;
      await repo.addEvent(ItemEvent(itemId: 'a', type: EventType.created, at: now, categoryId: 'read'));
      await repo.addEvent(ItemEvent(itemId: 'b', type: EventType.created, at: now, categoryId: 'read'));
      await repo.addEvent(ItemEvent(itemId: 'c', type: EventType.created, at: now, categoryId: 'buy'));
      await repo.addEvent(ItemEvent(itemId: 'a', type: EventType.completed, at: now, categoryId: 'read', daysWaited: 4));
      await repo.addEvent(ItemEvent(itemId: 'b', type: EventType.completed, at: now, categoryId: 'read', daysWaited: 6));
      await repo.addEvent(ItemEvent(itemId: 'c', type: EventType.dropped, at: now));
      await repo.addEvent(ItemEvent(itemId: 'c', type: EventType.snoozed, at: now));
      await repo.addEvent(ItemEvent(itemId: 'c', type: EventType.snoozed, at: now));
      await repo.upsertItem(item('x'));
      final st = await repo.stats(weekStartMs: now.subtract(const Duration(days: 3)).millisecondsSinceEpoch);
      expect(st.completed, 2);
      expect(st.dropped, 1);
      expect(st.snoozed, 2);
      expect(st.avgDaysWaited, 5);
      expect(st.topCategoryId, 'read');
      expect(st.active, 1);
      expect(st.completedThisWeek, 2);
    });
  });

  group('Database schema', () {
    test('creates schema v1 with built-in categories', () async {
      final adb = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi, now: () => t0, singleInstance: false);
      final cats = await LaterRepository(adb).loadCategories();
      expect(cats.map((c) => c.id), BuiltinCategories.ordered);
      expect(await adb.db.getVersion(), AppConfig.dbSchemaVersion);
      await adb.close();
    });

    test('persists across reopen (file database)', () async {
      final dir = await databaseFactoryFfi.getDatabasesPath();
      final path = '$dir/test_${DateTime.now().microsecondsSinceEpoch}.db';
      var adb = await AppDatabase.open(path: path, factory: databaseFactoryFfi, now: () => t0);
      await LaterRepository(adb).upsertItem(item('persist'));
      await adb.close();
      adb = await AppDatabase.open(path: path, factory: databaseFactoryFfi, now: () => t0);
      expect((await LaterRepository(adb).loadItems()).single.id, 'persist');
      await adb.close();
      await databaseFactoryFfi.deleteDatabase(path);
    });

    test('refuses to open a database from a newer app version', () async {
      final dir = await databaseFactoryFfi.getDatabasesPath();
      final path = '$dir/future_${DateTime.now().microsecondsSinceEpoch}.db';
      final db = await databaseFactoryFfi.openDatabase(path, options: OpenDatabaseOptions(version: 99));
      await db.close();
      await expectLater(
          AppDatabase.open(path: path, factory: databaseFactoryFfi), throwsA(anything));
      await databaseFactoryFfi.deleteDatabase(path);
    });
  });
}

String _sha(String s) => sha256.convert(utf8.encode(s)).toString();
