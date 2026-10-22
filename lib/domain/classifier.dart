import '../core/util/text.dart';
import 'models.dart';

/// A suggestion, never an action: the user always confirms.
class Classification {
  const Classification(this.type, this.reason);
  final ItemType type;

  /// Machine readable reason (`video_host`, `shop_host`, `url`, `idea_words`,
  /// `person_words`, `default`); the UI maps it to text.
  final String reason;
  bool get isDefault => reason == 'default';
}

/// Offline, rule based classification of a freshly captured item.
class ItemClassifier {
  const ItemClassifier._();

  static const _videoHosts = [
    'youtube.com', 'youtu.be', 'm.youtube.com', 'vimeo.com', 'aparat.com', 'namava.ir',
    'filimo.com', 'imvbox.com', 'dailymotion.com', 'twitch.tv', 'netflix.com', 'imdb.com',
  ];
  static const _shopHosts = [
    'digikala.com', 'torob.com', 'amazon.', 'aliexpress.com', 'ebay.com', 'basalam.com',
    'divar.ir', 'emalls.ir', 'technolife.ir', 'banimode.com', 'mobile.ir', 'shopify.com',
  ];
  static const _appHosts = [
    'play.google.com', 'cafebazaar.ir', 'myket.ir', 'apps.apple.com', 'f-droid.org',
    'apps.microsoft.com', 'microsoft.com/store', 'snapcraft.io', 'flathub.org', 'apkpure.com',
  ];
  static const _podcastHosts = [
    'podcasts.apple.com', 'castbox.fm', 'anchor.fm', 'podbean.com', 'pocketcasts.com',
    'overcast.fm', 'castro.fm', 'podcastaddict.com', 'fountain.fm', 'zeno.fm', 'radio.fm',
  ];
  static const _courseHosts = [
    'udemy.com', 'coursera.org', 'edx.org', 'udacity.com', 'skillshare.com', 'pluralsight.com',
    'khanacademy.org', 'maktabkhooneh.org', 'faradars.org', 'roocket.ir', 'linkedin.com/learning',
    'freecodecamp.org', 'datacamp.com', 'codecademy.com', 'sabzlearn.ir',
  ];
  static const _gameHosts = [
    'store.steampowered.com', 'steamcommunity.com', 'epicgames.com', 'gog.com', 'itch.io',
    'playstation.com', 'xbox.com', 'nintendo.com', 'gamejolt.com', 'humblebundle.com',
  ];
  static final _ideaWords = RegExp(
      r'(ایده|فکر کنم بشه|میشه .* ساخت|می‌شه .* ساخت|یه اپ|یک اپ|استارتاپ|کسب.?و.?کار|پروژه‌ی جدید|idea|what if|startup)',
      caseSensitive: false);
  static final _personWords = RegExp(
      r'(زنگ بزن|تماس بگیر|پیام بده|پیام بدم|زنگ بزنم|تماس بگیرم|تولد|احوال.?پرسی|به .+ (پیام|زنگ)|call |text |message )',
      caseSensitive: false);

  static Classification classify(String title, {String? url, String description = ''}) {
    final u = sanitizeUrl(url) ?? extractFirstUrl('$title $description');
    if (u != null) {
      final parsed = Uri.tryParse(u);
      final host = (parsed?.host ?? '').toLowerCase();
      final hostPath = '$host${parsed?.path ?? ''}'.toLowerCase();
      bool inList(List<String> l) => l.any((h) => host == h || host.endsWith('.$h') || hostPath.contains(h));
      if (host.contains('spotify.com') && (hostPath.contains('/episode') || hostPath.contains('/show'))) {
        return const Classification(ItemType.podcast, 'podcast_host');
      }
      if (inList(_podcastHosts)) return const Classification(ItemType.podcast, 'podcast_host');
      if (inList(_courseHosts)) return const Classification(ItemType.course, 'course_host');
      if (inList(_gameHosts)) return const Classification(ItemType.game, 'game_host');
      if (inList(_appHosts)) return const Classification(ItemType.app, 'app_host');
      if (_videoHosts.any((h) => host == h || host.endsWith('.$h') || host.contains(h))) {
        return const Classification(ItemType.watch, 'video_host');
      }
      if (_shopHosts.any((h) => host.contains(h))) {
        return const Classification(ItemType.wishlist, 'shop_host');
      }
      return const Classification(ItemType.read, 'url');
    }
    final text = normalizeForSearch('$title $description');
    if (_personWords.hasMatch(text) || _personWords.hasMatch('$title $description')) {
      return const Classification(ItemType.person, 'person_words');
    }
    if (_ideaWords.hasMatch('$title $description')) {
      return const Classification(ItemType.idea, 'idea_words');
    }
    return const Classification(ItemType.task, 'default');
  }
}
