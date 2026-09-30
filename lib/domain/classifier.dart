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
  static final _ideaWords = RegExp(
      r'(ایده|فکر کنم بشه|میشه .* ساخت|می‌شه .* ساخت|یه اپ|یک اپ|استارتاپ|کسب.?و.?کار|پروژه‌ی جدید|idea|what if|startup)',
      caseSensitive: false);
  static final _personWords = RegExp(
      r'(زنگ بزن|تماس بگیر|پیام بده|پیام بدم|زنگ بزنم|تماس بگیرم|تولد|احوال.?پرسی|به .+ (پیام|زنگ)|call |text |message )',
      caseSensitive: false);

  static Classification classify(String title, {String? url, String description = ''}) {
    final u = sanitizeUrl(url) ?? extractFirstUrl('$title $description');
    if (u != null) {
      final host = (Uri.tryParse(u)?.host ?? '').toLowerCase();
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
