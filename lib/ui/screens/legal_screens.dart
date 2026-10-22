import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../app_scope.dart';
import '../widgets/common.dart';

enum LegalKind { terms, privacy }

/// Loads a legal document from assets (edit assets/legal/*.txt to change it).
Future<String> loadLegalText(LegalKind kind, String lang) async {
  final name = kind == LegalKind.terms ? 'terms' : 'privacy';
  try {
    return await rootBundle.loadString('assets/legal/${name}_$lang.txt');
  } catch (_) {
    return rootBundle.loadString('assets/legal/${name}_fa.txt');
  }
}

class LegalTextScreen extends StatelessWidget {
  const LegalTextScreen({super.key, required this.kind});
  final LegalKind kind;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.appRead.settings.languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(kind == LegalKind.terms ? l.termsTitle : l.privacyTitle)),
      body: FutureBuilder<String>(
        future: loadLegalText(kind, lang),
        builder: (context, snap) {
          if (snap.hasError) return EmptyState(emoji: '⚠️', title: l.legalLoadError);
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return _LegalBody(text: snap.data!);
        },
      ),
    );
  }
}

class _LegalBody extends StatelessWidget {
  const _LegalBody({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final blocks = text.split('\n\n');
    return SelectionArea(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        itemCount: blocks.length,
        itemBuilder: (_, i) {
          final b = blocks[i].trim();
          final heading = b.startsWith('# ');
          return Padding(
            padding: EdgeInsets.only(bottom: 14, top: heading ? 10 : 0),
            child: Text(
              heading ? b.substring(2) : b,
              style: heading ? context.text.titleMedium : context.text.bodyMedium?.copyWith(height: 1.8),
            ),
          );
        },
      ),
    );
  }
}

/// First-run gate: the user must accept the Terms and Privacy Policy.
class LegalAcceptScreen extends StatefulWidget {
  const LegalAcceptScreen({super.key});

  @override
  State<LegalAcceptScreen> createState() => _LegalAcceptScreenState();
}

class _LegalAcceptScreenState extends State<LegalAcceptScreen> {
  bool _accepted = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.scheme;
    final app = context.appRead;
    void open(LegalKind k) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LegalTextScreen(kind: k)));

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 24),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: context.appColors.lavender, shape: BoxShape.circle),
                  child: Icon(Icons.verified_user_outlined, color: s.primary, size: 30),
                ),
                const SizedBox(height: 20),
                Semantics(header: true, child: Text(l.legalTitle, style: context.text.headlineMedium)),
                const SizedBox(height: 8),
                Text(l.legalIntro, style: context.text.bodyLarge?.copyWith(color: s.onSurfaceVariant)),
                const SizedBox(height: 24),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(l.termsTitle),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => open(LegalKind.terms),
                    ),
                    const Divider(indent: 56),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: Text(l.privacyTitle),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => open(LegalKind.privacy),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _accepted,
                  onChanged: (v) => setState(() => _accepted = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.legalAccept, style: context.text.bodyMedium),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: !_accepted || _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            await guarded(context, app.acceptLegal);
                            if (mounted) setState(() => _busy = false);
                          },
                    child: Text(l.legalContinue),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
