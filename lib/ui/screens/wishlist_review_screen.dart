import 'package:flutter/material.dart';

import '../../data/controller.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../app_scope.dart';
import '../widgets/common.dart';

/// "Do you still want it?" — one wishlist item at a time, three honest answers.
class WishlistReviewScreen extends StatefulWidget {
  const WishlistReviewScreen({super.key});

  @override
  State<WishlistReviewScreen> createState() => _WishlistReviewScreenState();
}

class _WishlistReviewScreenState extends State<WishlistReviewScreen> {
  late List<String> _queue;
  int _index = 0;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    _queue = [for (final i in context.appRead.wishlistToReview()) i.id];
  }

  Future<void> _answer(LaterItem item, WishAnswer a) async {
    await context.appRead.answerWishlist(item.id, a);
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
      appBar: AppBar(title: Text(l.wishReviewTitle)),
      body: SafeArea(
        child: finished || item == null
            ? EmptyState(emoji: '✨', title: l.staleAllDone, body: l.staleAllDoneBody)
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
                      if (item.price != null) ...[
                        const SizedBox(height: 8),
                        Text('${fmt.money(item.price!)} ${item.currency.isEmpty ? l.currencyDefault : item.currency}',
                            style: context.text.titleMedium?.copyWith(color: context.scheme.primary)),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        l.wishReviewQuestion(fmt.num(app.now().difference(item.lastReviewedAt ?? item.createdAt).inDays.clamp(1, 100000))),
                        textAlign: TextAlign.center,
                        style: context.text.bodyLarge,
                      ),
                    ]),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(onPressed: () => _answer(item, WishAnswer.still), child: Text(l.wishStill)),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => _answer(item, WishAnswer.unsure), child: Text(l.wishUnsure))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton(onPressed: () => _answer(item, WishAnswer.no), child: Text(l.wishNo))),
                  ]),
                ]),
              ),
      ),
    );
  }
}
