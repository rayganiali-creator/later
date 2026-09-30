import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/pro.dart';
import '../app_scope.dart';
import '../widgets/common.dart';
import '../widgets/date_picker.dart';
import '../widgets/item_tile.dart';
import '../widgets/pro_gate.dart';

/// People you want to remember to reach out to. Contacts are only linked by
/// reference (the user picks one entry in the system picker); nothing is
/// copied or uploaded.
class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final l = context.l10n;
    final app = context.appRead;
    final choice = await showAppSheet<String>(
      context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l.personAdd, style: ctx.text.titleLarge),
            ),
          ),
          ListTile(
            leading: Icon(Icons.contacts_rounded, color: ctx.scheme.primary),
            title: Text(l.personFromContacts),
            onTap: () => Navigator.pop(ctx, 'contact'),
          ),
          ListTile(
            leading: Icon(Icons.edit_rounded, color: ctx.scheme.primary),
            title: Text(l.personTypeName),
            onTap: () => Navigator.pop(ctx, 'name'),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
    if (choice == null || !context.mounted) return;
    Person? p;
    if (choice == 'contact') {
      final c = await app.platform.pickContact();
      if (!context.mounted) return;
      if (c == null) {
        showAppSnack(context, l.personPickerFailed);
        return;
      }
      p = await app.addPerson(c.name, contactUri: c.uri);
    } else {
      final name = await showDialog<String>(context: context, builder: (_) => _TextDialog(title: l.personName));
      if (name == null || name.trim().isEmpty || !context.mounted) return;
      p = await app.addPerson(name);
    }
    if (context.mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PersonScreen(personId: p!.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    final people = [...app.people]..sort((a, b) => a.name.compareTo(b.name));
    final due = app.access.has(ProFeature.peopleTools) ? app.peopleDue() : const <Person>[];

    return Scaffold(
      appBar: AppBar(title: Text(l.peopleTitle)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.personAdd,
        onPressed: () => _add(context),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: people.isEmpty
          ? EmptyState(
              emoji: '🤝',
              title: l.peopleEmptyTitle,
              body: l.peopleEmptyBody,
              action: FilledButton.icon(
                onPressed: () => _add(context),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(l.personAdd),
              ))
          : ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 110), children: [
              if (!app.isPro)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => showProSheet(context, featureName: l.peopleProHint),
                    child: Text(l.peopleProHint, style: context.text.labelMedium?.copyWith(color: s.primary)),
                  ),
                ),
              if (due.isNotEmpty) ...[
                SectionTitle(l.personDueTitle),
                for (final p in due.take(5))
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: _PersonTile(person: p, highlight: true)),
                const SizedBox(height: 8),
              ],
              for (final p in people)
                Padding(padding: const EdgeInsets.only(bottom: 10), child: _PersonTile(person: p)),
              Text(fmt.num(people.length),
                  textAlign: TextAlign.center,
                  style: context.text.labelSmall?.copyWith(color: s.onSurfaceVariant)),
            ]),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person, this.highlight = false});
  final Person person;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    final next = app.nextReminderOf(person.id);
    final last = person.lastInteractionAt;
    return AppCard(
      color: highlight ? context.appColors.warning.withValues(alpha: 0.08) : null,
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PersonScreen(personId: person.id))),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: s.primaryContainer,
          child: Text(person.name.characters.first, style: TextStyle(color: s.onPrimaryContainer)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(person.name, style: context.text.titleSmall),
            Text(
              last == null ? l.personNever : l.personLast(fmt.ago(last)),
              style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant),
            ),
            if (next != null)
              Text(l.personNext(fmt.date(next)), style: context.text.bodySmall?.copyWith(color: s.primary)),
          ]),
        ),
        if (person.contactUri != null) Icon(Icons.contacts_outlined, size: 18, color: s.onSurfaceVariant),
      ]),
    );
  }
}

class PersonScreen extends StatefulWidget {
  const PersonScreen({super.key, required this.personId});
  final String personId;

