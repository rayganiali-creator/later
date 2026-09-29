import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/config/pro_plans.dart';
import '../../core/theme/app_theme.dart';
import '../app_scope.dart';
import '../widgets/common.dart';

/// Test-build-only tools: Pro simulation, time travel, sample data,
/// notification probes. Unreachable unless [AppConfig.testToolsEnabled].
class QaToolsScreen extends StatelessWidget {
  const QaToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.testToolsEnabled) return const SizedBox.shrink();
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    final ent = app.pro.entitlement;
    final proState = app.isPro
        ? '${ent.planType.name} → ${ent.expiresAt!.toLocal()}'
        : (ent.expiresAt != null ? 'expired (${ent.expiresAt!.toLocal()})' : 'free');

    Widget btn(String label, Future<void> Function() action, {IconData icon = Icons.play_arrow_rounded}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton.icon(
            onPressed: () => guarded(context, action),
            icon: Icon(icon, size: 20),
            label: Align(alignment: AlignmentDirectional.centerStart, child: Text(label)),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l.qaTitle)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        AppCard(
          color: context.appColors.warning.withValues(alpha: 0.10),
          child: Text(l.qaNote),
        ),
        const SizedBox(height: 12),
        Text(l.qaProState(proState), style: context.text.bodyMedium),
        Text(l.qaClock(app.now().toString()), style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
        const SizedBox(height: 12),
        for (final p in [ProPlans.day1, ProPlans.day7, ProPlans.month1, ProPlans.month3, ProPlans.month6])
          btn(l.qaGrantPlan(_name(l, p)), () async {
            await app.debugGrantPro(p);
          }, icon: Icons.workspace_premium_outlined),
        btn(l.qaClearPro, app.debugClearPro, icon: Icons.block_rounded),
        const Divider(height: 28),
        for (final d in const [1, 7, 31, 91])
          btn(l.qaAdvance(fmt.num(d)), () => app.debugAdvanceDays(d), icon: Icons.fast_forward_rounded),
        btn(l.qaResetTime, app.debugResetTime, icon: Icons.restart_alt_rounded),
        const Divider(height: 28),
        for (final n in const [40, 100, 500, 1000, 5000])
          btn(l.qaSeed(fmt.num(n)), () async {
            final sw = Stopwatch()..start();
            await app.debugSeed(n, withSamples: n <= 40);
            if (context.mounted) showAppSnack(context, '${l.qaSeeded(fmt.num(n))} (${sw.elapsedMilliseconds} ms)');
          }, icon: Icons.dataset_outlined),
        const Divider(height: 28),
        btn(l.qaNotifNow, app.showTestNotification, icon: Icons.notifications_active_outlined),
        btn(l.qaNotifIn('30'), () async {
          await app.ensureNotificationPermission();
          await app.debugScheduleTestIn(30);
        }, icon: Icons.alarm_add_rounded),
        btn(l.qaNotifIn('120'), () async {
          await app.ensureNotificationPermission();
          await app.debugScheduleTestIn(120);
        }, icon: Icons.alarm_add_rounded),
      ]),
    );
  }

  String _name(dynamic l, ProPlan p) => switch (p.type) {
        ProPlanType.day1 => l.proPlanDay1 as String,
        ProPlanType.day7 => l.proPlanDay7 as String,
        ProPlanType.month1 => l.proPlan1 as String,
        ProPlanType.month3 => l.proPlan3 as String,
        ProPlanType.month6 => l.proPlan6 as String,
        ProPlanType.none => '',
      };
}
