import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../app_scope.dart';

/// Rounded surface card used across the app.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final s = context.scheme;
    final w = Material(
      color: color ?? s.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: borderColor ?? s.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (semanticLabel == null) return w;
    return Semantics(label: semanticLabel, button: onTap != null, child: ExcludeSemantics(child: w));
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Row(children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text, style: context.text.titleMedium),
            ),
          ),
          ?trailing,
        ]),
      );
}

/// Friendly empty state (emoji + title + body + optional action).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    this.body,
    this.action,
  });

  final String emoji;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.hasBoundedHeight ? box.maxHeight : 0),
            child: Center(child: _content(context)),
          ),
        ),
      );

  Widget _content(BuildContext context) => Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: context.appColors.lavender,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: ExcludeSemantics(child: Text(emoji, style: const TextStyle(fontSize: 42))),
              ),
              const SizedBox(height: 20),
              Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
              if (body != null) ...[
                const SizedBox(height: 8),
                Text(body!,
                    style: context.text.bodyMedium?.copyWith(color: context.scheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
              ],
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        );
}

/// Small rounded label.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.icon, this.color, this.background, this.emoji});
  final String text;
  final IconData? icon;
  final String? emoji;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background ?? context.scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 12)), const SizedBox(width: 4)],
        if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
        Flexible(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(color: fg)),
        ),
      ]),
    );
  }
}

/// Tiny "Pro" marker.
class ProTag extends StatelessWidget {
  const ProTag({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [context.scheme.primary, context.scheme.secondary]),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text('PRO',
            style: context.text.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            )),
      );
}

/// Subtle press animation for tappable hero cards.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, required this.onTap, this.semanticLabel});
  final Widget child;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down && !reduce ? 0.97 : 1,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: ExcludeSemantics(child: widget.child),
        ),
      ),
    );
  }
}

/// Snackbar with optional action (used for "undo").
void showAppSnack(BuildContext context, String text, {String? actionLabel, VoidCallback? onAction, Duration? duration}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(text),
    duration: duration ?? Duration(seconds: onAction != null ? 5 : 3),
    action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
  ));
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l = context.l10n;
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: destructive ? TextButton.styleFrom(foregroundColor: ctx.scheme.error) : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}

/// Shows a modal bottom sheet that grows with the keyboard.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder, bool full = false}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.of(context).size.height * (full ? 0.96 : 0.92)),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: builder(ctx),
    ),
  );
}

/// Runs an async action and shows a friendly error (never a raw exception).
Future<T?> guarded<T>(BuildContext context, Future<T> Function() action, {String? errorText}) async {
  try {
    return await action();
  } catch (e) {
    if (context.mounted) {
      showAppSnack(context, errorText ?? context.l10n.errorGeneric,
          actionLabel: context.l10n.retry, onAction: () => guarded(context, action, errorText: errorText));
    }
    return null;
  }
}
