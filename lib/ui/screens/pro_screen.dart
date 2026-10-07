import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/config/pro_plans.dart';
import '../../core/theme/app_theme.dart';
import '../../services/purchase_gateway.dart';
import '../app_scope.dart';
import '../widgets/common.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  ProPlanType? _busyPlan;
  bool _restoring = false;

  String _planName(ProPlan p) {
    final l = context.l10n;
    return switch (p.type) {
      ProPlanType.month1 => l.proPlan1,
      ProPlanType.month3 => l.proPlan3,
      ProPlanType.month6 => l.proPlan6,
      ProPlanType.day1 => l.proPlanDay1,
      ProPlanType.day7 => l.proPlanDay7,
      ProPlanType.none => '',
    };
  }

  String _price(int toman) {
    final s = toman.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return context.l10n.priceToman(context.fmt.num(b.toString().replaceAll(',', '٬')));
  }

  Future<void> _buy(ProPlan plan) async {
    final l = context.l10n;
    final app = context.appRead;
    setState(() => _busyPlan = plan.type);
    try {
      final r = await app.buy(plan);
      if (!mounted) return;
      switch (r.status) {
        case PurchaseStatus.success:
          showAppSnack(context, l.proPurchaseSuccess);
        case PurchaseStatus.cancelled:
          showAppSnack(context, l.proPurchaseCancelled);
        case PurchaseStatus.unavailable:
          showAppSnack(context, l.proPurchaseUnavailable);
        case PurchaseStatus.alreadyOwned:
          showAppSnack(context, l.proAlreadyOwned);
        case PurchaseStatus.failed:
          showAppSnack(context, l.proPurchaseFailed);
      }
    } catch (_) {
      if (mounted) showAppSnack(context, l.proPurchaseFailed);
    } finally {
      if (mounted) setState(() => _busyPlan = null);
    }
  }

  Future<void> _restore() async {
    final l = context.l10n;
    final app = context.appRead;
    setState(() => _restoring = true);
    try {
      final n = await app.restorePurchases();
      if (!mounted) return;
      showAppSnack(context, n > 0 ? l.proRestored(context.fmt.num(n)) : l.proNothingToRestore);
    } catch (_) {
      if (mounted) showAppSnack(context, l.errorGeneric);
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    final ent = app.pro.entitlement;
    final active = app.isPro;
    final expired = !active && ent.expiresAt != null;
    final remainingDays = active ? (ent.remainingAt(app.pro.effectiveNow()).inHours / 24).ceil() : 0;

    final features = [
      (l.proFT1, l.proFD1),
      (l.proFT2, l.proFD2),
      (l.proFT3, l.proFD3),
      (l.proFT4, l.proFD4),
      (l.proFT5, l.proFD5),
      (l.proFT6, l.proFD6),
      (l.proFT7, l.proFD7),
      (l.proFT8, l.proFD8),
      (l.proFT9, l.proFD9),
      (l.proFT10, l.proFD10),
      (l.proFT11, l.proFD11),
      (l.proFT12, l.proFD12),
      (l.proFT13, l.proFD13),
      (l.proFT14, l.proFD14),
      (l.proFT15, l.proFD15),
      (l.proFT16, l.proFD16),
      (l.proFT17, l.proFD17),
    ];
    final plans = [
      ...ProPlans.sellable,
      if (AppConfig.testToolsEnabled) ...[ProPlans.day1, ProPlans.day7],
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.proTitle)),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [s.primary, Color.lerp(s.primary, s.secondary, 0.85)!],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.auto_awesome_rounded, color: s.onPrimary, size: 34),
            const SizedBox(height: 10),
            Text(l.proHeadline, style: context.text.titleLarge?.copyWith(color: s.onPrimary)),
            if (active) ...[
              const SizedBox(height: 14),
              Semantics(
                liveRegion: true,
                child: Text(
                  '${l.proActiveUntil(fmt.date(ent.expiresAt!.toLocal(), omitCurrentYear: false))} · ${l.proRemaining(fmt.num(remainingDays))}',
                  style: context.text.titleSmall?.copyWith(color: s.onPrimary),
                ),
              ),
            ],
          ]),
        ),
        if (expired) ...[
          const SizedBox(height: 12),
          AppCard(
            color: context.appColors.warning.withValues(alpha: 0.10),
            borderColor: context.appColors.warning.withValues(alpha: 0.35),
            child: Text(l.proExpiredNote, style: context.text.bodyMedium),
          ),
        ],
        if (app.pro.tamperDetected) ...[
          const SizedBox(height: 12),
          AppCard(color: s.error.withValues(alpha: 0.08), child: Text(l.proTamper)),
        ],
        const SizedBox(height: 16),
        SectionTitle(l.proWhatYouGet),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: [
            for (var i = 0; i < features.length; i++) ...[
              if (i > 0) Divider(height: 1, color: s.outlineVariant),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.check_circle_rounded, size: 20, color: context.appColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(features[i].$1, style: context.text.titleSmall),
                      const SizedBox(height: 2),
                      Text(features[i].$2,
                          style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant, height: 1.5)),
                    ]),
                  ),
                ]),
              ),
            ],
          ]),
        ),
        SectionTitle(l.proFreeHeader),
        AppCard(child: Text(l.proFreeList, style: context.text.bodyMedium?.copyWith(height: 1.6))),
        const SizedBox(height: 10),
        Text(l.proFreeNote, style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
        const SizedBox(height: 20),
        for (final p in plans)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 12),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_planName(p), style: context.text.titleMedium),
                    Text(p.priceToman == 0 ? '—' : _price(p.priceToman),
                        style: context.text.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
                  ]),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(96, 46)),
                  onPressed: _busyPlan != null ? null : () => _buy(p),
                  child: _busyPlan == p.type
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: s.onPrimary))
                      : Text(active ? l.proExtend : l.proBuy),
                ),
              ]),
            ),
          ),
        Text(l.proStackNote, style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: _restoring ? null : _restore,
            icon: const Icon(Icons.restore_rounded),
            label: Text(l.proRestore),
          ),
        ),
      ]),
    );
  }
}
