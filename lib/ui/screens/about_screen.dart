import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../app_scope.dart';
import '../widgets/common.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final app = context.appRead;
    final s = context.scheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.about)),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [s.primary, s.secondary]),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(Icons.history_toggle_off_rounded, color: s.onPrimary, size: 48),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: Text(l.appName, style: context.text.headlineMedium)),
        Center(child: Text(l.versionValue(context.fmt.num(app.appVersion)), style: context.text.bodyMedium?.copyWith(color: s.onSurfaceVariant))),
        const SizedBox(height: 20),
        Text(l.tagline, textAlign: TextAlign.center, style: context.text.titleMedium?.copyWith(color: s.primary)),
        const SizedBox(height: 16),
        Text(l.aboutBody, textAlign: TextAlign.center, style: context.text.bodyLarge),
        const SizedBox(height: 12),
        Text(l.aboutOffline, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: s.onSurfaceVariant)),
        const SizedBox(height: 24),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.gavel_rounded),
              title: Text(l.aboutLicenses),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => showLicensePage(
                context: context,
                applicationName: l.appName,
                applicationVersion: app.appVersion,
                applicationLegalese: l.licensesLegalese,
              ),
            ),
            if (AppConfig.supportEmail.isNotEmpty) ...[
              const Divider(indent: 56),
              ListTile(
                leading: const Icon(Icons.mail_outline_rounded),
                title: Text(l.aboutContact),
                subtitle: Text(AppConfig.supportEmail, textDirection: TextDirection.ltr),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}
