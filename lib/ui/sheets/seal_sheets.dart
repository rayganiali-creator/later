import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/dates.dart';
import '../../domain/models.dart';
import '../../domain/pro.dart';
import '../app_scope.dart';
import '../type_info.dart';
import '../widgets/common.dart';
import '../widgets/date_picker.dart';
import '../widgets/pro_gate.dart';

/// "Move to…" — puts an item on another shelf.
Future<void> showMoveSheet(BuildContext context, LaterItem item) {
  final l = context.l10n;
  const targets = [ItemType.task, ItemType.read, ItemType.watch, ItemType.wishlist, ItemType.idea];
  return showAppSheet<void>(
    context,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l.moveToShelf, style: ctx.text.titleLarge),
            ),
          ),
          for (final t in targets)
            ListTile(
              enabled: t != item.type,
              leading: Icon(TypeInfo.icon(t), color: ctx.scheme.primary),
              title: Text(TypeInfo.shelfTitle(l, t)),
              trailing: t == item.type ? Icon(Icons.check_rounded, color: ctx.scheme.primary) : null,
              onTap: () async {
                Navigator.pop(ctx);
                final app = context.appRead;
                final undo = await guarded(context, () => app.moveToType(item.id, t));
                if (context.mounted && undo != null) {
                  showAppSnack(context, l.movedTo(TypeInfo.shelfTitle(l, t)), actionLabel: l.undo, onAction: undo);
                }
              },
            ),
          const SizedBox(height: 12),
        ]),
      ),
    ),
  );
}

/// Quick dates for sealing: 1 / 3 / 6 months, 1 year, or a custom date.
Future<DateTime?> pickUnlockDate(BuildContext context) async {
  final l = context.l10n;
  final app = context.appRead;
  final n = app.now();
  final cal = app.settings.calendar;
  final opts = <(String, DateTime)>[
    (l.sealQuick1m, Dates.startOfDay(Dates.addMonths(n, 1, cal))),
    (l.sealQuick3m, Dates.startOfDay(Dates.addMonths(n, 3, cal))),
    (l.sealQuick6m, Dates.startOfDay(Dates.addMonths(n, 6, cal))),
    (l.sealQuick1y, Dates.startOfDay(Dates.addMonths(n, 12, CalendarSystem.gregorian))),
  ];
  return showAppSheet<DateTime>(
    context,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l.sealPickDate, style: ctx.text.titleLarge),
            ),
          ),
          for (final o in opts)
            ListTile(
              leading: Icon(Icons.event_rounded, color: ctx.scheme.primary),
              title: Text(o.$1),
              subtitle: Text(ctx.fmt.date(o.$2, omitCurrentYear: false)),
              onTap: () => Navigator.pop(ctx, o.$2),
            ),
          ListTile(
            leading: Icon(Icons.edit_calendar_rounded, color: ctx.scheme.primary),
            title: Text(l.quickCustom),
            onTap: () async {
              final r = await showAppDatePicker(ctx);
              if (r?.date != null && ctx.mounted) Navigator.pop(ctx, r!.date);
            },
          ),
          const SizedBox(height: 12),
        ]),
      ),
    ),
  );
}

/// Seals an existing item until a date ("keep it for the future").
Future<void> showSealItemSheet(BuildContext context, LaterItem item) async {
  final l = context.l10n;
  final app = context.appRead;
  if (!app.canSeal(messages: false)) {
    showAppSnack(context, l.sealLimitFree(context.fmt.num(ProLimits.freeCapsules)));
    await showProSheet(context, featureName: l.sealProHint);
    return;
  }
  final d = await pickUnlockDate(context);
  if (d == null || !context.mounted) return;
  if (!d.isAfter(app.now())) {
    showAppSnack(context, l.sealNeedsFuture);
    return;
  }
  final r = await guarded(context, () => app.sealExisting(item.id, d));
  if (r != null && context.mounted) showAppSnack(context, l.sealSaved(context.fmt.date(d, omitCurrentYear: false)));
}

/// Creates a new capsule or future message.
Future<void> showSealCreateSheet(BuildContext context, {required bool message}) {
  return showAppSheet<void>(context, full: true, builder: (_) => _SealCreate(message: message));
}

class _SealCreate extends StatefulWidget {
  const _SealCreate({required this.message});
  final bool message;

  @override
  State<_SealCreate> createState() => _SealCreateState();
}

