import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../app_scope.dart';
import '../item_actions.dart';
import '../sheets/snooze_sheet.dart';
import '../widgets/common.dart';
import '../widgets/item_image.dart';

/// "بعداً، نه هیچ‌وقت": walks through long-waiting items one at a time.
class StaleReviewScreen extends StatefulWidget {
  const StaleReviewScreen({super.key});

  @override
  State<StaleReviewScreen> createState() => _StaleReviewScreenState();
}

class _StaleReviewScreenState extends State<StaleReviewScreen> {
  late List<String> _queue;
  int _index = 0;
  int _total = 0;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _queue = context.appRead.staleItems().map((e) => e.id).toList();
    _total = _queue.length;
  }

  void _advance() => setState(() => _index++);

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    final finished = _index >= _queue.length;
    LaterItem? item;
    if (!finished) {
      item = app.itemById(_queue[_index]);
      if (item == null || !item.isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _advance();
        });
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.staleTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: finished || item == null
              ? EmptyState(
                  emoji: '✨',
                  title: l.staleAllDone,
                  body: l.staleAllDoneBody,
                  action: FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.close)),
                )
              : Column(children: [
                  LinearProgressIndicator(
                    value: _total == 0 ? 1 : _index / _total,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(l.staleProgress(fmt.num(_index + 1), fmt.num(_total)),
                        style: context.text.labelMedium?.copyWith(color: s.onSurfaceVariant)),
                  ),
                  const Spacer(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _StaleCard(key: ValueKey(item.id), item: item),
                  ),
                  const SizedBox(height: 14),
                  Text(l.staleNoPressure,
                      style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant),
                      textAlign: TextAlign.center),
                  const Spacer(),
                  _actions(context, item),
                ]),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, LaterItem item) {
    final l = context.l10n;
    final app = context.appRead;
    if (item.type == ItemType.app) {
      Future<void> answer(AppAnswer a) async {
        await guarded(context, () => app.answerAppReview(item.id, a));
        _advance();
      }

      return Column(children: [
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () => answer(AppAnswer.installed), child: Text(l.appAnsInstalled))),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => answer(AppAnswer.still), child: Text(l.appAnsStill))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton(onPressed: () => answer(AppAnswer.later), child: Text(l.appAnsLater, textAlign: TextAlign.center))),
        ]),
        const SizedBox(height: 4),
        TextButton(onPressed: () => answer(AppAnswer.no), child: Text(l.appAnsNo)),
      ]);
    }
    return Column(children: [
      Row(children: [
        Expanded(
          child: FilledButton(
            onPressed: () async {
              await guarded(context, () => app.keep(item.id));
              _advance();
            },
            child: Text(l.staleKeep),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final before = item.snoozeCount;
              await showSnoozeSheet(context, item);
              if (!mounted) return;
              final after = app.itemById(item.id);
              if (after != null && after.snoozeCount != before) _advance();
            },
            child: Text(l.staleSnooze, textAlign: TextAlign.center),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await ItemActions.complete(context, item);
              _advance();
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(l.staleDone),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await ItemActions.drop(context, item);
              _advance();
            },
            icon: const Icon(Icons.spa_outlined, size: 18),
            label: Text(l.staleDrop),
          ),
        ),
      ]),
    ]);
  }
}

class _StaleCard extends StatelessWidget {
  const _StaleCard({super.key, required this.item});
  final LaterItem item;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final app = context.appRead;
    final fmt = context.fmt;
    final waited = app.now().difference(item.lastKeptAt ?? item.createdAt).inDays;
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        CoverThumb(
          item: item,
          size: 84,
          radius: 22,
          emoji: item.type == ItemType.task ? app.categoryEmoji(item.categoryId) : null,
        ),
        const SizedBox(height: 12),
        Text('«${item.title}»', textAlign: TextAlign.center, style: context.text.headlineSmall),
        const SizedBox(height: 14),
        Text(item.type == ItemType.app ? l.appReviewQuestion(fmt.num(waited)) : l.staleQuestion(fmt.num(waited)),
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(color: context.scheme.onSurfaceVariant)),
      ]),
    );
  }
}

