import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/learning.dart';
import '../../domain/models.dart';
import '../../domain/pro.dart';
import '../../l10n/app_localizations.dart';
import '../app_scope.dart';
import '../item_actions.dart';
import '../type_info.dart';
import '../widgets/common.dart';
import '../widgets/date_picker.dart';
import '../widgets/pro_gate.dart';

String platformLabel(AppL10n l, String p) => switch (p) {
      'android' => l.platAndroid,
      'windows' => l.platWindows,
      'macos' => l.platMac,
      'linux' => l.platLinux,
      'ios' => l.platIos,
      'web' => l.platWeb,
      _ => l.platOther,
    };

String levelLabel(AppL10n l, String v) => switch (v) {
      'beginner' => l.levelBeginner,
      'intermediate' => l.levelIntermediate,
      'advanced' => l.levelAdvanced,
      _ => '',
    };

/// The part of the detail sheet that belongs to apps / podcasts / courses /
/// games.
List<Widget> mediaSections(BuildContext context, BuildContext host, LaterItem item) {
  switch (item.type) {
    case ItemType.app:
      return _app(context, host, item);
    case ItemType.podcast:
      return _podcast(context, host, item);
    case ItemType.course:
      return _course(context, host, item);
    case ItemType.game:
      return _game(context, host, item);
    default:
      return const [];
  }
}

Widget _row(BuildContext context, IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 19, color: context.scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
      ]),
    );

Widget _history(BuildContext context, LaterItem item) {
  final l = context.l10n;
  final fmt = context.fmt;
  final pro = context.app.isPro;
  final h = item.stageHistory;
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 8),
    Row(children: [
      Text(l.statusHistoryTitle, style: context.text.labelLarge?.copyWith(color: context.scheme.onSurfaceVariant)),
      const SizedBox(width: 8),
      if (!pro) const ProTag(),
    ]),
    const SizedBox(height: 6),
    if (!pro)
      GestureDetector(
        onTap: () => showProSheet(context, featureName: l.statusHistoryPro),
        child: Text(l.statusHistoryPro, style: context.text.bodySmall?.copyWith(color: context.scheme.primary)),
      )
    else if (h.isEmpty)
      Text('—', style: context.text.bodySmall)
    else
      for (final e in h.reversed.take(12))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '${fmt.date(e.$1, omitCurrentYear: false)} · ${TypeInfo.stageLabel(l, item.type, e.$2)}',
            style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant),
          ),
        ),
  ]);
}

// ------------------------------------------------------------------- apps

List<Widget> _app(BuildContext context, BuildContext host, LaterItem item) {
  final l = context.l10n;
  final s = context.scheme;
  return [
    if (item.platforms.isNotEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final p in item.platforms) Pill(platformLabel(l, p), icon: Icons.devices_rounded),
        ]),
      ),
    if (item.isActive) ...[
      const SizedBox(height: 4),
      OutlinedButton.icon(
        onPressed: () => showAppReviewDialog(host, item),
        icon: Icon(Icons.help_outline_rounded, color: s.primary),
        label: Text(l.appStillNeed),
      ),
    ],
    _history(context, item),
  ];
}

/// "Do I still need this app?" with four honest answers.
Future<void> showAppReviewDialog(BuildContext context, LaterItem item) async {
  final l = context.l10n;
  final fmt = context.fmt;
  final app = context.appRead;
  final days = app.now().difference(item.lastKeptAt ?? item.createdAt).inDays.clamp(1, 100000);
  final a = await showDialog<AppAnswer>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      content: Text(l.appReviewQuestion(fmt.num(days))),
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actions: [
        FilledButton(onPressed: () => Navigator.pop(ctx, AppAnswer.installed), child: Text(l.appAnsInstalled)),
        OutlinedButton(onPressed: () => Navigator.pop(ctx, AppAnswer.still), child: Text(l.appAnsStill)),
        OutlinedButton(onPressed: () => Navigator.pop(ctx, AppAnswer.later), child: Text(l.appAnsLater)),
        TextButton(onPressed: () => Navigator.pop(ctx, AppAnswer.no), child: Text(l.appAnsNo)),
      ],
    ),
  );
  if (a != null && context.mounted) await app.answerAppReview(item.id, a);
}

