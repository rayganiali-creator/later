import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../domain/pro.dart';

enum ImageOrigin { gallery, camera }

/// Gets a picture from the user. The system picker / camera app do the
/// work, so the app needs no storage or camera permission.
abstract class ImagePickerGateway {
  /// Null when the user cancelled. Throws on unreadable / oversized files.
  Future<Uint8List?> pick(ImageOrigin origin);
}

class SystemImagePicker implements ImagePickerGateway {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<Uint8List?> pick(ImageOrigin origin) async {
    final f = await _picker.pickImage(
      source: origin == ImageOrigin.camera ? ImageSource.camera : ImageSource.gallery,
      // Shrinks big photos before they reach the app (memory-friendly).
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 92,
    );
    if (f == null) return null;
    final len = await f.length();
    if (len > ProLimits.maxImageSourceBytes) {
      await _cleanup(f.path);
      throw const FileSystemException('too large');
    }
    final bytes = await f.readAsBytes();
    await _cleanup(f.path);
    return bytes;
  }

  Future<void> _cleanup(String path) async {
    try {
      // Pictures handed over by the picker live in the app's cache.
      final file = File(path);
      if (path.contains('cache') && await file.exists()) await file.delete();
    } catch (_) {}
  }
}

/// Used by tests: returns whatever it was told to.
class FakeImagePicker implements ImagePickerGateway {
  Uint8List? next;
  Object? error;
  @override
  Future<Uint8List?> pick(ImageOrigin origin) async {
    if (error != null) throw error!;
    return next;
  }
}
