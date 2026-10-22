import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;

import '../../core/config/app_config.dart';
import '../../domain/models.dart';
import '../../services/platform_bridge.dart';
import '../app_scope.dart';
import '../nav_bus.dart';
import '../sheets/add_edit_sheet.dart';
import '../sheets/item_detail_sheet.dart';
import '../sheets/quick_capture_sheet.dart';
import 'idea_review_screen.dart';
import 'inbox_screen.dart';
import 'shelf_screen.dart';
import 'reveal_screen.dart';
import 'roulette_screen.dart';
import 'history_tab.dart';
import 'home_tab.dart';
import 'list_tab.dart';
import 'settings_tab.dart';

/// Main scaffold: bottom navigation + FAB. Also reacts to navigation
/// requests (quick actions, notification taps, share sheet).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.bus});
  final NavBus bus;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  /// The user went to the store to rate; ask when they come back whether it was sent.
  bool _awaitingReview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.bus.addListener(_onBus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerWidget());
  }

  /// Asked once, right at the start: put the widget on the home screen?
  Future<void> _offerWidget() async {
    if (!mounted) return;
    final app = context.appRead;
    if (app.settings.widgetOffered) return;
    await app.updateSettings((s) => s.copyWith(widgetOffered: true));
    if (!mounted) return;
    await offerHomeWidget(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.bus.removeListener(_onBus);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingReview) {
      _awaitingReview = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _askReviewSent());
    }
  }

  Future<void> _askReviewSent() async {
    if (!mounted) return;
    final l = context.l10n;
    final app = context.appRead;
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.reviewDoneTitle),
        content: Text(l.reviewDoneBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.reviewDoneNo)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.reviewDoneYes)),
        ],
      ),
    );
    if (sent == true) await app.updateSettings((s) => s.copyWith(reviewDone: true));
  }

  /// Back from the home screen would leave the app: ask for a rating first
  /// (until the user says they rated).
  Future<void> _onBack() async {
    if (widget.bus.tab != 0) {
      widget.bus.goTo(0);
      return;
    }
    final app = context.appRead;
    if (app.settings.reviewDone) {
      await SystemNavigator.pop();
      return;
    }
    final l = context.l10n;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.star_rounded, size: 34),
        title: Text(l.reviewTitle, textAlign: TextAlign.center),
        content: Text(l.reviewBody(AppConfig.storeLabel(fa: Localizations.localeOf(context).languageCode == 'fa')), textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowAlignment: OverflowBarAlignment.center,
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx, 'rate'), child: Text(l.reviewRate(AppConfig.storeLabel(fa: Localizations.localeOf(context).languageCode == 'fa')))),
          TextButton(onPressed: () => Navigator.pop(ctx, 'already'), child: Text(l.reviewAlready)),
          TextButton(onPressed: () => Navigator.pop(ctx, 'exit'), child: Text(l.reviewExit)),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'rate':
        final ok = await app.openStoreReview();
        if (!mounted) return;
        if (ok) {
          _awaitingReview = true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.reviewNoStore(AppConfig.storeLabel(fa: Localizations.localeOf(context).languageCode == 'fa')))));
        }
      case 'already':
        await app.updateSettings((s) => s.copyWith(reviewDone: true));
        await SystemNavigator.pop();
      case 'exit':
        await SystemNavigator.pop();
      default:
        break; // dismissed: stay in the app
    }
  }

  void _onBus() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final bus = widget.bus;

    // A notification asked us to open an item.
    final pending = app.takePendingOpenItem();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final it = app.itemById(pending);
        if (it != null && (it.type == ItemType.capsule || it.type == ItemType.future)) {
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RevealScreen(itemId: pending)));
        } else {
          showItemDetailSheet(context, pending);
        }
      });
    }
    final route = app.takePendingRoute();
    if (route == 'ideas') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const IdeaReviewScreen()));
      });
    }
    if (route == 'apps') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => const ShelfScreen(type: ItemType.app)));
        }
      });
    }

    final tabs = <Widget>[
      const HomeTab(),
      const ListTab(),
      const HistoryTab(),
      const SettingsTab(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
      body: IndexedStack(index: bus.tab, children: tabs),
      floatingActionButton: bus.tab == 3
          ? null
          : Semantics(
              label: l.semAdd,
              button: true,
              child: FloatingActionButton(
                tooltip: l.semAdd,
                onPressed: () => addFlow(context),
                child: const Icon(Icons.add_rounded, size: 30),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: bus.tab,
        onDestinationSelected: bus.goTo,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: l.navHome),
          NavigationDestination(icon: const Icon(Icons.inbox_outlined), selectedIcon: const Icon(Icons.inbox_rounded), label: l.navList),
          NavigationDestination(icon: const Icon(Icons.history_rounded), selectedIcon: const Icon(Icons.history_rounded), label: l.navHistory),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings_rounded), label: l.navSettings),
        ],
      ),
      ),
    );
  }
}

/// Handles quick actions (launcher shortcuts, widget buttons).
void handleQuickAction(BuildContext context, QuickAction a, NavBus bus) {
  switch (a) {
    case QuickAction.add:
      unawaited(addFlow(context));
    case QuickAction.pick:
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RouletteScreen()));
    case QuickAction.search:
      bus.focusSearch();
    case QuickAction.open:
      bus.goTo(0);
    case QuickAction.capture:
      unawaited(showQuickCapture(context));
    case QuickAction.inbox:
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const InboxScreen()));
    case QuickAction.item:
      final id = context.appRead.platform.takeActionArg();
      if (id != null) context.appRead.requestOpen(id);
  }
}

/// Dialog that offers the home-screen widget; on "yes" asks Android to pin it
/// (the system shows its own confirmation). Also used from Settings.
Future<void> offerHomeWidget(BuildContext context) async {
  final l = context.l10n;
  final app = context.appRead;
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.widgets_rounded, size: 34),
      title: Text(l.widgetOfferTitle, textAlign: TextAlign.center),
      content: Text(l.widgetOfferBody, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.widgetOfferNo)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.widgetOfferYes)),
      ],
    ),
  );
  if (yes != true || !context.mounted) return;
  final ok = await app.addWidgetToHome();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(ok ? l.widgetAddedToast : l.widgetManualHint)));
}