// --------------------------------------------------------------- podcasts

List<Widget> _podcast(BuildContext context, BuildContext host, LaterItem item) {
  final l = context.l10n;
  final fmt = context.fmt;
  final color = TypeInfo.color(item.type);
  return [
    if (item.show.isNotEmpty) _row(context, Icons.podcasts_rounded, item.show),
    if (item.creator.isNotEmpty) _row(context, Icons.person_outline_rounded, item.creator),
    if (item.isActive || item.progress > 0) ...[
      const SizedBox(height: 4),
      ProgressEditor(item: item, color: color),
      if (item.remainingSec != null)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${l.podcastProgress(fmt.num(item.progress))} · ${l.podcastRemaining(fmt.num(TypeInfo.clock(item.remainingSec!)))}',
            style: context.text.titleSmall?.copyWith(color: color),
          ),
        ),
    ],
    if (item.isActive) ...[
      const SizedBox(height: 10),
      FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: color),
        onPressed: () async {
          final app = host.appRead;
          if (item.stage == ItemStages.notListened) await app.setStage(item.id, ItemStages.listening);
          if (host.mounted && item.url != null) await ItemActions.openLink(host, item.url);
        },
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(item.progress > 0 ? l.continueListening : l.gameStart),
      ),
    ],
    _history(context, item),
  ];
}

/// Manual progress: a slider (percent) and, for podcasts, the last position.
class ProgressEditor extends StatefulWidget {
  const ProgressEditor({super.key, required this.item, required this.color});
  final LaterItem item;
  final Color color;

  @override
  State<ProgressEditor> createState() => _ProgressEditorState();
}

class _ProgressEditorState extends State<ProgressEditor> {
  late double _v = widget.item.progress.toDouble();
  late final TextEditingController _pos = TextEditingController(
      text: widget.item.positionSec != null && widget.item.positionSec! > 0 ? TypeInfo.clock(widget.item.positionSec!) : '');

  @override
  void didUpdateWidget(covariant ProgressEditor old) {
    super.didUpdateWidget(old);
    if (old.item.progress != widget.item.progress) _v = widget.item.progress.toDouble();
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final app = context.appRead;
    final item = widget.item;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('${l.fieldProgress}: ${fmt.num(_v.round())}٪', style: context.text.labelLarge),
      ]),
      Slider(
        value: _v,
        max: 100,
        divisions: 20,
        activeColor: widget.color,
        label: '${fmt.num(_v.round())}٪',
        onChanged: (v) => setState(() => _v = v),
        onChangeEnd: (v) => app.setProgress(item.id, percent: v.round()),
      ),
      if (item.type == ItemType.podcast)
        TextField(
          controller: _pos,
          keyboardType: TextInputType.datetime,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(labelText: l.lastPosition, hintText: l.lastPositionHint, isDense: true),
          onSubmitted: (t) {
            final sec = TypeInfo.parseClock(t);
            if (sec != null) app.setProgress(item.id, positionSec: sec);
          },
          onTapOutside: (_) {
            final sec = TypeInfo.parseClock(_pos.text);
            if (sec != null && sec != item.positionSec) app.setProgress(item.id, positionSec: sec);
            FocusScope.of(context).unfocus();
          },
        ),
    ]);
  }
}

// ---------------------------------------------------------------- courses

