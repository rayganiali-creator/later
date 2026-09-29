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
  }) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), fileName);
    final clock = now ?? DateTime.now;
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
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
    // 1: (db) async { await db.execute('ALTER TABLE items ADD COLUMN ...'); },
  };

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
  source TEXT
)''');
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
  }

  Future<void> close() => db.close();

  /// Deletes every user table row and re-seeds built-in categories.
  Future<void> wipe(DateTime now) async {
    await db.transaction((txn) async {
      await txn.delete('items');
      await txn.delete('events');
      await txn.delete('categories');
      await txn.delete('settings');
      for (final c in BuiltinCategories.create(now)) {
        await txn.insert('categories', c.toDb());
      }
    });
  }
}
