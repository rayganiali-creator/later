import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/settings.dart';

/// Text shared to the app from another app (Android share sheet).
class SharedContent {
  const SharedContent({required this.text, this.subject});
  final String text;
  final String? subject;
}

/// Quick actions coming from the launcher shortcuts / home-screen widget.
enum QuickAction { add, pick, search, open, capture, inbox, item }

class WidgetSnapshot {
  const WidgetSnapshot({
    required this.waitingCount,
    required this.isPro,
    this.suggestionTitle,
    this.suggestionId,
    this.topItems = const [],
    this.counts = const {},
    this.smartKind,
    this.smartText,
    this.smartId,
    this.todayItems = const [],
    required this.strings,
  });

  final int waitingCount;
  final bool isPro;
  final String? suggestionTitle;
  final String? suggestionId;

  /// Up to 4 titles for the (Pro) list widget.
  final List<String> topItems;

  /// Shelf counters shown by the widgets (inbox, today, learn, podcasts...).
  final Map<String, int> counts;

  /// The smart suggestion: which kind ("today", "learn", "listen", ...), the
  /// ready-to-show line and the item it is about.
  final String? smartKind;
  final String? smartText;
  final String? smartId;

  /// Items due today (or overdue), most urgent first: id, title, color (ARGB int), overdue.
  final List<Map<String, Object?>> todayItems;

  /// Localized strings needed by the native widget.
  final Map<String, String> strings;

  Map<String, Object?> toMap() => {
        'count': waitingCount,
        'pro': isPro,
        'suggestion': suggestionTitle,
        'suggestionId': suggestionId,
        'items': topItems,
        'counts': counts,
        'smartKind': smartKind,
        'smartText': smartText,
        'smartId': smartId,
        'today': todayItems,
        'strings': strings,
      };
}

/// Everything that needs Android-native code, behind one interface so the
/// rest of the app (and the tests) never touch platform channels directly.
abstract class PlatformBridge {
  /// Content that launched the app through the share sheet, if any. Consumed
  /// once.
  Future<SharedContent?> takeInitialShare();

  /// Shares that arrive while the app is running.
  Stream<SharedContent> get shares;

  Future<QuickAction?> takeInitialAction();
  Stream<QuickAction> get actions;

  /// The id that goes with [QuickAction.item] (consumed once).
  String? takeActionArg();

  /// The home-screen widget's refresh button was pressed.
  Stream<void> get widgetRefreshes;

  /// Sends the app to the background (after a quick save from a widget).
  Future<void> moveToBack();

  Future<void> updateWidgets(WidgetSnapshot snapshot);

  /// Asks Android to pin the home-screen widget (the system shows its own
  /// confirmation). False when the launcher cannot do it.
  Future<bool> requestPinWidget();
  Future<bool> openBatteryOptimizationSettings();
  Future<bool> openExactAlarmSettings();
  Future<bool> setLauncherIcon(IconVariant variant);
  Future<void> configureShortcuts(Map<String, String> labels);

  /// Opens the system contact picker (no contacts permission needed: the user
  /// picks one entry and only that entry is shared with the app).
  Future<PickedContact?> pickContact();

  /// Opens a contact in the address book app.
  Future<bool> openContact(String contactUri);
}

class PickedContact {
  const PickedContact({required this.name, required this.uri});
  final String name;
  final String uri;
}

class MethodChannelPlatformBridge implements PlatformBridge {
  MethodChannelPlatformBridge() {
    _channel.setMethodCallHandler(_onCall);
  }

  static const MethodChannel _channel = MethodChannel('app.baadan.later/platform');

  final StreamController<SharedContent> _shares = StreamController.broadcast();
  final StreamController<QuickAction> _actions = StreamController.broadcast();
  final StreamController<void> _refreshes = StreamController.broadcast();
  String? _arg;

  @override
  Stream<void> get widgetRefreshes => _refreshes.stream;

  @override
  String? takeActionArg() {
    final a = _arg;
    _arg = null;
    return a;
  }

  @override
  Future<void> moveToBack() async {
    await _bool('moveToBack');
  }

