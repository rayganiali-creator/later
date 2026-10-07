import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../core/config/app_config.dart';
import '../core/config/pro_plans.dart';
import '../core/util/dates.dart';
import '../core/util/ids.dart';
import '../core/util/text.dart';
import '../domain/classifier.dart';
import '../domain/models.dart';
import '../domain/pro.dart';
import 'package:image/image.dart' as img;

import '../domain/game_picker.dart';
import '../domain/learning.dart';
import '../domain/roulette.dart';
import '../domain/type_colors.dart';
import '../domain/widget_pick.dart';
import '../services/image_picker_gateway.dart';
import '../services/image_processor.dart';
import '../domain/universal_search.dart';
import '../domain/reminders.dart';
import '../domain/search_filter_sort.dart';
import '../domain/settings.dart';
import '../domain/smart_pick.dart';
import '../domain/snooze.dart';
import '../domain/transitions.dart';
import '../l10n/app_localizations.dart';
import '../services/attachment_store.dart';
import '../services/file_gateway.dart';
import '../services/notification_service.dart';
import '../services/platform_bridge.dart';
import '../services/purchase_gateway.dart';
import 'backup/backup_codec.dart';
import 'pro/pro_service.dart';
import 'repository.dart';

part 'controller_media.dart';

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

/// Counters shown on the home dashboard.
class DashboardCounts {
  const DashboardCounts({
    required this.today,
    required this.inbox,
    required this.read,
    required this.watch,
    required this.wishlist,
    required this.ideas,
    required this.future,
    required this.people,
    this.apps = 0,
    this.podcasts = 0,
    this.courses = 0,
    this.games = 0,
  });
  final int today, inbox, read, watch, wishlist, ideas, future, people, apps, podcasts, courses, games;
}

enum TriageChoice { today, thisWeek, noDate, read, watch, wishlist, idea, done, delete }

enum WishAnswer { still, unsure, no }

