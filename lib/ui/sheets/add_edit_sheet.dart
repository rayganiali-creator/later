import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/util/dates.dart';
import '../../core/util/ids.dart';
import '../../core/util/text.dart';
import '../../domain/models.dart';
import '../../domain/snooze.dart';
import '../app_scope.dart';
import '../screens/categories_screen.dart';
import '../widgets/common.dart';
import '../widgets/date_picker.dart';
import '../type_info.dart';
import '../widgets/pro_gate.dart';
import 'item_detail_sheet.dart' show parsePrice;

/// Opens the add/edit sheet. Returns the saved item (or null if dismissed).
Future<LaterItem?> showAddEditSheet(
  BuildContext context, {
  LaterItem? initial,
  String? presetTitle,
  String? presetCategory,
  ItemType? presetType,
}) {
  return showAppSheet<LaterItem>(
    context,
    full: true,
    builder: (_) => AddEditSheet(
        initial: initial, presetTitle: presetTitle, presetCategory: presetCategory, presetType: presetType),
  );
}

/// Opens the add sheet and confirms with a toast.
Future<void> addFlow(BuildContext context, {String? presetTitle, ItemType? presetType}) async {
  final l = context.l10n;
  final saved = await showAddEditSheet(context, presetTitle: presetTitle, presetType: presetType);
  if (saved != null && context.mounted) showAppSnack(context, l.toastAdded);
}

enum _ReminderChoice { off, atTime, before10, before60, beforeDay }

class AddEditSheet extends StatefulWidget {
  const AddEditSheet({super.key, this.initial, this.presetTitle, this.presetCategory, this.presetType});
  final LaterItem? initial;
  final String? presetTitle;
  final String? presetCategory;
  final ItemType? presetType;

  @override
  State<AddEditSheet> createState() => _AddEditSheetState();
}