  Future<dynamic> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'share':
        final c = _parseShare(call.arguments);
        if (c != null) _shares.add(c);
      case 'action':
        final a = _parseAction(call.arguments);
        if (a != null) _actions.add(a);
      case 'refreshWidgets':
        _refreshes.add(null);
    }
    return null;
  }

  static SharedContent? _parseShare(Object? args) {
    if (args is! Map) return null;
    final text = args['text'];
    if (text is! String || text.trim().isEmpty) return null;
    final subject = args['subject'];
    return SharedContent(
      text: text.length > 20000 ? text.substring(0, 20000) : text,
      subject: subject is String ? subject : null,
    );
  }

  QuickAction? _parseAction(Object? name) {
    if (name is String && name.startsWith('item:')) {
      final id = name.substring(5);
      if (RegExp(r'^[A-Za-z0-9_\-]{1,64}$').hasMatch(id)) {
        _arg = id;
        return QuickAction.item;
      }
      return null;
    }
    for (final a in QuickAction.values) {
      if (a.name == name) return a;
    }
    return null;
  }

  @override
  Stream<SharedContent> get shares => _shares.stream;
  @override
  Stream<QuickAction> get actions => _actions.stream;

  @override
  Future<SharedContent?> takeInitialShare() async {
    try {
      return _parseShare(await _channel.invokeMethod<Object>('takeInitialShare'));
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<QuickAction?> takeInitialAction() async {
    try {
      return _parseAction(await _channel.invokeMethod<Object>('takeInitialAction'));
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<bool> _bool(String method, [Object? args]) async {
    try {
      return (await _channel.invokeMethod<bool>(method, args)) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> updateWidgets(WidgetSnapshot s) async {
    await _bool('updateWidgets', s.toMap());
  }

  @override
  Future<bool> requestPinWidget() => _bool('requestPinWidget');

  @override
  Future<bool> openBatteryOptimizationSettings() => _bool('openBatterySettings');

  @override
  Future<bool> openExactAlarmSettings() => _bool('openExactAlarmSettings');

  @override
  Future<bool> setLauncherIcon(IconVariant v) => _bool('setLauncherIcon', v.name);

  @override
  Future<void> configureShortcuts(Map<String, String> labels) async {
    await _bool('configureShortcuts', labels);
  }

  @override
  Future<PickedContact?> pickContact() async {
    try {
      final r = await _channel.invokeMethod<Map<Object?, Object?>>('pickContact');
      if (r == null) return null;
      final name = r['name'];
      final uri = r['uri'];
      if (name is! String || name.trim().isEmpty) return null;
      return PickedContact(
        name: name.trim(),
        uri: uri is String && uri.startsWith('content://com.android.contacts/') ? uri : '',
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<bool> openContact(String contactUri) => _bool('openContact', contactUri);
}

/// No-op implementation for tests / unsupported platforms.
class NullPlatformBridge implements PlatformBridge {
  final StreamController<SharedContent> shareController = StreamController.broadcast();
  final StreamController<QuickAction> actionController = StreamController.broadcast();
  SharedContent? initialShare;
  QuickAction? initialAction;
  WidgetSnapshot? lastWidget;
  IconVariant? lastIcon;

  @override
  Stream<SharedContent> get shares => shareController.stream;
  @override
  Stream<QuickAction> get actions => actionController.stream;
  final StreamController<void> refreshController = StreamController.broadcast();
  @override
  Stream<void> get widgetRefreshes => refreshController.stream;
  String? actionArg;
  @override
  String? takeActionArg() {
    final a = actionArg;
    actionArg = null;
    return a;
  }

  bool movedToBack = false;
  @override
  Future<void> moveToBack() async => movedToBack = true;

  @override
  Future<SharedContent?> takeInitialShare() async {
    final s = initialShare;
    initialShare = null;
    return s;
  }

  @override
  Future<QuickAction?> takeInitialAction() async {
    final a = initialAction;
    initialAction = null;
    return a;
  }

  @override
  Future<void> updateWidgets(WidgetSnapshot snapshot) async => lastWidget = snapshot;
  int pinRequests = 0;
  bool pinResult = true;
  @override
  Future<bool> requestPinWidget() async {
    pinRequests++;
    return pinResult;
  }

  @override
  Future<bool> openBatteryOptimizationSettings() async => false;
  @override
  Future<bool> openExactAlarmSettings() async => false;
  @override
  Future<bool> setLauncherIcon(IconVariant variant) async {
    lastIcon = variant;
    return true;
  }

  @override
  Future<void> configureShortcuts(Map<String, String> labels) async {}

  PickedContact? nextContact;
  @override
  Future<PickedContact?> pickContact() async => nextContact;
  @override
  Future<bool> openContact(String contactUri) async => true;
}
