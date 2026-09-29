import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../app_scope.dart';
import '../screens/pro_screen.dart';
import 'common.dart';

/// Explains that a feature needs Pro and offers to open the plans screen.
/// The free version is never blocked from its core loop; this is only used
/// for the advanced features listed in the product spec.
Future<void> showProSheet(BuildContext context, {String? featureName}) {
  final l = context.l10n;
  return showAppSheet<void>(
    context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [ctx.scheme.primary, ctx.scheme.secondary]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 16),
        Text(l.proLockedTitle, style: ctx.text.titleLarge, textAlign: TextAlign.center),
        if (featureName != null) ...[
          const SizedBox(height: 6),
          Text(featureName,
              style: ctx.text.titleSmall?.copyWith(color: ctx.scheme.primary), textAlign: TextAlign.center),
        ],
        const SizedBox(height: 8),
        Text(l.proLockedBody,
            style: ctx.text.bodyMedium?.copyWith(color: ctx.scheme.onSurfaceVariant),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProScreen()));
            },
            child: Text(l.proSeePlans),
          ),
        ),
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.notNow)),
      ]),
    ),
  );
}
