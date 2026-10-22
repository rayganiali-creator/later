import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/config/pro_plans.dart';
import 'package:later/services/myket_gateway.dart';
import 'package:later/services/purchase_gateway.dart';
import 'package:myket_iap/util/constants.dart';
import 'package:myket_iap/util/purchase.dart';

Purchase p(String sku, {int state = 0, int time = 1760000000000, String token = 'tok'}) => Purchase()
  ..mSku = sku
  ..mPurchaseState = state
  ..mPurchaseTime = time
  ..mToken = token;

class FakeMyket implements MyketApi {
  int initCode = 0;
  int buyCode = 0;
  Purchase? bought;
  List<Purchase> ownedList = [];
  final List<String> consumed = [];
  int initCalls = 0;

  @override
  Future<int> init(String rsaKey) async {
    initCalls++;
    return initCode;
  }

  @override
  Future<({int code, Purchase? purchase})> buy(String sku, String payload) async => (code: buyCode, purchase: bought);
  @override
  Future<List<Purchase>> owned() async => ownedList;
  @override
  Future<bool> consume(Purchase purchase) async {
    consumed.add(purchase.mToken);
    ownedList = [for (final o in ownedList) if (o.mToken != purchase.mToken) o];
    return true;
  }
}

void main() {
  group('Myket gateway', () {
    test('a completed purchase of the right product succeeds with the market purchase time and token', () async {
      final f = FakeMyket()..bought = p(ProPlans.month1.sku, token: 'abc', time: 1760000000000);
      final g = MyketPurchaseGateway(api: f, rsaKey: 'k');
      final r = await g.purchase(ProPlans.month1);
      expect(r.status, PurchaseStatus.success);
      expect(r.plan, ProPlans.month1);
      expect(r.token, 'abc');
      expect(r.purchasedAt, DateTime.fromMillisecondsSinceEpoch(1760000000000, isUtc: true));
    });

    test('a purchase of another product or a not-completed state is never accepted', () async {
      final f = FakeMyket()..bought = p(ProPlans.month3.sku);
      expect((await MyketPurchaseGateway(api: f, rsaKey: 'k').purchase(ProPlans.month1)).status, PurchaseStatus.failed);
      f.bought = p(ProPlans.month1.sku, state: 1);
      expect((await MyketPurchaseGateway(api: f, rsaKey: 'k').purchase(ProPlans.month1)).status, PurchaseStatus.failed);
      f.bought = null;
      expect((await MyketPurchaseGateway(api: f, rsaKey: 'k').purchase(ProPlans.month1)).status, PurchaseStatus.failed);
    });

    test('cancel, already owned and unavailable map to the app statuses', () async {
      final f = FakeMyket();
      final g = MyketPurchaseGateway(api: f, rsaKey: 'k');
      f.buyCode = Constants.BILLING_RESPONSE_RESULT_USER_CANCELED;
      expect((await g.purchase(ProPlans.month1)).status, PurchaseStatus.cancelled);
      f.buyCode = Constants.IABHELPER_USER_CANCELLED;
      expect((await g.purchase(ProPlans.month1)).status, PurchaseStatus.cancelled);
      f.buyCode = Constants.BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED;
      expect((await g.purchase(ProPlans.month1)).status, PurchaseStatus.alreadyOwned);
      f.buyCode = Constants.BILLING_RESPONSE_RESULT_ERROR;
      expect((await g.purchase(ProPlans.month1)).status, PurchaseStatus.failed);
    });

    test('Myket missing: unavailable, nothing owned, and it connects again next time', () async {
      final f = FakeMyket()..initCode = Constants.BILLING_RESPONSE_RESULT_BILLING_UNAVAILABLE;
      final g = MyketPurchaseGateway(api: f, rsaKey: 'k');
      expect(await g.isAvailable(), isFalse);
      expect((await g.purchase(ProPlans.month1)).status, PurchaseStatus.unavailable);
      expect(await g.pendingPurchases(), isEmpty);
      f.initCode = 0;
      expect(await g.isAvailable(), isTrue);
    });

    test('owned purchases are listed (known plans only) and consume finds the purchase by token', () async {
      final f = FakeMyket()
        ..ownedList = [p(ProPlans.month1.sku, token: 'a'), p('unknown_sku', token: 'b'), p(ProPlans.month3.sku, token: 'c', state: 1)];
      final g = MyketPurchaseGateway(api: f, rsaKey: 'k');
      final list = await g.pendingPurchases();
      expect(list.map((e) => e.token), ['a']);
      await g.consume('a');
      expect(f.consumed, ['a']);
      expect(f.initCalls, 1, reason: 'connects once and reuses the connection');
    });
  });
}
