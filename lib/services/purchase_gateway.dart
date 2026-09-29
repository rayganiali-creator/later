import 'dart:async';

import 'package:flutter/services.dart';

import '../core/config/pro_plans.dart';

enum PurchaseStatus { success, cancelled, unavailable, failed }

class PurchaseResult {
  const PurchaseResult(this.status, {this.plan, this.purchasedAt, this.token});

  final PurchaseStatus status;
  final ProPlan? plan;

  /// Market side purchase time (authoritative when present).
  final DateTime? purchasedAt;

  /// Opaque purchase token used to consume the product after activation.
  final String? token;
}

/// Boundary to the market's billing service. The activation logic
/// ([ProService.applyPurchase]) never talks to a market directly, so a
/// different market or a receipt-verification server can be plugged in here.
abstract class PurchaseGateway {
  /// False when the store app / billing service is missing on this device.
  Future<bool> isAvailable();

  Future<PurchaseResult> purchase(ProPlan plan);

  /// Purchases made earlier that were never consumed/activated (e.g. the app
  /// crashed between payment and activation).
  Future<List<PurchaseResult>> pendingPurchases();

  /// Marks a purchase as consumed so the same product can be bought again.
  Future<void> consume(String token);
}

/// Cafe Bazaar billing through the native Poolakey integration
/// (android/app/src/main/kotlin/.../BazaarBillingPlugin.kt).
///
/// NOTE: needs Bazaar installed, a developer account with the products
/// configured, and the RSA public key passed through
/// `--dart-define=BAZAAR_RSA_KEY=...`. It cannot be exercised without them.
class BazaarPurchaseGateway implements PurchaseGateway {
  static const MethodChannel _channel = MethodChannel('app.baadan.later/billing');
  static const String rsaKey = String.fromEnvironment('BAZAAR_RSA_KEY');

  Future<T?> _call<T>(String m, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(m, args);
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (rsaKey.isEmpty) return false;
    try {
      return (await _call<bool>('isAvailable')) ?? false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<PurchaseResult> purchase(ProPlan plan) async {
    try {
      final r = await _call<Map<Object?, Object?>>('purchase', {
        'sku': plan.sku,
        'rsaKey': rsaKey,
      });
      if (r == null) return const PurchaseResult(PurchaseStatus.unavailable);
      switch (r['status']) {
        case 'success':
          final ms = r['purchaseTime'];
          return PurchaseResult(
            PurchaseStatus.success,
            plan: plan,
            purchasedAt:
                ms is int ? DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true) : null,
            token: r['token'] as String?,
          );
        case 'cancelled':
          return const PurchaseResult(PurchaseStatus.cancelled);
        case 'unavailable':
          return const PurchaseResult(PurchaseStatus.unavailable);
        default:
          return const PurchaseResult(PurchaseStatus.failed);
      }
    } on PlatformException {
      return const PurchaseResult(PurchaseStatus.failed);
    }
  }

  @override
  Future<List<PurchaseResult>> pendingPurchases() async {
    try {
      final r = await _call<List<Object?>>('pending', {'rsaKey': rsaKey});
      final out = <PurchaseResult>[];
      for (final e in r ?? const []) {
        if (e is! Map) continue;
        final plan = ProPlans.bySku('${e['sku']}');
        if (plan == null || plan.debugOnly) continue;
        final ms = e['purchaseTime'];
        out.add(PurchaseResult(
          PurchaseStatus.success,
          plan: plan,
          purchasedAt:
              ms is int ? DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true) : null,
          token: e['token'] as String?,
        ));
      }
      return out;
    } on PlatformException {
      return const [];
    }
  }

  @override
  Future<void> consume(String token) async {
    try {
      await _call<bool>('consume', {'token': token, 'rsaKey': rsaKey});
    } on PlatformException {
      // Retried through pendingPurchases() on the next launch.
    }
  }
}

/// QA/test gateway: "buys" instantly. Only wired up when
/// [AppConfig.testToolsEnabled] is true.
class SimulatedPurchaseGateway implements PurchaseGateway {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<PurchaseResult> purchase(ProPlan plan) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return PurchaseResult(PurchaseStatus.success, plan: plan, token: 'sim');
  }

  @override
  Future<List<PurchaseResult>> pendingPurchases() async => const [];

  @override
  Future<void> consume(String token) async {}
}

/// Used when no billing is available (e.g. Bazaar not installed).
class UnavailablePurchaseGateway implements PurchaseGateway {
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<PurchaseResult> purchase(ProPlan plan) async =>
      const PurchaseResult(PurchaseStatus.unavailable);
  @override
  Future<List<PurchaseResult>> pendingPurchases() async => const [];
  @override
  Future<void> consume(String token) async {}
}
