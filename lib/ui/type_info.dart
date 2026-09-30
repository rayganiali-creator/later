import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../l10n/app_localizations.dart';

/// Icons, names and stage labels for each shelf, in one place.
class TypeInfo {
  const TypeInfo._();

  static IconData icon(ItemType t) => switch (t) {
        ItemType.task => Icons.check_circle_outline_rounded,
        ItemType.read => Icons.menu_book_rounded,
        ItemType.watch => Icons.play_circle_outline_rounded,
        ItemType.wishlist => Icons.shopping_bag_outlined,
        ItemType.idea => Icons.lightbulb_outline_rounded,
        ItemType.person => Icons.person_outline_rounded,
        ItemType.capsule => Icons.hourglass_top_rounded,
        ItemType.future => Icons.mail_outline_rounded,
      };

  /// Shelf title ("بعداً بخون").
  static String shelfTitle(AppL10n l, ItemType t) => switch (t) {
        ItemType.read => l.shelfReadTitle,
        ItemType.watch => l.shelfWatchTitle,
        ItemType.wishlist => l.shelfWishTitle,
        ItemType.idea => l.shelfIdeaTitle,
        ItemType.person => l.shelfPeopleTitle,
        ItemType.capsule || ItemType.future => l.shelfFutureTitle,
        ItemType.task => l.navList,
      };

  static String stageLabel(AppL10n l, ItemType t, int s) {
    switch (t) {
      case ItemType.read:
        return [l.stageUnread, l.stageReading, l.stageRead, l.stageArchived][s.clamp(0, 3)];
      case ItemType.watch:
        return [l.stageUnwatched, l.stageWatching, l.stageWatched][s.clamp(0, 2)];
      case ItemType.wishlist:
        return [l.stageInterested, l.stageMaybe, l.stageBought, l.stageNotInterested][s.clamp(0, 3)];
      case ItemType.idea:
        return [l.stageIdeaNew, l.stageThinking, l.stageDeveloping, l.stageIdeaArchived, l.stageIdeaDropped][s.clamp(0, 4)];
      case ItemType.capsule:
      case ItemType.future:
        return s == ItemStages.opened ? l.stageOpened : l.stageSealed;
      default:
        return '';
    }
  }

  /// Label of the "I finished it" button for a type.
  static String doneLabel(AppL10n l, ItemType t) => switch (t) {
        ItemType.read => l.markAsRead,
        ItemType.watch => l.markAsWatched,
        ItemType.wishlist => l.markAsBought,
        _ => l.itemDone,
      };

  /// Host of a URL for compact display ("youtube.com").
  static String? host(String? url) {
    if (url == null) return null;
    final h = Uri.tryParse(url)?.host ?? '';
    if (h.isEmpty) return null;
    return h.startsWith('www.') ? h.substring(4) : h;
  }
}
