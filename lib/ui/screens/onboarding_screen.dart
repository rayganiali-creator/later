import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../app_scope.dart';
import '../widgets/common.dart';

/// First-run tutorial (5 pages, skippable).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    await guarded(context, () => context.appRead.updateSettings((s) => s.copyWith(onboardingDone: true)));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.scheme;
    final pages = <(IconData, String, String, String)>[
      (Icons.pause_circle_outline_rounded, '⏳', l.onb1Title, l.onb1Body),
      (Icons.inbox_rounded, '📥', l.onb2Title, l.onb2Body),
      (Icons.notifications_active_outlined, '🔔', l.onb3Title, l.onb3Body),
      (Icons.lock_outline_rounded, '🔒', l.onb4Title, l.onb4Body),
      (Icons.rocket_launch_outlined, '🚀', l.onb5Title, l.onb5Body),
    ];
    final last = _page == pages.length - 1;
    final reduce = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(onPressed: last ? null : _finish, child: Text(l.skip)),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final p = pages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedScale(
                      scale: i == _page ? 1 : 0.85,
                      duration: reduce ? Duration.zero : const Duration(milliseconds: 350),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            s.primaryContainer,
                            context.appColors.lavender,
                          ]),
                        ),
                        alignment: Alignment.center,
                        child: ExcludeSemantics(child: Text(p.$2, style: const TextStyle(fontSize: 76))),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Semantics(
                      header: true,
                      child: Text(p.$3, textAlign: TextAlign.center, style: context.text.headlineSmall),
                    ),
                    const SizedBox(height: 14),
                    Text(p.$4,
                        textAlign: TextAlign.center,
                        style: context.text.bodyLarge?.copyWith(color: s.onSurfaceVariant)),
                  ]),
                );
              },
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < pages.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 26 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page ? s.primary : s.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (last) {
                    _finish();
                  } else {
                    _controller.nextPage(
                      duration: reduce ? Duration.zero : const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
                child: Text(last ? l.onbStart : l.next),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
