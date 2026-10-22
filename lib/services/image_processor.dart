import 'dart:async';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../domain/pro.dart';

enum ImageError { tooLarge, invalid }

class ImageException implements Exception {
  const ImageException(this.kind);
  final ImageError kind;
  @override
  String toString() => 'ImageException($kind)';
}

/// A picture ready to store: a shrunk JPEG and a small preview of it.
class ProcessedImage {
  const ProcessedImage({required this.full, required this.thumb, required this.width, required this.height});
  final Uint8List full;
  final Uint8List thumb;
  final int width, height;
}

abstract class ImageProcessor {
  /// Validates [source] (type, size), shrinks it, strips metadata (EXIF, GPS)
  /// by re-encoding, and makes a thumbnail. Throws [ImageException].
  Future<ProcessedImage> process(Uint8List source);
}

/// What kind of picture a byte string really is, from its first bytes (the
/// file name or MIME type given by another app is never trusted).
String? sniffImageType(Uint8List b) {
  bool at(int i, List<int> s) {
    if (b.length < i + s.length) return false;
    for (var k = 0; k < s.length; k++) {
      if (b[i + k] != s[k]) return false;
    }
    return true;
  }

  if (at(0, [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (at(0, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) return 'image/png';
  if (at(0, [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
  if (at(0, [0x52, 0x49, 0x46, 0x46]) && at(8, [0x57, 0x45, 0x42, 0x50])) return 'image/webp';
  if (at(0, [0x42, 0x4D])) return 'image/bmp';
  if (at(4, [0x66, 0x74, 0x79, 0x70]) && (at(8, [0x68, 0x65, 0x69]) || at(8, [0x6D, 0x69, 0x66, 0x31]))) {
    return 'image/heic';
  }
  return null;
}

class _EncodeJob {
  _EncodeJob(this.rgba, this.w, this.h, this.quality);
  final TransferableTypedData rgba;
  final int w, h, quality;
}

/// Runs off the UI isolate: flatten transparency on white, drop the alpha
/// channel and encode a JPEG.
Uint8List _encodeJpeg(_EncodeJob j) {
  final src = j.rgba.materialize().asUint8List();
  final out = Uint8List(j.w * j.h * 3);
  var o = 0;
  for (var i = 0; i < src.length; i += 4) {
    final a = src[i + 3];
    if (a == 255) {
      out[o++] = src[i];
      out[o++] = src[i + 1];
      out[o++] = src[i + 2];
    } else {
      out[o++] = (src[i] * a + 255 * (255 - a)) ~/ 255;
      out[o++] = (src[i + 1] * a + 255 * (255 - a)) ~/ 255;
      out[o++] = (src[i + 2] * a + 255 * (255 - a)) ~/ 255;
    }
  }
  final image = img.Image.fromBytes(width: j.w, height: j.h, bytes: out.buffer, numChannels: 3);
  return Uint8List.fromList(img.encodeJpg(image, quality: j.quality));
}

class DefaultImageProcessor implements ImageProcessor {
  const DefaultImageProcessor();

  Future<(Uint8List, int, int)> _render(Uint8List src, int maxEdge, int quality) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(src);
    ui.ImageDescriptor desc;
    try {
      desc = await ui.ImageDescriptor.encoded(buffer);
    } catch (_) {
      buffer.dispose();
      throw const ImageException(ImageError.invalid);
    }
    try {
      final w = desc.width, h = desc.height;
      if (w <= 0 || h <= 0 || w * h > 120 * 1000 * 1000) {
        throw const ImageException(ImageError.invalid); // decompression-bomb guard
      }
      final long = w > h ? w : h;
      final scale = long > maxEdge ? maxEdge / long : 1.0;
      final tw = (w * scale).round().clamp(1, w);
      final th = (h * scale).round().clamp(1, h);
      final codec = await desc.instantiateCodec(targetWidth: tw, targetHeight: th);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final ow = image.width, oh = image.height;
      image.dispose();
      codec.dispose();
      if (data == null) throw const ImageException(ImageError.invalid);
      final job = _EncodeJob(
        TransferableTypedData.fromList([data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)]),
        ow,
        oh,
        quality,
      );
      final bytes = await compute(_encodeJpeg, job);
      return (bytes, ow, oh);
    } finally {
      desc.dispose();
      buffer.dispose();
    }
  }

  @override
  Future<ProcessedImage> process(Uint8List source) async {
    if (source.length > ProLimits.maxImageSourceBytes) throw const ImageException(ImageError.tooLarge);
    if (source.isEmpty || sniffImageType(source) == null) throw const ImageException(ImageError.invalid);
    try {
      var q = 82;
      var full = await _render(source, ProLimits.imageMaxEdge, q);
      while (full.$1.length > 900 * 1024 && q > 50) {
        q -= 12;
        full = await _render(source, ProLimits.imageMaxEdge, q);
      }
      final thumb = await _render(source, ProLimits.thumbEdge, 74);
      return ProcessedImage(full: full.$1, thumb: thumb.$1, width: full.$2, height: full.$3);
    } on ImageException {
      rethrow;
    } catch (_) {
      throw const ImageException(ImageError.invalid);
    }
  }
}
