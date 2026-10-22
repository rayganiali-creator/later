import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/pro.dart';
import '../app_scope.dart';
import '../widgets/common.dart';
import '../widgets/pro_gate.dart';

const _emojiChoices = [
  '🏷️', '✈️', '🏠', '🎮', '🎵', '📷', '🍽️', '💪', '🧠', '💰',
  '🎁', '🧰', '🚗', '🐾', '🌱', '📞', '🎓', '🩺', '🧾', '⭐',
];

/// Creates (or edits) a custom category. Returns it, or null if cancelled or
/// the free-tier limit was hit (a Pro sheet is shown in that case).
Future<ItemCategory?> showCategoryDialog(BuildContext context, {ItemCategory? existing}) async {
  final app = context.appRead;
  final l = context.l10n;
  if (existing == null && !app.canAddCategory) {
    if (context.mounted) {
      showAppSnack(context, l.categoryLimit(context.fmt.num(ProLimits.freeCustomCategories), context.fmt.num(ProLimits.proCustomCategories)));
      await showProSheet(context, featureName: l.proF4);
    }
    return null;
  }
  return showDialog<ItemCategory?>(
    context: context,
    builder: (_) => _CategoryDialog(existing: existing),
  );
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.existing});
  final ItemCategory? existing;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late String _emoji = widget.existing?.emoji ?? _emojiChoices.first;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _name.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    final app = context.appRead;
    final nav = Navigator.of(context);
    try {
      ItemCategory? c;
      final ex = widget.existing;
      if (ex == null) {
        c = await app.addCategory(text, _emoji);
      } else {
        await app.updateCategory(ex, name: text, emoji: _emoji);
        c = app.categoryById(ex.id);
      }
      nav.pop(c);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnack(context, context.l10n.errorGeneric);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.existing == null ? l.categoryNew : l.categoryEdit),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 30,
            decoration: InputDecoration(hintText: l.categoryNameHint, counterText: ''),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          Text(l.categoryEmojiHint, style: context.text.labelLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final e in _emojiChoices)
              Semantics(
                button: true,
                selected: e == _emoji,
                label: e,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: e == _emoji ? context.scheme.primaryContainer : context.scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: e == _emoji ? Border.all(color: context.scheme.primary, width: 1.5) : null,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              ),
          ]),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(onPressed: _saving ? null : _save, child: Text(l.save)),
      ],
    );
  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final custom = app.categories.where((c) => !c.builtin).toList();
    final counts = <String, int>{};
    for (final i in app.activeItems) {
      counts[i.categoryId] = (counts[i.categoryId] ?? 0) + 1;
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.categoriesManage)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.categoryNew),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l.categoryLimit(fmt.num(ProLimits.freeCustomCategories), fmt.num(ProLimits.proCustomCategories)),
              style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant),
            ),
          ),
          for (final c in app.categories.where((c) => c.builtin))
            _tile(context, c, counts[c.id] ?? 0, null),
          if (custom.isNotEmpty) const SizedBox(height: 12),
          for (final c in custom) _tile(context, c, counts[c.id] ?? 0, c),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, ItemCategory c, int count, ItemCategory? editable) {
    final app = context.appRead;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Text(c.emoji, style: const TextStyle(fontSize: 26)),
          title: Text(app.categoryName(c.id)),
          subtitle: Text(editable == null ? l.categoryBuiltin : context.fmt.num(count)),
          trailing: editable == null
              ? Text(context.fmt.num(count), style: context.text.labelLarge)
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: l.edit,
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => showCategoryDialog(context, existing: editable),
                  ),
                  IconButton(
                    tooltip: l.delete,
                    icon: Icon(Icons.delete_outline_rounded, color: context.scheme.error),
                    onPressed: () async {
                      final ok = await confirmDialog(context,
                          title: l.categoryDeleteTitle,
                          body: l.categoryDeleteBody,
                          confirmLabel: l.delete,
                          destructive: true);
                      if (ok && context.mounted) await guarded(context, () => app.deleteCategory(c.id));
                    },
                  ),
                ]),
        ),
      ),
    );
  }
}
