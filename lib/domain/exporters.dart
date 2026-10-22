import 'dart:convert';
import 'dart:typed_data';

import 'models.dart';

/// Human-readable exports (Pro): CSV and Markdown.
class Exporters {
  const Exporters._();

  /// CSV cells starting with these characters are interpreted as formulas by
  /// spreadsheet apps; neutralize them (CSV injection).
  static String _cell(String v) {
    var s = v.replaceAll('\r', ' ').replaceAll('\n', ' ');
    if (s.isNotEmpty && '=+-@\t'.contains(s[0])) s = "'$s";
    if (s.contains(',') || s.contains('"') || s.contains(';')) {
      s = '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _date(DateTime? d) => d == null
      ? ''
      : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _dateTime(DateTime? d) =>
      d == null ? '' : '${_date(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// UTF-8 with BOM so Excel shows Persian text correctly.
  static Uint8List csv(Iterable<LaterItem> items, String Function(String) categoryName) {
    final b = StringBuffer('title,category,status,due,priority,minutes,url,tags,description,note,created,completed\n');
    for (final i in items) {
      b.writeln([
        _cell(i.title),
        _cell(categoryName(i.categoryId)),
        i.status.name,
        i.hasTime ? _dateTime(i.dueAt) : _date(i.dueAt),
        i.priority.name,
        i.estimatedMinutes?.toString() ?? '',
        _cell(i.url ?? ''),
        _cell(i.tags.join(' ')),
        _cell(i.description),
        _cell(i.note),
        _dateTime(i.createdAt),
        _dateTime(i.completedAt ?? i.droppedAt),
      ].join(','));
    }
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(b.toString())]);
  }

  static Uint8List markdown(Iterable<LaterItem> items, String Function(String) categoryName, {required String title}) {
    final b = StringBuffer('# $title\n\n');
    final byCat = <String, List<LaterItem>>{};
    for (final i in items) {
      (byCat[i.categoryId] ??= []).add(i);
    }
    for (final e in byCat.entries) {
      b.writeln('## ${categoryName(e.key)}\n');
      for (final i in e.value) {
        final box = i.status == ItemStatus.done ? '[x]' : '[ ]';
        final due = i.dueAt == null ? '' : ' — ${i.hasTime ? _dateTime(i.dueAt) : _date(i.dueAt)}';
        final url = i.url == null ? '' : ' (${i.url})';
        b.writeln('- $box ${i.title.replaceAll('\n', ' ')}$due$url');
      }
      b.writeln();
    }
    return Uint8List.fromList(utf8.encode(b.toString()));
  }
}
