import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/dates.dart';
import '../../data/controller.dart';
import '../../domain/settings.dart';
import '../../services/notification_service.dart';
import '../app_scope.dart';
import '../widgets/common.dart';
import '../widgets/pro_gate.dart';
import 'about_screen.dart';
import 'backup_screen.dart';
import 'categories_screen.dart';
import 'legal_screens.dart';
import 'pro_screen.dart';
import 'qa_tools_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> with WidgetsBindingObserver {
  NotificationPermission? _perm;
  bool? _exact;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final app = context.appRead;
    final p = await app.notifications.permission();
    final e = await app.notifications.exactAlarmsAllowed();
    if (!mounted) return;
    setState(() {
      _perm = p;
      _exact = e;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final st = app.settings;
    final s = context.scheme;

    String themeName(ThemeMode m) => switch (m) {
          ThemeMode.light => l.themeLight,
          ThemeMode.dark => l.themeDark,
          ThemeMode.system => l.themeSystem,
        };

    String accentName(AccentPalette a) => switch (a) {
          AccentPalette.indigo => l.accentIndigo,
          AccentPalette.teal => l.accentTeal,
          AccentPalette.rose => l.accentRose,
          AccentPalette.amber => l.accentAmber,
          AccentPalette.slate => l.accentSlate,
        };

    String iconName(IconVariant v) => switch (v) {
          IconVariant.classic => l.iconClassic,
          IconVariant.teal => l.iconTeal,
          IconVariant.rose => l.iconRose,
          IconVariant.dark => l.iconDark,
        };

    final ent = app.pro.entitlement;
    final proSub = app.isPro
        ? l.proSettingsActive(fmt.date(ent.expiresAt!.toLocal(), omitCurrentYear: false))
        : l.proSettingsFree;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(l.settingsTitle, style: context.text.headlineSmall),
          ),
          // Pro card
          PressableScale(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProScreen())),
            semanticLabel: '${l.proSettingsTitle}. $proSub',
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [s.primary, Color.lerp(s.primary, s.secondary, 0.8)!]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(children: [
                Icon(Icons.auto_awesome_rounded, color: s.onPrimary, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.proSettingsTitle, style: context.text.titleMedium?.copyWith(color: s.onPrimary)),
                    Text(proSub, style: context.text.bodySmall?.copyWith(color: s.onPrimary.withValues(alpha: 0.85))),
                  ]),
                ),
                Icon(Icons.chevron_left_rounded, color: s.onPrimary),
              ]),
            ),
          ),

          _section(l.secAppearance),
          _group([
            _tile(Icons.brightness_6_rounded, l.theme, themeName(st.themeMode), onTap: () async {
              final v = await _choose<ThemeMode>(context, l.theme, ThemeMode.values, st.themeMode, themeName);
              if (v != null) await app.updateSettings((x) => x.copyWith(themeMode: v));
            }),
            _tile(Icons.palette_outlined, l.accent, accentName(st.accent),
                pro: st.accent != AccentPalette.indigo && !app.isPro, onTap: () async {
              final v = await _choose<AccentPalette>(context, l.accent, AccentPalette.values, st.accent, accentName,
                  lockedWhen: (a) => a != AccentPalette.indigo && !app.isPro,
                  swatch: (a) => accentColor(a, Theme.of(context).brightness));
              if (v == null) return;
              if (v != AccentPalette.indigo && !app.isPro) {
                if (context.mounted) await showProSheet(context, featureName: l.proF7);
                return;
              }
              await app.updateSettings((x) => x.copyWith(accent: v));
            }),
            _tile(Icons.apps_rounded, l.appIcon, iconName(st.iconVariant),
                pro: st.iconVariant != IconVariant.classic && !app.isPro, onTap: () async {
              final v = await _choose<IconVariant>(context, l.appIcon, IconVariant.values, st.iconVariant, iconName,
                  lockedWhen: (a) => a != IconVariant.classic && !app.isPro);
              if (v == null) return;
              if (v != IconVariant.classic && !app.isPro) {
                if (context.mounted) await showProSheet(context, featureName: l.proF7);
                return;
              }
              await app.updateSettings((x) => x.copyWith(iconVariant: v));
              if (context.mounted) showAppSnack(context, l.iconChangeNote);
            }),
          ]),

          _section(l.secReminders),
          _group([
            SwitchListTile(
              value: st.remindersEnabled,
              title: Text(l.remindersToggle),
              secondary: const Icon(Icons.notifications_active_outlined),
              onChanged: (v) async {
                await app.updateSettings((x) => x.copyWith(remindersEnabled: v));
                if (v) {
                  await app.ensureNotificationPermission();
                  _refresh();
                }
              },
            ),
            _tile(Icons.schedule_rounded, l.defaultReminderTime, fmt.minutesOfDay(st.defaultReminderMinutes), onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: st.defaultReminderMinutes ~/ 60, minute: st.defaultReminderMinutes % 60),
                builder: (ctx, child) => MediaQuery(
                  data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                  child: child!,
                ),
              );
              if (t != null) {
                await app.updateSettings((x) => x.copyWith(defaultReminderMinutes: t.hour * 60 + t.minute));
              }
            }),
            SwitchListTile(
              value: st.privateNotifications,
              title: Text(l.privateNotifications),
              subtitle: Text(l.privateNotificationsSub),
              secondary: const Icon(Icons.visibility_off_outlined),
              onChanged: (v) => app.updateSettings((x) => x.copyWith(privateNotifications: v)),
            ),
            _tile(
              Icons.notifications_outlined,
              l.notifPermission,
              _perm == NotificationPermission.denied ? l.notifPermissionOff : l.notifPermissionOn,
              danger: _perm == NotificationPermission.denied,
              onTap: () async {
                if (_perm == NotificationPermission.denied) {
                  final ok = await app.ensureNotificationPermission();
                  if (!ok) await app.notifications.openSystemSettings();
                } else {
                  await app.notifications.openSystemSettings();
                }
                _refresh();
              },
            ),
            _tile(
              Icons.alarm_on_rounded,
              l.exactAlarm,
              (_exact ?? true) ? l.exactAlarmOk : l.exactAlarmOff,
              danger: _exact == false,
              onTap: () async {
                if (_exact == false) await app.notifications.requestExactAlarms();
                _refresh();
              },
            ),
            _tile(Icons.battery_saver_rounded, l.batteryOptimization, l.batteryOptimizationSub,
                onTap: () => app.platform.openBatteryOptimizationSettings()),
            _tile(Icons.notification_add_outlined, l.sendTestNotification, null, onTap: () async {
              try {
                await app.ensureNotificationPermission();
                await app.showTestNotification();
                if (context.mounted) showAppSnack(context, l.testNotificationSent);
              } catch (e) {
                // Never a raw exception for users; QA builds also show the detail.
                final detail = AppConfig.testToolsEnabled ? '\n$e' : '';
                if (context.mounted) showAppSnack(context, '${l.errorGeneric}$detail', duration: const Duration(seconds: 8));
              }
            }),
          ]),

          _section(l.secGeneral),
          _group([
            _tile(Icons.language_rounded, l.language, st.languageCode == 'fa' ? l.langFa : l.langEn, onTap: () async {
              final v = await _choose<String>(context, l.language, const ['fa', 'en'], st.languageCode,
                  (c) => c == 'fa' ? l.langFa : l.langEn);
              if (v != null) await app.updateSettings((x) => x.copyWith(languageCode: v));
            }),
            _tile(Icons.calendar_month_rounded, l.calendar, st.calendar == CalendarSystem.jalali ? l.calJalali : l.calGregorian,
                onTap: () async {
              final v = await _choose<CalendarSystem>(context, l.calendar, CalendarSystem.values, st.calendar,
                  (c) => c == CalendarSystem.jalali ? l.calJalali : l.calGregorian);
              if (v != null) await app.updateSettings((x) => x.copyWith(calendar: v));
            }),
            _tile(Icons.view_week_rounded, l.weekStart, Dates.weekdayName(_dayOf(st.weekStart), fmt.fa), onTap: () async {
              final v = await _choose<int>(context, l.weekStart, const [6, 7, 1], st.weekStart,
                  (d) => Dates.weekdayName(_dayOf(d), fmt.fa));
              if (v != null) await app.updateSettings((x) => x.copyWith(weekStart: v));
            }),
            _tile(Icons.weekend_outlined, l.weekendDay, Dates.weekdayName(_dayOf(st.weekendDay), fmt.fa), onTap: () async {
              final v = await _choose<int>(context, l.weekendDay, const [4, 5, 6, 7], st.weekendDay,
                  (d) => Dates.weekdayName(_dayOf(d), fmt.fa));
              if (v != null) await app.updateSettings((x) => x.copyWith(weekendDay: v));
            }),
            SwitchListTile(
              value: st.keepHistory,
              title: Text(l.keepHistory),
              subtitle: Text(l.keepHistorySub),
              secondary: const Icon(Icons.history_rounded),
              onChanged: (v) => app.updateSettings((x) => x.copyWith(keepHistory: v)),
            ),
            _tile(Icons.hourglass_bottom_rounded, l.staleAfter, l.daysN(fmt.num(st.staleDays)), onTap: () async {
              final v = await _choose<int>(context, l.staleAfter, const [14, 30, 60, 90], st.staleDays,
                  (d) => l.daysN(fmt.num(d)));
              if (v != null) await app.updateSettings((x) => x.copyWith(staleDays: v));
            }),
            _tile(Icons.shopping_bag_outlined, l.wishlistReviewAfter, l.daysN(fmt.num(st.wishlistReviewDays)),
                onTap: () async {
              final v = await _choose<int>(context, l.wishlistReviewAfter, const [14, 30, 60, 90], st.wishlistReviewDays,
                  (d) => l.daysN(fmt.num(d)));
              if (v != null) await app.updateSettings((x) => x.copyWith(wishlistReviewDays: v));
            }),
            _tile(Icons.lightbulb_outline_rounded, l.ideaReviewEvery, l.daysN(fmt.num(st.ideaReviewDays)),
                trailing: app.isPro ? null : const ProTag(), onTap: () async {
              if (!app.isPro) {
                await showProSheet(context, featureName: l.ideaProHint);
                return;
              }
              if (!context.mounted) return;
              final v = await _choose<int>(context, l.ideaReviewEvery, const [14, 30, 60, 90], st.ideaReviewDays,
                  (d) => l.daysN(fmt.num(d)));
              if (v != null) await app.updateSettings((x) => x.copyWith(ideaReviewDays: v));
            }),
            SwitchListTile(
              value: st.ideaReviewReminder && app.isPro,
              title: Row(children: [Flexible(child: Text(l.ideaReviewMonthly)), if (!app.isPro) ...[const SizedBox(width: 8), const ProTag()]]),
              secondary: const Icon(Icons.event_repeat_rounded),
              onChanged: (v) async {
                if (!app.isPro) {
                  await showProSheet(context, featureName: l.ideaProHint);
                  return;
                }
                await app.updateSettings((x) => x.copyWith(ideaReviewReminder: v));
              },
            ),
            SwitchListTile(
              value: st.askWhereOnShare,
              title: Text(l.askWhereOnShare),
              subtitle: Text(l.askWhereOnShareSub),
              secondary: const Icon(Icons.ios_share_rounded),
              onChanged: (v) => app.updateSettings((x) => x.copyWith(askWhereOnShare: v)),
            ),
            _tile(Icons.casino_outlined, l.settingsRouletteCats,
                st.rouletteCategories.isEmpty ? l.settingsRouletteCatsAll : fmt.num(st.rouletteCategories.length),
                trailing: app.isPro ? null : const ProTag(), onTap: () async {
              if (!app.isPro) {
                await showProSheet(context, featureName: l.rouletteProHint);
                return;
              }
              if (!context.mounted) return;
              await _pickRouletteCats(context);
            }),
          ]),

          _section(l.secData),
          _group([
            _tile(Icons.category_outlined, l.categoriesManage, null,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()))),
            _tile(Icons.backup_outlined, l.backupRestore, null,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BackupScreen()))),
            _tile(Icons.delete_forever_outlined, l.resetApp, l.resetAppSub, danger: true, onTap: () => _reset(context)),
          ]),

          _section(l.secAbout),
          _group([
            _tile(Icons.description_outlined, l.termsTitle, null,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LegalTextScreen(kind: LegalKind.terms)))),
            _tile(Icons.privacy_tip_outlined, l.privacyTitle, null,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LegalTextScreen(kind: LegalKind.privacy)))),
            _tile(Icons.info_outline_rounded, l.about, l.versionValue(fmt.num(app.appVersion)),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen()))),
            if (AppConfig.testToolsEnabled)
              _tile(Icons.science_outlined, l.qaTitle, null,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const QaToolsScreen()))),
          ]),
        ],
      ),
    );
  }

  static DateTime _dayOf(int weekday) => DateTime(2026, 9, 28).add(Duration(days: weekday - 1)); // 2026-09-28 is Monday

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 22, 8, 8),
        child: Text(t, style: context.text.labelLarge?.copyWith(color: context.scheme.primary)),
      );

  Widget _group(List<Widget> children) => AppCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const Divider(indent: 56),
          ],
        ]),
      );

  Widget _tile(IconData icon, String title, String? subtitle,
      {VoidCallback? onTap, bool danger = false, bool pro = false, Widget? trailing}) {
    final s = context.scheme;
    return ListTile(
      leading: Icon(icon, color: danger ? s.error : s.onSurfaceVariant),
      title: Text(title, style: danger ? TextStyle(color: s.error) : null),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: trailing ?? (pro ? const ProTag() : const Icon(Icons.chevron_left_rounded, size: 20)),
      onTap: onTap,
    );
  }

  Future<T?> _choose<T>(BuildContext context, String title, List<T> values, T current, String Function(T) label,
      {bool Function(T)? lockedWhen, Color Function(T)? swatch}) {
    return showAppSheet<T>(
      context,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(title, style: ctx.text.titleLarge),
              ),
            ),
            for (final v in values)
              ListTile(
                leading: swatch == null
                    ? null
                    : CircleAvatar(radius: 12, backgroundColor: swatch(v)),
                title: Text(label(v)),
                trailing: (lockedWhen?.call(v) ?? false)
                    ? const ProTag()
                    : (v == current ? Icon(Icons.check_rounded, color: ctx.scheme.primary) : null),
                onTap: () => Navigator.pop(ctx, v),
              ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickRouletteCats(BuildContext context) {
    final app = context.appRead;
    final l = context.l10n;
    return showAppSheet<void>(
      context,
      builder: (ctx) => _CatPicker(app: app, title: l.settingsRouletteCats),
    );
  }

  Future<void> _reset(BuildContext context) async {
    final l = context.l10n;
    final app = context.appRead;
    final ok = await showDialog<bool>(context: context, builder: (_) => const _ResetDialog());
    if (ok == true && context.mounted) {
      await guarded(context, app.resetAll);
      HapticFeedback.heavyImpact();
      if (context.mounted) showAppSnack(context, l.resetDone);
    }
  }
}