class _SealCreateState extends State<_SealCreate> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _tags = TextEditingController();
  DateTime? _date;
  RepeatRule _repeat = RepeatRule.none;
  final List<({String name, String mime, Uint8List bytes})> _files = [];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _tags.dispose();
    super.dispose();
  }

  static String _mime(String name) {
    final e = name.toLowerCase().split('.').last;
    return switch (e) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _addFile() async {
    final l = context.l10n;
    final app = context.appRead;
    if (!app.access.has(ProFeature.richFutureMessages)) {
      await showProSheet(context, featureName: l.sealProHint);
      return;
    }
    if (_files.length >= ProLimits.maxAttachmentsPerMessage) return;
    try {
      final f = await FilePicker.pickFile();
      if (f == null) return;
      final len = f.lengthSync() ?? await f.length();
      if (len != null && len > ProLimits.maxAttachmentBytes) {
        if (mounted) setState(() => _error = l.sealAttachTooBig);
        return;
      }
      final b = BytesBuilder(copy: false);
      await for (final c in f.readAsByteStream()) {
        b.add(c);
        if (b.length > ProLimits.maxAttachmentBytes) {
          if (mounted) setState(() => _error = l.sealAttachTooBig);
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _error = null;
        _files.add((name: f.name, mime: _mime(f.name), bytes: b.takeBytes()));
      });
    } catch (_) {
      if (mounted) setState(() => _error = l.sealAttachFailed);
    }
  }

  Future<void> _save() async {
    final l = context.l10n;
    final app = context.appRead;
    if (_saving) return;
    if (_date == null || !_date!.isAfter(app.now())) {
      setState(() => _error = l.sealNeedsFuture);
      return;
    }
    if (_body.text.trim().isEmpty && _title.text.trim().isEmpty) {
      setState(() => _error = l.titleRequired);
      return;
    }
    if (!app.canSeal(messages: widget.message)) {
      showAppSnack(context, l.sealLimitFree(context.fmt.num(widget.message ? ProLimits.freeFutureMessages : ProLimits.freeCapsules)));
      await showProSheet(context, featureName: l.sealProHint);
      return;
    }
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    try {
      final item = await app.seal(
        title: _title.text,
        body: _body.text,
        unlockAt: _date!,
        message: widget.message,
        repeat: _repeat,
        tags: _tags.text.split(RegExp(r'[,،]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      );
      if (item != null) {
        for (final f in _files) {
          await app.addAttachment(item.id, f.name, f.mime, f.bytes);
        }
      }
      if (mounted && item != null) showAppSnack(context, l.sealSaved(context.fmt.date(_date!, omitCurrentYear: false)));
      nav.pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l.errorGeneric;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final pro = app.access.has(widget.message ? ProFeature.richFutureMessages : ProFeature.richTimeCapsules);
    final n = app.now();
    final cal = app.settings.calendar;
    final quick = <(String, DateTime)>[
      (l.sealQuick1m, Dates.startOfDay(Dates.addMonths(n, 1, cal))),
      (l.sealQuick3m, Dates.startOfDay(Dates.addMonths(n, 3, cal))),
      (l.sealQuick6m, Dates.startOfDay(Dates.addMonths(n, 6, cal))),
      (l.sealQuick1y, Dates.startOfDay(Dates.addMonths(n, 12, CalendarSystem.gregorian))),
    ];
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Text(widget.message ? l.messageNew : l.capsuleNew, style: context.text.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            maxLength: 200,
            decoration: InputDecoration(hintText: l.sealTitleHint, counterText: ''),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _body,
            minLines: 4,
            maxLines: 10,
            maxLength: 8000,
            decoration: InputDecoration(hintText: widget.message ? l.messageBodyHint : l.capsuleBodyHint, counterText: ''),
          ),
          const SizedBox(height: 12),
          Text(l.sealPickDate, style: context.text.labelLarge?.copyWith(color: context.scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final q in quick)
              ChoiceChip(
                label: Text(q.$1),
                selected: _date != null && Dates.isSameDay(_date!, q.$2),
                onSelected: (_) => setState(() => _date = q.$2),
              ),
            ActionChip(
              avatar: const Icon(Icons.edit_calendar_rounded, size: 18),
              label: Text(_date != null && !quick.any((q) => Dates.isSameDay(q.$2, _date!))
                  ? fmt.date(_date!, omitCurrentYear: false)
                  : l.quickCustom),
              onPressed: () async {
                final r = await showAppDatePicker(context, initial: _date);
                if (r?.date != null && mounted) setState(() => _date = r!.date);
              },
            ),
          ]),
          if (_date != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l.sealOpenOn(fmt.date(_date!, omitCurrentYear: false)),
                  style: context.text.bodyMedium?.copyWith(color: context.scheme.primary)),
            ),
          const SizedBox(height: 14),
          if (widget.message) ...[
            Row(children: [
              Text(l.sealRepeat, style: context.text.labelLarge?.copyWith(color: context.scheme.onSurfaceVariant)),
              if (!pro) ...[const SizedBox(width: 8), const ProTag()],
            ]),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              for (final r in const [RepeatRule.none, RepeatRule.monthly, RepeatRule.yearly])
                ChoiceChip(
                  label: Text(fmt.repeat(r)),
                  selected: _repeat == r,
                  onSelected: (_) {
                    if (r != RepeatRule.none && !pro) {
                      showProSheet(context, featureName: l.sealProHint);
                      return;
                    }
                    setState(() => _repeat = r);
                  },
                ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Text(l.sealAttach, style: context.text.labelLarge?.copyWith(color: context.scheme.onSurfaceVariant)),
              if (!pro) ...[const SizedBox(width: 8), const ProTag()],
            ]),
            const SizedBox(height: 4),
            Text(l.sealAttachLimit(fmt.num(ProLimits.maxAttachmentsPerMessage), fmt.num(ProLimits.maxAttachmentBytes ~/ (1024 * 1024))),
                style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant)),
            for (var i = 0; i < _files.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_files[i].mime.startsWith('image/') ? Icons.image_outlined : Icons.attach_file_rounded),
                title: Text(_files[i].name, overflow: TextOverflow.ellipsis),
                trailing: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _files.removeAt(i))),
              ),
            TextButton.icon(
              onPressed: _addFile,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(l.sealAttachAdd),
            ),
            const SizedBox(height: 8),
            if (pro)
              TextField(
                controller: _tags,
                decoration: InputDecoration(labelText: l.fieldTags, hintText: l.fieldTagsHint, prefixIcon: const Icon(Icons.tag_rounded)),
              ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, style: TextStyle(color: context.scheme.error)),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.lock_outline_rounded),
            label: Text(l.save),
          ),
          if (!pro)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l.sealProHint, style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }
}
