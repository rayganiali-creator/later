import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../app_scope.dart';
import '../type_info.dart';
import '../widgets/common.dart';

/// Opened by the home-screen widget's "+": a title and one tap for the kind
/// of thing, saved straight away. The details can be filled in later.
Future<void> showQuickCapture(BuildContext context, {bool leaveAfterSave = true}) {
  return showAppSheet<void>(context, builder: (_) => _QuickCapture(leaveAfterSave: leaveAfterSave));
}

class _QuickCapture extends StatefulWidget {
  const _QuickCapture({required this.leaveAfterSave});
  final bool leaveAfterSave;

  @override
  State<_QuickCapture> createState() => _QuickCaptureState();
}

class _QuickCaptureState extends State<_QuickCapture> {
  final _title = TextEditingController();
  ItemType _type = ItemType.task;
  bool _saving = false;

  static const kinds = [
    ItemType.task,
    ItemType.read,
    ItemType.watch,
    ItemType.podcast,
    ItemType.app,
    ItemType.game,
    ItemType.course,
    ItemType.wishlist,
    ItemType.idea,
  ];

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (_saving || _title.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final app = context.appRead;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await app.quickAdd(_title.text, type: _type, source: 'widget', inbox: _type == ItemType.task);
      nav.pop();
      messenger?.showSnackBar(SnackBar(content: Text(l.captureSaved), duration: const Duration(seconds: 2)));
      if (widget.leaveAfterSave) await app.platform.moveToBack();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnack(context, l.errorGeneric);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(l.widgetQuickAdd, style: context.text.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            autofocus: true,
            maxLength: 500,
            maxLines: null,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(hintText: l.captureHint, counterText: ''),
          ),
          const SizedBox(height: 10),
          Text(l.captureKinds, style: context.text.labelLarge?.copyWith(color: context.scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in kinds)
              ChoiceChip(
                avatar: Icon(TypeInfo.icon(t), size: 18, color: TypeInfo.color(t)),
                label: Text(t == ItemType.task ? l.navList : TypeInfo.shelfTitle(l, t)),
                selected: _type == t,
                onSelected: (_) => setState(() => _type = t),
              ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _saving ? null : _save, child: Text(l.save)),
          ),
        ]),
      ),
    );
  }
}