/// Confirmation dialog that requires typing a word (owns its controller).
class _ResetDialog extends StatefulWidget {
  const _ResetDialog();

  @override
  State<_ResetDialog> createState() => _ResetDialogState();
}

class _ResetDialogState extends State<_ResetDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final match = _ctrl.text.trim() == l.resetWord;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: context.scheme.error, size: 36),
      title: Text(l.resetConfirmTitle),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.resetConfirmBody),
          const SizedBox(height: 14),
          Text(l.resetTypeHint(l.resetWord), style: context.text.labelLarge),
          const SizedBox(height: 8),
          TextField(controller: _ctrl, onChanged: (_) => setState(() {})),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        TextButton(
          onPressed: match ? () => Navigator.pop(context, true) : null,
          style: TextButton.styleFrom(foregroundColor: context.scheme.error),
          child: Text(l.resetAction),
        ),
      ],
    );
  }
}


class _CatPicker extends StatefulWidget {
  const _CatPicker({required this.app, required this.title});
  final LaterController app;
  final String title;

  @override
  State<_CatPicker> createState() => _CatPickerState();
}

class _CatPickerState extends State<_CatPicker> {
  late final Set<String> _sel = {...widget.app.settings.rouletteCategories};

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(widget.title, style: context.text.titleLarge),
            ),
          ),
          for (final c in app.categories)
            CheckboxListTile(
              value: _sel.contains(c.id),
              title: Text('${c.emoji} ${app.categoryName(c.id)}'),
              onChanged: (v) {
                setState(() => v == true ? _sel.add(c.id) : _sel.remove(c.id));
                app.updateSettings((x) => x.copyWith(rouletteCategories: {..._sel}));
              },
            ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}
