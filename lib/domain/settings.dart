import 'package:flutter/material.dart' show ThemeMode;

import '../core/config/app_config.dart';
import '../core/util/dates.dart';

/// Accent palettes. The first is free, the others require Pro.
enum AccentPalette { indigo, teal, rose, amber, slate }

/// Alternative launcher icons (Pro).
enum IconVariant { classic, teal, rose, dark }

/// User settings, persisted as key/value strings (and included in backups).
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.accent = AccentPalette.indigo,
    this.languageCode = 'fa',
    this.calendar = CalendarSystem.jalali,
    this.weekStart = DateTime.saturday,
    this.weekendDay = DateTime.friday,
    this.defaultReminderMinutes = 9 * 60,
    this.remindersEnabled = true,
    this.privateNotifications = false,
    this.keepHistory = true,
    this.staleDays = AppConfig.defaultStaleDays,
    this.onboardingDone = false,
    this.termsAcceptedVersion = 0,
    this.privacyAcceptedVersion = 0,
    this.termsAcceptedAt,
    this.autoBackup = false,
    this.iconVariant = IconVariant.classic,
    this.lastAutoBackupAt,
    this.lastBackupAt,
    this.rouletteCategories = const {},
    this.wishlistReviewDays = 30,
    this.ideaReviewDays = 30,
    this.ideaReviewReminder = false,
    this.appReviewReminder = false,
    this.askWhereOnShare = true,
  });

  /// Categories that take part in the roulette (empty = all). Pro to change.
  final Set<String> rouletteCategories;

  /// A wishlist item older than this is asked about ("still want it?").
  final int wishlistReviewDays;

  /// Ideas not reviewed for this long show up in the idea review (Pro).
  final int ideaReviewDays;

  /// Monthly "time to review your ideas" notification (Pro).
  final bool ideaReviewReminder;

  /// Pro: a monthly nudge to review apps that are still waiting.
  final bool appReviewReminder;

  /// Ask where a shared item should go (otherwise it just lands in the inbox).
  final bool askWhereOnShare;

  final ThemeMode themeMode;
  final AccentPalette accent;
  final String languageCode;
  final CalendarSystem calendar;

  /// [DateTime.monday]..[DateTime.sunday].
  final int weekStart;
  final int weekendDay;

  /// Default reminder time as minutes since midnight.
  final int defaultReminderMinutes;
  final bool remindersEnabled;

  /// Hide item titles in notifications (lock screen privacy).
  final bool privateNotifications;
  final bool keepHistory;
  final int staleDays;
  final bool onboardingDone;
  final int termsAcceptedVersion;
  final int privacyAcceptedVersion;
  final DateTime? termsAcceptedAt;
  final bool autoBackup;
  final IconVariant iconVariant;
  final DateTime? lastAutoBackupAt;
  final DateTime? lastBackupAt;

  bool get legalAccepted =>
      termsAcceptedVersion >= AppConfig.termsVersion &&
      privacyAcceptedVersion >= AppConfig.privacyVersion;

  AppSettings copyWith({
    ThemeMode? themeMode,
    AccentPalette? accent,
    String? languageCode,
    CalendarSystem? calendar,
    int? weekStart,
    int? weekendDay,
    int? defaultReminderMinutes,
    bool? remindersEnabled,
    bool? privateNotifications,
    bool? keepHistory,
    int? staleDays,
    bool? onboardingDone,
    int? termsAcceptedVersion,
    int? privacyAcceptedVersion,
    DateTime? termsAcceptedAt,
    bool? autoBackup,
    IconVariant? iconVariant,
    DateTime? lastAutoBackupAt,
    DateTime? lastBackupAt,
    Set<String>? rouletteCategories,
    int? wishlistReviewDays,
    int? ideaReviewDays,
    bool? ideaReviewReminder,
    bool? appReviewReminder,
    bool? askWhereOnShare,
  }) =>
      AppSettings(
        rouletteCategories: rouletteCategories ?? this.rouletteCategories,
        wishlistReviewDays: wishlistReviewDays ?? this.wishlistReviewDays,
        ideaReviewDays: ideaReviewDays ?? this.ideaReviewDays,
        ideaReviewReminder: ideaReviewReminder ?? this.ideaReviewReminder,
        appReviewReminder: appReviewReminder ?? this.appReviewReminder,
        askWhereOnShare: askWhereOnShare ?? this.askWhereOnShare,
        themeMode: themeMode ?? this.themeMode,
        accent: accent ?? this.accent,
        languageCode: languageCode ?? this.languageCode,
        calendar: calendar ?? this.calendar,
        weekStart: weekStart ?? this.weekStart,
        weekendDay: weekendDay ?? this.weekendDay,
        defaultReminderMinutes:
            defaultReminderMinutes ?? this.defaultReminderMinutes,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        privateNotifications:
            privateNotifications ?? this.privateNotifications,
        keepHistory: keepHistory ?? this.keepHistory,
        staleDays: staleDays ?? this.staleDays,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        termsAcceptedVersion:
            termsAcceptedVersion ?? this.termsAcceptedVersion,
        privacyAcceptedVersion:
            privacyAcceptedVersion ?? this.privacyAcceptedVersion,
        termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
        autoBackup: autoBackup ?? this.autoBackup,
        iconVariant: iconVariant ?? this.iconVariant,
        lastAutoBackupAt: lastAutoBackupAt ?? this.lastAutoBackupAt,
        lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      );

  /// Flat string map used for both the settings table and backups.
  Map<String, String> toMap() => {
        'themeMode': themeMode.name,
        'accent': accent.name,
        'language': languageCode,
        'calendar': calendar.name,
        'weekStart': '$weekStart',
        'weekendDay': '$weekendDay',
        'defaultReminderMinutes': '$defaultReminderMinutes',
        'remindersEnabled': '$remindersEnabled',
        'privateNotifications': '$privateNotifications',
        'keepHistory': '$keepHistory',
        'staleDays': '$staleDays',
        'onboardingDone': '$onboardingDone',
        'termsAcceptedVersion': '$termsAcceptedVersion',
        'privacyAcceptedVersion': '$privacyAcceptedVersion',
        if (termsAcceptedAt != null)
          'termsAcceptedAt': '${termsAcceptedAt!.millisecondsSinceEpoch}',
        'autoBackup': '$autoBackup',
        'iconVariant': iconVariant.name,
        if (lastAutoBackupAt != null)
          'lastAutoBackupAt': '${lastAutoBackupAt!.millisecondsSinceEpoch}',
        if (lastBackupAt != null)
          'lastBackupAt': '${lastBackupAt!.millisecondsSinceEpoch}',
        'rouletteCategories': (rouletteCategories.toList()..sort()).join(','),
        'wishlistReviewDays': '$wishlistReviewDays',
        'ideaReviewDays': '$ideaReviewDays',
        'ideaReviewReminder': '$ideaReviewReminder',
        'appReviewReminder': '$appReviewReminder',
        'askWhereOnShare': '$askWhereOnShare',
      };

  /// Lenient parser: unknown/invalid values fall back to defaults.
  factory AppSettings.fromMap(Map<String, String> m) {
    T enumOf<T extends Enum>(List<T> values, String? name, T fallback) {
      for (final v in values) {
        if (v.name == name) return v;
      }
      return fallback;
    }

    int intOf(String? s, int fallback, {int? min, int? max}) {
      final v = int.tryParse(s ?? '');
      if (v == null) return fallback;
      if (min != null && v < min) return fallback;
      if (max != null && v > max) return fallback;
      return v;
    }

    bool boolOf(String? s, bool fallback) =>
        s == 'true' ? true : (s == 'false' ? false : fallback);

    DateTime? dateOf(String? s) {
      final v = int.tryParse(s ?? '');
      return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
    }

    const d = AppSettings();
    return AppSettings(
      themeMode: enumOf(ThemeMode.values, m['themeMode'], d.themeMode),
      accent: enumOf(AccentPalette.values, m['accent'], d.accent),
      languageCode: (m['language'] == 'en' || m['language'] == 'fa')
          ? m['language']!
          : d.languageCode,
      calendar: enumOf(CalendarSystem.values, m['calendar'], d.calendar),
      weekStart: intOf(m['weekStart'], d.weekStart, min: 1, max: 7),
      weekendDay: intOf(m['weekendDay'], d.weekendDay, min: 1, max: 7),
      defaultReminderMinutes: intOf(
          m['defaultReminderMinutes'], d.defaultReminderMinutes,
          min: 0, max: 1439),
      remindersEnabled: boolOf(m['remindersEnabled'], d.remindersEnabled),
      privateNotifications:
          boolOf(m['privateNotifications'], d.privateNotifications),
      keepHistory: boolOf(m['keepHistory'], d.keepHistory),
      staleDays: intOf(m['staleDays'], d.staleDays, min: 3, max: 3650),
      onboardingDone: boolOf(m['onboardingDone'], d.onboardingDone),
      termsAcceptedVersion:
          intOf(m['termsAcceptedVersion'], 0, min: 0, max: 1000),
      privacyAcceptedVersion:
          intOf(m['privacyAcceptedVersion'], 0, min: 0, max: 1000),
      termsAcceptedAt: dateOf(m['termsAcceptedAt']),
      autoBackup: boolOf(m['autoBackup'], d.autoBackup),
      iconVariant: enumOf(IconVariant.values, m['iconVariant'], d.iconVariant),
      lastAutoBackupAt: dateOf(m['lastAutoBackupAt']),
      lastBackupAt: dateOf(m['lastBackupAt']),
      rouletteCategories: (m['rouletteCategories'] ?? '')
          .split(',')
          .where((e) => RegExp(r'^[A-Za-z0-9_\-]{1,64}$').hasMatch(e))
          .take(200)
          .toSet(),
      wishlistReviewDays: intOf(m['wishlistReviewDays'], d.wishlistReviewDays, min: 3, max: 3650),
      ideaReviewDays: intOf(m['ideaReviewDays'], d.ideaReviewDays, min: 3, max: 3650),
      ideaReviewReminder: boolOf(m['ideaReviewReminder'], d.ideaReviewReminder),
      appReviewReminder: boolOf(m['appReviewReminder'], d.appReviewReminder),
      askWhereOnShare: boolOf(m['askWhereOnShare'], d.askWhereOnShare),
    );
  }
}
