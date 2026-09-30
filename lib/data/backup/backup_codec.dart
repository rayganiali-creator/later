import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../core/config/app_config.dart';
import '../../core/util/ids.dart';
import '../../core/util/text.dart';
import '../../domain/models.dart';
import '../../domain/settings.dart';
import '../repository.dart';

enum BackupError {
  empty,
  tooLarge,
  notJson,
  notABackup,
  missingFields,
  futureVersion,
  unsupportedVersion,
  checksumMismatch,
  invalidData,
  migrationFailed,
}

/// Thrown for every problem with a backup file. Never contains user data.
class BackupException implements Exception {
  const BackupException(this.error, [this.detail]);

  final BackupError error;

  /// Technical detail for logs/support (no personal content).
  final String? detail;

  @override
  String toString() => 'BackupException(${error.name}${detail == null ? '' : ': $detail'})';
}

/// A parsed, validated and *migrated* backup, ready to be restored.
class DecodedBackup {
  const DecodedBackup({
    required this.snapshot,
    required this.createdAt,
    required this.sourceSchemaVersion,
    required this.appVersion,
    this.proBlob,
  });

  final LaterSnapshot snapshot;
  final DateTime createdAt;
  final int sourceSchemaVersion;
  final String appVersion;

  /// Raw `pro` section ({entitlement, sig}) if present; verified elsewhere.
  final Map<String, Object?>? proBlob;
}

/// Schema migrations of the backup *envelope*: `migrations[v]` upgrades a
/// document of schema `v` to `v + 1`. Registered steps must be pure.
typedef BackupMigration = Map<String, Object?> Function(Map<String, Object?>);

class BackupMigrator {
  BackupMigrator({Map<int, BackupMigration>? steps, int? target})
      : _steps = steps ?? builtinSteps,
        target = target ?? AppConfig.backupSchemaVersion;

  /// Released migrations. Never edit a released step; add a new one.
  static final Map<int, BackupMigration> builtinSteps = {
    // v1 -> v2: item types, people, collections, attachments were added.
    // Old files simply have none of them: add the empty sections.
    1: (doc) {
      final data = Map<String, Object?>.from(doc['data']! as Map);
      data.putIfAbsent('people', () => <Object?>[]);
      data.putIfAbsent('interactions', () => <Object?>[]);
      data.putIfAbsent('collections', () => <Object?>[]);
      data.putIfAbsent('attachments', () => <Object?>[]);
      return {...doc, 'data': data};
    },
  };

  final Map<int, BackupMigration> _steps;
  final int target;

  /// Upgrades [doc] (whose `schemaVersion` is [from]) to [target].
  Map<String, Object?> migrate(Map<String, Object?> doc, int from) {
    var v = from;
    var cur = doc;
    while (v < target) {
      final step = _steps[v];
      if (step == null) {
        throw BackupException(BackupError.unsupportedVersion, 'no migration $v');
      }
      try {
        cur = step(cur);
      } catch (e) {
        if (e is BackupException) rethrow;
        throw BackupException(BackupError.migrationFailed, 'step $v');
      }
      v++;
      cur['schemaVersion'] = v;
    }
    return cur;
  }
}

/// Encodes/decodes the `.later` backup file (UTF-8 JSON).
///
/// Layout:
/// ```
/// { "format": "later-backup", "schemaVersion": 1, "appVersion": "1.0.0",
///   "createdAt": <epoch ms>, "checksum": "<sha256 of jsonEncode(data)>",
///   "data": { "items": [...], "categories": [...], "events": [...],
///             "settings": {...}, "pro": {...}? } }
/// ```
class BackupCodec {
  BackupCodec({BackupMigrator? migrator})
      : _migrator = migrator ?? BackupMigrator();

  final BackupMigrator _migrator;

  static const int _maxMs = 4102444800000; // 2100-01-01

