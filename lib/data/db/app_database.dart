import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/config/app_config.dart';
import '../../domain/models.dart';

/// Opens the SQLite database and owns schema creation & migrations.
///
/// Migration rules (see docs/ARCHITECTURE.md):
///  * bump [AppConfig.dbSchemaVersion],
///  * add a `_migrations[oldVersion]` step that upgrades oldVersion -> +1,
///  * add a test in test/database_test.dart.
/// Steps run inside the upgrade transaction; never edit released steps.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const String fileName = 'later.db';

  /// Opens (or creates) the database. [path] defaults to the app databases
  /// directory; pass [inMemoryPath] (or a temp path) in tests.
  static Future<AppDatabase> open({
    String? path,
    DatabaseFactory? factory,
    DateTime Function()? now,
    bool singleInstance = true,
  }) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), fileName);
    final clock = now ?? DateTime.now;
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        singleInstance: singleInstance,
        version: AppConfig.dbSchemaVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) => _create(db, clock()),
        onUpgrade: (db, oldV, newV) async {
          for (var v = oldV; v < newV; v++) {
            final step = _migrations[v];
            if (step == null) {
              throw StateError('Missing DB migration $v -> ${v + 1}');
            }
            await step(db);
          }
        },
        onDowngrade: (db, oldV, newV) async {
          throw StateError(
              'Database schema $oldV is newer than supported $newV');
        },
      ),
    );
    return AppDatabase._(db);
  }

  /// oldVersion -> migration to oldVersion + 1.
  static final Map<int, Future<void> Function(Database)> _migrations = {
    // v1 -> v2: item types/stages, inbox, sealed items, people, collections,
    // attachments. Every existing row becomes a plain task with defaults.
    1: (db) async {
      const cols = [
        'item_type INTEGER NOT NULL DEFAULT 0',
        'stage INTEGER NOT NULL DEFAULT 0',
        'inbox INTEGER NOT NULL DEFAULT 0',
        'unlock_at INTEGER',
        'person_id TEXT',
        'collection_id TEXT',
        'last_reviewed_at INTEGER',
        "extra TEXT NOT NULL DEFAULT '{}'",
      ];
      for (final c in cols) {
        await db.execute('ALTER TABLE items ADD COLUMN $c');
      }
      await db.execute('CREATE INDEX idx_items_type ON items(item_type)');
      await _createV2Tables(db);
    },
    // v2 -> v3: pictures. Attachments get a role (file / image / thumb) and
    // thumbnails point at the image they preview.
    2: (db) async {
      await _addAttachmentRoles(db);
    },
  };

  static Future<void> _addAttachmentRoles(Database db) async {
    await db.execute("ALTER TABLE attachments ADD COLUMN role TEXT NOT NULL DEFAULT 'file'");
    await db.execute('ALTER TABLE attachments ADD COLUMN ref TEXT');
  }

  static Future<void> _createV2Tables(Database db) async {
    await db.execute('''
CREATE TABLE people (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  contact_uri TEXT,
  note TEXT NOT NULL DEFAULT '',
  group_name TEXT NOT NULL DEFAULT '',
  last_interaction_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
    await db.execute('''
CREATE TABLE interactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  person_id TEXT NOT NULL,
  at INTEGER NOT NULL,
  note TEXT NOT NULL DEFAULT ''
)''');
    await db.execute('CREATE INDEX idx_interactions_person ON interactions(person_id)');
    await db.execute('''
CREATE TABLE collections (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  item_type INTEGER NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
)''');
    await db.execute('''
CREATE TABLE attachments (
  id TEXT PRIMARY KEY,
  item_id TEXT NOT NULL,
  name TEXT NOT NULL,
  mime TEXT NOT NULL,
  size INTEGER NOT NULL,
  created_at INTEGER NOT NULL
)''');
    await db.execute('CREATE INDEX idx_attachments_item ON attachments(item_id)');
  }

  static Future<void> _create(Database db, DateTime now) async {
    final batch = db.batch();
    batch.execute('''
CREATE TABLE items (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  note TEXT NOT NULL DEFAULT '',
  category_id TEXT NOT NULL,
  url TEXT,
  tags TEXT NOT NULL DEFAULT '[]',
  priority INTEGER NOT NULL DEFAULT 1,
  est_minutes INTEGER,
  due_at INTEGER,
  has_time INTEGER NOT NULL DEFAULT 0,
  reminder_enabled INTEGER NOT NULL DEFAULT 0,
  reminder_offset_min INTEGER NOT NULL DEFAULT 0,
  repeat_rule INTEGER NOT NULL DEFAULT 0,
  status INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  completed_at INTEGER,
  dropped_at INTEGER,
  snooze_count INTEGER NOT NULL DEFAULT 0,
  last_kept_at INTEGER,
  source TEXT,
  item_type INTEGER NOT NULL DEFAULT 0,
  stage INTEGER NOT NULL DEFAULT 0,
  inbox INTEGER NOT NULL DEFAULT 0,
  unlock_at INTEGER,
  person_id TEXT,
  collection_id TEXT,
  last_reviewed_at INTEGER,
  extra TEXT NOT NULL DEFAULT '{}'
)''');
    batch.execute('CREATE INDEX idx_items_type ON items(item_type)');
    batch.execute('CREATE INDEX idx_items_status ON items(status)');
    batch.execute('CREATE INDEX idx_items_due ON items(due_at)');
    batch.execute('''
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  emoji TEXT NOT NULL,
  builtin INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
)''');
    batch.execute('''
CREATE TABLE events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  item_id TEXT NOT NULL,
  type INTEGER NOT NULL,
  at INTEGER NOT NULL,
  category_id TEXT,
  days_waited INTEGER
)''');
    batch.execute('CREATE INDEX idx_events_type_at ON events(type, at)');
    batch.execute('''
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)''');
    for (final c in BuiltinCategories.create(now)) {
      batch.insert('categories', c.toDb());
    }
    await batch.commit(noResult: true);
    await _createV2Tables(db);
    await _addAttachmentRoles(db);
  }

  Future<void> close() => db.close();

  /// Deletes every user table row and re-seeds built-in categories.
  Future<void> wipe(DateTime now) async {
    await db.transaction((txn) async {
      await txn.delete('items');
      await txn.delete('events');
      await txn.delete('categories');
      await txn.delete('settings');
      await txn.delete('people');
      await txn.delete('interactions');
      await txn.delete('collections');
      await txn.delete('attachments');
      for (final c in BuiltinCategories.create(now)) {
        await txn.insert('categories', c.toDb());
      }
    });
  }
}
