import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/backup/backup_codec.dart';
import '../../domain/exporters.dart';
import '../../services/file_gateway.dart';
import '../app_scope.dart';
import '../widgets/common.dart';
import '../widgets/pro_gate.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  String _errorText(BackupError e) {
    final l = context.l10n;
    return switch (e) {
      BackupError.empty => l.backupErrEmpty,
      BackupError.tooLarge => l.backupErrTooLarge,
      BackupError.notJson => l.backupErrNotJson,
      BackupError.notABackup => l.backupErrNotBackup,
      BackupError.missingFields => l.backupErrMissing,
      BackupError.futureVersion => l.backupErrFuture,
      BackupError.unsupportedVersion => l.backupErrUnsupported,
      BackupError.checksumMismatch => l.backupErrChecksum,
      BackupError.invalidData => l.backupErrInvalid,
      BackupError.migrationFailed => l.backupErrMigration,
    };
  }

  Future<void> _export() async {
    final l = context.l10n;
    final app = context.appRead;
    setState(() => _busy = true);
    try {
      final ok = await app.exportBackup(dialogTitle: l.backupExport);
      if (ok && mounted) showAppSnack(context, l.backupExported);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errorGeneric, actionLabel: l.retry, onAction: _export);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportText(bool csv) async {
    final l = context.l10n;
    final app = context.appRead;
    if (!app.isPro) {
      await showProSheet(context, featureName: l.backupAdvancedExport);
      return;
    }
    setState(() => _busy = true);
    try {
      final items = app.allItems;
      final n = app.now();
      final stamp = '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
      final bytes = csv
          ? Exporters.csv(items, app.categoryName)
          : Exporters.markdown(items, app.categoryName, title: l.appName);
      final ok = await app.files.saveBackup('Later_$stamp.${csv ? 'csv' : 'md'}', bytes,
          dialogTitle: csv ? l.exportCsv : l.exportText);
      if (ok && mounted) showAppSnack(context, l.exportSaved);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errorGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final l = context.l10n;
    final app = context.appRead;
    final fmt = context.fmt;
    setState(() => _busy = true);
    try {
      final picked = await app.files.pickBackup(dialogTitle: l.backupImport);
      if (picked == null) return;
      final DecodedBackup decoded;
      try {
        decoded = app.inspectBackup(picked.bytes);
      } on BackupException catch (e) {
        if (mounted) {
          await _showError(_errorText(e.error));
        }
        return;
      }
      if (!mounted) return;
      final incoming = decoded.snapshot.items.length;
      final date = fmt.date(decoded.createdAt, omitCurrentYear: false);
      final body = app.hasUserData
          ? l.restoreConfirmReplace(fmt.num(app.allItems.length), fmt.num(incoming), date)
          : l.restoreConfirmEmpty(fmt.num(incoming), date);
      final ok = await confirmDialog(context,
          title: l.restoreConfirmTitle, body: body, confirmLabel: l.restoreAction, destructive: app.hasUserData);
      if (!ok || !mounted) return;
      final hadPro = app.isPro;
      await app.restore(decoded);
      if (!mounted) return;
      showAppSnack(context, l.restoreDone);
      if (!hadPro && app.isPro) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (mounted) showAppSnack(context, l.restoreProRestored);
      }
    } on FileTooLargeException {
      if (mounted) await _showError(l.backupErrTooLarge);
    } catch (_) {
      if (mounted) await _showError(l.backupErrGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showError(String text) {
    final l = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.error_outline_rounded, color: ctx.scheme.error, size: 34),
        title: Text(l.backupImport),
        content: Text('$text\n\n${l.backupNoChange}'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.ok))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final st = app.settings;
    final s = context.scheme;
    final last = st.lastBackupAt;

    return Scaffold(
      appBar: AppBar(title: Text(l.backupTitle)),
      body: Stack(children: [
        ListView(padding: const EdgeInsets.all(20), children: [
          Text(l.backupIntro, style: context.text.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
          const SizedBox(height: 16),
          AppCard(
            child: Row(children: [
              Icon(last == null ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
                  color: last == null ? context.appColors.warning : context.appColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  last == null ? l.backupNever : l.backupLast(fmt.date(last, omitCurrentYear: false)),
                  style: context.text.titleSmall,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(l.backupExport),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
            child: Text(l.backupExportSub, style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _import,
            icon: const Icon(Icons.download_rounded),
            label: Text(l.backupImport),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
            child: Text(l.backupImportSub, style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              SwitchListTile(
                value: st.autoBackup && app.isPro,
                onChanged: (v) {
                  if (!app.isPro) {
                    showProSheet(context, featureName: l.backupAuto);
                    return;
                  }
                  app.updateSettings((x) => x.copyWith(autoBackup: v));
                },
                title: Row(children: [
                  Flexible(child: Text(l.backupAuto)),
                  if (!app.isPro) ...[const SizedBox(width: 8), const ProTag()],
                ]),
                subtitle: Text(l.backupAutoSub),
              ),
              const Divider(indent: 16),
              ListTile(
                leading: const Icon(Icons.table_chart_outlined),
                title: Row(children: [
                  Flexible(child: Text(l.exportCsv)),
                  if (!app.isPro) ...[const SizedBox(width: 8), const ProTag()],
                ]),
                onTap: _busy ? null : () => _exportText(true),
              ),
              const Divider(indent: 16),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: Row(children: [
                  Flexible(child: Text(l.exportText)),
                  if (!app.isPro) ...[const SizedBox(width: 8), const ProTag()],
                ]),
                onTap: _busy ? null : () => _exportText(false),
              ),
            ]),
          ),
        ]),
        if (_busy) const Positioned.fill(child: ColoredBox(color: Color(0x33000000), child: Center(child: CircularProgressIndicator()))),
      ]),
    );
  }
}

