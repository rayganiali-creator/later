import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config/pro_plans.dart';
import '../../domain/pro.dart';

/// Key/value secret storage. Production uses the Android Keystore backed
/// [SecureVault]; tests use [MemoryVault].
abstract class Vault {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureVault implements Vault {
  SecureVault([FlutterSecureStorage? s]) : _s = s ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;

  @override
  Future<String?> read(String key) async {
    try {
      return await _s.read(key: key);
    } catch (_) {
      return null; // corrupted keystore entry => treated as "no Pro"
    }
  }

  @override
  Future<void> write(String key, String value) => _s.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

class MemoryVault implements Vault {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

/// Owns the Pro entitlement: persistence (secure + integrity protected),
/// clock-rollback protection and purchase stacking.
///
/// Threat model (documented in docs/SECURITY.md): the app is local-first, so a
/// determined user with a rooted device / modified APK can always forge local
/// state. We make casual tampering (editing files, restoring old app data,
/// setting the clock back, hand-editing backups) ineffective, and we keep the
/// purchase verification hook ([PurchaseGateway]) separate so that a server or
/// market-side receipt check can be added later without touching the UI.
class ProService extends ChangeNotifier {
  ProService({
    required Vault vault,
    DateTime Function()? clock,
    String backupSigningKey = const String.fromEnvironment('LATER_PRO_SIGNING_KEY'),
  })  : _clock = clock ?? DateTime.now,
        _backupKey = backupSigningKey,
        _vault = vault;

  static const _kRecord = 'pro.record.v1';
  static const _kDeviceKey = 'pro.devkey.v1';

  final Vault _vault;
  final DateTime Function() _clock;
  final String _backupKey;

  ProEntitlement _entitlement = ProEntitlement.none;
  DateTime? _lastSeen;
  bool _tamperDetected = false;
  List<int>? _deviceKey;

  ProEntitlement get entitlement => _entitlement;
  bool get tamperDetected => _tamperDetected;
  bool get backupSigningAvailable => _backupKey.isNotEmpty;

  /// "Now" for entitlement decisions. Never earlier than the latest time we
  /// have seen, so rolling the device clock back cannot extend Pro.
  DateTime effectiveNow([DateTime? raw]) {
    final n = (raw ?? _clock()).toUtc();
    final seen = _lastSeen;
    return (seen != null && seen.isAfter(n)) ? seen : n;
  }

  bool isActive([DateTime? now]) => _entitlement.isActiveAt(effectiveNow(now));

  ProAccess access([DateTime? now]) => ProAccess(_entitlement, effectiveNow(now));

  Future<void> load() async {
    final raw = await _vault.read(_kRecord);
    if (raw == null) return;
    final rec = await _decodeRecord(raw);
    if (rec == null) {
      _tamperDetected = true;
      _entitlement = ProEntitlement.none;
    } else {
      _entitlement = rec.$1;
      _lastSeen = rec.$2;
    }
    await touch();
    notifyListeners();
  }

  /// Records that time has reached "now" (monotonic high-water mark).
  Future<void> touch([DateTime? raw]) async {
    final n = (raw ?? _clock()).toUtc();
    if (_lastSeen == null || n.isAfter(_lastSeen!)) {
      _lastSeen = n;
      await _persist();
    }
  }

  /// Applies a completed purchase. [purchasedAt] should be the market's
  /// purchase time when available.
  Future<ProEntitlement> applyPurchase(ProPlan plan, {DateTime? purchasedAt}) async {
    final now = effectiveNow(purchasedAt);
    _entitlement = _entitlement.applyPurchase(plan, now);
    _tamperDetected = false;
    await touch(now);
    await _persist();
    notifyListeners();
    return _entitlement;
  }

  /// Removes Pro (QA tools / reset). User data is never touched.
  Future<void> clear() async {
    _entitlement = ProEntitlement.none;
    await _persist();
    notifyListeners();
  }

  /// QA only: forgets the clock high-water mark (used with time travel).
  Future<void> debugResetClockMark() async {
    _lastSeen = null;
    await _persist();
  }

  // ------------------------------------------------------------ persistence

  Future<List<int>> _key() async {
    if (_deviceKey != null) return _deviceKey!;
    final existing = await _vault.read(_kDeviceKey);
    if (existing != null) {
      try {
        _deviceKey = base64Decode(existing);
        return _deviceKey!;
      } catch (_) {}
    }
    final r = Random.secure();
    final k = List<int>.generate(32, (_) => r.nextInt(256));
    await _vault.write(_kDeviceKey, base64Encode(k));
    _deviceKey = k;
    return k;
  }

  Future<void> _persist() async {
    final payload = jsonEncode({
      'v': 1,
      'e': _entitlement.toJson(),
      'seen': _lastSeen?.millisecondsSinceEpoch,
    });
    final mac = Hmac(sha256, await _key()).convert(utf8.encode(payload)).toString();
    await _vault.write(_kRecord, '$payload.$mac');
  }

  Future<(ProEntitlement, DateTime?)?> _decodeRecord(String raw) async {
    final idx = raw.lastIndexOf('.');
    if (idx <= 0) return null;
    final payload = raw.substring(0, idx);
    final mac = raw.substring(idx + 1);
    final expected = Hmac(sha256, await _key()).convert(utf8.encode(payload)).toString();
    if (!_constantTimeEquals(mac, expected)) return null;
    try {
      final m = jsonDecode(payload);
      if (m is! Map) return null;
      final e = ProEntitlement.fromJson(m['e']);
      if (e == null) return null;
      final seen = m['seen'];
      return (
        e,
        seen is int ? DateTime.fromMillisecondsSinceEpoch(seen, isUtc: true) : null
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------- backup

  /// Signed entitlement for inclusion in a backup file, or null when signing
  /// is not configured or there is nothing to store.
  Map<String, Object?>? exportForBackup() {
    if (_backupKey.isEmpty || _entitlement.expiresAt == null) return null;
    final body = _entitlement.encode();
    return {'entitlement': _entitlement.toJson(), 'sig': _sign(body)};
  }

  String _sign(String body) =>
      Hmac(sha256, utf8.encode(_backupKey)).convert(utf8.encode(body)).toString();

  /// Adopts a backup's entitlement if its signature is valid, it is not in
  /// the future relative to [now] and it is still running. Returns true when
  /// the local entitlement changed.
  Future<bool> importFromBackup(Map<String, Object?>? blob, {DateTime? now}) async {
    if (blob == null || _backupKey.isEmpty) return false;
    final ent = ProEntitlement.fromJson(blob['entitlement']);
    final sig = blob['sig'];
    if (ent == null || sig is! String) return false;
    if (!_constantTimeEquals(sig, _sign(ent.encode()))) return false;
    final n = effectiveNow(now);
    if (!ent.isActiveAt(n)) return false;
    if (ent.startAt != null && ent.startAt!.isAfter(n.add(const Duration(days: 1)))) {
      return false;
    }
    final cur = _entitlement.expiresAt;
    if (cur != null && !ent.expiresAt!.isAfter(cur)) return false;
    _entitlement = ent;
    await _persist();
    notifyListeners();
    return true;
  }
}

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var r = 0;
  for (var i = 0; i < a.length; i++) {
    r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return r == 0;
}