  Uint8List encode(
    LaterSnapshot s, {
    required DateTime now,
    required String appVersion,
    Map<String, Object?>? proBlob,
  }) {
    final data = <String, Object?>{
      'items': [for (final i in s.items) i.toDb()],
      'categories': [for (final c in s.categories) c.toDb()],
      'events': [
        for (final e in s.events) (e.toDb()..remove('id')),
      ],
      'settings': s.settings,
      'people': [for (final x in s.people) x.toDb()],
      'interactions': [for (final x in s.interactions) (x.toDb()..remove('id'))],
      'collections': [for (final x in s.collections) x.toDb()],
      'attachments': [
        for (final a in s.attachments)
          if (s.attachmentBytes[a.id] != null)
            {...a.toDb(), 'data': base64Encode(s.attachmentBytes[a.id]!)},
      ],
      'pro': ?proBlob,
    };
    final dataJson = jsonEncode(data);
    final checksum = sha256.convert(utf8.encode(dataJson)).toString();
    final doc = <String, Object?>{
      'format': AppConfig.backupFormatId,
      'schemaVersion': AppConfig.backupSchemaVersion,
      'appVersion': appVersion,
      'createdAt': now.millisecondsSinceEpoch,
      'checksum': checksum,
      'data': data,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(doc)));
  }

  DecodedBackup decode(Uint8List bytes, {DateTime? now}) {
    if (bytes.isEmpty) throw const BackupException(BackupError.empty);
    if (bytes.length > AppConfig.maxBackupBytes) {
      throw const BackupException(BackupError.tooLarge);
    }
    _checkNesting(bytes);
    Object? root;
    try {
      root = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const BackupException(BackupError.notJson);
    }
    if (root is! Map) throw const BackupException(BackupError.notABackup);
    if (root['format'] != AppConfig.backupFormatId) {
      throw const BackupException(BackupError.notABackup);
    }
    final version = root['schemaVersion'];
    if (version is! int || version < 1) {
      throw const BackupException(BackupError.missingFields, 'schemaVersion');
    }
    if (version > _migrator.target) {
      throw BackupException(BackupError.futureVersion, '$version');
    }
    final dataRaw = root['data'];
    final checksum = root['checksum'];
    final created = root['createdAt'];
    if (dataRaw is! Map || checksum is! String || created is! int) {
      throw const BackupException(BackupError.missingFields);
    }
    // Integrity first: detects truncated/edited/corrupted files.
    final actual = sha256.convert(utf8.encode(jsonEncode(dataRaw))).toString();
    if (actual != checksum) {
      throw const BackupException(BackupError.checksumMismatch);
    }

    var doc = Map<String, Object?>.from(root.cast<String, Object?>());
    doc['data'] = Map<String, Object?>.from(dataRaw.cast<String, Object?>());
    if (version < _migrator.target) doc = _migrator.migrate(doc, version);

    final data = doc['data'];
    if (data is! Map) throw const BackupException(BackupError.missingFields);
    final LaterSnapshot snapshot;
    try {
      snapshot = _parseData(data.cast<String, Object?>(), now ?? DateTime.now());
    } on BackupException {
      rethrow;
    } catch (_) {
      // Wrong JSON types inside records (e.g. a number where text is expected).
      throw const BackupException(BackupError.invalidData, 'record types');
    }
    final pro = data['pro'];
    return DecodedBackup(
      snapshot: snapshot,
      createdAt: _date(created, 'createdAt'),
      sourceSchemaVersion: version,
      appVersion: cleanText(root['appVersion'] as String?, 40),
      proBlob: pro is Map ? pro.cast<String, Object?>() : null,
    );
  }

  /// Rejects absurdly nested JSON before handing it to the parser (a hostile
  /// file could otherwise exhaust the stack). Legit backups nest < 8 levels.
  static void _checkNesting(Uint8List b) {
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (final c in b) {
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (c == 0x5C) {
          escaped = true;
        } else if (c == 0x22) {
          inString = false;
        }
        continue;
      }
      if (c == 0x22) {
        inString = true;
      } else if (c == 0x5B || c == 0x7B) {
        if (++depth > 32) throw const BackupException(BackupError.notJson, 'nesting');
      } else if (c == 0x5D || c == 0x7D) {
        depth--;
      }
    }
  }

  // --------------------------------------------------------------- parsing

  LaterSnapshot _parseData(Map<String, Object?> d, DateTime now) {
    final itemsRaw = d['items'];
    final catsRaw = d['categories'];
    final eventsRaw = d['events'];
    final settingsRaw = d['settings'];
    if (itemsRaw is! List ||
        catsRaw is! List ||
        eventsRaw is! List ||
        settingsRaw is! Map) {
      throw const BackupException(BackupError.missingFields, 'data sections');
    }
    if (itemsRaw.length > AppConfig.maxItemsInBackup ||
        eventsRaw.length > AppConfig.maxItemsInBackup * 4 ||
        catsRaw.length > 1000) {
      throw const BackupException(BackupError.invalidData, 'too many records');
    }

    final cats = <ItemCategory>[];
    final catIds = <String>{};
    for (final raw in catsRaw) {
      final c = _parseCategory(raw);
      if (!catIds.add(c.id)) {
        throw const BackupException(BackupError.invalidData, 'duplicate category');
      }
      cats.add(c);
    }
    // Ensure every built-in category exists.
    var next = cats.fold<int>(0, (m, c) => c.sortOrder > m ? c.sortOrder : m) + 1;
    for (final b in BuiltinCategories.create(now)) {
      if (catIds.add(b.id)) {
        cats.add(ItemCategory(
          id: b.id, name: '', emoji: b.emoji, builtin: true,
          sortOrder: next++, createdAt: now,
        ));
      }
    }

    final items = <LaterItem>[];
    final itemIds = <String>{};
    for (final raw in itemsRaw) {
      var i = _parseItem(raw);
      if (!itemIds.add(i.id)) {
        throw const BackupException(BackupError.invalidData, 'duplicate item');
      }
      if (!catIds.contains(i.categoryId)) {
        i = i.copyWith(categoryId: BuiltinCategories.other);
      }
      items.add(i);
    }

    final events = <ItemEvent>[];
    for (final raw in eventsRaw) {
      events.add(_parseEvent(raw));
    }

    final settings = <String, String>{};
    for (final e in settingsRaw.entries) {
      if (e.key is String && e.value is String && (e.key as String).length < 64 &&
          (e.value as String).length < 256) {
        settings[e.key as String] = e.value as String;
      }
    }
    // Normalize through the lenient parser: drops unknown keys/invalid values.
    final clean = AppSettings.fromMap(settings).toMap();

    final peopleRaw = d['people'];
    final interRaw = d['interactions'];
    final colRaw = d['collections'];
    final attRaw = d['attachments'];
    if (peopleRaw is! List || interRaw is! List || colRaw is! List || attRaw is! List) {
      throw const BackupException(BackupError.missingFields, 'v2 sections');
    }
    if (peopleRaw.length > 100000 || interRaw.length > 500000 || colRaw.length > 10000 || attRaw.length > 20000) {
      throw const BackupException(BackupError.invalidData, 'too many records');
    }
    final people = <Person>[];
    final personIds = <String>{};
    for (final raw in peopleRaw) {
      final p = _parsePerson(raw);
      if (!personIds.add(p.id)) _bad('duplicate person');
      people.add(p);
    }
    final collections = <ItemCollection>[];
    final colIds = <String>{};
    for (final raw in colRaw) {
      final c = _parseCollection(raw);
      if (!colIds.add(c.id)) _bad('duplicate collection');
      collections.add(c);
    }
    final interactions = <Interaction>[];
    for (final raw in interRaw) {
      final i = _parseInteraction(raw);
      if (personIds.contains(i.personId)) interactions.add(i);
    }
    final attachments = <Attachment>[];
    final bytes = <String, Uint8List>{};
    for (final raw in attRaw) {
      if (raw is! Map) _bad('attachment');
      final a = _parseAttachment(raw);
      final data = raw['data'];
      if (data is! String || data.length > 4 * 1024 * 1024 * 4 ~/ 3 + 16) _bad('attachment.data');
      final b = base64Decode(data);
      if (b.length > 3 * 1024 * 1024) _bad('attachment.size');
      if (!itemIds.contains(a.itemId) || attachments.any((x) => x.id == a.id)) continue;
      attachments.add(Attachment(
          id: a.id, itemId: a.itemId, name: a.name, mime: a.mime, size: b.length, createdAt: a.createdAt));
      bytes[a.id] = b;
    }
    // Drop dangling links instead of failing the whole restore.
    final cleanedItems = [
      for (final i in items)
        i.copyWith(
          personId: i.personId != null && !personIds.contains(i.personId) ? null : i.personId,
          collectionId: i.collectionId != null && !colIds.contains(i.collectionId) ? null : i.collectionId,
        ),
    ];
    return LaterSnapshot(
      items: cleanedItems,
      categories: cats,
      events: events,
      settings: clean,
      people: people,
      interactions: interactions,
      collections: collections,
      attachments: attachments,
      attachmentBytes: bytes,
    );
  }

  Person _parsePerson(Object? raw) {
    if (raw is! Map) _bad('person');
    final id = raw['id'];
    if (id is! String || !isValidId(id)) _bad('person.id');
    final name = cleanText(raw['name'] as String?, 200);
    if (name.isEmpty) _bad('person.name');
    final uri = raw['contact_uri'];
    return Person(
      id: id,
      name: name,
      contactUri: uri is String && uri.startsWith('content://com.android.contacts/') && uri.length < 500 ? uri : null,
      note: cleanText(raw['note'] as String?, AppConfig.maxTextLength),
      group: cleanText(raw['group_name'] as String?, 60),
      lastInteractionAt: _dateOpt(raw['last_interaction_at'], 'person.last'),
      createdAt: _date(raw['created_at'], 'person.created'),
      updatedAt: _date(raw['updated_at'], 'person.updated'),
    );
  }

  Interaction _parseInteraction(Object? raw) {
    if (raw is! Map) _bad('interaction');
    final pid = raw['person_id'];
    if (pid is! String || !isValidId(pid)) _bad('interaction.person');
    return Interaction(
      personId: pid,
      at: _date(raw['at'], 'interaction.at'),
      note: cleanText(raw['note'] as String?, 2000),
    );
  }

  ItemCollection _parseCollection(Object? raw) {
    if (raw is! Map) _bad('collection');
    final id = raw['id'];
    if (id is! String || !isValidId(id)) _bad('collection.id');
    final name = cleanText(raw['name'] as String?, 60);
    if (name.isEmpty) _bad('collection.name');
    final t = _intOpt(raw['item_type'], 0, ItemType.values.length - 1, 'collection.type');
    return ItemCollection(
      id: id,
      name: name,
      type: ItemType.values[t ?? 0],
      sortOrder: raw['sort_order'] is int ? raw['sort_order'] as int : 0,
      createdAt: _date(raw['created_at'], 'collection.created'),
    );
  }

  Attachment _parseAttachment(Map raw) {
    final id = raw['id'];
    final itemId = raw['item_id'];
    if (id is! String || !isValidId(id) || itemId is! String || !isValidId(itemId)) _bad('attachment.id');
    final name = cleanText(raw['name'] as String?, 120).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final mime = cleanText(raw['mime'] as String?, 80);
    return Attachment(
      id: id,
      itemId: itemId,
      name: name.isEmpty ? 'file' : name,
      mime: RegExp(r'^[a-z0-9.+-]+/[a-z0-9.+-]+$').hasMatch(mime) ? mime : 'application/octet-stream',
      size: 0,
      createdAt: _date(raw['created_at'], 'attachment.created'),
    );
  }

  Never _bad(String what) => throw BackupException(BackupError.invalidData, what);

  DateTime _date(Object? v, String field) {
    if (v is! int || v < 0 || v > _maxMs) _bad(field);
    return DateTime.fromMillisecondsSinceEpoch(v);
  }

  DateTime? _dateOpt(Object? v, String field) => v == null ? null : _date(v, field);

  ItemCategory _parseCategory(Object? raw) {
    if (raw is! Map) _bad('category');
    final id = raw['id'];
    if (id is! String || !isValidId(id)) _bad('category.id');
    final name = cleanText(raw['name'] as String?, 60);
    final emoji = cleanText(raw['emoji'] as String?, 16);
    final builtin = raw['builtin'] == 1;
    if (!builtin && name.isEmpty) _bad('category.name');
    final sort = raw['sort_order'];
    return ItemCategory(
      id: id,
      name: builtin ? '' : name,
      emoji: emoji.isEmpty ? '📦' : emoji,
      builtin: builtin,
      sortOrder: sort is int ? sort : 0,
      createdAt: _date(raw['created_at'], 'category.created_at'),
    );
  }

  int? _intOpt(Object? v, int min, int max, String field) {
    if (v == null) return null;
    if (v is! int || v < min || v > max) _bad(field);
    return v;
  }

  LaterItem _parseItem(Object? raw) {
    if (raw is! Map) _bad('item');
    final id = raw['id'];
    if (id is! String || !isValidId(id)) _bad('item.id');
    final title = cleanText(raw['title'] as String?, AppConfig.maxTitleLength);
    if (title.isEmpty) _bad('item.title');
    final cat = raw['category_id'];
    if (cat is! String || !isValidId(cat)) _bad('item.category_id');

    List<String> tags = const [];
    final tagsRaw = raw['tags'];
    if (tagsRaw is String) {
      try {
        final t = jsonDecode(tagsRaw);
        if (t is List) {
          tags = t
              .whereType<String>()
              .map((s) => cleanText(s, AppConfig.maxTagLength))
              .where((s) => s.isNotEmpty)
              .take(AppConfig.maxTagsPerItem)
              .toList();
        }
      } catch (_) {
        _bad('item.tags');
      }
    } else if (tagsRaw != null) {
      _bad('item.tags');
    }

    final url = raw['url'] == null ? null : sanitizeUrl(raw['url'] as String?);
    final status = _intOpt(raw['status'], 0, ItemStatus.values.length - 1, 'item.status') ?? 0;
    final priority = _intOpt(raw['priority'], 0, 2, 'item.priority') ?? 1;
    final repeat = _intOpt(raw['repeat_rule'], 0, RepeatRule.values.length - 1, 'item.repeat') ?? 0;
    final type = _intOpt(raw['item_type'], 0, ItemType.values.length - 1, 'item.type') ?? 0;
    final stage = _intOpt(raw['stage'], 0, 20, 'item.stage') ?? 0;
    var extra = <String, Object?>{};
    final extraRaw = raw['extra'];
    if (extraRaw is String && extraRaw.length < 20000) {
      try {
        final e = jsonDecode(extraRaw);
        if (e is Map) extra = _cleanExtra(e.cast<String, Object?>());
      } catch (_) {
        _bad('item.extra');
      }
    }
    final personId = raw['person_id'];
    final collectionId = raw['collection_id'];
    final created = _date(raw['created_at'], 'item.created_at');
    return LaterItem(
      id: id,
      title: title,
      description: cleanText(raw['description'] as String?, AppConfig.maxTextLength),
      note: cleanText(raw['note'] as String?, AppConfig.maxTextLength),
      categoryId: cat,
      url: url,
      tags: tags,
      priority: ItemPriority.values[priority],
      estimatedMinutes: _intOpt(raw['est_minutes'], 1, 24 * 60 * 30, 'item.est'),
      dueAt: _dateOpt(raw['due_at'], 'item.due_at'),
      hasTime: raw['has_time'] == 1,
      reminderEnabled: raw['reminder_enabled'] == 1,
      reminderOffsetMinutes:
          _intOpt(raw['reminder_offset_min'], 0, 60 * 24 * 365, 'item.offset') ?? 0,
      repeat: RepeatRule.values[repeat],
      status: ItemStatus.values[status],
      createdAt: created,
      updatedAt: _dateOpt(raw['updated_at'], 'item.updated_at') ?? created,
      completedAt: _dateOpt(raw['completed_at'], 'item.completed_at'),
      droppedAt: _dateOpt(raw['dropped_at'], 'item.dropped_at'),
      snoozeCount: _intOpt(raw['snooze_count'], 0, 100000, 'item.snooze') ?? 0,
      lastKeptAt: _dateOpt(raw['last_kept_at'], 'item.last_kept_at'),
      source: cleanText(raw['source'] as String?, 20).isEmpty
          ? null
          : cleanText(raw['source'] as String?, 20),
      type: ItemType.values[type],
      stage: stage,
      inbox: raw['inbox'] == 1,
      unlockAt: _dateOpt(raw['unlock_at'], 'item.unlock_at'),
      personId: personId is String && isValidId(personId) ? personId : null,
      collectionId: collectionId is String && isValidId(collectionId) ? collectionId : null,
      lastReviewedAt: _dateOpt(raw['last_reviewed_at'], 'item.last_reviewed_at'),
      extra: extra,
    );
  }

  /// Keeps only known, well-typed keys of the free-form `extra` map.
  Map<String, Object?> _cleanExtra(Map<String, Object?> m) {
    final out = <String, Object?>{};
    num? n(Object? v) => v is num && v.isFinite && v.abs() < 1e15 ? v : null;
    if (n(m['price']) != null) out['price'] = n(m['price']);
    if (n(m['targetPrice']) != null) out['targetPrice'] = n(m['targetPrice']);
    if (m['currency'] is String) out['currency'] = cleanText(m['currency'] as String, 12);
    if (m['watchKind'] is String) out['watchKind'] = cleanText(m['watchKind'] as String, 12);
    final score = n(m['score']);
    if (score != null && score >= 0 && score <= 10) out['score'] = score.toInt();
    final links = m['links'];
    if (links is List) {
      out['links'] = links.whereType<String>().where(isValidId).take(50).toList();
    }
    final hist = m['priceHistory'];
    if (hist is List) {
      out['priceHistory'] = [
        for (final e in hist.take(500))
          if (e is List && e.length == 2 && n(e[0]) != null && n(e[1]) != null) [n(e[0]), n(e[1])],
      ];
    }
    return out;
  }

  ItemEvent _parseEvent(Object? raw) {
    if (raw is! Map) _bad('event');
    final itemId = raw['item_id'];
    if (itemId is! String || !isValidId(itemId)) _bad('event.item_id');
    final type = _intOpt(raw['type'], 0, EventType.values.length - 1, 'event.type');
    if (type == null) _bad('event.type');
    final cat = raw['category_id'];
    return ItemEvent(
      itemId: itemId,
      type: EventType.values[type],
      at: _date(raw['at'], 'event.at'),
      categoryId: cat is String && isValidId(cat) ? cat : null,
      daysWaited: _intOpt(raw['days_waited'], 0, 100000, 'event.days'),
    );
  }
}
