import 'dart:convert';

import '../core/config/pro_plans.dart';

/// Immutable Pro entitlement based on real timestamps (UTC epoch).
///
/// There is deliberately no `isPro` boolean: activity is always derived from
/// [expiresAt] and the current time, so Pro turns off by itself.
class ProEntitlement {
  const ProEntitlement({
    this.planType = ProPlanType.none,
    this.startAt,
    this.expiresAt,
  });

  static const ProEntitlement none = ProEntitlement();

  final ProPlanType planType;
  final DateTime? startAt;
  final DateTime? expiresAt;

  bool isActiveAt(DateTime now) =>
      expiresAt != null && now.toUtc().isBefore(expiresAt!.toUtc());

  Duration remainingAt(DateTime now) {
    if (expiresAt == null) return Duration.zero;
    final r = expiresAt!.toUtc().difference(now.toUtc());
    return r.isNegative ? Duration.zero : r;
  }

  /// Stacks a purchase on top of what is left of the current entitlement:
  ///
  ///   newExpiry = now + max(currentExpiry - now, 0) + purchasedDuration
  ///
  /// When the entitlement had already expired the new period starts at [now].
  ProEntitlement applyPurchase(ProPlan plan, DateTime now) {
    final n = now.toUtc();
    final remaining = remainingAt(n);
    final active = isActiveAt(n);
    return ProEntitlement(
      planType: plan.type,
      startAt: active && startAt != null ? startAt!.toUtc() : n,
      expiresAt: n.add(remaining + plan.duration),
    );
  }

  Map<String, Object?> toJson() => {
        'planType': planType.name,
        'startAt': startAt?.toUtc().millisecondsSinceEpoch,
        'expiresAt': expiresAt?.toUtc().millisecondsSinceEpoch,
      };

  static ProEntitlement? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final plan = ProPlanType.values.where((p) => p.name == raw['planType']);
    final s = raw['startAt'];
    final e = raw['expiresAt'];
    if (plan.isEmpty) return null;
    if ((s != null && s is! int) || (e != null && e is! int)) return null;
    return ProEntitlement(
      planType: plan.first,
      startAt: s == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(s as int, isUtc: true),
      expiresAt: e == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(e as int, isUtc: true),
    );
  }

  String encode() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is ProEntitlement &&
      other.planType == planType &&
      other.startAt == startAt &&
      other.expiresAt == expiresAt;

  @override
  int get hashCode => Object.hash(planType, startAt, expiresAt);
}

/// Features that require Pro. The free tier stays fully usable for the core
/// "keep it for later" loop.
enum ProFeature {
  advancedSmartPick,
  smartFilters,
  fullStatistics,
  fullHistory,
  moreCategories,
  recurringReminders,
  advancedReminders,
  advancedSearch,
  advancedWidgets,
  moreThemes,
  iconCustomization,
  autoBackups,
  advancedExport,
  smartRoulette,
  rouletteHistory,
  smartInbox,
  advancedShelves,
  ideaTools,
  peopleTools,
  richTimeCapsules,
  richFutureMessages,
  multipleCollections,
}

class ProLimits {
  const ProLimits._();

  static const int freeCustomCategories = 2;
  static const int proCustomCategories = 40;
  static const int freeHistoryDays = 7;

  /// Sealed things a free user can have at the same time.
  static const int freeCapsules = 2;
  static const int freeFutureMessages = 2;
  static const int freeCollectionsPerType = 0;
  static const int proCollectionsPerType = 12;
  static const int maxAttachmentBytes = 2 * 1024 * 1024;
  static const int maxAttachmentsPerMessage = 3;
}

/// Read-only view answering "may the user use X right now?".
class ProAccess {
  const ProAccess(this.entitlement, this.now);

  final ProEntitlement entitlement;
  final DateTime now;

  bool get isPro => entitlement.isActiveAt(now);
  bool has(ProFeature f) => isPro;

  int get customCategoryLimit =>
      isPro ? ProLimits.proCustomCategories : ProLimits.freeCustomCategories;
}
