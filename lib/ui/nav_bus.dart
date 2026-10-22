import 'package:flutter/material.dart';

import '../domain/search_filter_sort.dart';

/// Cross-screen navigation requests (quick actions, notification taps).
class NavBus extends ChangeNotifier {
  int tab = 0;
  int _searchFocusTick = 0;
  int get searchFocusTick => _searchFocusTick;

  ItemFilter? _pendingFilter;
  ItemFilter? takeFilter() {
    final f = _pendingFilter;
    _pendingFilter = null;
    return f;
  }

  void goTo(int t) {
    tab = t;
    notifyListeners();
  }

  void showListWithFilter(ItemFilter f) {
    _pendingFilter = f;
    tab = 1;
    notifyListeners();
  }

  void focusSearch() {
    tab = 1;
    _searchFocusTick++;
    notifyListeners();
  }
}

class NavScope extends InheritedNotifier<NavBus> {
  const NavScope({super.key, required NavBus bus, required super.child}) : super(notifier: bus);
  static NavBus of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<NavScope>()!.notifier!;
  static NavBus read(BuildContext c) => c.getInheritedWidgetOfExactType<NavScope>()!.notifier!;
}
