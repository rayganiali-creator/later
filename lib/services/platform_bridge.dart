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
enum QuickAction { add, pick, search, open }

class WidgetSnapshot {
  const WidgetSnapshot({
    required this.waitingCount,
    required this.isPro,
    this.suggestionTitle,
    this.suggestionId,
    this.topItems = const [],
    required this.strings,
  });

  final int waitingCount;
  final bool isPro;
  final String? suggestionTitle;
  final String? suggestionId;

  /// Up to 4 titles for the (Pro) list widget.
  final List<String> topItems;

  /// Localized strings needed by the native widget.
  final Map<String, String> strings;

  Map<String, Object?> toMap() => {
        'count': waitingCount,
        'pro': isPro,
        'suggestion': suggestionTitle,
        'suggestionId': suggestionId,
        'items': topItems,
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

  Future<void> updateWidgets(WidgetSnapshot snapshot);
  Future<bool> openBatteryOptimizationSettings();
  Future<bool> openExactAlarmSettings();
  Future<bool> setLauncherIcon(IconVariant variant);
  Future<void> configureShortcuts(Map<String, String> labels);
}

class MethodChannelPlatformBridge implements PlatformBridge {
  MethodChannelPlatformBridge() {
    _channel.setMethodCallHandler(_onCall);
  }

  static const MethodChannel _channel = MethodChannel('app.baadan.later/platform');

  final StreamController<SharedContent> _shares = StreamController.broadcast();
  final StreamController<QuickAction> _actions = StreamController.broadcast();

  Future<dynamic> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'share':
        final c = _parseShare(call.arguments);
        if (c != null) _shares.add(c);
      case 'action':
        final a = _parseAction(call.arguments);
        if (a != null) _actions.add(a);
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

  static QuickAction? _parseAction(Object? name) {
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
  Future<bool> openBatteryOptimizationSettings() => _bool('openBatterySettings');

  @override
  Future<bool> openExactAlarmSettings() => _bool('openExactAlarmSettings');

  @override
  Future<bool> setLauncherIcon(IconVariant v) => _bool('setLauncherIcon', v.name);

  @override
  Future<void> configureShortcuts(Map<String, String> labels) async {
    await _bool('configureShortcuts', labels);
  }
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
}
