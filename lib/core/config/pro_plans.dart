/// Pro plans & prices. Single source of truth: change prices/durations here.
///
/// Durations are fixed day counts (1 month = 30 days, 3 months = 90 days,
/// 6 months = 180 days) so entitlement maths is exact, timezone-independent
/// and identical everywhere (tests, UI, backup).
enum ProPlanType { none, day1, day7, month1, month3, month6 }

class ProPlan {
  const ProPlan({
    required this.type,
    required this.sku,
    required this.durationDays,
    required this.priceToman,
    this.debugOnly = false,
  });

  final ProPlanType type;

  /// In-app product id configured in the market's developer console.
  final String sku;
  final int durationDays;
  final int priceToman;

  /// Plans only offered by the QA/test tools (never sold).
  final bool debugOnly;

  Duration get duration => Duration(days: durationDays);
}

class ProPlans {
  const ProPlans._();

  static const ProPlan month1 = ProPlan(
    type: ProPlanType.month1,
    sku: 'later_pro_1m',
    durationDays: 30,
    priceToman: 19000,
  );
  static const ProPlan month3 = ProPlan(
    type: ProPlanType.month3,
    sku: 'later_pro_3m',
    durationDays: 90,
    priceToman: 55000,
  );
  static const ProPlan month6 = ProPlan(
    type: ProPlanType.month6,
    sku: 'later_pro_6m',
    durationDays: 180,
    priceToman: 100000,
  );

  /// QA-only plans used by the test tools to simulate short subscriptions.
  static const ProPlan day1 = ProPlan(
    type: ProPlanType.day1,
    sku: 'debug_1d',
    durationDays: 1,
    priceToman: 0,
    debugOnly: true,
  );
  static const ProPlan day7 = ProPlan(
    type: ProPlanType.day7,
    sku: 'debug_7d',
    durationDays: 7,
    priceToman: 0,
    debugOnly: true,
  );

  /// Plans sold to real users, in display order.
  static const List<ProPlan> sellable = [month1, month3, month6];

  static const List<ProPlan> all = [day1, day7, month1, month3, month6];

  static ProPlan? byType(ProPlanType type) {
    for (final p in all) {
      if (p.type == type) return p;
    }
    return null;
  }

  static ProPlan? bySku(String sku) {
    for (final p in all) {
      if (p.sku == sku) return p;
    }
    return null;
  }
}
