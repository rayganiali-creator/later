import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/pro.dart';
import '../../services/image_picker_gateway.dart';
import '../../services/image_processor.dart';
import '../app_scope.dart';
import '../screens/image_viewer_screen.dart';
import 'common.dart';
import 'item_image.dart';
import 'pro_gate.dart';

/// The "pictures" part of an item: a strip of thumbnails plus an add button.
///
/// For a saved item ([itemId]) changes are stored right away. For a draft
/// ([pending]) the processed pictures are kept in the list the parent owns and
/// stored by the parent after the item itself is saved.
class PictureSection extends StatefulWidget {
  const PictureSection({super.key, this.itemId, this.pending, this.onPendingChanged});
  final String? itemId;
  final List<ProcessedImage>? pending;
  final VoidCallback? onPendingChanged;

  @override
  State<PictureSection> createState() => _PictureSectionState();
}

class _PictureSectionState extends State<PictureSection> {
  bool _busy = false;

  Future<ImageOrigin?> _askOrigin() {
    final l = context.l10n;
    return showAppSheet<ImageOrigin>(
      context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.photo_camera_outlined, color: ctx.scheme.primary),
            title: Text(l.imgTake),
            onTap: () => Navigator.pop(ctx, ImageOrigin.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_outlined, color: ctx.scheme.primary),
            title: Text(l.imgGallery),
            onTap: () => Navigator.pop(ctx, ImageOrigin.gallery),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Text(l.imgPrivacy, style: ctx.text.bodySmall?.copyWith(color: ctx.scheme.onSurfaceVariant)),
          ),
        ]),
      ),
    );
  }

  int get _count => widget.itemId != null
      ? context.appRead.imagesOf(widget.itemId!).length
      : (widget.pending?.length ?? 0);

  Future<void> _add() async {
    final app = context.appRead;
    final l = context.l10n;
    if (_count >= app.imageLimit) {
      await showProSheet(context, featureName: l.imgProMore);
      return;
    }
    final origin = await _askOrigin();
    if (origin == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final bytes = await app.imagePicker.pick(origin);
      if (bytes == null) return;
      final p = await app.processImage(bytes);
      if (widget.itemId != null) {
        await app.attachProcessed(widget.itemId!, p);
      } else {
        widget.pending?.add(p);
        widget.onPendingChanged?.call();
      }
      if (mounted) showAppSnack(context, l.imgAdded);
    } on ImageException catch (e) {
      if (mounted) showAppSnack(context, e.kind == ImageError.tooLarge ? l.imgTooBig : l.imgInvalid);
    } on StateError {
      if (mounted) await showProSheet(context, featureName: l.imgProMore);
    } catch (_) {
      if (mounted) showAppSnack(context, l.imgFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final s = context.scheme;
    final saved = widget.itemId != null ? app.imagesOf(widget.itemId!) : const <Attachment>[];
    final item = widget.itemId != null ? app.itemById(widget.itemId!) : null;
    final cover = item == null ? null : app.coverImageId(item);
    final pending = widget.pending ?? const <ProcessedImage>[];
    final total = saved.length + pending.length;

    Widget addTile() => Semantics(
          button: true,
          label: l.imgAdd,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _busy ? null : _add,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: s.outlineVariant),
                color: s.surfaceContainer,
              ),
              child: _busy
                  ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2)))
                  : Icon(Icons.add_photo_alternate_outlined, color: s.primary),
            ),
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 76,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final a in saved)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ImageViewerScreen(itemId: widget.itemId!, initialImageId: a.id))),
                child: Stack(children: [
                  StoredImage(imageId: a.id, size: 76, radius: 14),
                  if (a.id == cover)
                    PositionedDirectional(
                      top: 4,
                      start: 4,
                      child: Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade600),
                    ),
                ]),
              ),
            ),
          for (var k = 0; k < pending.length; k++)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(pending[k].thumb, width: 76, height: 76, fit: BoxFit.cover),
                ),
                PositionedDirectional(
                  top: 2,
                  end: 2,
                  child: InkWell(
                    onTap: () {
                      widget.pending!.removeAt(k);
                      widget.onPendingChanged?.call();
                      setState(() {});
                    },
                    child: const CircleAvatar(
                        radius: 11, backgroundColor: Colors.black54, child: Icon(Icons.close_rounded, size: 14, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          addTile(),
        ]),
      ),
      if (total == 0)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(l.imgPrivacy, style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
        ),
      if (!app.access.has(ProFeature.galleryImages) && total >= 1)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: GestureDetector(
            onTap: () => showProSheet(context, featureName: l.imgProMore),
            child: Text(l.imgProMore, style: context.text.labelMedium?.copyWith(color: s.primary)),
          ),
        ),
    ]);
  }
}
