import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../core/config/app_config.dart';
import '../core/config/pro_plans.dart';
import '../core/util/dates.dart';
import '../core/util/ids.dart';
import '../core/util/text.dart';
import '../domain/models.dart';
import '../domain/pro.dart';
import '../domain/reminders.dart';
import '../domain/search_filter_sort.dart';
import '../domain/settings.dart';
import '../domain/smart_pick.dart';
import '../domain/snooze.dart';
import '../domain/transitions.dart';
import '../l10n/app_localizations.dart';
import '../services/file_gateway.dart';
import '../services/notification_service.dart';
import '../services/platform_bridge.dart';
import '../services/purchase_gateway.dart';
import 'backup/backup_codec.dart';
import 'pro/pro_service.dart';
import 'repository.dart';

class HomeCounts {
  const HomeCounts({
    required this.total,
    required this.today,
    required this.thisWeek,
    required this.noDate,
    required this.overdue,
    required this.stale,
  });
  final int total;
  final int today;
  final int thisWeek;
  final int noDate;
  final int overdue;
  final int stale;
}

/// Reversible action result (for "undo" snackbars).
typedef UndoAction = Future<void> Function();

enum RestoreOutcome { restored }

class PurchaseOutcome {
  const PurchaseOutcome(this.status, [this.entitlement]);
  final PurchaseStatus status;
  final ProEntitlement? entitlement;
}

/// The app's single source of truth for UI: holds the in-memory model, applies
/// user actions transactionally, and keeps reminders/widgets in sync.
class LaterController extends ChangeNotifier {
  LaterController({
    required this.repo,
    required this.pro,
    required this.notifications,
    required this.reminderService,
    required this.platform,
    required this.files,
    required this.purchases,
    required this.appVersion,
    DateTime Function()? clock,
    SmartPicker? picker,
    BackupCodec? codec,
  })  : _baseClock = clock ?? DateTime.now,
        picker = picker ?? SmartPicker(),
        codec = codec ?? BackupCodec();

  final LaterRepository repo;
  final ProService pro;
  final NotificationGateway notifications;
  final ReminderService reminderService;
  final PlatformBridge platform;
  final FileGateway files;
  final PurchaseGateway purchases;
  final String appVersion;
  final SmartPicker picker;
  final BackupCodec codec;
  final DateTime Function() _baseClock;

  // ---------------------------------------------------------------- state

  List<LaterItem> _items = const [];
  List<ItemCategory> _categories = const [];
  AppSettings _settings = const AppSettings();
  bool _loaded = false;
  Duration _debugOffset = Duration.zero;
  ReminderSyncResult _reminderStatus = ReminderSyncResult.empty;
  int _rev = 0;
  Timer? _syncTimer;
  String? _pendingOpenItemId;
  bool _disposed = false;

  bool get loaded => _loaded;
  List<LaterItem> get allItems => _items;
  List<ItemCategory> get categories => _categories;
  AppSettings get settings => _settings;
  ReminderSyncResult get reminderStatus => _reminderStatus;
  int get revision => _rev;
  Duration get debugOffset => _debugOffset;

  /// Id of an item a notification asked to open; consumed by the UI.
  String? takePendingOpenItem() {
    final v = _pendingOpenItemId;
    _pendingOpenItemId = null;
    return v;
  }

  /// "Now" for all product logic. In QA builds it can be shifted to
  /// simulate the passing of time (Pro expiry, stale items...).
  DateTime now() => _baseClock().add(_debugOffset);

  ProAccess get access => pro.access(now());
  bool get isPro => access.isPro;

  AppL10n get l10n => lookupAppL10n(Locale(_settings.languageCode));

  SnoozeCalculator get snoozeCalculator => SnoozeCalculator(
        weekStart: _settings.weekStart,
        weekendDay: _settings.weekendDay,
        calendar: _settings.calendar,
      );

  // ------------------------------------------------------------ lifecycle

