import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/platform_bridge.dart';
import '../app_scope.dart';
import '../nav_bus.dart';
import '../sheets/add_edit_sheet.dart';
import '../sheets/item_detail_sheet.dart';
import 'decide_screen.dart';
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

class _HomeShellState extends State<HomeShell> {
  @override
  void initState() {
    super.initState();
    widget.bus.addListener(_onBus);
  }

  @override
  void dispose() {
    widget.bus.removeListener(_onBus);
    super.dispose();
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
        if (mounted) showItemDetailSheet(context, pending);
      });
    }

    final tabs = <Widget>[
      const HomeTab(),
      const ListTab(),
      const HistoryTab(),
      const SettingsTab(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        child: KeyedSubtree(key: ValueKey(bus.tab), child: tabs[bus.tab]),
      ),
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
    );
  }
}

/// Handles quick actions (launcher shortcuts, widget buttons).
void handleQuickAction(BuildContext context, QuickAction a, NavBus bus) {
  switch (a) {
    case QuickAction.add:
      unawaited(addFlow(context));
    case QuickAction.pick:
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DecideScreen()));
    case QuickAction.search:
      bus.focusSearch();
    case QuickAction.open:
      bus.goTo(0);
  }
}
