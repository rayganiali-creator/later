import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../widgets/common.dart';

/// Full-screen picture viewer for an item: swipe between pictures, pinch to
/// zoom, choose the main picture, delete.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({super.key, required this.itemId, this.initialImageId});
  final String itemId;
  final String? initialImageId;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pc;
  int _index = 0;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final imgs = context.appRead.imagesOf(widget.itemId);
    final i = imgs.indexWhere((a) => a.id == widget.initialImageId);
    _index = i < 0 ? 0 : i;
    _pc = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final imgs = app.imagesOf(widget.itemId);
    final item = app.itemById(widget.itemId);
    if (imgs.isEmpty || item == null) {
      return Scaffold(appBar: AppBar(), body: EmptyState(emoji: '🖼️', title: l.imgNone));
    }
    final i = _index.clamp(0, imgs.length - 1);
    final cur = imgs[i];
    final isCover = app.coverImageId(item) == cur.id;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${context.fmt.num(i + 1)} / ${context.fmt.num(imgs.length)}'),
        actions: [
          if (!isCover)
            IconButton(
              tooltip: l.imgSetCover,
              icon: const Icon(Icons.star_border_rounded),
              onPressed: () => app.setCover(item.id, cur.id),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Pill(l.imgCover, icon: Icons.star_rounded)),
            ),
          IconButton(
            tooltip: l.imgRemove,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final ok = await confirmDialog(context,
                  title: l.imgRemove, body: l.imgRemove, confirmLabel: l.delete, destructive: true);
              if (!ok || !context.mounted) return;
              await app.removeImage(cur.id);
              if (!context.mounted) return;
              if (app.imagesOf(widget.itemId).isEmpty) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pc,
        itemCount: imgs.length,
        onPageChanged: (v) => setState(() => _index = v),
        itemBuilder: (_, k) => _Page(imageId: imgs[k].id),
      ),
    );
  }
}

class _Page extends StatefulWidget {
  const _Page({required this.imageId});
  final String imageId;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  Future<Uint8List?>? _f;

  @override
  void initState() {
    super.initState();
    _f = null;
  }

  @override
  Widget build(BuildContext context) {
    _f ??= context.appRead.imageBytes(widget.imageId);
    return FutureBuilder<Uint8List?>(
      future: _f,
      builder: (context, snap) {
        final b = snap.data;
        if (b == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(child: Image.memory(b, fit: BoxFit.contain, gaplessPlayback: true)),
        );
      },
    );
  }
}
