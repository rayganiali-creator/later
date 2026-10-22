import 'dart:math';

final Random _secure = _createRandom();

Random _createRandom() {
  try {
    return Random.secure();
  } catch (_) {
    return Random();
  }
}

/// 128-bit random id as 32 hex chars. Collision-free for our purposes and
/// safe to embed in file names / notification payloads.
String newId() {
  final b = StringBuffer();
  for (var i = 0; i < 4; i++) {
    b.write(_secure.nextInt(1 << 32).toRadixString(16).padLeft(8, '0'));
  }
  return b.toString();
}

/// Stable 31-bit FNV-1a hash used to derive notification ids from item ids.
/// (`String.hashCode` is not guaranteed stable across runs/versions.)
int stableHash31(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}

final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_\-]{1,64}$');

/// Ids coming from files must match this to be accepted.
bool isValidId(String? s) => s != null && _idPattern.hasMatch(s);
