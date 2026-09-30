import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../../domain/search_filter_sort.dart';
import '../../domain/smart_pick.dart';
import '../app_scope.dart';
import '../nav_bus.dart';
import '../sheets/add_edit_sheet.dart';
import '../sheets/smart_pick_sheet.dart';
import '../type_info.dart';
import '../widgets/common.dart';
import 'future_screen.dart';
import 'idea_review_screen.dart';
import 'inbox_screen.dart';
import 'people_screens.dart';
import 'reveal_screen.dart';
import 'roulette_screen.dart';
import 'search_screen.dart';
import 'shelf_screen.dart';
import 'stale_review_screen.dart';
import 'wishlist_review_screen.dart';

/// The dashboard. It never lists items: it only shows where things are and
/// what deserves attention. The full list lives in the next tab.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final l = context.l10n;
    final fmt = context.fmt;
    final s = context.scheme;
    final d = app.dashboardCounts();
    final nav = NavScope.read(context);
    final counts = app.homeCounts();
    final returned = [
      for (final i in app.activeItems)
        if (i.type == ItemType.capsule || i.type == ItemType.future) i
    ];
    final wishReview = app.wishlistToReview().length;
    final ideaReview = app.ideasToReview().length;
    final empty = app.allItems.isEmpty && app.people.isEmpty;

    if (empty) {
      return SafeArea(
        child: Column(children: [
          const _Header(),
          Expanded(
            child: EmptyState(
              emoji: '🌱',
              title: l.homeEmptyTitle,
              body: l.homeEmptyBody,
              action: FilledButton.icon(
                onPressed: () => addFlow(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(l.homeEmptyCta),
              ),
            ),
          ),
        ]),
      );
    }

    void go(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

    Widget shelf(ItemType t, int n, Widget target) => _ShelfTile(
          icon: TypeInfo.icon(t),
          label: TypeInfo.shelfTitle(l, t),
          count: n,
          onTap: () => go(target),
        );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        children: [
          const _Header(),
          // Things that came back from the past come first.
          for (final r in returned.take(2))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                color: s.primaryContainer.withValues(alpha: 0.55),
                borderColor: s.primary.withValues(alpha: 0.3),
                onTap: () => go(RevealScreen(itemId: r.id)),
                semanticLabel: l.returnedBanner,
                child: Row(children: [
                  Icon(TypeInfo.icon(r.type), color: s.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.type == ItemType.future ? l.messageReturnedTitle : l.returnedBanner,
                          style: context.text.titleSmall),
                      Text(l.returnedBannerBody,
                          style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                    ]),
                  ),
                  Icon(Icons.chevron_left_rounded, color: s.onSurfaceVariant),
                ]),
              ),
            ),
          PressableScale(
            semanticLabel: l.dashRoulette,
            onTap: () => go(const RouletteScreen()),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [s.primary, Color.lerp(s.primary, s.secondary, 0.7)!],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: s.primary.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Row(children: [
                Icon(Icons.casino_rounded, color: s.onPrimary, size: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.dashRoulette, style: context.text.titleLarge?.copyWith(color: s.onPrimary)),
                    const SizedBox(height: 4),
                    Text(l.pickCardSub,
                        style: context.text.bodyMedium?.copyWith(color: s.onPrimary.withValues(alpha: 0.85))),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final m in smartPickMinuteOptions)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.timer_outlined, size: 16),
                      label: Text(m == null ? l.anyTime : fmt.minutes(m)),
                      onPressed: () => showSmartPickSheet(context, initialMinutes: m, preselect: true),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _NumberCard(
                label: l.statToday,
                value: fmt.num(d.today),
                highlight: d.today > 0,
                onTap: () => nav.showListWithFilter(const ItemFilter(FilterKind.today)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberCard(
                label: l.statOverdue,
                value: fmt.num(counts.overdue),
                danger: counts.overdue > 0,
                onTap: () => nav.showListWithFilter(const ItemFilter(FilterKind.overdue)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberCard(
                label: l.navList,
                value: fmt.num(counts.total),
                onTap: () => nav.goTo(1),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => go(const InboxScreen()),
            semanticLabel: '${l.dashInbox}: ${d.inbox == 0 ? l.dashInboxEmpty : l.dashInboxCount(fmt.num(d.inbox))}',
            child: Row(children: [
              Badge(
                isLabelVisible: d.inbox > 0,
                label: Text(fmt.num(d.inbox)),
                child: Icon(Icons.move_to_inbox_rounded, color: s.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.dashInbox, style: context.text.titleSmall),
                  Text(d.inbox == 0 ? l.dashInboxEmpty : l.dashInboxCount(fmt.num(d.inbox)),
                      style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
                ]),
              ),
              Icon(Icons.chevron_left_rounded, color: s.onSurfaceVariant),
            ]),
          ),
          if (counts.stale > 0) ...[
            const SizedBox(height: 10),
            _Banner(
              icon: Icons.hourglass_bottom_rounded,
              title: l.staleBannerTitle(fmt.num(counts.stale)),
              body: l.staleBannerBody,
              onTap: () => go(const StaleReviewScreen()),
            ),
          ],
          if (wishReview > 0) ...[
            const SizedBox(height: 10),
            _Banner(
              icon: Icons.shopping_bag_outlined,
              title: l.wishReviewTitle,
              body: l.shelfWishTitle,
              onTap: () => go(const WishlistReviewScreen()),
            ),
          ],
          if (ideaReview > 0 && app.isPro) ...[
            const SizedBox(height: 10),
            _Banner(
              icon: Icons.lightbulb_outline_rounded,
              title: l.ideaReviewBanner(fmt.num(ideaReview)),
              body: l.ideaReviewIntro,
              onTap: () => go(const IdeaReviewScreen()),
            ),
          ],
          SectionTitle(l.dashShelves),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              shelf(ItemType.read, d.read, const ShelfScreen(type: ItemType.read)),
              shelf(ItemType.watch, d.watch, const ShelfScreen(type: ItemType.watch)),
              shelf(ItemType.wishlist, d.wishlist, const ShelfScreen(type: ItemType.wishlist)),
              shelf(ItemType.idea, d.ideas, const ShelfScreen(type: ItemType.idea)),
              shelf(ItemType.person, d.people, const PeopleScreen()),
              shelf(ItemType.capsule, d.future, const FutureScreen()),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.scheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [s.primary, s.secondary]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.history_toggle_off_rounded, color: s.onPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.appName, style: context.text.titleLarge),
            Text(l.tagline,
                style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        IconButton(
          tooltip: l.searchEverywhere,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
          icon: const Icon(Icons.search_rounded),
        ),
      ]),
    );
  }
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({
    required this.label,
    required this.value,
    required this.onTap,
    this.highlight = false,
    this.danger = false,
  });
  final String label, value;
  final VoidCallback onTap;
  final bool highlight, danger;

  @override
  Widget build(BuildContext context) {
    final s = context.scheme;
    final color = danger ? context.appColors.danger : (highlight ? s.primary : s.onSurface);
    return Semantics(
      button: true,
      label: '$label $value',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: s.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: s.outlineVariant),
          ),
          child: ExcludeSemantics(
            child: Column(children: [
              Text(value, style: context.text.headlineSmall?.copyWith(color: color)),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium?.copyWith(color: s.onSurfaceVariant)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ShelfTile extends StatelessWidget {
  const _ShelfTile({required this.icon, required this.label, required this.count, required this.onTap});
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.scheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: onTap,
      semanticLabel: '$label ${context.fmt.num(count)}',
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: context.appColors.lavender, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: s.primary, size: 22),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
            Text(context.fmt.num(count),
                style: context.text.bodySmall?.copyWith(color: s.onSurfaceVariant)),
          ]),
        ),
      ]),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.title, required this.body, required this.onTap});
  final IconData icon;
  final String title, body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AppCard(
      color: c.warning.withValues(alpha: 0.10),
      borderColor: c.warning.withValues(alpha: 0.35),
      onTap: onTap,
      semanticLabel: title,
      child: Row(children: [
        Icon(icon, color: c.warning),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: context.text.titleSmall),
            Text(body, style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant)),
          ]),
        ),
        Icon(Icons.chevron_left_rounded, color: context.scheme.onSurfaceVariant),
      ]),
    );
  }
}
