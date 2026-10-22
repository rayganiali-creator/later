import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../app_scope.dart';
import '../type_info.dart';

/// A small picture of an item (its cover), or a tinted icon when it has none.
class CoverThumb extends StatelessWidget {
  const CoverThumb({super.key, required this.item, this.size = 52, this.radius = 14, this.emoji});
  final LaterItem item;
  final double size, radius;

  /// Shown instead of the type icon when there is no picture.
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final id = app.coverImageId(item);
    final color = TypeInfo.color(item.type);
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.5))
          : Icon(TypeInfo.icon(item.type), color: color, size: size * 0.5),
    );
    if (id == null) return fallback;
    return StoredImage(imageId: id, size: size, radius: radius, thumb: true, fallback: fallback);
  }
}

/// A stored picture, either its small preview or the full image.
class StoredImage extends StatefulWidget {
  const StoredImage({
    super.key,
    required this.imageId,
    this.size,
    this.radius = 12,
    this.thumb = true,
    this.fit = BoxFit.cover,
    this.fallback,
  });
  final String imageId;
  final double? size;
  final double radius;
  final bool thumb;
  final BoxFit fit;
  final Widget? fallback;

  @override
  State<StoredImage> createState() => _StoredImageState();
}

class _StoredImageState extends State<StoredImage> {
  Future<Uint8List?>? _f;
  String? _for;

  @override
  Widget build(BuildContext context) {
    final app = context.appRead;
    if (_for != widget.imageId + (widget.thumb ? 't' : 'f')) {
      _for = widget.imageId + (widget.thumb ? 't' : 'f');
      _f = widget.thumb ? app.thumbBytes(widget.imageId) : app.imageBytes(widget.imageId);
    }
    final s = widget.size;
    return FutureBuilder<Uint8List?>(
      future: _f,
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) {
          return widget.fallback ??
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                    color: context.scheme.surfaceContainer, borderRadius: BorderRadius.circular(widget.radius)),
              );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: Image.memory(
            bytes,
            width: s,
            height: s,
            fit: widget.fit,
            gaplessPlayback: true,
            cacheWidth: s == null ? 1200 : (s * 3).round(),
            errorBuilder: (_, _, _) => widget.fallback ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