  @override
  State<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends State<PersonScreen> {
  Future<void> _talked(Person p) async {
    final app = context.appRead;
    final l = context.l10n;
    if (!app.access.has(ProFeature.peopleTools)) {
      await app.logInteraction(p.id);
      if (mounted) showAppSnack(context, l.toastSaved);
      return;
    }
    final r = await showDialog<_TalkResult>(context: context, builder: (_) => const _TalkDialog());
    if (r == null) return;
    await app.logInteraction(p.id, note: r.note, followUpDays: r.followUpDays);
    if (mounted) showAppSnack(context, l.toastSaved);
  }

  Future<void> _addReminder(Person p) async {
    final l = context.l10n;
    final app = context.appRead;
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(title: l.personAddReminder, hint: l.personReminderHint),
    );
    if (title == null || title.trim().isEmpty || !mounted) return;
    final d = await showAppDatePicker(context, initial: app.now().add(const Duration(days: 1)));
    if (!mounted) return;
    await app.addPersonReminder(p.id, title: '${p.name}: ${title.trim()}', dueAt: d?.date, reminder: d?.date != null);
    if (mounted) showAppSnack(context, l.toastAdded);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    final p = app.personById(widget.personId);
    if (p == null) return Scaffold(appBar: AppBar(), body: EmptyState(emoji: '🤷', title: l.itemNotFound));
    final pro = app.access.has(ProFeature.peopleTools);
    final items = app.personItems(p.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            tooltip: l.delete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final ok = await confirmDialog(context,
                  title: l.personDeleteTitle, body: l.personDeleteBody, confirmLabel: l.delete, destructive: true);
              if (ok && context.mounted) {
                await app.deletePerson(p.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.lastInteractionAt == null ? l.personNever : l.personLast(fmt.ago(p.lastInteractionAt!)),
                style: context.text.titleSmall),
            const SizedBox(height: 4),
            Text(
              () {
                final n = app.nextReminderOf(p.id);
                return n == null ? l.personNoNext : l.personNext(fmt.date(n));
              }(),
              style: context.text.bodyMedium?.copyWith(color: s.onSurfaceVariant),
            ),
            if (p.contactUri != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(l.personContactRef, style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
              ),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(
                onPressed: () => _talked(p),
                icon: const Icon(Icons.check_rounded),
                label: Text(l.personTalked),
              ),
              OutlinedButton.icon(
                onPressed: () => _addReminder(p),
                icon: const Icon(Icons.add_alert_rounded),
                label: Text(l.personAddReminder),
              ),
              if (p.contactUri != null)
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await app.platform.openContact(p.contactUri!);
                    if (!ok && context.mounted) showAppSnack(context, l.errorGeneric);
                  },
                  icon: const Icon(Icons.contacts_rounded),
                  label: Text(l.personOpenContact),
                ),
            ]),
          ]),
        ),
        SectionTitle(l.personNote),
        _NoteField(person: p),
        if (pro) ...[
          SectionTitle(l.personGroup),
          _GroupField(person: p),
        ],
        SectionTitle(l.personLinked),
        if (items.isEmpty)
          Text(l.personNoNext, style: context.text.bodyMedium?.copyWith(color: s.onSurfaceVariant))
        else
          for (final i in items) Padding(padding: const EdgeInsets.only(bottom: 10), child: ItemTile(item: i)),
        SectionTitle(l.personHistory, trailing: pro ? null : const ProTag()),
        if (!pro)
          GestureDetector(
            onTap: () => showProSheet(context, featureName: l.peopleProHint),
            child: Text(l.peopleProHint, style: context.text.bodyMedium?.copyWith(color: s.primary)),
          )
        else
          FutureBuilder<List<Interaction>>(
            key: ValueKey(p.lastInteractionAt),
            future: app.interactionsOf(p.id),
            builder: (context, snap) {
              final rows = snap.data ?? const <Interaction>[];
              if (rows.isEmpty) {
                return Text(l.personNever, style: context.text.bodyMedium?.copyWith(color: s.onSurfaceVariant));
              }
              return Column(children: [
                for (final r in rows)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.chat_bubble_outline_rounded),
                    title: Text(fmt.date(r.at.toLocal(), omitCurrentYear: false)),
                    subtitle: r.note.isEmpty ? null : Text(r.note),
                  ),
              ]);
            },
          ),
      ]),
    );
  }
}

class _NoteField extends StatefulWidget {
  const _NoteField({required this.person});
  final Person person;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final TextEditingController _c = TextEditingController(text: widget.person.note);
  final _f = FocusNode();

  @override
  void initState() {
    super.initState();
    _f.addListener(() {
      if (!_f.hasFocus) _save();
    });
  }

  void _save() {
    final p = context.appRead.personById(widget.person.id);
    if (p != null && p.note != _c.text) context.appRead.updatePerson(p.copyWith(note: _c.text));
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _c,
        focusNode: _f,
        minLines: 2,
        maxLines: 6,
        textInputAction: TextInputAction.done,
        onTapOutside: (_) => _f.unfocus(),
        decoration: InputDecoration(hintText: context.l10n.personNote),
      );
}

class _GroupField extends StatefulWidget {
  const _GroupField({required this.person});
  final Person person;

  @override
  State<_GroupField> createState() => _GroupFieldState();
}

class _GroupFieldState extends State<_GroupField> {
  late final TextEditingController _c = TextEditingController(text: widget.person.group);
  final _f = FocusNode();

  @override
  void initState() {
    super.initState();
    _f.addListener(() {
      if (!_f.hasFocus) {
        final p = context.appRead.personById(widget.person.id);
        if (p != null && p.group != _c.text) context.appRead.updatePerson(p.copyWith(group: _c.text));
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _c,
        focusNode: _f,
        maxLength: 60,
        onTapOutside: (_) => _f.unfocus(),
        decoration: InputDecoration(hintText: context.l10n.personGroup),
      );
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.title, this.hint});
  final String title;
  final String? hint;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLength: 200,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, _c.text), child: Text(l.save)),
      ],
    );
  }
}

class _TalkResult {
  const _TalkResult(this.note, this.followUpDays);
  final String note;
  final int? followUpDays;
}

class _TalkDialog extends StatefulWidget {
  const _TalkDialog();

  @override
  State<_TalkDialog> createState() => _TalkDialogState();
}

class _TalkDialogState extends State<_TalkDialog> {
  final _c = TextEditingController();
  int? _days;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    return AlertDialog(
      title: Text(l.personTalked),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: _c, maxLength: 500, decoration: InputDecoration(hintText: l.interactionNoteHint)),
          const SizedBox(height: 8),
          Text(l.personFollowUp, style: context.text.titleSmall),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final d in const [null, 7, 14, 30, 90])
              ChoiceChip(
                label: Text(d == null ? l.none : l.personFollowUpDays(fmt.num(d))),
                selected: _days == d,
                onSelected: (_) => setState(() => _days = d),
              ),
          ]),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, _TalkResult(_c.text, _days)), child: Text(l.save)),
      ],
    );
  }
}
