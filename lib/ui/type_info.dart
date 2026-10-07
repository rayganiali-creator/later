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
        ItemType.app => Icons.apps_rounded,
        ItemType.podcast => Icons.headphones_rounded,
        ItemType.course => Icons.school_outlined,
        ItemType.game => Icons.sports_esports_outlined,
      };

  /// Each shelf has its own accent so it is recognisable at a glance.
  static Color color(ItemType t) => switch (t) {
        ItemType.task => const Color(0xFF5B4FD6),
        ItemType.read => const Color(0xFF2F7BC9),
        ItemType.watch => const Color(0xFFD64F6E),
        ItemType.wishlist => const Color(0xFFD08A1E),
        ItemType.idea => const Color(0xFFC9A400),
        ItemType.person => const Color(0xFF2E9E8F),
        ItemType.capsule || ItemType.future => const Color(0xFF7E57C2),
        ItemType.app => const Color(0xFF3D8B5A),
        ItemType.podcast => const Color(0xFFE0663C),
        ItemType.course => const Color(0xFF3F6FD0),
        ItemType.game => const Color(0xFF9B4FCF),
      };

  /// Longer line shown under a shelf's title.
  static String shelfSub(AppL10n l, ItemType t) => switch (t) {
        ItemType.app => l.shelfAppSub,
        ItemType.podcast => l.shelfPodcastSub,
        ItemType.course => l.shelfCourseSub,
        ItemType.game => l.shelfGameSub,
        _ => '',
      };

  /// Shelves that have a cover picture (apps, podcasts, courses, games).
  static bool hasCover(ItemType t) =>
      t == ItemType.app || t == ItemType.podcast || t == ItemType.course || t == ItemType.game ||
      t == ItemType.wishlist || t == ItemType.watch || t == ItemType.read;

  /// Shelf title ("بعداً بخون").
  static String shelfTitle(AppL10n l, ItemType t) => switch (t) {
        ItemType.read => l.shelfReadTitle,
        ItemType.watch => l.shelfWatchTitle,
        ItemType.wishlist => l.shelfWishTitle,
        ItemType.idea => l.shelfIdeaTitle,
        ItemType.person => l.shelfPeopleTitle,
        ItemType.capsule || ItemType.future => l.shelfFutureTitle,
        ItemType.app => l.shelfAppTitle,
        ItemType.podcast => l.shelfPodcastTitle,
        ItemType.course => l.shelfCourseTitle,
        ItemType.game => l.shelfGameTitle,
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
      case ItemType.app:
        return [l.stageNotInstalled, l.stageWantInstall, l.stageEvaluating, l.stageInstalled, l.stageAppNotWanted][s.clamp(0, 4)];
      case ItemType.podcast:
        return [l.stageNotListened, l.stageListening, l.stagePaused, l.stageListened][s.clamp(0, 3)];
      case ItemType.course:
        return [l.stageLearnLater, l.stageLearning, l.stagePaused, l.stageLearned, l.stageLearnAbandoned][s.clamp(0, 4)];
      case ItemType.game:
        return [l.stageWantPlay, l.stagePlaying, l.stagePaused, l.stageGameFinished, l.stageGameDropped][s.clamp(0, 4)];
      default:
        return '';
    }
  }

  /// Label of the "I finished it" button for a type.
  static String doneLabel(AppL10n l, ItemType t) => switch (t) {
        ItemType.read => l.markAsRead,
        ItemType.watch => l.markAsWatched,
        ItemType.wishlist => l.markAsBought,
        ItemType.app => l.markAsInstalled,
        ItemType.podcast => l.markAsListened,
        ItemType.course || ItemType.game => l.markAsLearned,
        _ => l.itemDone,
      };

  /// Host of a URL for compact display ("youtube.com").
  /// "42:10" / "1:05:30" from seconds.
  static String clock(int sec) {
    final h = sec ~/ 3600, m = (sec % 3600) ~/ 60, s = sec % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  /// Parses "18:32", "1:05:30" or a bare number of minutes into seconds.
  static int? parseClock(String raw) {
    final t = raw.trim().replaceAll('٫', ':').replaceAll('：', ':');
    final norm = StringBuffer();
    for (final c in t.runes) {
      if (c >= 0x6F0 && c <= 0x6F9) {
        norm.writeCharCode(c - 0x6F0 + 48);
      } else if (c >= 0x660 && c <= 0x669) {
        norm.writeCharCode(c - 0x660 + 48);
      } else {
        norm.writeCharCode(c);
      }
    }
    final s = norm.toString();
    if (s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length > 3 || parts.any((p) => int.tryParse(p) == null)) return null;
    final n = parts.map(int.parse).toList();
    if (n.any((v) => v < 0)) return null;
    if (n.length == 1) return n[0] * 60; // minutes
    if (n.length == 2) return n[0] * 60 + n[1];
    return n[0] * 3600 + n[1] * 60 + n[2];
  }

  static String? host(String? url) {
    if (url == null) return null;
    final h = Uri.tryParse(url)?.host ?? '';
    if (h.isEmpty) return null;
    return h.startsWith('www.') ? h.substring(4) : h;
  }
}