List<Widget> _course(BuildContext context, BuildContext host, LaterItem item) {
  final l = context.l10n;
  final fmt = context.fmt;
  final app = context.app;
  final color = TypeInfo.color(item.type);
  final pro = app.access.has(ProFeature.learnTools);
  final now = app.now();
  final stats = statsOfSessions(item.sessions, now, weekStart: app.settings.weekStart);
  final weekly = item.weeklyGoalMinutes;
  return [
    if (item.show.isNotEmpty) _row(context, Icons.language_rounded, item.show),
    if (item.creator.isNotEmpty) _row(context, Icons.person_outline_rounded, item.creator),
    if (item.level.isNotEmpty) _row(context, Icons.stairs_rounded, levelLabel(l, item.level)),
    if (item.goal.isNotEmpty)
      Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(14)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.flag_outlined, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(item.goal, style: context.text.bodyMedium)),
        ]),
      ),
    if (item.isActive || item.progress > 0) ProgressEditor(item: item, color: color),
    const SizedBox(height: 4),
    Row(children: [
      Text(l.learnGoalTitle, style: context.text.labelLarge?.copyWith(color: context.scheme.onSurfaceVariant)),
      const SizedBox(width: 8),
      if (!pro) const ProTag(),
      const Spacer(),
      TextButton(onPressed: () => _goalDialog(host, item), child: Text(l.edit)),
    ]),
    if (pro && item.goalDate != null) _row(context, Icons.event_rounded, '${l.goalDate} ${fmt.date(item.goalDate!, omitCurrentYear: false)}'),
    if (pro && weekly != null) ...[
      _row(context, Icons.speed_rounded, l.weekGoalProgress(fmt.num(stats.weekMinutes), fmt.num(weekly))),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (stats.weekMinutes / weekly).clamp(0, 1).toDouble(),
          minHeight: 6,
          color: color,
          backgroundColor: color.withValues(alpha: 0.15),
        ),
      ),
    ],
    if (!pro)
      GestureDetector(
        onTap: () => showProSheet(context, featureName: l.learnProHint),
        child: Text(l.learnProHint, style: context.text.bodySmall?.copyWith(color: context.scheme.primary)),
      ),
    if (item.isActive) ...[
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () => showSessionDialog(host, item),
        icon: const Icon(Icons.timer_outlined),
        label: Text(l.sessionLog),
      ),
    ],
    if (pro && stats.sessionCount > 0)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(spacing: 8, runSpacing: 6, children: [
          Pill('${l.statsTotalTime}: ${l.minutesTotal(fmt.num(stats.totalMinutes))}', icon: Icons.timer_outlined),
          Pill('${l.statsStreak}: ${l.streakDays(fmt.num(stats.streakDays))}', icon: Icons.local_fire_department_outlined),
        ]),
      ),
    if (item.url != null && item.isActive)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: color),
          onPressed: () async {
            final a = host.appRead;
            if (item.stage == ItemStages.learnLater) await a.setStage(item.id, ItemStages.learning);
            if (host.mounted) await ItemActions.openLink(host, item.url);
          },
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l.openLinkApp),
        ),
      ),
    _history(context, item),
  ];
}

// ------------------------------------------------------------------ games

List<Widget> _game(BuildContext context, BuildContext host, LaterItem item) {
  final l = context.l10n;
  final fmt = context.fmt;
  final app = context.app;
  final pro = app.access.has(ProFeature.gameTools);
  final stats = statsOfSessions(item.sessions, app.now(), weekStart: app.settings.weekStart);
  return [
    if (item.genre.isNotEmpty) _row(context, Icons.category_outlined, item.genre),
    if (item.platforms.isNotEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final p in item.platforms) Pill(platformLabel(l, p), icon: Icons.devices_rounded),
        ]),
      ),
    if (item.isActive) ...[
      const SizedBox(height: 4),
      OutlinedButton.icon(
        onPressed: () => showSessionDialog(host, item),
        icon: const Icon(Icons.timer_outlined),
        label: Row(mainAxisSize: MainAxisSize.min, children: [Text(l.sessionLog), if (!pro) ...[const SizedBox(width: 6), const ProTag()]]),
      ),
    ],
    if (pro && stats.sessionCount > 0)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(spacing: 8, runSpacing: 6, children: [
          Pill('${l.statsTotalTime}: ${l.minutesTotal(fmt.num(stats.totalMinutes))}', icon: Icons.timer_outlined),
          Pill('${l.statsWeekMinutes}: ${l.minutesTotal(fmt.num(stats.weekMinutes))}'),
        ]),
      ),
    if (!pro)
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: GestureDetector(
          onTap: () => showProSheet(context, featureName: l.gameProHint),
          child: Text(l.gameProHint, style: context.text.bodySmall?.copyWith(color: context.scheme.primary)),
        ),
      ),
    if (item.url != null && item.isActive)
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: () => ItemActions.openLink(host, item.url),
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: Text(l.openLinkApp),
        ),
      ),
    _history(context, item),
  ];
}

