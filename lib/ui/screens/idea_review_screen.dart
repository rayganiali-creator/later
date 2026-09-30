import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../app_scope.dart';
import '../widgets/common.dart';

/// Monthly look at the idea vault: keep thinking, develop, archive or let go.
class IdeaReviewScreen extends StatefulWidget {
  const IdeaReviewScreen({super.key});

  @override
  State<IdeaReviewScreen> createState() => _IdeaReviewScreenState();
}

class _IdeaReviewScreenState extends State<IdeaReviewScreen> {
  late List<String> _queue;
  int _index = 0;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _queue = [for (final i in context.appRead.ideasToReview()) i.id];
  }

  Future<void> _do(LaterItem i, int stage) async {
    await context.appRead.reviewIdea(i.id, stage: stage);
    if (mounted) setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final finished = _index >= _queue.length;
    final item = finished ? null : app.itemById(_queue[_index]);
    if (!finished && (item == null || !item.isActive)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index++);
      });
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.ideaReviewTitle)),
      body: SafeArea(
        child: finished || item == null
            ? EmptyState(emoji: '💡', title: l.ideaReviewNone)
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(children: [
                  Text(l.staleProgress(fmt.num(_index + 1), fmt.num(_queue.length)),
                      style: context.text.labelMedium?.copyWith(color: context.scheme.onSurfaceVariant)),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: context.scheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: context.scheme.outlineVariant),
                    ),
                    child: Column(children: [
                      Text(item.title, style: context.text.headlineSmall, textAlign: TextAlign.center),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(item.description,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: context.text.bodyMedium?.copyWith(color: context.scheme.onSurfaceVariant)),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        item.lastReviewedAt == null
                            ? l.ideaNeverReviewed
                            : l.ideaLastReviewed(fmt.ago(item.lastReviewedAt!)),
                        style: context.text.labelMedium?.copyWith(color: context.scheme.onSurfaceVariant),
                      ),
                    ]),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: () => _do(item, ItemStages.developing), child: Text(l.ideaDevelop)),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                        onPressed: () => _do(item, ItemStages.thinking), child: Text(l.ideaKeepThinking)),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () => _do(item, ItemStages.ideaArchived), child: Text(l.ideaArchiveIt))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: OutlinedButton(
                            onPressed: () => _do(item, ItemStages.ideaDropped), child: Text(l.ideaDropIt))),
                  ]),
                ]),
              ),
      ),
    );
  }
}
