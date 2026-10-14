import 'dart:async';

import 'package:myket_iap/myket_iap.dart';
import 'package:myket_iap/util/constants.dart';
import 'package:myket_iap/util/iab_result.dart';
import 'package:myket_iap/util/inventory.dart';
import 'package:myket_iap/util/purchase.dart';

import '../core/config/pro_plans.dart';
import 'purchase_gateway.dart';

/// The few Myket billing calls the app needs, behind an interface so the
/// gateway logic can be tested without the store.
abstract class MyketApi {
  /// Connects to the Myket app. Returns the Myket response code (0 = ok).
  Future<int> init(String rsaKey);

  /// Starts the purchase screen. Returns the response code and the purchase.
  Future<({int code, Purchase? purchase})> buy(String sku, String payload);

  /// Everything the account still owns.
  Future<List<Purchase>> owned();

  Future<bool> consume(Purchase purchase);
}

class RealMyketApi implements MyketApi {
  @override
  Future<int> init(String rsaKey) async {
    final r = await MyketIAP.init(rsaKey: rsaKey);
    return r?.mResponse ?? Constants.BILLING_RESPONSE_RESULT_BILLING_UNAVAILABLE;
  }

  @override
  Future<({int code, Purchase? purchase})> buy(String sku, String payload) async {
    final m = await MyketIAP.launchPurchaseFlow(sku: sku, payload: payload);
    final r = m[MyketIAP.RESULT];
    final p = m[MyketIAP.PURCHASE];
    return (
      code: r is IabResult ? r.mResponse : Constants.IABHELPER_UNKNOWN_ERROR,
      purchase: p is Purchase ? p : null,
    );
  }

  @override
  Future<List<Purchase>> owned() async {
    final m = await MyketIAP.queryInventory();
    final inv = m[MyketIAP.INVENTORY];
    if (inv is! Inventory) return const [];
    return inv.mPurchaseMap.values.toList();
  }

  @override
  Future<bool> consume(Purchase purchase) async {
    final m = await MyketIAP.consume(purchase: purchase);
    final r = m[MyketIAP.RESULT];
    return r is IabResult && r.isSuccess();
  }
}

/// Myket billing. Same behaviour as the Bazaar gateway: purchases are kept at
/// the market (not consumed while they still count) so Pro can be restored.
class MyketPurchaseGateway implements PurchaseGateway {
  MyketPurchaseGateway({MyketApi? api, String? rsaKey})
      : _api = api ?? RealMyketApi(),
        _rsaKey = rsaKey ?? const String.fromEnvironment('MYKET_RSA_KEY');

  final MyketApi _api;
  final String _rsaKey;
  Future<int>? _init;

  Future<bool> _ready() async {
    try {
      _init ??= _api.init(_rsaKey);
      final code = await _init!;
      if (code != Constants.BILLING_RESPONSE_RESULT_OK) _init = null; // try again next time
      return code == Constants.BILLING_RESPONSE_RESULT_OK;
    } catch (_) {
      _init = null;
      return false;
    }
  }

  @override
  Future<bool> isAvailable() => _ready();

  @override
  Future<PurchaseResult> purchase(ProPlan plan) async {
    if (!await _ready()) return const PurchaseResult(PurchaseStatus.unavailable);
    try {
      final payload = DateTime.now().microsecondsSinceEpoch.toString();
      final r = await _api.buy(plan.sku, payload);
      switch (r.code) {
        case Constants.BILLING_RESPONSE_RESULT_OK:
          final p = r.purchase;
          // Accept only a real, completed purchase of exactly this product.
          if (p == null || p.mSku != plan.sku || p.mPurchaseState != 0) {
            return const PurchaseResult(PurchaseStatus.failed);
          }
          return PurchaseResult(
            PurchaseStatus.success,
            plan: plan,
            purchasedAt: DateTime.fromMillisecondsSinceEpoch(p.mPurchaseTime, isUtc: true),
            token: p.mToken,
          );
        case Constants.BILLING_RESPONSE_RESULT_USER_CANCELED:
        case Constants.IABHELPER_USER_CANCELLED:
          return const PurchaseResult(PurchaseStatus.cancelled);
        case Constants.BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED:
          return const PurchaseResult(PurchaseStatus.alreadyOwned);
        case Constants.BILLING_RESPONSE_RESULT_BILLING_UNAVAILABLE:
        case Constants.IABHELPER_REMOTE_EXCEPTION:
          return const PurchaseResult(PurchaseStatus.unavailable);
        default:
          return const PurchaseResult(PurchaseStatus.failed);
      }
    } catch (_) {
      return const PurchaseResult(PurchaseStatus.failed);
    }
  }

  @override
  Future<List<PurchaseResult>> pendingPurchases() async {
    if (!await _ready()) return const [];
    try {
      final out = <PurchaseResult>[];
      for (final p in await _api.owned()) {
        final plan = ProPlans.bySku(p.mSku);
        if (plan == null || plan.debugOnly || p.mPurchaseState != 0) continue;
        out.add(PurchaseResult(
          PurchaseStatus.success,
          plan: plan,
          purchasedAt: DateTime.fromMillisecondsSinceEpoch(p.mPurchaseTime, isUtc: true),
          token: p.mToken,
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> consume(String token) async {
    if (!await _ready()) return;
    try {
      for (final p in await _api.owned()) {
        if (p.mToken == token) {
          await _api.consume(p);
          return;
        }
      }
    } catch (_) {
      // Retried on the next start.
    }
  }
}
