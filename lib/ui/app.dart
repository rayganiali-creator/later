import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../domain/settings.dart';
import '../data/controller.dart';
import '../l10n/app_localizations.dart';
import '../services/platform_bridge.dart';
import 'app_scope.dart';
import 'nav_bus.dart';
import 'screens/home_shell.dart';
import 'screens/legal_screens.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/common.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

class LaterApp extends StatefulWidget {
  const LaterApp({super.key, required this.controller});
  final LaterController controller;

  @override
  State<LaterApp> createState() => _LaterAppState();
}

class _LaterAppState extends State<LaterApp> with WidgetsBindingObserver {
  final NavBus _bus = NavBus();
  StreamSubscription<SharedContent>? _shareSub;
  StreamSubscription<QuickAction>? _actionSub;
  Object? _initError;

  LaterController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_boot());
  }

  Future<void> _boot() async {
    try {
      await c.init();
    } catch (e) {
      if (mounted) setState(() => _initError = e);
      return;
    }
    _shareSub = c.platform.shares.listen(_onShare);
    _actionSub = c.platform.actions.listen(_onAction);
    final share = await c.platform.takeInitialShare();
    if (share != null) await _onShare(share);
    final action = await c.platform.takeInitialAction();
    if (action != null) _onAction(action);
    if (mounted) setState(() {});
  }

  Future<void> _onShare(SharedContent s) async {
    try {
      final item = await c.handleShare(s);
      if (item != null) {
        rootMessengerKey.currentState?.hideCurrentSnackBar();
        rootMessengerKey.currentState?.showSnackBar(SnackBar(
          content: Text(c.l10n.shareAdded(item.title.length > 60 ? '${item.title.substring(0, 60)}…' : item.title)),
        ));
      }
    } catch (_) {
      rootMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(c.l10n.errorGeneric)));
    }
  }

  void _onAction(QuickAction a) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !c.loaded || !c.settings.onboardingDone || !c.settings.legalAccepted) return;
    handleQuickAction(ctx, a, _bus);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(c.onResume());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shareSub?.cancel();
    _actionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final st = c.settings;
        final isPro = c.loaded && c.isPro;
        // When Pro ends, non-free accents fall back to the default palette
        // (the stored choice is kept and comes back if Pro is renewed).
        final effectiveAccent = isPro ? st.accent : AccentPalette.indigo;
        final locale = Locale(st.languageCode);
        return AppScope(
          controller: c,
          child: NavScope(
            bus: _bus,
            child: MaterialApp(
              navigatorKey: rootNavigatorKey,
              scaffoldMessengerKey: rootMessengerKey,
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (ctx) => AppL10n.of(ctx).appName,
              locale: locale,
              supportedLocales: AppL10n.supportedLocales,
              localizationsDelegates: const [
                AppL10n.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: st.themeMode,
              theme: AppTheme.build(Brightness.light, effectiveAccent),
              darkTheme: AppTheme.build(Brightness.dark, effectiveAccent),
              builder: (context, child) {
                // Respect the system font scale but keep layouts usable.
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.6)),
                  child: child!,
                );
              },
              home: _initError != null
                  ? _FatalError(onRetry: () {
                      setState(() => _initError = null);
                      unawaited(_boot());
                    })
                  : !c.loaded
                      ? const _Splash()
                      : !st.onboardingDone
                          ? const OnboardingScreen()
                          : !st.legalAccepted
                              ? const LegalAcceptScreen()
                              : HomeShell(bus: _bus),
            ),
          ),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Icon(Icons.history_toggle_off_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
        ),
      );
}

class _FatalError extends StatelessWidget {
  const _FatalError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      body: EmptyState(
        emoji: '⚠️',
        title: l.errorLoad,
        body: l.errorGeneric,
        action: FilledButton(onPressed: onRetry, child: Text(l.retry)),
      ),
    );
  }
}