  Future<void> init() async {
    final snap = await repo.loadAll();
    _items = snap.items;
    _categories = snap.categories;
    _settings = AppSettings.fromMap(snap.settings);
    await pro.load();
    _loaded = true;
    _bump();
    await notifications.init(
      onTap: handleNotificationTap,
      texts: _notificationTexts(),
    );
    final launch = await notifications.launchTap();
    if (launch != null) unawaited(handleNotificationTap(launch));
    unawaited(syncReminders());
    unawaited(_pushWidgets());
    unawaited(platform.configureShortcuts({
      'add': l10n.shortcutAdd,
      'pick': l10n.shortcutPick,
      'search': l10n.shortcutSearch,
    }));
    unawaited(autoBackupIfDue());
  }

  /// Called when the app returns to the foreground: re-reads the database
  /// (background notification actions may have changed it) and re-syncs the
  /// OS scheduler (timezone / clock changes, cleared alarms).
  Future<void> onResume() async {
    if (!_loaded) return;
    await pro.touch(_baseClock());
    final snap = await repo.loadAll();
    _items = snap.items;
    _categories = snap.categories;
    _bump();
    unawaited(syncReminders());
    unawaited(_pushWidgets());
  }

  @override
  void dispose() {
    _disposed = true;
    _syncTimer?.cancel();
    super.dispose();
  }

  void _bump() {
    _rev++;
    _cache = null;
    if (!_disposed) notifyListeners();
  }

  // ------------------------------------------------------------- queries

  _Cache? _cache;
  _Cache get _c => _cache ??= _Cache(_items, now(), _settings);

  List<LaterItem> get activeItems => _c.active;
  List<LaterItem> get historyItems => _c.history;

  LaterItem? itemById(String id) {
    for (final i in _items) {
      if (i.id == id) return i;
    }
    return null;
  }

