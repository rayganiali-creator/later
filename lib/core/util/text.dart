/// Persian/Arabic text helpers.
const _fa = '۰۱۲۳۴۵۶۷۸۹';
const _ar = '٠١٢٣٤٥٦٧٨٩';

/// Converts ASCII digits to Persian digits.
String toFaDigits(Object? v) {
  final s = '$v';
  final b = StringBuffer();
  for (final c in s.codeUnits) {
    if (c >= 0x30 && c <= 0x39) {
      b.write(_fa[c - 0x30]);
    } else {
      b.writeCharCode(c);
    }
  }
  return b.toString();
}

/// Converts Persian/Arabic digits to ASCII digits.
String toEnDigits(String s) {
  final b = StringBuffer();
  for (final c in s.split('')) {
    final i = _fa.indexOf(c);
    final j = _ar.indexOf(c);
    if (i >= 0) {
      b.write(i);
    } else if (j >= 0) {
      b.write(j);
    } else {
      b.write(c);
    }
  }
  return b.toString();
}

/// Normalizes text for searching: unifies Arabic/Persian letter variants,
/// removes diacritics and ZWNJ, unifies digits, lowercases Latin.
String normalizeForSearch(String input) {
  final s = toEnDigits(input);
  final b = StringBuffer();
  for (final r in s.runes) {
    switch (r) {
      case 0x064A: // ي
      case 0x0649: // ى
        b.write('ی');
      case 0x0643: // ك
        b.write('ک');
      case 0x0629: // ة
        b.write('ه');
      case 0x0623: // أ
      case 0x0625: // إ
      case 0x0671: // ٱ
        b.write('ا');
      case 0x200C: // ZWNJ
      case 0x200D:
      case 0x200E:
      case 0x200F:
      case 0x0640: // tatweel
        b.write(r == 0x200C ? ' ' : '');
      default:
        if (r >= 0x064B && r <= 0x065F) continue; // harakat
        if (r == 0x0670) continue;
        b.writeCharCode(r);
    }
  }
  return b.toString().toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Validates and normalizes a user supplied URL. Only http(s) links are
/// accepted; anything else (javascript:, file:, intent:, content:...) is
/// rejected so it can never be launched.
String? sanitizeUrl(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  if (s.isEmpty || s.length > 4000) return null;
  if (!s.contains('://')) {
    if (s.contains(' ') || !s.contains('.')) return null;
    s = 'https://$s';
  }
  final uri = Uri.tryParse(s);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty) return null;
  return uri.toString();
}

/// Extracts the first http(s) URL from a free-form text (share sheet).
String? extractFirstUrl(String text) {
  final m = RegExp(r'https?://[^\s<>"]+', caseSensitive: false)
      .firstMatch(text);
  if (m == null) return null;
  var u = m.group(0)!;
  while (u.isNotEmpty && '.,;:!?)]}»"\''.contains(u[u.length - 1])) {
    u = u.substring(0, u.length - 1);
  }
  return sanitizeUrl(u);
}

/// Trims and clamps length, collapsing control characters.
String cleanText(String? s, int max) {
  if (s == null) return '';
  final t = s.replaceAll(RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'), '');
  final trimmed = t.trim();
  return trimmed.length > max ? trimmed.substring(0, max) : trimmed;
}
