import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/config/app_config.dart';

class PickedFile {
  const PickedFile(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

class FileTooLargeException implements Exception {
  const FileTooLargeException();
}

/// File access for backups. Uses the Android system file picker (Storage
/// Access Framework), so the app needs *no* storage permission.
abstract class FileGateway {
  /// Lets the user choose where to save. Returns true when saved.
  Future<bool> saveBackup(String fileName, Uint8List bytes, {required String dialogTitle});

  /// Lets the user choose a file. Returns null when cancelled. Throws
  /// [FileTooLargeException] for files above [AppConfig.maxBackupBytes].
  Future<PickedFile?> pickBackup({required String dialogTitle});

  /// Private app storage used for automatic and pre-restore backups.
  Future<Directory> internalBackupDir();
}

class SystemFileGateway implements FileGateway {
  @override
  Future<bool> saveBackup(String fileName, Uint8List bytes, {required String dialogTitle}) async {
    final path = await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: bytes,
    );
    return path != null;
  }

  @override
  Future<PickedFile?> pickBackup({required String dialogTitle}) async {
    final f = await FilePicker.pickFile(
      dialogTitle: dialogTitle,
      type: FileType.any,
    );
    if (f == null) return null;
    final known = f.lengthSync() ?? await f.length();
    if (known != null && known > AppConfig.maxBackupBytes) {
      throw const FileTooLargeException();
    }
    // Stream with a hard cap so a hostile/huge file is never fully loaded.
    final builder = BytesBuilder(copy: false);
    await for (final chunk in f.readAsByteStream()) {
      builder.add(chunk);
      if (builder.length > AppConfig.maxBackupBytes) {
        throw const FileTooLargeException();
      }
    }
    return PickedFile(f.name, builder.takeBytes());
  }

  @override
  Future<Directory> internalBackupDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'backups'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}

/// Small helpers for the private backup directory.
class BackupFiles {
  const BackupFiles._();

  /// Writes atomically (temp file + rename) so a crash never leaves a
  /// half-written backup behind.
  static Future<void> write(String dir, String name, Uint8List bytes) async {
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final tmp = File(p.join(dir, '$safe.tmp'));
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(p.join(dir, safe));
  }

  /// Keeps only the newest [keep] files whose name starts with [prefix].
  static Future<void> prune(String dir, {required String prefix, required int keep}) async {
    final files = <File>[];
    await for (final e in Directory(dir).list()) {
      if (e is File && p.basename(e.path).startsWith(prefix)) files.add(e);
    }
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    for (final f in files.skip(keep)) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }
}