class ShelfStats {
  const ShelfStats({
    required this.waiting,
    required this.finished,
    required this.finishedThisWeek,
    required this.finishedThisMonth,
    required this.minutesWaiting,
    required this.avgDaysToFinish,
    required this.totalPrice,
    this.dropped = 0,
  });
  final int dropped;
  final int waiting, finished, finishedThisWeek, finishedThisMonth, minutesWaiting;
  final double? avgDaysToFinish;
  final double totalPrice;
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
    AttachmentStore? attachmentStore,
    DateTime Function()? clock,
    SmartPicker? picker,
    Roulette? roulette,
    GamePicker? gamePicker,
    ImageProcessor? imageProcessor,
    ImagePickerGateway? imagePicker,
    BackupCodec? codec,
  })  : _baseClock = clock ?? DateTime.now,
        picker = picker ?? SmartPicker(),
        roulette = roulette ?? Roulette(),
        gamePicker = gamePicker ?? GamePicker(),
        imageProcessor = imageProcessor ?? const DefaultImageProcessor(),
        imagePicker = imagePicker ?? SystemImagePicker(),
        attachmentStore = attachmentStore ?? MemoryAttachmentStore(),
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
  final Roulette roulette;
  final GamePicker gamePicker;
  final ImageProcessor imageProcessor;
  final ImagePickerGateway imagePicker;
  final AttachmentStore attachmentStore;
  final BackupCodec codec;
  final DateTime Function() _baseClock;

  // ---------------------------------------------------------------- state

  List<LaterItem> _items = const [];
  List<ItemCategory> _categories = const [];
  List<Person> _people = const [];
  List<ItemCollection> _collections = const [];
  List<Attachment> _attachments = const [];
  final List<String> _recentSpins = [];
  final List<String> _recentGames = [];
  final List<String> _recentGenres = [];

  // Small pictures are shown in every list: keep the decoded bytes around.
  final Map<String, Uint8List> _thumbCache = {};
  Map<String, Attachment>? _thumbIndex;
  int _thumbIndexRev = -1;
  AppSettings _settings = const AppSettings();
  bool _loaded = false;
  Duration _debugOffset = Duration.zero;
  ReminderSyncResult _reminderStatus = ReminderSyncResult.empty;
  int _rev = 0;
  Timer? _syncTimer;
  StreamSubscription<void>? _refreshSub;
  String? _pendingOpenItemId;
  bool _disposed = false;

  bool get loaded => _loaded;
  List<LaterItem> get allItems => _items;
  List<ItemCategory> get categories => _categories;
  List<Person> get people => _people;
  List<ItemCollection> get collections => _collections;
  List<Attachment> get attachments => _attachments;
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
    _adopt(snap);
    await pro.load();
    _loaded = true;
    _bump();
    _refreshSub = platform.widgetRefreshes.listen((_) => unawaited(_pushWidgets()));
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
    unawaited(sweepAttachments());
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
    _people = snap.people;
    _collections = snap.collections;
    _attachments = snap.attachments;
    _bump();
    unawaited(syncReminders());
    unawaited(_pushWidgets());
  }

  void _adopt(LaterSnapshot snap) {
    _items = snap.items;
    _categories = snap.categories;
    _people = snap.people;
    _collections = snap.collections;
    _attachments = snap.attachments;
    _settings = AppSettings.fromMap(snap.settings);
  }

  @override
  void dispose() {
    _disposed = true;
    _syncTimer?.cancel();
    _refreshSub?.cancel();
    super.dispose();
  }

  void _bump() {
    _rev++;
    _cache = null;
    if (!_disposed) notifyListeners();
  }

  // ------------------------------------------------------------- queries

  _Cache? _cache;
  _Cache get _c {
    final c = _cache;
    final n = now();
    if (c != null && (c.nextUnlock == null || n.isBefore(c.nextUnlock!))) return c;
    return _cache = _Cache(_items, n);
  }

  /// Everything visible right now (sealed things are hidden).
  List<LaterItem> get activeItems => _c.active;

  /// Sealed capsules / messages that have not opened yet.
  List<LaterItem> get sealedItems => _c.sealed;
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
      if (_staleFor(i, n)) stale++;
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

  /// Ideas have their own review, sealed things must not nag, wishlist items use
  /// their own (usually shorter) "still want it?" period.
  bool _staleFor(LaterItem i, DateTime n) {
    switch (i.type) {
      case ItemType.idea:
      case ItemType.capsule:
      case ItemType.future:
        return false;
      case ItemType.wishlist:
        return isStale(i, n, _settings.wishlistReviewDays);
      default:
        return isStale(i, n, _settings.staleDays);
    }
  }

  List<LaterItem> staleItems() {
    final n = now();
    final list = activeItems.where((i) => _staleFor(i, n)).toList();
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
    ItemType type = ItemType.task,
    bool inbox = true,
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
      type: type,
      // Fast capture lands in the inbox unless the caller already sorted it.
      inbox: inbox && dueAt == null && type == ItemType.task,
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
    return _sanitizeExtra(i).copyWith(
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
      unlockTitleOf: (i) => i.type == ItemType.future ? l.notifFutureTitle : l.notifCapsuleTitle,
      unlockBodyOf: (i) => i.type == ItemType.future ? l.notifFutureBody : l.notifCapsuleBody,
      extra: _systemReminders(),
    );
    _reminderStatus = r;
    if (!_disposed) notifyListeners();
    return r;
  }

  static const _ideaReviewId = 'sys:idea_review';
  static const _appReviewId = 'sys:app_review';

  /// Reminders that do not belong to a single item.
  List<PlannedReminder> _systemReminders() {
    final n = now();
    final m = _settings.defaultReminderMinutes;
    DateTime monthly(int day) {
      var at = DateTime(n.year, n.month, day, m ~/ 60, m % 60);
      if (!at.isAfter(n)) at = DateTime(n.year, n.month + 1, day, m ~/ 60, m % 60);
      return at;
    }

    final l = l10n;
    return [
      if (_settings.ideaReviewReminder && access.has(ProFeature.ideaTools) && activeItems.any((i) => i.type == ItemType.idea))
        PlannedReminder(
          notificationId: stableHash31(_ideaReviewId),
          itemId: _ideaReviewId,
          fireAt: monthly(1),
          repeat: RepeatRule.monthly,
          title: l.notifIdeaReviewTitle,
          body: l.notifIdeaReviewBody,
          sealed: true,
        ),
      if (_settings.appReviewReminder && access.has(ProFeature.appTools) && activeItems.any((i) => i.type == ItemType.app))
        PlannedReminder(
          notificationId: stableHash31(_appReviewId),
          itemId: _appReviewId,
          fireAt: monthly(15),
          repeat: RepeatRule.monthly,
          title: l.notifAppReviewTitle,
          body: l.notifAppReviewBody,
          sealed: true,
        ),
    ];
  }

  /// Asks for the notification permission at the moment the user first turns
  /// a reminder on (never at startup).
  Future<bool> ensureNotificationPermission({bool askExact = true}) async {
    var p = await notifications.permission();
    if (p == NotificationPermission.denied) p = await notifications.requestPermission();
    if (p == NotificationPermission.granted && askExact) {
      if (!await notifications.exactAlarmsAllowed()) {
        await notifications.requestExactAlarms();
      }
    }
    final ok = p == NotificationPermission.granted;
    unawaited(syncReminders());
    return ok;
  }

  /// Opens an item's detail on the next frame (widget taps, notifications).
  void requestOpen(String id) {
    if (itemById(id) == null) return;
    _pendingOpenItemId = id;
    _bump();
  }

  String? _pendingRoute;

  /// A screen a notification asked to open (`ideas`), consumed by the UI.
  String? takePendingRoute() {
    final v = _pendingRoute;
    _pendingRoute = null;
    return v;
  }

  Future<void> handleNotificationTap(NotificationTap tap) async {
    if (tap.itemId == _ideaReviewId) {
      _pendingRoute = 'ideas';
      _bump();
      return;
    }
    if (tap.itemId == _appReviewId) {
      _pendingRoute = 'apps';
      _bump();
      return;
    }
    final item = itemById(tap.itemId);
    if (item == null || !item.isActive) return;
    if (item.type == ItemType.capsule || item.type == ItemType.future) {
      _pendingOpenItemId = item.id;
      _bump();
      return;
    }
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
      // Saved right away (nothing is lost if the app is closed); the user can
      // then put it on the right shelf with one tap.
      inbox: true,
    ));
  }

  // ---------------------------------------------------------------- widgets

  Future<void> _pushWidgets() async {
    if (!_loaded) return;
    try {
      final l = l10n;
      final fmt = _widgetNum;
      final pick = widgetSuggestion;
      String? text, kind;
      if (pick != null) {
        final t = pick.item.title;
        final m = pick.item.estimatedMinutes;
        kind = pick.kind.name;
        text = switch (pick.kind) {
          WidgetPickKind.today => l.widgetSmartToday(t),
          WidgetPickKind.learn => l.widgetSmartLearn(t),
          WidgetPickKind.listen => l.widgetSmartListen(t),
          WidgetPickKind.freeTime => l.widgetSmartFree(fmt(m ?? 0), t),
          WidgetPickKind.game => l.widgetSmartGame(fmt(m ?? 30), t),
          WidgetPickKind.waiting => l.widgetSmartWaiting(t),
        };
      }
      final top = sortItems(activeItems, SortMode.nearestDeadline, now: now())
          .take(4)
          .map((e) => e.title)
          .toList();
      final counts = widgetCounts();
      await platform.updateWidgets(WidgetSnapshot(
        waitingCount: activeItems.length,
        isPro: isPro,
        suggestionTitle: pick?.item.title,
        suggestionId: pick?.item.id,
        topItems: top,
        counts: counts,
        smartKind: kind,
        smartText: text,
        smartId: pick?.item.id,
        todayItems: [
          for (final i in todayItems().take(6))
            {
              'id': i.id,
              'title': i.title,
              'color': typeColorValue(i.type),
              'overdue': isOverdue(i, now()),
            }
        ],
        strings: {
          'app': l.appName,
          'tagline': l.widgetTagline,
          'waiting': l.widgetWaiting('{n}'),
          'empty': l.widgetEmpty,
          'add': l.widgetAdd,
          'pick': l.widgetPick,
          'proOnly': l.widgetProOnly,
          'suggestion': l.widgetSuggestion,
          'inbox': l.widgetInbox,
          'today': l.widgetToday,
          'learn': l.widgetLearn,
          'podcasts': l.widgetPodcasts,
          'games': l.widgetGames,
          'wishlist': l.widgetWishlist,
          'ideas': l.widgetIdeas,
          'refresh': l.widgetRefresh,
          'read': l.widgetRead,
          'todayEmpty': l.widgetTodayEmpty,
          'more': l.widgetMore('{n}'),
          'overdue': l.widgetOverdue,
          'fa': _settings.languageCode == 'fa' ? '1' : '0',
          'day': '${now().year * 10000 + now().month * 100 + now().day}',
          'nothing': l.widgetNothing,
        },
      ));
    } catch (_) {
      // Widgets are a convenience; never fail user actions because of them.
    }
  }

  /// Asks the launcher to add the widget to the home screen.
  Future<bool> addWidgetToHome() => platform.requestPinWidget();

  String _widgetNum(int n) => _settings.languageCode == 'fa' ? toFaDigits(n) : '$n';

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
    final base = await _snapshot();
    final bytes = <String, Uint8List>{};
    for (final a in base.attachments) {
      final b = await attachmentStore.read(a.id);
      if (b != null) bytes[a.id] = b;
    }
    final snap = LaterSnapshot(
      items: base.items,
      categories: base.categories,
      events: base.events,
      settings: base.settings,
      people: base.people,
      interactions: base.interactions,
      collections: base.collections,
      attachments: base.attachments,
      attachmentBytes: bytes,
    );
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
    _adopt(snap);
    // Attachment bytes: write the restored ones, drop any that are gone.
    for (final a in backup.snapshot.attachments) {
      final b = backup.snapshot.attachmentBytes[a.id];
      if (b != null) await attachmentStore.write(a.id, b);
    }
    await attachmentStore.retainOnly({for (final a in snap.attachments) a.id});
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
    _adopt(snap);
    _settings = const AppSettings();
    await attachmentStore.retainOnly({});
    await notifications.cancelAll();
    _bump();
    unawaited(_pushWidgets());
  }

  // ================================================================ shelves

  /// Active items of one shelf (Read Later, Watch Later, Wishlist...).
  List<LaterItem> shelf(ItemType t, {String? collectionId}) => [
        for (final i in activeItems)
          if (i.type == t && (collectionId == null || i.collectionId == collectionId)) i
      ];

  /// Finished items of one shelf (read, watched, bought, archived...).
  List<LaterItem> shelfHistory(ItemType t) => [
        for (final i in historyItems)
          if (i.type == t) i
      ];

  List<LaterItem> get inboxItems => [
        for (final i in activeItems)
          if (i.inbox) i
      ];

  /// Everything set for today (or overdue), any shelf, most urgent first.
  /// Sealed capsules / future letters have their own place and are left out.
  List<LaterItem> todayItems() {
    final n = now();
    final list = [
      for (final i in activeItems)
        if (i.type != ItemType.capsule &&
            i.type != ItemType.future &&
            (isDueToday(i, n) || isOverdue(i, n)))
          i
    ];
    list.sort((a, b) {
      final ao = isOverdue(a, n), bo = isOverdue(b, n);
      if (ao != bo) return ao ? -1 : 1;
      final ad = effectiveDue(a, n), bd = effectiveDue(b, n);
      if (ad != null && bd != null) return ad.compareTo(bd);
      return a.title.compareTo(b.title);
    });
    return list;
  }

  DashboardCounts dashboardCounts() {
    var today = 0, inbox = 0, read = 0, watch = 0, wish = 0, ideas = 0, unopened = 0;
    var apps = 0, pods = 0, courses = 0, games = 0;
    for (final i in activeItems) {
      if (i.inbox) inbox++;
      switch (i.type) {
        case ItemType.read:
          read++;
        case ItemType.watch:
          watch++;
        case ItemType.wishlist:
          wish++;
        case ItemType.idea:
          ideas++;
        case ItemType.app:
          apps++;
        case ItemType.podcast:
          pods++;
        case ItemType.course:
          courses++;
        case ItemType.game:
          games++;
        case ItemType.capsule:
        case ItemType.future:
          unopened++; // unlocked but not opened yet
        default:
          break;
      }
    }
    today = todayItems().length;
    return DashboardCounts(
      today: today,
      inbox: inbox,
      read: read,
      watch: watch,
      wishlist: wish,
      ideas: ideas,
      future: sealedItems.length + unopened,
      people: _people.length,
      apps: apps,
      podcasts: pods,
      courses: courses,
      games: games,
    );
  }

  /// Puts an item on a shelf with one tap (inbox triage, share sheet).
  Future<UndoAction?> moveToType(String id, ItemType type) async {
    final cur = itemById(id);
    if (cur == null) return null;
    return _commit(cur, Transitions.moveToType(cur, type, now()));
  }

  Future<UndoAction?> setStage(String id, int stage) async {
    final cur = itemById(id);
    if (cur == null) return null;
    return _commit(cur, Transitions.setStage(cur, stage, now()));
  }

  /// Marks an inbox item as sorted without moving it anywhere.
  Future<UndoAction?> triage(String id, TriageChoice c) async {
    final cur = itemById(id);
    if (cur == null) return null;
    final n = now();
    switch (c) {
      case TriageChoice.today:
        return _commit(cur, _sorted(cur, n, dueAt: Dates.startOfDay(n)));
      case TriageChoice.thisWeek:
        final end = Dates.addDays(Dates.startOfWeek(n, _settings.weekStart), 6);
        return _commit(cur, _sorted(cur, n, dueAt: end.isBefore(Dates.startOfDay(n)) ? Dates.startOfDay(n) : end));
      case TriageChoice.noDate:
        return _commit(cur, _sorted(cur, n));
      case TriageChoice.read:
        return moveToType(id, ItemType.read);
      case TriageChoice.watch:
        return moveToType(id, ItemType.watch);
      case TriageChoice.wishlist:
        return moveToType(id, ItemType.wishlist);
      case TriageChoice.idea:
        return moveToType(id, ItemType.idea);
      case TriageChoice.done:
        return complete(id);
      case TriageChoice.delete:
        return delete(id);
    }
  }

  Transition _sorted(LaterItem i, DateTime n, {DateTime? dueAt}) => Transition(
        i.copyWith(inbox: false, dueAt: dueAt ?? i.dueAt, hasTime: dueAt != null ? false : i.hasTime, updatedAt: n),
        ItemEvent(itemId: i.id, type: EventType.moved, at: n, categoryId: i.categoryId),
      );

  /// Writes a transition and returns an undo that restores the previous item.
  Future<UndoAction?> _commit(LaterItem prev, Transition t) async {
    await repo.upsertItemWithEvent(t.item, t.event);
    _replace(t.item);
    _afterItemsChanged();
    return () async {
      await repo.removeLastEvent(prev.id, t.event.type);
      await repo.upsertItem(prev);
      _replace(prev);
      _afterItemsChanged();
    };
  }

  /// Suggests a shelf for [item] (Pro "Smart Inbox"). Never applied silently.
  Classification? suggestionFor(LaterItem item) {
    if (!access.has(ProFeature.smartInbox)) return null;
    final c = ItemClassifier.classify(item.title, url: item.url, description: item.description);
    return c.isDefault ? null : c;
  }

  // ================================================================ roulette

  RouletteOptions rouletteOptions({
    int? minutes,
    ItemPriority? priority,
    RouletteEnergy? energy,
    Set<String>? categories,
  }) {
    final pro = access.has(ProFeature.smartRoulette);
    final cats = pro ? (categories ?? _settings.rouletteCategories) : const <String>{};
    return RouletteOptions(
      availableMinutes: pro ? minutes : null,
      categoryIds: cats.isEmpty ? null : cats,
      priority: pro ? priority : null,
      energy: pro ? energy : null,
      recentIds: List.of(_recentSpins),
    );
  }

  /// Draws one item for "قرعه بعداً" and remembers it (history is Pro).
  Future<LaterItem?> spinRoulette({RouletteOptions? options}) async {
    final o = options ?? rouletteOptions();
    final r = roulette.spin(activeItems, now(), o);
    if (r == null) return null;
    _recentSpins.add(r.id);
    while (_recentSpins.length > 3) {
      _recentSpins.removeAt(0);
    }
    await repo.addEvent(ItemEvent(itemId: r.id, type: EventType.spun, at: now(), categoryId: r.categoryId));
    return r;
  }

  /// Roulette history (Pro): newest first.
  Future<List<(ItemEvent, LaterItem?)>> rouletteHistory({int limit = 100}) async {
    final ev = await repo.events(type: EventType.spun);
    return [for (final e in ev.take(limit)) (e, itemById(e.itemId))];
  }

  // ================================================================ people

  Person? personById(String id) {
    for (final p in _people) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<Person> addPerson(String name, {String? contactUri, String note = '', String group = ''}) async {
    final n = now();
    final clean = cleanText(name, 200);
    if (clean.isEmpty) throw ArgumentError('empty name');
    final p = Person(
      id: newId(),
      name: clean,
      contactUri: contactUri,
      note: cleanText(note, AppConfig.maxTextLength),
      group: access.has(ProFeature.peopleTools) ? cleanText(group, 60) : '',
      createdAt: n,
      updatedAt: n,
    );
    await repo.upsertPerson(p);
    _people = [..._people, p];
    _bump();
    return p;
  }

  Future<void> updatePerson(Person p) async {
    final u = p.copyWith(
      name: cleanText(p.name, 200).isEmpty ? p.name : cleanText(p.name, 200),
      note: cleanText(p.note, AppConfig.maxTextLength),
      group: access.has(ProFeature.peopleTools) ? cleanText(p.group, 60) : p.group,
      updatedAt: now(),
    );
    await repo.upsertPerson(u);
    _people = [for (final x in _people) x.id == u.id ? u : x];
    _bump();
  }

  Future<void> deletePerson(String id) async {
    await repo.deletePerson(id);
    _people = _people.where((p) => p.id != id).toList();
    _items = [for (final i in _items) i.personId == id ? i.copyWith(personId: null) : i];
    _afterItemsChanged();
  }

  /// "We just talked". Pro also keeps the log and can schedule a follow-up.
  Future<void> logInteraction(String personId, {DateTime? at, String note = '', int? followUpDays}) async {
    final p = personById(personId);
    if (p == null) return;
    final when = at ?? now();
    final pro = access.has(ProFeature.peopleTools);
    if (pro) {
      await repo.addInteraction(Interaction(personId: personId, at: when, note: cleanText(note, 2000)));
    }
    await updatePersonRaw(p.copyWith(lastInteractionAt: when, updatedAt: now()));
    if (pro && followUpDays != null && followUpDays > 0) {
      await addPersonReminder(
        personId,
        title: p.name,
        dueAt: Dates.startOfDay(Dates.addDays(when, followUpDays)),
        reminder: true,
      );
    }
  }

  Future<void> updatePersonRaw(Person p) async {
    await repo.upsertPerson(p);
    _people = [for (final x in _people) x.id == p.id ? p : x];
    _bump();
  }

  Future<List<Interaction>> interactionsOf(String personId) => repo.interactionsOf(personId);

  /// "Message Ali later": a reminder item linked to the person.
  Future<LaterItem> addPersonReminder(
    String personId, {
    required String title,
    DateTime? dueAt,
    bool hasTime = false,
    bool reminder = true,
    RepeatRule repeat = RepeatRule.none,
  }) {
    final n = now();
    return saveNew(LaterItem(
      id: newId(),
      title: title,
      categoryId: BuiltinCategories.people,
      createdAt: n,
      updatedAt: n,
      type: ItemType.person,
      personId: personId,
      dueAt: dueAt,
      hasTime: hasTime,
      reminderEnabled: reminder && dueAt != null,
      repeat: access.has(ProFeature.recurringReminders) ? repeat : RepeatRule.none,
      source: 'person',
    ));
  }

  List<LaterItem> personItems(String personId) => [
        for (final i in activeItems)
          if (i.personId == personId) i
      ];

  DateTime? nextReminderOf(String personId) {
    final n = now();
    DateTime? best;
    for (final i in personItems(personId)) {
      final d = effectiveDue(i, n);
      if (d != null && (best == null || d.isBefore(best))) best = d;
    }
    return best;
  }

  /// People not contacted for [days] days (Pro dashboard).
  List<Person> peopleDue({int days = 30}) {
    final n = now();
    return [
      for (final p in _people)
        if (p.lastInteractionAt == null
            ? Dates.daysBetween(p.createdAt, n) >= days
            : Dates.daysBetween(p.lastInteractionAt!, n) >= days)
          p
    ];
  }

  // ============================================================ collections

  int collectionLimit(ItemType t) =>
      access.has(ProFeature.multipleCollections) ? ProLimits.proCollectionsPerType : ProLimits.freeCollectionsPerType;

  List<ItemCollection> collectionsOf(ItemType t) => [
        for (final c in _collections)
          if (c.type == t) c
      ];

  bool canAddCollection(ItemType t) => collectionsOf(t).length < collectionLimit(t);

  Future<ItemCollection?> addCollection(String name, ItemType type) async {
    final clean = cleanText(name, 40);
    if (clean.isEmpty || !canAddCollection(type)) return null;
    final c = ItemCollection(
      id: 'k_${newId().substring(0, 12)}',
      name: clean,
      type: type,
      sortOrder: _collections.length,
      createdAt: now(),
    );
    await repo.upsertCollection(c);
    _collections = [..._collections, c];
    _bump();
    return c;
  }

  Future<void> deleteCollection(String id) async {
    await repo.deleteCollection(id);
    _collections = _collections.where((c) => c.id != id).toList();
    _items = [for (final i in _items) i.collectionId == id ? i.copyWith(collectionId: null) : i];
    _bump();
  }

  Future<void> setCollection(String itemId, String? collectionId) async {
    final cur = itemById(itemId);
    if (cur == null) return;
    await update(cur.copyWith(collectionId: collectionId));
  }

  // ================================================================ wishlist

  /// Records a new price. Every change is kept in the history (Pro shows it).
  Future<void> setPrice(String id, double? price, {String? currency}) async {
    final cur = itemById(id);
    if (cur == null) return;
    var next = cur.withExtra('price', price).withExtra('currency', currency ?? cur.currency);
    if (price != null && price != cur.price) {
      final hist = [
        ...((cur.extra['priceHistory'] as List?) ?? const []),
        [now().millisecondsSinceEpoch, price],
      ];
      next = next.withExtra('priceHistory', hist.length > 200 ? hist.sublist(hist.length - 200) : hist);
    }
    await update(next);
  }

  Future<void> setTargetPrice(String id, double? target) async {
    final cur = itemById(id);
    if (cur == null || !access.has(ProFeature.advancedShelves)) return;
    await update(cur.withExtra('targetPrice', target));
  }

  /// Wishlist items nobody has looked at for a while ("still want it?").
  List<LaterItem> wishlistToReview() {
    final n = now();
    return [
      for (final i in activeItems)
        if (i.type == ItemType.wishlist &&
            Dates.daysBetween(i.lastReviewedAt ?? i.createdAt, n) >= _settings.wishlistReviewDays)
          i
    ]..sort((a, b) => (a.lastReviewedAt ?? a.createdAt).compareTo(b.lastReviewedAt ?? b.createdAt));
  }

  Future<void> answerWishlist(String id, WishAnswer a) async {
    final cur = itemById(id);
    if (cur == null) return;
    switch (a) {
      case WishAnswer.still:
        await _commit(cur, Transitions.review(cur, now()));
      case WishAnswer.unsure:
        final r = Transitions.review(cur, now());
        await _commit(cur, Transition(r.item.copyWith(stage: ItemStages.maybe), r.event));
      case WishAnswer.no:
        await setStage(id, ItemStages.notInterested);
    }
  }

  // ================================================================ ideas

  List<LaterItem> ideasToReview() {
    final n = now();
    return [
      for (final i in activeItems)
        if (i.type == ItemType.idea &&
            Dates.daysBetween(i.lastReviewedAt ?? i.createdAt, n) >= _settings.ideaReviewDays)
          i
    ]..sort((a, b) => (a.lastReviewedAt ?? a.createdAt).compareTo(b.lastReviewedAt ?? b.createdAt));
  }

  Future<void> reviewIdea(String id, {int? stage, int? score}) async {
    final cur = itemById(id);
    if (cur == null) return;
    var t = Transitions.review(cur, now());
    var item = t.item;
    if (score != null && access.has(ProFeature.ideaTools)) item = item.withExtra('score', score.clamp(0, 10));
    if (stage != null) item = Transitions.setStage(item, stage, now()).item;
    await repo.upsertItemWithEvent(item, t.event);
    _replace(item);
    _afterItemsChanged();
  }

  /// Pro: two ideas that belong together.
  Future<void> linkItems(String a, String b) async {
    if (!access.has(ProFeature.ideaTools) || a == b) return;
    final x = itemById(a), y = itemById(b);
    if (x == null || y == null) return;
    LaterItem add(LaterItem i, String other) {
      final l = {...i.links, other}.toList();
      return i.withExtra('links', l);
    }
    await update(add(x, b));
    await update(add(itemById(b)!, a));
  }

  Future<void> unlinkItems(String a, String b) async {
    for (final pair in [(a, b), (b, a)]) {
      final i = itemById(pair.$1);
      if (i == null) continue;
      await update(i.withExtra('links', i.links.where((e) => e != pair.$2).toList()));
    }
  }

  List<LaterItem> linkedItems(LaterItem i) => [
        for (final id in i.links)
          if (itemById(id) != null) itemById(id)!
      ];

  /// Pro: turn an idea into a normal to-do.
  Future<UndoAction?> convertIdeaToTask(String id) async {
    if (!access.has(ProFeature.ideaTools)) return null;
    return moveToType(id, ItemType.task);
  }

  // ============================================================ shelf stats

  ShelfStats shelfStats(ItemType t) {
    final n = now();
    final week = Dates.startOfWeek(n, _settings.weekStart);
    final month = DateTime(n.year, n.month, 1);
    var waiting = 0, minutes = 0;
    var finishedWeek = 0, finishedMonth = 0, finished = 0, dropped = 0;
    var waitedDays = 0;
    double spend = 0;
    for (final i in _items) {
      if (i.type != t) continue;
      if (i.isActive) {
        waiting++;
        minutes += i.estimatedMinutes ?? 0;
        if (t == ItemType.wishlist && i.price != null) spend += i.price!;
      } else if (i.status == ItemStatus.done && i.completedAt != null) {
        finished++;
        waitedDays += Dates.daysBetween(i.createdAt, i.completedAt!).clamp(0, 100000);
        if (!i.completedAt!.isBefore(week)) finishedWeek++;
        if (!i.completedAt!.isBefore(month)) finishedMonth++;
      } else if (i.status == ItemStatus.dropped) {
        dropped++;
      }
    }
    return ShelfStats(
      waiting: waiting,
      finished: finished,
      finishedThisWeek: finishedWeek,
      finishedThisMonth: finishedMonth,
      minutesWaiting: minutes,
      avgDaysToFinish: finished == 0 ? null : waitedDays / finished,
      totalPrice: spend,
      dropped: dropped,
    );
  }

  // ======================================================= sealed / future

  /// How many capsules / future messages are sealed right now.
  int sealedCount({required bool messages}) => [
        for (final i in sealedItems)
          if ((i.type == ItemType.future) == messages) i
      ].length;

  bool canSeal({required bool messages}) {
    if (access.has(messages ? ProFeature.richFutureMessages : ProFeature.richTimeCapsules)) return true;
    return sealedCount(messages: messages) <
        (messages ? ProLimits.freeFutureMessages : ProLimits.freeCapsules);
  }

  /// Creates a capsule or a future message. Returns null if the free limit is
  /// reached (the UI then offers Pro).
  Future<LaterItem?> seal({
    required String title,
    String body = '',
    required DateTime unlockAt,
    bool message = false,
    RepeatRule repeat = RepeatRule.none,
    List<String> tags = const [],
    String? categoryId,
  }) async {
    if (!canSeal(messages: message)) return null;
    if (!unlockAt.isAfter(now())) throw ArgumentError('unlock date must be in the future');
    final n = now();
    final pro = access.has(message ? ProFeature.richFutureMessages : ProFeature.richTimeCapsules);
    return saveNew(LaterItem(
      id: newId(),
      title: title.trim().isEmpty ? (message ? l10n.defaultMessageTitle : l10n.defaultCapsuleTitle) : title,
      description: body,
      categoryId: categoryId != null && pro ? categoryId : BuiltinCategories.other,
      tags: pro ? tags : const [],
      createdAt: n,
      updatedAt: n,
      type: message ? ItemType.future : ItemType.capsule,
      unlockAt: unlockAt,
      repeat: pro ? repeat : RepeatRule.none,
      source: 'sealed',
    ));
  }

  /// Seals an existing item until [unlockAt] (hidden everywhere until then).
  Future<LaterItem?> sealExisting(String id, DateTime unlockAt) async {
    final cur = itemById(id);
    if (cur == null || !unlockAt.isAfter(now())) return null;
    if (!canSeal(messages: false)) return null;
    final u = cur.copyWith(unlockAt: unlockAt, inbox: false);
    await update(u);
    return itemById(id);
  }

  /// Opens a capsule / message that has reached its date.
  Future<LaterItem?> openSealed(String id) async {
    final cur = itemById(id);
    if (cur == null || cur.isLockedAt(now())) return null;
    DateTime? next;
    if (cur.repeat != RepeatRule.none && access.has(ProFeature.richFutureMessages)) {
      final base = cur.unlockAt ?? now();
      var d = base;
      var k = 0;
      while (!d.isAfter(now()) && k < 500) {
        k++;
        d = switch (cur.repeat) {
          RepeatRule.daily => Dates.addDays(base, k),
          RepeatRule.weekly => Dates.addDays(base, 7 * k),
          RepeatRule.monthly => Dates.addMonths(base, k, CalendarSystem.gregorian),
          RepeatRule.yearly => Dates.addMonths(base, 12 * k, CalendarSystem.gregorian),
          RepeatRule.none => base,
        };
      }
      next = d;
    }
    final t = Transitions.openSealed(cur, now(), nextUnlock: next);
    await repo.upsertItemWithEvent(t.item, t.event);
    _replace(t.item);
    _afterItemsChanged();
    return cur; // the content as it was when it opened
  }

  /// Everything sealed or opened, for the future timeline.
  List<LaterItem> timeline({required bool messages}) {
    bool inTimeline(LaterItem i) => messages
        ? i.type == ItemType.future
        : (i.type == ItemType.capsule || (i.unlockAt != null && i.type != ItemType.future));
    final all = [
      for (final i in _items)
        if (inTimeline(i)) i
    ];
    all.sort((a, b) => (a.unlockAt ?? a.createdAt).compareTo(b.unlockAt ?? b.createdAt));
    return all;
  }

  // ============================================================ attachments

  /// Files attached to a future message (pictures are handled separately).
  List<Attachment> attachmentsOf(String itemId) => [
        for (final a in _attachments)
          if (a.itemId == itemId && a.role == AttachmentRole.file) a
      ];

  /// Pro: a small file on a future message. Stays on the device.
  Future<Attachment?> addAttachment(String itemId, String name, String mime, Uint8List bytes) async {
    if (!access.has(ProFeature.richFutureMessages)) return null;
    if (bytes.isEmpty || bytes.length > ProLimits.maxAttachmentBytes) throw ArgumentError('size');
    if (attachmentsOf(itemId).length >= ProLimits.maxAttachmentsPerMessage) throw StateError('limit');
    final a = Attachment(
      id: newId(),
      itemId: itemId,
      name: cleanText(name, 120).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_'),
      mime: RegExp(r'^[a-z0-9.+-]+/[a-z0-9.+-]+$').hasMatch(mime) ? mime : 'application/octet-stream',
      size: bytes.length,
      createdAt: now(),
    );
    await attachmentStore.write(a.id, bytes);
    await repo.upsertAttachment(a);
    _attachments = [..._attachments, a];
    _bump();
    return a;
  }

  Future<Uint8List?> attachmentBytes(String id) => attachmentStore.read(id);

  Future<void> removeAttachment(String id) async {
    await attachmentStore.delete(id);
    await repo.deleteAttachment(id);
    _attachments = _attachments.where((a) => a.id != id).toList();
    _bump();
  }

  /// Removes attachment rows/files whose item no longer exists.
  Future<void> sweepAttachments() async {
    final ids = {for (final i in _items) i.id};
    for (final a in _attachments.where((a) => !ids.contains(a.itemId)).toList()) {
      await removeAttachment(a.id);
    }
  }

  // ================================================================ search

  List<SearchHit> search(String query) => universalSearch(
        items: [..._items.where((i) => !i.isLockedAt(now()))],
        people: _people,
        query: query,
        now: now(),
        advanced: access.has(ProFeature.advancedSearch),
        categoryName: categoryName,
      );

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

  /// QA: a small, realistic set of typed items, a person, a capsule that opens
  /// tomorrow and a message that is already unlocked.
  Future<void> debugSeedShelves() async {
    if (!AppConfig.testToolsEnabled) return;
    final n = now();
    LaterItem mk(String title, ItemType t,
            {String? url, int stage = 0, bool inbox = false, Map<String, Object?> extra = const {}, DateTime? created, String? cat}) =>
        LaterItem(
          id: newId(),
          title: title,
          categoryId: cat ?? BuiltinCategories.other,
          createdAt: created ?? n.subtract(const Duration(days: 3)),
          updatedAt: n,
          type: t,
          stage: stage,
          url: url,
          inbox: inbox,
          extra: extra,
          source: 'sample',
        );
    final items = [
      mk('مقاله‌ی «عادت‌های کوچک»', ItemType.read, url: 'https://example.com/small-habits', cat: BuiltinCategories.link),
      mk('سخنرانی درباره‌ی تمرکز', ItemType.watch, url: 'https://www.youtube.com/watch?v=abc', cat: BuiltinCategories.link),
      mk('هدفون بی‌سیم', ItemType.wishlist,
          extra: {'price': 2400000, 'currency': 'تومان'}, created: n.subtract(const Duration(days: 45))),
      mk('اپ یادآور آب‌خوردن', ItemType.idea, created: n.subtract(const Duration(days: 40))),
      mk('لینک ذخیره‌شده‌ی بدون مقصد', ItemType.task, url: 'https://www.digikala.com/product/x', inbox: true),
      mk('یه فکر سریع', ItemType.task, inbox: true),
    ];
    for (final i in items) {
      await repo.upsertItemWithEvent(
          i, ItemEvent(itemId: i.id, type: EventType.created, at: i.createdAt, categoryId: i.categoryId));
    }
    _items = [..._items, ...items];
    if (_people.isEmpty) await addPerson('علی نمونه');
    _afterItemsChanged();
    if (canSeal(messages: false)) {
      await seal(title: 'کپسول نمونه', body: 'این متن فردا باز می‌شه.', unlockAt: Dates.startOfDay(Dates.addDays(n, 1)), message: false);
    }
    if (canSeal(messages: true)) {
      await seal(title: 'پیام نمونه', body: 'سلام از گذشته!', unlockAt: Dates.startOfDay(Dates.addDays(n, 1)), message: true);
    }    await debugSeedMedia();
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
  _Cache(List<LaterItem> items, DateTime now) {
    final a = <LaterItem>[];
    final h = <LaterItem>[];
    final sealed = <LaterItem>[];
    DateTime? next;
    for (final i in items) {
      if (!i.isActive) {
        h.add(i);
      } else if (i.isLockedAt(now)) {
        sealed.add(i);
        if (next == null || i.unlockAt!.isBefore(next)) next = i.unlockAt;
      } else {
        a.add(i);
      }
    }
    h.sort((x, y) => (y.completedAt ?? y.droppedAt ?? y.updatedAt)
        .compareTo(x.completedAt ?? x.droppedAt ?? x.updatedAt));
    active = a;
    history = h;
    this.sealed = sealed;
    nextUnlock = next;
  }
  late final List<LaterItem> active;
  late final List<LaterItem> history;
  late final List<LaterItem> sealed;
  late final DateTime? nextUnlock;
}