class _AddEditSheetState extends State<AddEditSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _note = TextEditingController();
  final _url = TextEditingController();
  final _tags = TextEditingController();
  final _price = TextEditingController();
  final _currency = TextEditingController();
  final _titleFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  String _category = BuiltinCategories.other;
  DateTime? _date;
  TimeOfDay? _time;
  _ReminderChoice _reminder = _ReminderChoice.off;
  RepeatRule _repeat = RepeatRule.none;
  ItemPriority _priority = ItemPriority.normal;
  ItemType? _type; // null = not sorted yet (goes to the inbox)
  String _watchKind = 'video';
  int? _minutes;
  bool _expanded = false;
  bool _dirty = false;
  bool _saving = false;
  bool _inited = false;

  bool get _editing => widget.initial != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    final i = widget.initial;
    if (i != null) {
      _title.text = i.title;
      _desc.text = i.description;
      _note.text = i.note;
      _url.text = i.url ?? '';
      _tags.text = i.tags.join('، ');
      _category = i.categoryId;
      _date = i.dueAt == null ? null : Dates.startOfDay(i.dueAt!);
      _time = i.hasTime && i.dueAt != null ? TimeOfDay(hour: i.dueAt!.hour, minute: i.dueAt!.minute) : null;
      _priority = i.priority;
      _type = i.inbox ? null : i.type;
      _watchKind = i.watchKind;
      _price.text = i.price == null ? '' : i.price!.round().toString();
      _currency.text = i.currency;
      _minutes = i.estimatedMinutes;
      _repeat = i.repeat;
      if (i.reminderEnabled && i.dueAt != null) {
        _reminder = switch (i.reminderOffsetMinutes) {
          0 => _ReminderChoice.atTime,
          10 => _ReminderChoice.before10,
          60 => _ReminderChoice.before60,
          1440 => _ReminderChoice.beforeDay,
          _ => _ReminderChoice.atTime,
        };
      }
      _expanded = i.description.isNotEmpty ||
          i.note.isNotEmpty ||
          i.url != null ||
          i.tags.isNotEmpty ||
          i.estimatedMinutes != null ||
          i.priority != ItemPriority.normal ||
          i.dueAt != null;
    } else {
      _type = widget.presetType;
      _expanded = widget.presetType == ItemType.wishlist || widget.presetType == ItemType.read || widget.presetType == ItemType.watch;
      _title.text = widget.presetTitle ?? '';
      final cats = context.appRead.categories;
      if (widget.presetCategory != null && cats.any((c) => c.id == widget.presetCategory)) {
        _category = widget.presetCategory!;
      }
    }
    for (final c in [_title, _desc, _note, _url, _tags, _price, _currency]) {
      c.addListener(() => _dirty = true);
    }
    if (!_editing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _titleFocus.requestFocus());
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _desc, _note, _url, _tags, _price, _currency]) {
      c.dispose();
    }
    _titleFocus.dispose();
    super.dispose();
  }

  int get _offset => switch (_reminder) {
        _ReminderChoice.before10 => 10,
        _ReminderChoice.before60 => 60,
        _ReminderChoice.beforeDay => 1440,
        _ => 0,
      };

  Future<void> _pickDate() async {
    final r = await showAppDatePicker(context, initial: _date, allowClear: true);
    if (r == null || !mounted) return;
    setState(() {
      _dirty = true;
      _date = r.date;
      if (_date == null) {
        _time = null;
        _reminder = _ReminderChoice.off;
        _repeat = RepeatRule.none;
      }
    });
  }

  void _quickDate(SnoozeOption? o) {
    final app = context.appRead;
    setState(() {
      _dirty = true;
      if (o == null) {
        _date = null;
        _time = null;
        _reminder = _ReminderChoice.off;
        _repeat = RepeatRule.none;
        return;
      }
      final t = app.snoozeCalculator.compute(o, app.now());
      _date = t.dueAt == null ? null : Dates.startOfDay(t.dueAt!);
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t == null || !mounted) return;
    setState(() {
      _dirty = true;
      _time = t;
    });
    // Choosing a time means "tell me then": turn the reminder on unless the
    // user already picked one.
    if (_reminder == _ReminderChoice.off) await _setReminder(_ReminderChoice.atTime);
  }

  Future<void> _setReminder(_ReminderChoice c) async {
    if (c != _ReminderChoice.off) {
      final app = context.appRead;
      final l = context.l10n;
      final ok = await app.ensureNotificationPermission();
      if (!ok && mounted) {
        showAppSnack(context, l.reminderPermissionBanner,
            actionLabel: l.openSettings, onAction: () => app.notifications.openSystemSettings());
      }
    }
    if (!mounted) return;
    setState(() {
      _dirty = true;
      _reminder = c;
      if (c == _ReminderChoice.off) _repeat = RepeatRule.none;
    });
  }

  Future<void> _setRepeat(RepeatRule r) async {
    if (r != RepeatRule.none && !context.appRead.isPro) {
      await showProSheet(context, featureName: context.l10n.repeatProHint);
      return;
    }
    setState(() {
      _dirty = true;
      _repeat = r;
    });
  }

  List<String> _parseTags() => _tags.text
      .split(RegExp(r'[,،;\n]'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (_saving) return;
    final l = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) {
      if (_title.text.trim().isEmpty) _titleFocus.requestFocus();
      return;
    }
    setState(() => _saving = true);
    final app = context.appRead;
    final nav = Navigator.of(context);
    try {
      DateTime? due;
      if (_date != null) {
        due = _time == null
            ? Dates.startOfDay(_date!)
            : DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute);
      }
      final hasReminder = due != null && _reminder != _ReminderChoice.off;
      final type = _type ?? ItemType.task;
      final unsorted = _type == null && due == null;
      final price = parsePrice(_price.text);
      Map<String, Object?> extraFor(Map<String, Object?> base) {
        final m = Map<String, Object?>.from(base);
        if (type == ItemType.wishlist) {
          if (price != null) {
            m['price'] = price;
          } else {
            m.remove('price');
          }
          final cur = _currency.text.trim();
          if (cur.isNotEmpty) {
            m['currency'] = cur;
          } else {
            m.remove('currency');
          }
        }
        if (type == ItemType.watch) m['watchKind'] = _watchKind;
        return m;
      }

      LaterItem saved;
      if (_editing) {
        saved = widget.initial!.copyWith(
          title: _title.text,
          description: _desc.text,
          note: _note.text,
          url: sanitizeUrl(_url.text),
          tags: _parseTags(),
          categoryId: _category,
          priority: _priority,
          estimatedMinutes: _minutes,
          dueAt: due,
          hasTime: _time != null && due != null,
          reminderEnabled: hasReminder,
          reminderOffsetMinutes: hasReminder ? _offset : 0,
          repeat: hasReminder ? _repeat : RepeatRule.none,
          type: type,
          stage: type == widget.initial!.type ? widget.initial!.stage : 0,
          inbox: widget.initial!.inbox && unsorted,
          extra: extraFor(widget.initial!.extra),
        );
        if (price != null && price != widget.initial!.price && type == ItemType.wishlist) {
          await app.update(saved.copyWith(extra: widget.initial!.extra));
          await app.setPrice(saved.id, price, currency: _currency.text.trim().isEmpty ? null : _currency.text.trim());
          saved = app.itemById(saved.id)!;
          await app.update(saved.copyWith(
              title: _title.text, description: _desc.text, note: _note.text, url: sanitizeUrl(_url.text),
              tags: _parseTags(), categoryId: _category, priority: _priority, estimatedMinutes: _minutes,
              dueAt: due, hasTime: _time != null && due != null, reminderEnabled: hasReminder,
              reminderOffsetMinutes: hasReminder ? _offset : 0, repeat: hasReminder ? _repeat : RepeatRule.none,
              type: type, inbox: false));
        } else {
          await app.update(saved);
        }
      } else {
        final n = app.now();
        saved = await app.saveNew(LaterItem(
          id: newId(),
          title: _title.text,
          description: _desc.text,
          note: _note.text,
          url: sanitizeUrl(_url.text),
          tags: _parseTags(),
          categoryId: _category,
          priority: _priority,
          estimatedMinutes: _minutes,
          dueAt: due,
          hasTime: _time != null && due != null,
          reminderEnabled: hasReminder,
          reminderOffsetMinutes: hasReminder ? _offset : 0,
          repeat: hasReminder ? _repeat : RepeatRule.none,
          createdAt: n,
          updatedAt: n,
          source: 'manual',
          type: type,
          inbox: unsorted,
          extra: extraFor(const {}),
        ));
        if (price != null && type == ItemType.wishlist) {
          // Seed the price history with the first price.
          final fresh = app.itemById(saved.id);
          if (fresh != null) await app.update(fresh.withExtra('priceHistory', [[n.millisecondsSinceEpoch, price]]));
        }
      }
      HapticFeedback.lightImpact();
      nav.pop(saved);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnack(context, l.errorGeneric, actionLabel: l.retry, onAction: _save);
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty || _title.text.trim().isEmpty && !_editing) return true;
    final l = context.l10n;
    return confirmDialog(context,
        title: l.discardTitle, body: l.discardBody, confirmLabel: l.discard, destructive: true);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;

    final quick = <(SnoozeOption?, String)>[
      (SnoozeOption.tonight, l.quickToday),
      (SnoozeOption.tomorrow, l.quickTomorrow),
      (SnoozeOption.weekend, l.quickWeekend),
      (SnoozeOption.nextWeek, l.quickNextWeek),
      (null, l.quickNoDate),
    ];
    bool quickSelected(SnoozeOption? o) {
      if (o == null) return _date == null;
      if (_date == null) return false;
      final t = app.snoozeCalculator.compute(o, app.now()).dueAt;
      return t != null && Dates.isSameDay(t, _date!);
    }

    final reminderChoices = <(_ReminderChoice, String)>[
      (_ReminderChoice.off, l.reminderOff),
      (_ReminderChoice.atTime, _time == null ? l.reminderAtDefault(fmt.minutesOfDay(app.settings.defaultReminderMinutes)) : l.reminderAtTime),
      if (_time != null) (_ReminderChoice.before10, l.reminderBefore10),
      if (_time != null) (_ReminderChoice.before60, l.reminderBefore60Label),
      (_ReminderChoice.beforeDay, l.reminderBefore1d),
    ];

    return PopScope(
      canPop: !_dirty || (_title.text.trim().isEmpty && !_editing),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmDiscard()) nav.pop();
      },
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Row(children: [
                Expanded(child: Text(_editing ? l.editTitle : l.addTitle, style: context.text.titleLarge)),
                IconButton(
                  tooltip: l.close,
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    if (await _confirmDiscard()) nav.pop();
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ]),
              const SizedBox(height: 8),
              TextFormField(
                controller: _title,
                focusNode: _titleFocus,
                textInputAction: TextInputAction.done,
                maxLength: 500,
                maxLines: null,
                minLines: 1,
                style: context.text.titleMedium,
                decoration: InputDecoration(hintText: l.titleHint, counterText: ''),
                validator: (v) => (v == null || v.trim().isEmpty) ? l.titleRequired : null,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 14),
              _label(l.addTypeLabel),
              SizedBox(
                height: 44,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(l.addTypeAuto),
                      selected: _type == null,
                      onSelected: (_) => setState(() {
                        _dirty = true;
                        _type = null;
                      }),
                    ),
                  ),
                  for (final t in const [ItemType.task, ItemType.read, ItemType.watch, ItemType.wishlist, ItemType.idea])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        avatar: Icon(TypeInfo.icon(t), size: 18),
                        label: Text(l.typeName(t.name)),
                        selected: _type == t,
                        onSelected: (_) => setState(() {
                          _dirty = true;
                          _type = t;
                          if (t == ItemType.wishlist || t == ItemType.read || t == ItemType.watch) _expanded = true;
                        }),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 16),
              _label(l.fieldCategory),
              SizedBox(
                height: 44,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final c in app.categories)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text('${c.emoji} ${app.categoryName(c.id)}'),
                        selected: _category == c.id,
                        onSelected: (_) => setState(() {
                          _dirty = true;
                          _category = c.id;
                        }),
                      ),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l.categoryNew),
                    onPressed: () async {
                      final c = await showCategoryDialog(context);
                      if (c != null && mounted) setState(() => _category = c.id);
                    },
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              _label(l.fieldDate),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final q in quick)
                  ChoiceChip(
                    label: Text(q.$2),
                    selected: quickSelected(q.$1),
                    onSelected: (_) => _quickDate(q.$1),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: Text(_date != null && !quick.any((q) => quickSelected(q.$1))
                      ? fmt.date(_date!, omitCurrentYear: false)
                      : l.quickCustom),
                  onPressed: _pickDate,
                ),
              ]),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _date == null
                    ? const SizedBox(width: double.infinity)
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(height: 14),
                        _label(l.fieldTime),
                        Wrap(spacing: 8, children: [
                          ActionChip(
                            avatar: const Icon(Icons.schedule_rounded, size: 18),
                            label: Text(_time == null
                                ? l.timePick
                                : fmt.time(DateTime(2000, 1, 1, _time!.hour, _time!.minute))),
                            onPressed: _pickTime,
                          ),
                          if (_time != null)
                            ActionChip(
                              label: Text(l.timeNone),
                              onPressed: () => setState(() {
                                _time = null;
                                if (_reminder == _ReminderChoice.before10 || _reminder == _ReminderChoice.before60) {
                                  _reminder = _ReminderChoice.atTime;
                                }
                              }),
                            ),
                        ]),
                        const SizedBox(height: 14),
                        _label(l.reminder),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final r in reminderChoices)
                            ChoiceChip(
                              label: Text(r.$2),
                              selected: _reminder == r.$1,
                              onSelected: (_) => _setReminder(r.$1),
                            ),
                        ]),
                        if (_reminder != _ReminderChoice.off) ...[
                          const SizedBox(height: 14),
                          _label(l.repeat),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final r in RepeatRule.values)
                              ChoiceChip(
                                label: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Text(fmt.repeat(r)),
                                  if (r != RepeatRule.none && !app.isPro) ...[const SizedBox(width: 6), const ProTag()],
                                ]),
                                selected: _repeat == r,
                                onSelected: (_) => _setRepeat(r),
                              ),
                          ]),
                        ],
                      ]),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more_rounded),
                ),
                label: Text(_expanded ? l.lessOptions : l.moreOptions),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: !_expanded
                    ? const SizedBox(width: double.infinity)
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (_type == ItemType.wishlist) ...[
                          Row(children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _price,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(labelText: l.fieldPrice, hintText: l.priceHint),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _currency,
                                decoration: InputDecoration(labelText: l.fieldCurrency, hintText: l.currencyDefault),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                        ],
                        if (_type == ItemType.watch) ...[
                          _label(l.fieldWatchKind),
                          Wrap(spacing: 8, children: [
                            for (final k in const [('video', 0), ('movie', 1), ('series', 2), ('other', 3)])
                              ChoiceChip(
                                label: Text([l.kindVideo, l.kindMovie, l.kindSeries, l.kindOther][k.$2]),
                                selected: _watchKind == k.$1,
                                onSelected: (_) => setState(() {
                                  _dirty = true;
                                  _watchKind = k.$1;
                                }),
                              ),
                          ]),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _desc,
                          maxLines: 3,
                          minLines: 1,
                          maxLength: 2000,
                          decoration: InputDecoration(labelText: l.fieldDescription, counterText: ''),
                        ),
                        const SizedBox(height: 12),
                        _label(l.priority),
                        SegmentedButton<ItemPriority>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(value: ItemPriority.low, label: Text(l.priorityLow)),
                            ButtonSegment(value: ItemPriority.normal, label: Text(l.priorityNormal)),
                            ButtonSegment(value: ItemPriority.high, label: Text(l.priorityHigh)),
                          ],
                          selected: {_priority},
                          onSelectionChanged: (v) => setState(() {
                            _dirty = true;
                            _priority = v.first;
                          }),
                        ),
                        const SizedBox(height: 14),
                        _label(l.duration),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          ChoiceChip(
                            label: Text(l.durationUnknown),
                            selected: _minutes == null,
                            onSelected: (_) => setState(() {
                              _dirty = true;
                              _minutes = null;
                            }),
                          ),
                          for (final m in const [5, 15, 30, 60])
                            ChoiceChip(
                              label: Text(fmt.minutes(m)),
                              selected: _minutes == m,
                              onSelected: (_) => setState(() {
                                _dirty = true;
                                _minutes = m;
                              }),
                            ),
                          ActionChip(
                            label: Text(_minutes != null && ![5, 15, 30, 60].contains(_minutes)
                                ? fmt.minutes(_minutes!)
                                : l.durationCustom),
                            onPressed: _customDuration,
                          ),
                        ]),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _url,
                          keyboardType: TextInputType.url,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(labelText: l.fieldUrl, prefixIcon: const Icon(Icons.link_rounded)),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return null;
                            return sanitizeUrl(t) == null ? l.urlInvalid : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _tags,
                          decoration: InputDecoration(
                            labelText: l.fieldTags,
                            hintText: l.fieldTagsHint,
                            prefixIcon: const Icon(Icons.tag_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _note,
                          maxLines: 5,
                          minLines: 2,
                          maxLength: 5000,
                          decoration: InputDecoration(labelText: l.fieldNote, counterText: ''),
                        ),
                      ]),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: s.onPrimary))
                    : Text(l.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _customDuration() async {
    final v = await showDialog<int>(
      context: context,
      builder: (_) => _DurationDialog(initial: _minutes),
    );
    if (v != null && v > 0 && mounted) {
      setState(() {
        _dirty = true;
        _minutes = v.clamp(1, 1440);
      });
    }
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: context.text.labelLarge?.copyWith(color: context.scheme.onSurfaceVariant)),
      );
}

class _DurationDialog extends StatefulWidget {
  const _DurationDialog({this.initial});
  final int? initial;

  @override
  State<_DurationDialog> createState() => _DurationDialogState();
}

class _DurationDialogState extends State<_DurationDialog> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initial?.toString() ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.duration),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩]'))],
        decoration: InputDecoration(hintText: l.durationCustomHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(context, int.tryParse(toEnDigits(_ctrl.text))),
          child: Text(l.ok),
        ),
      ],
    );
  }
}