  ItemCategory? categoryById(String id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  String categoryName(String id) {
    final c = categoryById(id);
    if (c == null) return l10n.categoryName(BuiltinCategories.other);
    return c.builtin ? l10n.categoryName(c.id) : c.name;
  }

  String categoryEmoji(String id) =>
      categoryById(id)?.emoji ?? BuiltinCategories.emojis[BuiltinCategories.other]!;

  HomeCounts homeCounts() {
    final n = now();
    var today = 0, week = 0, none = 0, over = 0, stale = 0;
    for (final i in activeItems) {
      if (isDueToday(i, n)) today++;
      if (isDueThisWeek(i, n, _settings.weekStart)) week++;
      if (i.dueAt == null) none++;
      if (isOverdue(i, n)) over++;
      if (isStale(i, n, _settings.staleDays)) stale++;
    }
    return HomeCounts(
      total: activeItems.length,
      today: today,
      thisWeek: week,
      noDate: none,
      overdue: over,
      stale: stale,
    );
  }

  List<LaterItem> staleItems() {
    final n = now();
    final list = activeItems
        .where((i) => isStale(i, n, _settings.staleDays))
        .toList();
    list.sort((a, b) => (a.lastKeptAt ?? a.createdAt)
        .compareTo(b.lastKeptAt ?? b.createdAt));
    return list;
  }

  /// Filtered, searched and sorted list for the main list screen.
  List<LaterItem> query({
    ItemFilter filter = ItemFilter.all,
    String search = '',
    SortMode sort = SortMode.newest,
  }) {
    final n = now();
    final q = SearchQuery(search, advanced: isPro);
    final out = activeItems.where((i) {
      if (!matchesFilter(i, filter, n,
          weekStart: _settings.weekStart, staleDays: _settings.staleDays)) {
        return false;
      }
      return matchesSearch(i, q, categoryName: categoryName);
    });
    return sortItems(out, sort, now: n);
  }

  List<ScoredItem> smartPick({
    int? minutes,
    Set<String> exclude = const {},
    String? categoryId,
    int limit = 1,
  }) =>
      picker.pick(
        activeItems,
        now(),
        PickOptions(
          availableMinutes: minutes,
          excludeIds: exclude,
          advanced: isPro,
          categoryId: categoryId,
          limit: limit,
        ),
      );

  Future<StatsData> stats() {
    final n = now();
    return repo.stats(
      weekStartMs: Dates.startOfWeek(n, _settings.weekStart).millisecondsSinceEpoch,
    );
  }

  // ------------------------------------------------------------ item CRUD

  ItemCategory get _otherCategory => categoryById(BuiltinCategories.other)!;

  /// Fastest path: just a title (and optional URL / category).
  Future<LaterItem> quickAdd(
    String title, {
    String? categoryId,
    String? url,
    String source = 'manual',
    DateTime? dueAt,
    bool hasTime = false,
  }) {
    final n = now();
    final cleaned = cleanText(title, AppConfig.maxTitleLength);
    if (cleaned.isEmpty) throw ArgumentError('empty title');
    final cat = categoryId != null && categoryById(categoryId) != null
        ? categoryId
        : (url != null ? BuiltinCategories.link : _otherCategory.id);
    return saveNew(LaterItem(
      id: newId(),
      title: cleaned,
      categoryId: cat,
      url: sanitizeUrl(url),
      createdAt: n,
      updatedAt: n,
      dueAt: dueAt,
      hasTime: hasTime,
      source: source,
    ));
  }

  Future<LaterItem> saveNew(LaterItem draft) async {
    final n = now();
    final item = _sanitize(draft).copyWith(updatedAt: n);
    await repo.upsertItemWithEvent(
      item,
      ItemEvent(itemId: item.id, type: EventType.created, at: n, categoryId: item.categoryId),
    );
    _items = [..._items, item];
    _afterItemsChanged();
    return item;
  }

  Future<void> update(LaterItem edited) async {
    final item = _sanitize(edited).copyWith(updatedAt: now());
    await repo.upsertItem(item);
    _replace(item);
    _afterItemsChanged();
  }

  LaterItem _sanitize(LaterItem i) {
    final tags = <String>[];
    for (final t in i.tags) {
      final c = cleanText(t.replaceAll('#', ''), AppConfig.maxTagLength);
      if (c.isNotEmpty && !tags.contains(c) && tags.length < AppConfig.maxTagsPerItem) {
        tags.add(c);
      }
    }
    final cat = categoryById(i.categoryId) != null ? i.categoryId : BuiltinCategories.other;
    return i.copyWith(
      title: cleanText(i.title, AppConfig.maxTitleLength),
      description: cleanText(i.description, AppConfig.maxTextLength),
      note: cleanText(i.note, AppConfig.maxTextLength),
      url: sanitizeUrl(i.url),
      tags: tags,
      categoryId: cat,
      estimatedMinutes: i.estimatedMinutes != null && i.estimatedMinutes! > 0
          ? min(i.estimatedMinutes!, 60 * 24)
          : null,
      reminderEnabled: i.dueAt != null && i.reminderEnabled,
      hasTime: i.dueAt != null && i.hasTime,
    );
  }

  void _replace(LaterItem item) {
    _items = [for (final i in _items) i.id == item.id ? item : i];
  }

  void _remove(String id) {
    _items = _items.where((i) => i.id != id).toList();
  }

  Future<UndoAction?> complete(String id) => _finish(id, done: true);

  /// "بی‌خیالش شدم"
  Future<UndoAction?> drop(String id) => _finish(id, done: false);

  Future<UndoAction?> _finish(String id, {required bool done}) async {
    final cur = itemById(id);
    if (cur == null) return null;
    final n = now();
    final t = done ? Transitions.complete(cur, n) : Transitions.drop(cur, n);
    if (_settings.keepHistory) {
      await repo.upsertItemWithEvent(t.item, t.event);
      _replace(t.item);
    } else {
      // History disabled: no archive, but keep the anonymous event so the
      // statistics remain meaningful.
      await repo.deleteItemWithEvent(id, t.event);
      _remove(id);
    }
    _afterItemsChanged();
    return () async {
      await repo.removeLastEvent(id, t.event.type);
      final restored = Transitions.reopen(cur, now());
      await repo.upsertItem(restored);
      _items = [..._items.where((i) => i.id != id), restored];
      _afterItemsChanged();
    };
  }

  /// Puts a done/dropped item back into the active list.
  Future<void> reopen(String id) async {
    final cur = itemById(id);
    if (cur == null) return;
    await repo.removeLastEvent(
        id, cur.status == ItemStatus.done ? EventType.completed : EventType.dropped);
    await repo.addEvent(ItemEvent(
        itemId: id, type: EventType.reopened, at: now(), categoryId: cur.categoryId));
    final it = Transitions.reopen(cur, now());
    await repo.upsertItem(it);
    _replace(it);
    _afterItemsChanged();
  }

  Future<UndoAction?> snooze(String id, SnoozeOption option) =>
      snoozeTo(id, snoozeCalculator.compute(option, now()));

  Future<UndoAction?> snoozeTo(String id, SnoozeTarget target) async {
    final cur = itemById(id);
    if (cur == null) return null;
    final t = Transitions.snooze(cur, target, now());
    await repo.upsertItemWithEvent(t.item, t.event);
    _replace(t.item);
    _afterItemsChanged();
    return () async {
      await repo.removeLastEvent(id, EventType.snoozed);
      await repo.upsertItem(cur);
      _replace(cur);
      _afterItemsChanged();
    };
  }

  Future<void> keep(String id) async {
    final cur = itemById(id);
    if (cur == null) return;
    final t = Transitions.keep(cur, now());
    await repo.upsertItemWithEvent(t.item, t.event);
    _replace(t.item);
    _afterItemsChanged();
  }

  /// Permanently deletes an item. Returns an undo action.
  Future<UndoAction?> delete(String id) async {
    final cur = itemById(id);
    if (cur == null) return null;
    final n = now();
    final ev = ItemEvent(
      itemId: id,
      type: EventType.deleted,
      at: n,
      categoryId: cur.categoryId,
      daysWaited: Dates.daysBetween(cur.createdAt, n).clamp(0, 100000),
    );
    await repo.deleteItemWithEvent(id, ev);
    _remove(id);
    _afterItemsChanged();
    return () async {
      await repo.removeLastEvent(id, EventType.deleted);
      await repo.upsertItem(cur);
      _items = [..._items, cur];
      _afterItemsChanged();
    };
  }

  void _afterItemsChanged() {
    _bump();
    scheduleReminderSync();
    unawaited(_pushWidgets());
  }

  // ------------------------------------------------------------ categories

  bool get canAddCategory =>
      _categories.where((c) => !c.builtin).length < access.customCategoryLimit;

  Future<ItemCategory?> addCategory(String name, String emoji) async {
    if (!canAddCategory) return null;
    final n = now();
    final clean = cleanText(name, 30);
    if (clean.isEmpty) return null;
    final c = ItemCategory(
      id: 'c_${newId().substring(0, 12)}',
      name: clean,
      emoji: cleanText(emoji, 8).isEmpty ? '🏷️' : cleanText(emoji, 8),
      sortOrder: _categories.fold<int>(0, (m, c) => max(m, c.sortOrder)) + 1,
      createdAt: n,
    );
    await repo.upsertCategory(c);
    _categories = [..._categories, c];
    _bump();
    return c;
  }

  Future<void> updateCategory(ItemCategory c, {String? name, String? emoji}) async {
    if (c.builtin) return;
    final u = c.copyWith(
      name: name == null ? null : cleanText(name, 30),
      emoji: emoji == null ? null : cleanText(emoji, 8),
    );
    if (u.name.isEmpty) return;
    await repo.upsertCategory(u);
    _categories = [for (final x in _categories) x.id == u.id ? u : x];
    _bump();
  }

  Future<void> deleteCategory(String id) async {
    final c = categoryById(id);
    if (c == null || c.builtin) return;
    await repo.deleteCategory(id, BuiltinCategories.other);
    _categories = _categories.where((x) => x.id != id).toList();
    _items = [
      for (final i in _items)
        i.categoryId == id ? i.copyWith(categoryId: BuiltinCategories.other) : i
    ];
    _bump();
  }

  // -------------------------------------------------------------- settings

  Future<void> updateSettings(AppSettings Function(AppSettings) change) async {
    final before = _settings;
    final next = change(before);
    await repo.saveSettings(next);
    _settings = next;
    _bump();
    if (next.remindersEnabled != before.remindersEnabled ||
        next.defaultReminderMinutes != before.defaultReminderMinutes ||
        next.privateNotifications != before.privateNotifications ||
        next.languageCode != before.languageCode) {
      scheduleReminderSync();
    }
    if (next.languageCode != before.languageCode || next.weekStart != before.weekStart) {
      unawaited(_pushWidgets());
    }
    if (next.iconVariant != before.iconVariant) {
      unawaited(platform.setLauncherIcon(isPro ? next.iconVariant : IconVariant.classic));
    }
  }

  Future<void> acceptLegal() => updateSettings((s) => s.copyWith(
        termsAcceptedVersion: AppConfig.termsVersion,
        privacyAcceptedVersion: AppConfig.privacyVersion,
        termsAcceptedAt: now(),
      ));

  // -------------------------------------------------------------- reminders

  NotificationTexts _notificationTexts() {
    final l = l10n;
    return NotificationTexts(
      channelName: l.notifChannelName,
      channelDescription: l.notifChannelDescription,
      actionDone: l.notifActionDone,
      actionTomorrow: l.notifActionTomorrow,
      privateTitle: l.appName,
      privateBody: l.notifPrivateBody,
      testTitle: l.notifTestTitle,
      testBody: l.notifTestBody,
    );
  }

  /// Debounced sync (many quick edits => one OS scheduling pass).
  void scheduleReminderSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 400), () => unawaited(syncReminders()));
  }

  Future<ReminderSyncResult> syncReminders() async {
    _syncTimer?.cancel();
    final l = l10n;
    final allowRepeat = access.has(ProFeature.recurringReminders);
    final r = await reminderService.sync(
      items: _items,
      now: now(),
      remindersEnabled: _settings.remindersEnabled,
      allowRepeat: allowRepeat,
      privateMode: _settings.privateNotifications,
      defaultMinutesOfDay: _settings.defaultReminderMinutes,
      maxScheduled: AppConfig.maxScheduledNotifications,
      texts: _notificationTexts(),
      titleOf: (i) => i.title,
      bodyOf: (i) => i.description.isNotEmpty
          ? i.description
          : '${categoryEmoji(i.categoryId)} ${categoryName(i.categoryId)} · ${l.notifBodyGeneric}',
    );
    _reminderStatus = r;
    if (!_disposed) notifyListeners();
    return r;
  }

  /// Asks for the notification permission at the moment the user first turns
  /// a reminder on (never at startup).
  Future<bool> ensureNotificationPermission() async {
    var p = await notifications.permission();
    if (p == NotificationPermission.denied) p = await notifications.requestPermission();
    if (p == NotificationPermission.granted) {
      if (!await notifications.exactAlarmsAllowed()) {
        await notifications.requestExactAlarms();
      }
    }
    final ok = p == NotificationPermission.granted;
    unawaited(syncReminders());
    return ok;
  }

  Future<void> handleNotificationTap(NotificationTap tap) async {
    final item = itemById(tap.itemId);
    if (item == null || !item.isActive) return;
    switch (tap.actionId) {
      case NotificationTap.actionDone:
        await complete(tap.itemId);
      case NotificationTap.actionTomorrow:
        await snooze(tap.itemId, SnoozeOption.tomorrow);
      default:
        _pendingOpenItemId = tap.itemId;
        _bump();
    }
  }

  // ---------------------------------------------------------------- share

  /// Creates an item from text shared by another app.
  Future<LaterItem?> handleShare(SharedContent c) async {
    final text = c.text.trim();
    if (text.isEmpty) return null;
    final url = extractFirstUrl(text);
    var title = (c.subject ?? '').trim();
    if (title.isEmpty) {
      var t = text;
      if (url != null) t = t.replaceAll(RegExp(r'https?://[^\s<>"]+'), '').trim();
      title = t.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    }
    title = cleanText(title, AppConfig.maxTitleLength);
    if (title.isEmpty) title = url ?? cleanText(text, 120);
    if (title.isEmpty) return null;
    final remainder = text.replaceAll(RegExp(r'https?://[^\s<>"]+'), '').trim();
    final n = now();
    return saveNew(LaterItem(
      id: newId(),
      title: title,
      description: remainder == title ? '' : cleanText(remainder, AppConfig.maxTextLength),
      categoryId: url != null ? BuiltinCategories.link : BuiltinCategories.other,
      url: url,
      createdAt: n,
      updatedAt: n,
      source: 'share',
    ));
  }

  // ---------------------------------------------------------------- widgets

  Future<void> _pushWidgets() async {
    if (!_loaded) return;
    try {
      final l = l10n;
      final s = smartPick(limit: 1);
      final top = sortItems(activeItems, SortMode.nearestDeadline, now: now())
          .take(4)
          .map((e) => e.title)
          .toList();
      await platform.updateWidgets(WidgetSnapshot(
        waitingCount: activeItems.length,
        isPro: isPro,
        suggestionTitle: s.isEmpty ? null : s.first.item.title,
        suggestionId: s.isEmpty ? null : s.first.item.id,
        topItems: top,
        strings: {
          'app': l.appName,
          'waiting': l.widgetWaiting('{n}'),
          'empty': l.widgetEmpty,
          'add': l.widgetAdd,
          'pick': l.widgetPick,
          'proOnly': l.widgetProOnly,
          'suggestion': l.widgetSuggestion,
        },
      ));
    } catch (_) {
      // Widgets are a convenience; never fail user actions because of them.
    }
  }

  // ------------------------------------------------------------------ Pro

  Future<PurchaseOutcome> buy(ProPlan plan) async {
    if (plan.debugOnly && !AppConfig.testToolsEnabled) {
      return const PurchaseOutcome(PurchaseStatus.failed);
    }
    final r = await purchases.purchase(plan);
    if (r.status != PurchaseStatus.success) return PurchaseOutcome(r.status);
    final ent = await pro.applyPurchase(plan, purchasedAt: r.purchasedAt);
    if (r.token != null) await purchases.consume(r.token!);
    _proChanged();
    return PurchaseOutcome(PurchaseStatus.success, ent);
  }

  /// Re-applies purchases that were paid but never activated.
  Future<int> restorePurchases() async {
    var n = 0;
    for (final p in await purchases.pendingPurchases()) {
      if (p.plan == null) continue;
      await pro.applyPurchase(p.plan!, purchasedAt: p.purchasedAt);
      if (p.token != null) await purchases.consume(p.token!);
      n++;
    }
    if (n > 0) _proChanged();
    return n;
  }

  void _proChanged() {
    _bump();
    scheduleReminderSync();
    unawaited(_pushWidgets());
    unawaited(platform.setLauncherIcon(isPro ? _settings.iconVariant : IconVariant.classic));
  }

  /// Runs periodic housekeeping after the entitlement may have expired.
  void refreshProState() => _proChanged();

  // ---------------------------------------------------------------- backup

  Future<LaterSnapshot> _snapshot() => repo.loadAll();

  Future<Uint8List> buildBackupBytes() async {
    final snap = await _snapshot();
    return codec.encode(
      snap,
      now: now(),
      appVersion: appVersion,
      proBlob: pro.exportForBackup(),
    );
  }

  static String backupFileName(DateTime d) =>
      'Later_Backup_${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}.${AppConfig.backupExtension}';

  /// Exports through the system file picker. Returns false if cancelled.
  Future<bool> exportBackup({required String dialogTitle}) async {
    final bytes = await buildBackupBytes();
    final ok = await files.saveBackup(backupFileName(now()), bytes, dialogTitle: dialogTitle);
    if (ok) await updateSettings((s) => s.copyWith(lastBackupAt: now()));
    return ok;
  }

  /// Validates a backup without touching current data.
  DecodedBackup inspectBackup(Uint8List bytes) => codec.decode(bytes, now: now());

  bool get hasUserData => _items.isNotEmpty;

  /// Replaces all data with [backup]. A safety copy of the current data is
  /// written to private storage first; nothing changes if restoring fails.
  Future<void> restore(DecodedBackup backup) async {
    // Safety net: keep what the user had, so "restore" is never destructive.
    try {
      final bytes = await buildBackupBytes();
      final dir = await files.internalBackupDir();
      await BackupFiles.write(dir.path, 'pre_restore.${AppConfig.backupExtension}', bytes);
    } catch (_) {/* best effort */}

    await repo.replaceAll(backup.snapshot);
    final snap = await repo.loadAll();
    _items = snap.items;
    _categories = snap.categories;
    _settings = AppSettings.fromMap(snap.settings);
    await pro.importFromBackup(backup.proBlob, now: now());
    _bump();
    await syncReminders();
    unawaited(_pushWidgets());
    _proChanged();
  }

  /// Pro: keeps up to 5 automatic weekly backups in private storage.
  Future<void> autoBackupIfDue() async {
    try {
      if (!_settings.autoBackup || !access.has(ProFeature.autoBackups)) return;
      final last = _settings.lastAutoBackupAt;
      if (last != null && now().difference(last) < const Duration(days: 7)) return;
      final bytes = await buildBackupBytes();
      final dir = await files.internalBackupDir();
      final d = now();
      await BackupFiles.write(dir.path, 'auto_${backupFileName(d)}', bytes);
      await BackupFiles.prune(dir.path, prefix: 'auto_', keep: 5);
      await updateSettings((s) => s.copyWith(lastAutoBackupAt: d));
    } catch (_) {/* never bother the user */}
  }

  // ----------------------------------------------------------------- reset

  /// Deletes everything (items, categories, history, settings). The Pro
  /// entitlement is *not* touched: it belongs to the purchase, not the data.
  Future<void> resetAll() async {
    await repo.wipe(now());
    final snap = await repo.loadAll();
    _items = snap.items;
    _categories = snap.categories;
    _settings = const AppSettings();
    await notifications.cancelAll();
    _bump();
    unawaited(_pushWidgets());
  }

  // ------------------------------------------------------------- QA tools

  Future<void> debugAdvanceDays(int days) async {
    if (!AppConfig.testToolsEnabled) return;
    _debugOffset += Duration(days: days);
    await pro.touch(now());
    _proChanged();
  }

  Future<void> debugResetTime() async {
    if (!AppConfig.testToolsEnabled) return;
    _debugOffset = Duration.zero;
    await pro.debugResetClockMark();
    _proChanged();
  }

  Future<void> debugGrantPro(ProPlan plan) async {
    if (!AppConfig.testToolsEnabled) return;
    await pro.applyPurchase(plan, purchasedAt: now());
    _proChanged();
  }

  Future<void> debugClearPro() async {
    if (!AppConfig.testToolsEnabled) return;
    await pro.clear();
    _proChanged();
  }

  Future<void> debugSeed(int count, {bool withSamples = true}) async {
    if (!AppConfig.testToolsEnabled) return;
    final rng = Random(count);
    final n = now();
    final titles = withSamples ? _sampleTitles : const <(String, String)>[];
    final items = <LaterItem>[];
    for (var k = 0; k < count; k++) {
      final t = titles.isNotEmpty
          ? titles[k % titles.length]
          : ('مورد نمونه ${toFaDigits(k + 1)}', BuiltinCategories.other);
      final due = rng.nextInt(4) == 0 ? Dates.startOfDay(n).add(Duration(days: rng.nextInt(20) - 3)) : null;
      items.add(LaterItem(
        id: newId(),
        title: k < titles.length ? t.$1 : '${t.$1} ${toFaDigits(k + 1)}',
        categoryId: t.$2,
        createdAt: n.subtract(Duration(days: rng.nextInt(70), hours: rng.nextInt(20))),
        updatedAt: n,
        dueAt: due,
        priority: ItemPriority.values[rng.nextInt(3)],
        estimatedMinutes: [null, 5, 10, 15, 30, 60, 90][rng.nextInt(7)],
        tags: rng.nextInt(3) == 0 ? ['نمونه'] : const [],
        source: 'sample',
      ));
    }
    await repo.upsertItems(items);
    for (final i in items) {
      await repo.addEvent(ItemEvent(
          itemId: i.id, type: EventType.created, at: i.createdAt, categoryId: i.categoryId));
    }
    _items = [..._items, ...items];
    _afterItemsChanged();
  }

  /// Fires a notification right now (permission / channel check). Available
  /// to users in Settings so they can verify notifications work.
  Future<void> showTestNotification() async {
    final t = _notificationTexts();
    await notifications.showNow(id: 424242, title: t.testTitle, body: t.testBody);
  }

  /// Human-readable notification diagnostics (QA + Settings support info).
  Future<String> notificationDiagnostics() async {
    final b = StringBuffer();
    try {
      b.writeln('permission: ${(await notifications.permission()).name}');
      b.writeln('exactAlarms: ${await notifications.exactAlarmsAllowed()}');
      b.writeln('pending: ${(await notifications.pendingIds()).length}');
      b.writeln('lastSync: scheduled=${_reminderStatus.scheduled} failed=${_reminderStatus.failed}');
    } catch (e) {
      b.writeln('error: ${e.runtimeType}: $e');
    }
    return b.toString();
  }

  /// Schedules a real test reminder in [seconds] (exercises AlarmManager).
  Future<void> debugScheduleTestIn(int seconds) async {
    final t = _notificationTexts();
    final at = DateTime.now().add(Duration(seconds: seconds));
    final exact = await notifications.exactAlarmsAllowed();
    await notifications.schedule(
      PlannedReminder(
        notificationId: 424243,
        itemId: 'test',
        fireAt: DateTime(at.year, at.month, at.day, at.hour, at.minute, at.second),
        repeat: RepeatRule.none,
        title: t.testTitle,
        body: t.testBody,
      ),
      exact: exact,
      privateMode: false,
      texts: t,
    );
  }

  static const List<(String, String)> _sampleTitles = [
    ('مقاله‌ی «قدرت عادت‌های کوچک» را بخوانم', BuiltinCategories.read),
    ('فیلم «پدرخوانده» را ببینم', BuiltinCategories.watch),
    ('به دندانپزشکی زنگ بزنم', BuiltinCategories.people),
    ('هدفون بی‌سیم جدید بخرم', BuiltinCategories.buy),
    ('ایده‌ی اپلیکیشن یادداشت صوتی را بررسی کنم', BuiltinCategories.idea),
    ('لینک آموزش فلاتر را ذخیره کنم', BuiltinCategories.link),
    ('گزارش ماهانه را بازبینی کنم', BuiltinCategories.work),
    ('پیام تبریک به دوستم بدهم', BuiltinCategories.people),
    ('پادکست جدید را گوش کنم', BuiltinCategories.watch),
    ('کتاب «مغز متفکر» را شروع کنم', BuiltinCategories.read),
  ];
}

/// Lazily computed, revision-scoped derived lists.
class _Cache {
  _Cache(List<LaterItem> items, DateTime now, AppSettings s) {
    final a = <LaterItem>[];
    final h = <LaterItem>[];
    for (final i in items) {
      (i.isActive ? a : h).add(i);
    }
    h.sort((x, y) => (y.completedAt ?? y.droppedAt ?? y.updatedAt)
        .compareTo(x.completedAt ?? x.droppedAt ?? x.updatedAt));
    active = a;
    history = h;
  }
  late final List<LaterItem> active;
  late final List<LaterItem> history;
}
