import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../app_scope.dart';
import '../widgets/common.dart';

/// The moment a time capsule / future message opens.
class RevealScreen extends StatefulWidget {
  const RevealScreen({super.key, required this.itemId});
  final String itemId;

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> {
  LaterItem? _opened;
  bool _busy = false;
  final Map<String, Uint8List> _bytes = {};

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    final app = context.appRead;
    final r = await guarded(context, () => app.openSealed(widget.itemId));
    if (!mounted) return;
    if (r != null) {
      for (final a in app.attachmentsOf(widget.itemId)) {
        final b = await app.attachmentBytes(a.id);
        if (b != null) _bytes[a.id] = b;
      }
    }
    if (mounted) {
      setState(() {
        _opened = r;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    final item = _opened ?? app.itemById(widget.itemId);
    if (item == null) {
      return Scaffold(appBar: AppBar(), body: EmptyState(emoji: '🫥', title: l.itemNotFound));
    }
    final message = item.type == ItemType.future;
    final locked = item.isLockedAt(app.now());
    final showContent = _opened != null || item.stage == ItemStages.opened;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: locked
              ? EmptyState(
                  emoji: '🔒',
                  title: l.lockedUntil(fmt.date(item.unlockAt!, omitCurrentYear: false)),
                )
              : showContent
                  ? ListView(children: [
                      Text(message ? l.messageReturnedTitle : l.returnedTitle,
                          style: context.text.labelLarge?.copyWith(color: s.primary)),
                      const SizedBox(height: 10),
                      SelectableText(item.title, style: context.text.headlineSmall),
                      const SizedBox(height: 6),
                      Text(l.writtenOn(fmt.date(item.createdAt, omitCurrentYear: false)),
                          style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      if (item.description.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: context.appColors.lavender,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: SelectableText(item.description, style: context.text.bodyLarge?.copyWith(height: 1.9)),
                        ),
                      for (final a in app.attachmentsOf(item.id)) ...[
                        const SizedBox(height: 14),
                        if (a.isImage && _bytes[a.id] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.memory(_bytes[a.id]!, fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox.shrink()),
                          )
                        else
                          AppCard(
                            child: Row(children: [
                              const Icon(Icons.attach_file_rounded),
                              const SizedBox(width: 10),
                              Expanded(child: Text(a.name, overflow: TextOverflow.ellipsis)),
                              TextButton(
                                onPressed: _bytes[a.id] == null
                                    ? null
                                    : () => app.files.saveBackup(a.name, _bytes[a.id]!, dialogTitle: a.name),
                                child: Text(l.save),
                              ),
                            ]),
                          ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.ok)),
                    ])
                  : Column(children: [
                      const Spacer(),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.85, end: 1),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.elasticOut,
                        builder: (_, v, child) => Transform.scale(scale: v, child: child),
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: context.appColors.lavender),
                          alignment: Alignment.center,
                          child: Text(message ? '💌' : '🕰️', style: const TextStyle(fontSize: 60)),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(message ? l.messageReturnedTitle : l.returnedTitle,
                          textAlign: TextAlign.center, style: context.text.headlineSmall),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(onPressed: _busy ? null : _open, child: Text(l.openIt)),
                      ),
                    ]),
        ),
      ),
    );
  }
}