// ---------------------------------------------------------- shared dialogs

/// Logs minutes studied / played (Pro).
Future<void> showSessionDialog(BuildContext context, LaterItem item) async {
  final l = context.l10n;
  final app = context.appRead;
  final feature = item.type == ItemType.course ? ProFeature.learnTools : ProFeature.gameTools;
  if (!app.access.has(feature)) {
    await showProSheet(context, featureName: item.type == ItemType.course ? l.learnProHint : l.gameProHint);
    return;
  }
  final m = await showDialog<int>(context: context, builder: (_) => const _MinutesDialog());
  if (m == null || !context.mounted) return;
  final ok = await app.logSession(item.id, m);
  if (ok && context.mounted) showAppSnack(context, l.sessionLogged);
}

class _MinutesDialog extends StatefulWidget {
  const _MinutesDialog();

  @override
  State<_MinutesDialog> createState() => _MinutesDialogState();
}

class _MinutesDialogState extends State<_MinutesDialog> {
  final _c = TextEditingController();

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
      title: Text(l.sessionMinutes),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in const [15, 30, 45, 60, 90])
            ActionChip(label: Text(fmt.minutes(m)), onPressed: () => Navigator.pop(context, m)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _c,
          keyboardType: TextInputType.number,
          autofocus: false,
          decoration: InputDecoration(labelText: l.sessionMinutes),
          onSubmitted: (v) {
            final n = TypeInfo.parseClock(v);
            if (n != null) Navigator.pop(context, (n / 60).round().clamp(1, 1440));
          },
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(
          onPressed: () {
            final n = int.tryParse(TypeInfo.parseClock(_c.text) == null ? '' : '${(TypeInfo.parseClock(_c.text)! / 60).round()}');
            if (n != null && n > 0) Navigator.pop(context, n.clamp(1, 1440));
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}

/// Goal text (free); target date and weekly minutes (Pro).
Future<void> _goalDialog(BuildContext context, LaterItem item) async {
  final app = context.appRead;
  final r = await showDialog<_GoalResult>(context: context, builder: (_) => _GoalDialog(item: item));
  if (r == null) return;
  await app.setLearnGoal(item.id, goal: r.goal, goalDate: r.date, weeklyMinutes: r.weekly);
}

class _GoalResult {
  const _GoalResult(this.goal, this.date, this.weekly);
  final String goal;
  final DateTime? date;
  final int? weekly;
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({required this.item});
  final LaterItem item;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final _goal = TextEditingController(text: widget.item.goal);
  late final _weekly = TextEditingController(text: widget.item.weeklyGoalMinutes?.toString() ?? '');
  late DateTime? _date = widget.item.goalDate;

  @override
  void dispose() {
    _goal.dispose();
    _weekly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final pro = context.appRead.access.has(ProFeature.learnTools);
    return AlertDialog(
      title: Text(l.learnGoalTitle),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _goal,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(labelText: l.fieldGoal, hintText: l.goalHint),
          ),
          const SizedBox(height: 14),
          if (!pro)
            GestureDetector(
              onTap: () => showProSheet(context, featureName: l.learnProHint),
              child: Text(l.learnProHint, style: context.text.bodySmall?.copyWith(color: context.scheme.primary)),
            )
          else ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.event_rounded),
              label: Text(_date == null ? l.goalDate : fmt.date(_date!, omitCurrentYear: false)),
              onPressed: () async {
                final r = await showAppDatePicker(context, initial: _date, allowClear: true);
                if (r != null) setState(() => _date = r.date);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weekly,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.weeklyGoal),
            ),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(
          onPressed: () {
            final w = int.tryParse(TypeInfo.parseClock(_weekly.text) == null ? '' : _weekly.text.trim());
            Navigator.pop(context, _GoalResult(_goal.text, _date, w));
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}
