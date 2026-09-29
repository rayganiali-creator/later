import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/config/pro_plans.dart';
import 'package:later/data/pro/pro_service.dart';
import 'package:later/domain/pro.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 30, 12);

  group('ProEntitlement maths', () {
    test('inactive by default', () {
      expect(ProEntitlement.none.isActiveAt(t0), isFalse);
      expect(ProEntitlement.none.remainingAt(t0), Duration.zero);
    });

    test('Scenario 1: 1 month => active, then inactive after 30 days', () {
      final e = ProEntitlement.none.applyPurchase(ProPlans.month1, t0);
      expect(e.isActiveAt(t0), isTrue);
      expect(e.isActiveAt(t0.add(const Duration(days: 29, hours: 23))), isTrue);
      expect(e.isActiveAt(t0.add(const Duration(days: 30))), isFalse);
      expect(e.expiresAt, t0.add(const Duration(days: 30)));
      expect(e.planType, ProPlanType.month1);
      expect(e.startAt, t0);
    });

    test('Scenario 2: 3 months lasts exactly 90 days', () {
      final e = ProEntitlement.none.applyPurchase(ProPlans.month3, t0);
      expect(e.expiresAt, t0.add(const Duration(days: 90)));
      expect(e.isActiveAt(t0.add(const Duration(days: 90, seconds: -1))), isTrue);
      expect(e.isActiveAt(t0.add(const Duration(days: 90))), isFalse);
    });

    test('Scenario 3: 6 months lasts exactly 180 days', () {
      final e = ProEntitlement.none.applyPurchase(ProPlans.month6, t0);
      expect(e.expiresAt, t0.add(const Duration(days: 180)));
      expect(e.isActiveAt(t0.add(const Duration(days: 180, seconds: -1))), isTrue);
      expect(e.isActiveAt(t0.add(const Duration(days: 180))), isFalse);
    });

    test('Scenario 4: 15 days left on 1 month + 3 months => 15d + 90d', () {
      final first = ProEntitlement.none.applyPurchase(ProPlans.month1, t0);
      final at = t0.add(const Duration(days: 15));
      final e = first.applyPurchase(ProPlans.month3, at);
      expect(e.expiresAt, at.add(const Duration(days: 15 + 90)));
      // start of the *original* subscription is kept while it was running
      expect(e.startAt, t0);
      expect(e.planType, ProPlanType.month3);
    });

    test('Scenario 5: expired Pro + new purchase starts at purchase time', () {
      final first = ProEntitlement.none.applyPurchase(ProPlans.month1, t0);
      final at = t0.add(const Duration(days: 45));
      expect(first.isActiveAt(at), isFalse);
      final e = first.applyPurchase(ProPlans.month3, at);
      expect(e.startAt, at);
      expect(e.expiresAt, at.add(const Duration(days: 90)));
    });

    test('stacking works for every plan combination', () {
      for (final a in ProPlans.sellable) {
        for (final b in ProPlans.sellable) {
          final e1 = ProEntitlement.none.applyPurchase(a, t0);
          final at = t0.add(const Duration(days: 7));
          final e2 = e1.applyPurchase(b, at);
          expect(e2.expiresAt,
              t0.add(Duration(days: a.durationDays + b.durationDays)));
        }
      }
    });

    test('purchase at the exact expiry instant starts fresh', () {
      final e1 = ProEntitlement.none.applyPurchase(ProPlans.month1, t0);
      final at = e1.expiresAt!;
      final e2 = e1.applyPurchase(ProPlans.month1, at);
      expect(e2.expiresAt, at.add(const Duration(days: 30)));
    });

    test('json round trip and invalid json', () {
      final e = ProEntitlement.none.applyPurchase(ProPlans.month3, t0);
      expect(ProEntitlement.fromJson(e.toJson()), e);
      expect(ProEntitlement.fromJson({'planType': 'bogus'}), isNull);
      expect(ProEntitlement.fromJson({'planType': 'month1', 'expiresAt': 'x'}), isNull);
      expect(ProEntitlement.fromJson(5), isNull);
    });

    test('prices come from central config', () {
      expect(ProPlans.month1.priceToman, 19000);
      expect(ProPlans.month3.priceToman, 55000);
      expect(ProPlans.month6.priceToman, 100000);
      expect(ProPlans.sellable.every((p) => !p.debugOnly), isTrue);
    });
  });

  group('ProService', () {
    late DateTime now;
    late MemoryVault vault;
    late ProService svc;

    setUp(() {
      now = t0;
      vault = MemoryVault();
      svc = ProService(vault: vault, clock: () => now, backupSigningKey: 'k');
    });

    test('purchase persists and survives reload', () async {
      await svc.applyPurchase(ProPlans.month1);
      expect(svc.isActive(), isTrue);
      final again = ProService(vault: vault, clock: () => now, backupSigningKey: 'k');
      await again.load();
      expect(again.isActive(), isTrue);
      expect(again.entitlement, svc.entitlement);
    });

    test('expires by itself, data model untouched', () async {
      await svc.applyPurchase(ProPlans.month1);
      now = t0.add(const Duration(days: 31));
      expect(svc.isActive(), isFalse);
      expect(svc.access().isPro, isFalse);
      expect(svc.access().has(ProFeature.fullStatistics), isFalse);
    });

    test('rolling the clock back does not extend Pro', () async {
      await svc.applyPurchase(ProPlans.month1);
      now = t0.add(const Duration(days: 31));
      await svc.touch(); // app opened after expiry
      now = t0.add(const Duration(days: 5)); // user sets clock back
      expect(svc.isActive(), isFalse);
      final again = ProService(vault: vault, clock: () => now, backupSigningKey: 'k');
      await again.load();
      expect(again.isActive(), isFalse);
    });

    test('tampered record is rejected', () async {
      await svc.applyPurchase(ProPlans.month1);
      final raw = vault.data['pro.record.v1']!;
      vault.data['pro.record.v1'] = raw.replaceFirst('month1', 'month6');
      final again = ProService(vault: vault, clock: () => now, backupSigningKey: 'k');
      await again.load();
      expect(again.isActive(), isFalse);
      expect(again.tamperDetected, isTrue);
    });

    test('garbage record is rejected without throwing', () async {
      vault.data['pro.record.v1'] = 'nonsense';
      await svc.load();
      expect(svc.isActive(), isFalse);
    });

    test('backup export/import (reinstall scenario)', () async {
      await svc.applyPurchase(ProPlans.month3);
      final blob = svc.exportForBackup()!;
      final fresh = ProService(vault: MemoryVault(), clock: () => now, backupSigningKey: 'k');
      expect(await fresh.importFromBackup(blob), isTrue);
      expect(fresh.entitlement, svc.entitlement);
    });

    test('backup with forged signature / edited expiry is ignored', () async {
      await svc.applyPurchase(ProPlans.month1);
      final blob = Map<String, Object?>.from(svc.exportForBackup()!);
      final ent = Map<String, Object?>.from(blob['entitlement']! as Map);
      ent['expiresAt'] = (ent['expiresAt']! as int) + 999999999;
      blob['entitlement'] = ent;
      final fresh = ProService(vault: MemoryVault(), clock: () => now, backupSigningKey: 'k');
      expect(await fresh.importFromBackup(blob), isFalse);
      expect(fresh.isActive(), isFalse);
      // wrong key on another build
      final other = ProService(vault: MemoryVault(), clock: () => now, backupSigningKey: 'other');
      expect(await other.importFromBackup(svc.exportForBackup()), isFalse);
    });

    test('expired backup entitlement is not restored; longer local one is kept', () async {
      await svc.applyPurchase(ProPlans.month1);
      final blob = svc.exportForBackup();
      now = t0.add(const Duration(days: 40));
      final fresh = ProService(vault: MemoryVault(), clock: () => now, backupSigningKey: 'k');
      expect(await fresh.importFromBackup(blob), isFalse);

      now = t0;
      await svc.applyPurchase(ProPlans.month6);
      expect(await svc.importFromBackup(blob), isFalse);
    });

    test('no signing key => nothing exported or imported', () async {
      final nokey = ProService(vault: MemoryVault(), clock: () => now, backupSigningKey: '');
      await nokey.applyPurchase(ProPlans.month1);
      expect(nokey.exportForBackup(), isNull);
      expect(await nokey.importFromBackup({'entitlement': {}, 'sig': 'x'}), isFalse);
    });

    test('clear() removes Pro only', () async {
      await svc.applyPurchase(ProPlans.month1);
      await svc.clear();
      expect(svc.isActive(), isFalse);
    });

    test('custom category limit follows entitlement', () async {
      expect(svc.access().customCategoryLimit, ProLimits.freeCustomCategories);
      await svc.applyPurchase(ProPlans.month1);
      expect(svc.access().customCategoryLimit, ProLimits.proCustomCategories);
    });
  });
}
