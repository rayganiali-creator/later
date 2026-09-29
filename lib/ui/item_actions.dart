import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/util/text.dart';
import '../domain/models.dart';
import '../domain/snooze.dart';
import 'app_scope.dart';
import 'widgets/common.dart';
import 'widgets/date_picker.dart';

/// Shared user-facing item operations (each shows feedback + undo).
class ItemActions {
  const ItemActions._();

  static Future<void> complete(BuildContext context, LaterItem item) async {
    final app = context.appRead;
    final l = context.l10n;
    final undo = await guarded(context, () => app.complete(item.id));
    if (!context.mounted || undo == null) return;
    showAppSnack(context, l.toastDone,
        actionLabel: l.undo, onAction: () => guarded(context, undo));
  }

  static Future<void> drop(BuildContext context, LaterItem item) async {
    final app = context.appRead;
    final l = context.l10n;
    final undo = await guarded(context, () => app.drop(item.id));
    if (!context.mounted || undo == null) return;
    showAppSnack(context, l.toastDropped,
        actionLabel: l.undo, onAction: () => guarded(context, undo));
  }

  static Future<void> delete(BuildContext context, LaterItem item, {bool confirm = true}) async {
    final app = context.appRead;
    final l = context.l10n;
    if (confirm) {
      final ok = await confirmDialog(context,
          title: l.confirmDeleteTitle,
          body: l.confirmDeleteBody,
          confirmLabel: l.delete,
          destructive: true);
      if (!ok || !context.mounted) return;
    }
    final undo = await guarded(context, () => app.delete(item.id));
    if (!context.mounted || undo == null) return;
    showAppSnack(context, l.toastDeleted,
        actionLabel: l.undo, onAction: () => guarded(context, undo));
  }

  static Future<void> reopen(BuildContext context, LaterItem item) async {
    final l = context.l10n;
    await guarded(context, () => context.appRead.reopen(item.id));
    if (context.mounted) showAppSnack(context, l.toastReopened);
  }

  static String _targetLabel(BuildContext context, SnoozeTarget t) {
    final l = context.l10n;
    final f = context.fmt;
    if (t.dueAt == null) return l.snoozeNoDate;
    final base = f.date(t.dueAt!);
    return t.hasTime ? '$base · ${f.time(t.dueAt!)}' : base;
  }

  /// Snooze via preset.
  static Future<void> snooze(BuildContext context, LaterItem item, SnoozeOption o) async {
    final app = context.appRead;
    final l = context.l10n;
    final target = app.snoozeCalculator.compute(o, app.now());
    await _applySnooze(context, item, target, l);
  }

  static Future<void> _applySnooze(
      BuildContext context, LaterItem item, SnoozeTarget target, dynamic l) async {
    final app = context.appRead;
    final label = _targetLabel(context, target);
    final undo = await guarded(context, () => app.snoozeTo(item.id, target));
    if (!context.mounted || undo == null) return;
    showAppSnack(context, context.l10n.toastSnoozed(label),
        actionLabel: context.l10n.undo, onAction: () => guarded(context, undo));
  }

  /// Snooze via calendar. Returns true when applied.
  static Future<bool> snoozeCustom(BuildContext context, LaterItem item) async {
    final r = await showAppDatePicker(context, initial: item.dueAt);
    if (r == null || r.date == null || !context.mounted) return false;
    await _applySnooze(context, item, SnoozeTarget(r.date, false), context.l10n);
    return true;
  }

  static Future<void> openLink(BuildContext context, String? url) async {
    final safe = sanitizeUrl(url);
    final l = context.l10n;
    if (safe == null) {
      showAppSnack(context, l.itemLinkFailed);
      return;
    }
    bool ok = false;
    try {
      ok = await launchUrl(Uri.parse(safe), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok && context.mounted) showAppSnack(context, l.itemLinkFailed);
  }
}
