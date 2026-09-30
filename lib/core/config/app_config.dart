import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;

/// Central, non-secret configuration of the app.
///
/// Anything that may change between releases (limits, thresholds, legal
/// document versions) lives here so it is easy to find and review.
class AppConfig {
  const AppConfig._();

  static const String appName = 'بعداً';
  static const String appNameEn = 'Later';
  static const String tagline = 'الان لازم نیست؛ فقط فراموشش نکن.';

  /// SQLite schema version (see [AppDatabase] migrations).
  static const int dbSchemaVersion = 2;

  /// Backup file schema version (see [BackupMigrator]).
  static const int backupSchemaVersion = 2;
  static const String backupFormatId = 'later-backup';
  static const String backupExtension = 'later';

  /// Backups larger than this are rejected before parsing (DoS protection).
  static const int maxBackupBytes = 64 * 1024 * 1024;

  /// Sanity limits applied to every imported record.
  static const int maxItemsInBackup = 200000;
  static const int maxTextLength = 20000;
  static const int maxTitleLength = 500;
  static const int maxTagLength = 40;
  static const int maxTagsPerItem = 20;

  /// After this many days without a decision an item is offered for review.
  static const int defaultStaleDays = 30;

  /// Legal documents. Bump the version to force users to re-accept.
  static const int termsVersion = 1;
  static const int privacyVersion = 1;

  /// Contact address shown in About / store listing. Leave empty to hide.
  static const String supportEmail = 'manseyed2000@gmail.com';

  /// Maximum number of pending notifications kept scheduled with the OS
  /// (Android limits the number of alarms an app may hold).
  static const int maxScheduledNotifications = 300;

  /// Default local hours (24h) used by snooze shortcuts.
  static const int tonightHour = 20;

  /// True in builds that may show the QA / test tools (Pro simulation,
  /// sample data, time travel). Never true for the store flavor in release.
  static bool get testToolsEnabled {
    if (appFlavor == 'store') return false;
    return kDebugMode || appFlavor == 'qa';
  }

  static const String flavorName = String.fromEnvironment(
    'FLUTTER_APP_FLAVOR',
    defaultValue: '',
  );
}
