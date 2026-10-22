import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Private storage for the bytes of small attachments (future messages).
/// Only opaque ids are used as file names; nothing user-controlled reaches the
/// file system path.
abstract class AttachmentStore {
  Future<void> write(String id, Uint8List bytes);
  Future<Uint8List?> read(String id);
  Future<void> delete(String id);

  /// Removes every stored file whose id is not in [keep].
  Future<void> retainOnly(Set<String> keep);
}

final RegExp _safeId = RegExp(r'^[A-Za-z0-9_\-]{1,64}$');

class FileAttachmentStore implements AttachmentStore {
  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final d = Directory(p.join(base.path, 'attachments'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<File?> _file(String id) async {
    if (!_safeId.hasMatch(id)) return null;
    return File(p.join((await _dir()).path, id));
  }

  @override
  Future<void> write(String id, Uint8List bytes) async {
    final f = await _file(id);
    if (f == null) throw ArgumentError('bad id');
    await f.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List?> read(String id) async {
    final f = await _file(id);
    if (f == null || !await f.exists()) return null;
    return f.readAsBytes();
  }

  @override
  Future<void> delete(String id) async {
    final f = await _file(id);
    if (f != null && await f.exists()) await f.delete();
  }

  @override
  Future<void> retainOnly(Set<String> keep) async {
    await for (final e in (await _dir()).list()) {
      if (e is File && !keep.contains(p.basename(e.path))) {
        try {
          await e.delete();
        } catch (_) {}
      }
    }
  }
}

class MemoryAttachmentStore implements AttachmentStore {
  final Map<String, Uint8List> data = {};
  @override
  Future<void> write(String id, Uint8List bytes) async => data[id] = bytes;
  @override
  Future<Uint8List?> read(String id) async => data[id];
  @override
  Future<void> delete(String id) async => data.remove(id);
  @override
  Future<void> retainOnly(Set<String> keep) async => data.removeWhere((k, _) => !keep.contains(k));
}
