// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Later';

  @override
  String get tagline => 'Not now — just don\'t forget it.';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Try again';

  @override
  String get done => 'Done';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get continueLabel => 'Continue';

  @override
  String get undo => 'Undo';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get all => 'All';

  @override
  String get none => 'None';

  @override
  String get proBadge => 'Pro';

  @override
  String get loading => 'Loading…';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorLoad => 'Couldn\'t load your data.';

  @override
  String get navHome => 'Home';

  @override
  String get navList => 'Later';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get semAdd => 'Add a new item';

  @override
  String get onb1Title => 'You don\'t need it now.';

  @override
  String get onb1Body => 'Free your mind from a thousand half-finished things.';

  @override
  String get onb2Title =>
      'Keep anything you don\'t want to forget, right here.';

  @override
  String get onb2Body =>
      'An article, a movie, a purchase, an idea, a link, a call… just type it or Share it from any app.';

  @override
  String get onb3Title => 'Later reminds you by itself.';

  @override
  String get onb3Body =>
      'Give it a date and time — or don\'t, and ask \"give me one\" whenever you have a moment.';

  @override
  String get onb4Title => 'No account, no server.';

  @override
  String get onb4Body =>
      'Your data stays on your own device and works even without internet.';

  @override
  String get onb5Title => 'Ready?';

  @override
  String get onb5Body => 'Put anything that isn\'t for now right here.';

  @override
  String get onbStart => 'Let\'s go';

  @override
  String get legalTitle => 'Before you start';

  @override
  String get legalIntro =>
      'Please read and accept the Terms of Use and the Privacy Policy.';

  @override
  String get termsTitle => 'Terms of Use';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get legalAccept =>
      'I have read and accept the Terms of Use and Privacy Policy.';

  @override
  String get legalContinue => 'Accept and continue';

  @override
  String get legalLoadError => 'Couldn\'t load the text.';

  @override
  String get legalUpdatedTitle => 'Updated terms';

  @override
  String homeWaiting(String count) {
    return '$count items are waiting for you';
  }

  @override
  String get homeWaitingOne => 'One item is waiting for you';

  @override
  String get homeEmptyTitle => 'Nothing for later yet.';

  @override
  String get homeEmptyBody => 'Nice. Your mind is free for now. 🌱';

  @override
  String get homeEmptyCta => 'Add your first item';

  @override
  String get statToday => 'Today';

  @override
  String get statWeek => 'This week';

  @override
  String get statNoDate => 'No date';

  @override
  String get statOverdue => 'Overdue';

  @override
  String get statStale => 'Waiting long';

  @override
  String get pickCardTitle => '🎯 Give me one';

  @override
  String get pickCardSub => 'Don\'t know what to do now? I\'ll choose.';

  @override
  String get timeCardTitle => 'How much time do you have?';

  @override
  String minutesN(String n) {
    return '$n min';
  }

  @override
  String get hourOne => '1 hour';

  @override
  String get anyTime => 'Doesn\'t matter';

  @override
  String get homeTodaySection => 'Today & overdue';

  @override
  String get homeSeeAll => 'See all';

  @override
  String staleBannerTitle(String count) {
    return '$count items have been waiting a long time';
  }

  @override
  String get staleBannerBody => 'Take a quick look: keep or let go.';

  @override
  String get decideTitle => 'Don\'t decide';

  @override
  String get decideIntro => 'I don\'t know what to do right now.';

  @override
  String get decideLabel => '🎯 Your next suggestion:';

  @override
  String decideAbout(String n) {
    return 'About $n min';
  }

  @override
  String get decideDo => 'I\'ll do it';

  @override
  String get decideLater => 'Later';

  @override
  String get decideAnother => 'Give me another';

  @override
  String get decideNone => 'Nothing to suggest';

  @override
  String get decideNoneBody => 'Your list is empty or nothing fits. 🌱';

  @override
  String get decideNoMore => 'No more items to suggest.';

  @override
  String get decideDoneToast => 'Nice! Done ✓';

  @override
  String get smartPickTitle => 'Smart pick';

  @override
  String get smartPickHeader => 'How much time do you have now?';

  @override
  String smartPickResultsFor(String time) {
    return 'Fits $time';
  }

  @override
  String get smartPickResultsAny => 'Suggestions';

  @override
  String get smartPickEmpty => 'I couldn\'t find anything for that long.';

  @override
  String get smartPickProHint =>
      'Advanced picks (priority & category filter) with Pro';

  @override
  String get smartPickCategory => 'Only from category…';

  @override
  String get smartPickAllCategories => 'All categories';

  @override
  String get listTitle => 'Later';

  @override
  String get searchHint => 'Search Later…';

  @override
  String get searchAdvancedHint =>
      'Advanced search (tags, links, notes) with Pro';

  @override
  String get filterAll => 'All';

  @override
  String get filterToday => 'Today';

  @override
  String get filterWeek => 'This week';

  @override
  String get filterNoDate => 'No date';

  @override
  String get filterOverdue => 'Overdue';

  @override
  String get filterHigh => 'High priority';

  @override
  String get filterStale => 'Waiting long';

  @override
  String get sortTitle => 'Sort';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortDeadline => 'Nearest deadline';

  @override
  String get sortPriority => 'Priority';

  @override
  String get sortShortest => 'Shortest task';

  @override
  String get sortLongest => 'Longest task';

  @override
  String get listEmptyFiltered => 'Nothing found';

  @override
  String get listEmptyFilteredBody => 'Try changing the filter or search.';

  @override
  String get smartFiltersPro => 'Smart filters with Pro';

  @override
  String get overdue => 'Overdue';

  @override
  String waitingDays(String n) {
    return 'Waiting $n days';
  }

  @override
  String get dueToday => 'Today';

  @override
  String get dueTomorrow => 'Tomorrow';

  @override
  String atTime(String time) {
    return 'at $time';
  }

  @override
  String get noDate => 'No date';

  @override
  String get priorityHigh => 'High priority';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityLow => 'Low';

  @override
  String get priority => 'Priority';

  @override
  String get duration => 'Estimated time';

  @override
  String minutesShort(String n) {
    return '${n}m';
  }

  @override
  String get reminder => 'Reminder';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatNone => 'Once';

  @override
  String get repeatDaily => 'Every day';

  @override
  String get repeatWeekly => 'Every week';

  @override
  String get repeatMonthly => 'Every month';

  @override
  String snoozedTimes(String n) {
    return 'Snoozed $n times';
  }

  @override
  String get itemDone => 'Done';

  @override
  String get itemSnooze => 'Later';

  @override
  String get itemDrop => 'Let it go';

  @override
  String get itemOpenLink => 'Open link';

  @override
  String get itemLinkFailed => 'Couldn\'t open the link.';

  @override
  String get toastDone => 'Done ✓';

  @override
  String get toastDropped => 'Set aside';

  @override
  String get toastDeleted => 'Deleted';

  @override
  String toastSnoozed(String when) {
    return 'Moved to $when';
  }

  @override
  String get toastSaved => 'Saved';

  @override
  String get toastAdded => 'Added to Later';

  @override
  String get toastReopened => 'Back in your list';

  @override
  String get confirmDeleteTitle => 'Delete this item?';

  @override
  String get confirmDeleteBody => 'This item will be permanently deleted.';

  @override
  String createdOn(String date) {
    return 'Added on $date';
  }

  @override
  String get itemNotFound => 'This item no longer exists.';

  @override
  String get addTitle => 'Something for later';

  @override
  String get editTitle => 'Edit';

  @override
  String get titleHint => 'What should I keep for later?';

  @override
  String get titleRequired => 'Write a title';

  @override
  String get moreOptions => 'More options';

  @override
  String get lessOptions => 'Fewer options';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldNote => 'Note';

  @override
  String get fieldUrl => 'Link';

  @override
  String get urlInvalid => 'Invalid link (http and https only).';

  @override
  String get fieldTags => 'Tags';

  @override
  String get fieldTagsHint => 'Separate with commas';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldDate => 'Date';

  @override
  String get fieldTime => 'Time';

  @override
  String get datePick => 'Pick a date…';

  @override
  String get timePick => 'Pick a time…';

  @override
  String get timeNone => 'No time';

  @override
  String get reminderOff => 'No reminder';

  @override
  String get reminderAtTime => 'At the time';

  @override
  String get reminderBefore10 => '10 min before';

  @override
  String get reminderBefore1h => '1 hour before';

  @override
  String get reminderBefore1d => '1 day before';

  @override
  String get reminderNeedsDate => 'A reminder needs a date.';

  @override
  String reminderAtDefault(String time) {
    return 'at $time (default)';
  }

  @override
  String get repeatProHint => 'Repeating reminders with Pro';

  @override
  String get durationUnknown => 'Unknown';

  @override
  String get durationCustom => 'Custom';

  @override
  String get durationCustomHint => 'How many minutes?';

  @override
  String get quickToday => 'Today';

  @override
  String get quickTomorrow => 'Tomorrow';

  @override
  String get quickWeekend => 'Weekend';

  @override
  String get quickNextWeek => 'Next week';

  @override
  String get quickNoDate => 'No date';

  @override
  String get quickCustom => 'Other date';

  @override
  String get discardTitle => 'Discard changes?';

  @override
  String get discardBody => 'What you typed hasn\'t been saved.';

  @override
  String get discard => 'Discard';

  @override
  String get snoozeTitle => 'Snooze until…';

  @override
  String get snoozeTonight => 'Tonight';

  @override
  String get snoozeTomorrow => 'Tomorrow';

  @override
  String get snoozeWeekend => 'This weekend';

  @override
  String get snoozeNextWeek => 'Next week';

  @override
  String get snoozeNextMonth => 'Next month';

  @override
  String get snoozeCustom => 'Pick a date';

  @override
  String get snoozeNoDate => 'No date';

  @override
  String get datePickerTitle => 'Pick a date';

  @override
  String get prevMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get today => 'Today';

  @override
  String get clear => 'Clear';

  @override
  String get staleTitle => 'Later, not never';

  @override
  String staleQuestion(String days) {
    return 'This has been waiting for you for $days days.\nDo you still want to keep it?';
  }

  @override
  String get staleKeep => 'Keep';

  @override
  String get staleSnooze => 'Schedule for later';

  @override
  String get staleDone => 'Done';

  @override
  String get staleDrop => 'Let it go';

  @override
  String staleProgress(String i, String n) {
    return '$i of $n';
  }

  @override
  String get staleAllDone => 'All clear ✨';

  @override
  String get staleAllDoneBody => 'Your list just got lighter.';

  @override
  String get staleNoPressure => 'No rush; no decision is wrong.';

  @override
  String get historyTitle => 'History';

  @override
  String get periodToday => 'Today';

  @override
  String get periodWeek => 'This week';

  @override
  String get periodMonth => 'This month';

  @override
  String get periodAll => 'All';

  @override
  String get historyEmpty => 'Nothing in your history yet';

  @override
  String get historyEmptyBody => 'Completed and set-aside items stay here.';

  @override
  String historyDoneAt(String date) {
    return 'Done · $date';
  }

  @override
  String historyDroppedAt(String date) {
    return 'Set aside · $date';
  }

  @override
  String get historyRestore => 'Move back to list';

  @override
  String get historyProNote => 'Full history (month & all) with Pro';

  @override
  String get historyDisabled =>
      'History is off; only anonymous statistics are kept.';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsDone => 'Completed';

  @override
  String get statsDropped => 'Set aside';

  @override
  String get statsDeleted => 'Deleted';

  @override
  String get statsSnoozed => 'Times snoozed';

  @override
  String get statsActive => 'Active';

  @override
  String get statsAvgWait => 'Average wait until done';

  @override
  String statsDaysValue(String n) {
    return '$n days';
  }

  @override
  String get statsTopCategory => 'Top category';

  @override
  String get statsThisWeek => 'Completed this week';

  @override
  String get statsProLocked => 'Full statistics with Pro';

  @override
  String get statsNoData => '—';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get secAppearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System default';

  @override
  String get accent => 'Accent colour';

  @override
  String get accentIndigo => 'Indigo';

  @override
  String get accentTeal => 'Teal';

  @override
  String get accentRose => 'Rose';

  @override
  String get accentAmber => 'Amber';

  @override
  String get accentSlate => 'Slate';

  @override
  String get appIcon => 'App icon';

  @override
  String get iconClassic => 'Classic';

  @override
  String get iconTeal => 'Teal';

  @override
  String get iconRose => 'Rose';

  @override
  String get iconDark => 'Dark';

  @override
  String get iconChangeNote =>
      'The launcher may take a moment to refresh the icon.';

  @override
  String get secReminders => 'Reminders';

  @override
  String get remindersToggle => 'Reminders';

  @override
  String get defaultReminderTime => 'Default reminder time';

  @override
  String get privateNotifications => 'Hide text in notifications';

  @override
  String get privateNotificationsSub =>
      'Item titles won\'t show on the lock screen.';

  @override
  String get notifPermission => 'Notification access';

  @override
  String get notifPermissionOn => 'Enabled';

  @override
  String get notifPermissionOff => 'Disabled — tap to open settings';

  @override
  String get exactAlarm => 'Reminder accuracy';

  @override
  String get exactAlarmOk => 'Exact';

  @override
  String get exactAlarmOff => 'Approximate — \"exact alarms\" not allowed';

  @override
  String get batteryOptimization => 'Battery restrictions';

  @override
  String get batteryOptimizationSub =>
      'Some phones block reminders; tap to open the settings.';

  @override
  String get sendTestNotification => 'Send a test notification';

  @override
  String get testNotificationSent => 'Test notification sent.';

  @override
  String get secGeneral => 'General';

  @override
  String get language => 'Language';

  @override
  String get langFa => 'فارسی (Persian)';

  @override
  String get langEn => 'English';

  @override
  String get calendar => 'Calendar';

  @override
  String get calJalali => 'Jalali (Persian)';

  @override
  String get calGregorian => 'Gregorian';

  @override
  String get weekStart => 'Start of week';

  @override
  String get weekendDay => 'Weekend day';

  @override
  String get keepHistory => 'Keep history';

  @override
  String get keepHistorySub =>
      'Keep completed and set-aside items in the archive.';

  @override
  String get staleAfter => 'Review long-waiting items after';

  @override
  String daysN(String n) {
    return '$n days';
  }

  @override
  String get secData => 'Data';

  @override
  String get backupRestore => 'Backup & restore';

  @override
  String get categoriesManage => 'Manage categories';

  @override
  String get secAbout => 'About';

  @override
  String get proSettingsTitle => 'Later Pro';

  @override
  String get proSettingsFree => 'Free plan';

  @override
  String proSettingsActive(String date) {
    return 'Active until $date';
  }

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'Later is a small, fast app for keeping things that aren\'t for now — no account, no server.';

  @override
  String get aboutOffline => 'All your data is stored only on your device.';

  @override
  String get aboutLicenses => 'Open-source licences';

  @override
  String get aboutContact => 'Support';

  @override
  String get version => 'Version';

  @override
  String versionValue(String v) {
    return 'Version $v';
  }

  @override
  String get resetApp => 'Reset app';

  @override
  String get resetAppSub => 'All items, categories, history and settings';

  @override
  String get resetConfirmTitle => 'Erase everything?';

  @override
  String get resetConfirmBody =>
      'All items, categories, history and settings will be permanently deleted. This cannot be undone.\n(Your Pro subscription is not affected.)\nWe suggest making a backup first.';

  @override
  String resetTypeHint(String word) {
    return 'To confirm, type \"$word\"';
  }

  @override
  String get resetWord => 'ERASE';

  @override
  String get resetAction => 'Erase everything';

  @override
  String get resetDone => 'Everything was erased.';

  @override
  String categoryName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'work': 'Work',
      'read': 'To read',
      'watch': 'To watch',
      'buy': 'To buy',
      'idea': 'Ideas',
      'link': 'Links',
      'people': 'People',
      'other': 'Other',
    });
    return '$_temp0';
  }

  @override
  String get categoryNew => 'New category';

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryNameHint => 'Category name';

  @override
  String get categoryEmojiHint => 'Emoji';

  @override
  String categoryLimit(String free, String pro) {
    return 'The free plan allows $free custom categories; Pro allows up to $pro.';
  }

  @override
  String get categoryDeleteTitle => 'Delete this category?';

  @override
  String get categoryDeleteBody => 'Its items will move to \"Other\".';

  @override
  String get categoryBuiltin => 'Built-in category';

  @override
  String get backupTitle => 'Backup & restore';

  @override
  String get backupIntro =>
      'Your data lives only on this device. Make a backup file before moving or reinstalling.';

  @override
  String get backupExport => 'Export my data';

  @override
  String get backupExportSub =>
      'A .later file with all items, categories, history and settings';

  @override
  String get backupImport => 'Restore from file';

  @override
  String get backupImportSub => 'Choose a previous backup file';

  @override
  String backupLast(String date) {
    return 'Last backup: $date';
  }

  @override
  String get backupNever => 'You haven\'t made a backup yet';

  @override
  String get backupExported => 'Backup saved ✓';

  @override
  String get backupAuto => 'Automatic weekly backup';

  @override
  String get backupAutoSub =>
      'Keeps up to 5 copies in private app storage (Pro).';

  @override
  String get backupAdvancedExport => 'More export formats (Pro)';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportText => 'Export text (Markdown)';

  @override
  String get exportSaved => 'File saved ✓';

  @override
  String get restoreConfirmTitle => 'Restore data?';

  @override
  String restoreConfirmReplace(String current, String date, String incoming) {
    return 'Your current data ($current items) will be replaced by the file ($incoming items, created $date).\nA safety copy of the current data is kept first.';
  }

  @override
  String restoreConfirmEmpty(String date, String incoming) {
    return 'The file contains $incoming items (created $date).';
  }

  @override
  String get restoreAction => 'Restore';

  @override
  String get restoreDone => 'Data restored ✓';

  @override
  String get restoreProRestored => 'Your Pro subscription was restored too.';

  @override
  String get backupErrEmpty => 'The file is empty.';

  @override
  String get backupErrTooLarge => 'The file is too large.';

  @override
  String get backupErrNotJson => 'The file is damaged or incomplete.';

  @override
  String get backupErrNotBackup => 'This is not a Later backup file.';

  @override
  String get backupErrMissing => 'The file is incomplete.';

  @override
  String get backupErrFuture =>
      'This backup was made by a newer version of the app. Please update the app.';

  @override
  String get backupErrUnsupported =>
      'This backup format is no longer supported.';

  @override
  String get backupErrChecksum => 'The file is damaged or has been modified.';

  @override
  String get backupErrInvalid => 'The file contents are not valid.';

  @override
  String get backupErrMigration => 'Upgrading the file format failed.';

  @override
  String get backupErrGeneric =>
      'Restore failed. Your current data was not changed.';

  @override
  String get backupNoChange => 'Your current data was not changed.';

  @override
  String get proTitle => 'Later Pro';

  @override
  String get proHeadline => 'More power for people who use Later a lot.';

  @override
  String get proFreeNote =>
      'The free version stays fully usable and none of your data is ever limited or deleted.';

  @override
  String proActiveUntil(String date) {
    return 'Active until $date';
  }

  @override
  String proRemaining(String n) {
    return '$n days left';
  }

  @override
  String get proExpiredNote =>
      'Your Pro has ended. Your data is safe; only Pro features are switched off.';

  @override
  String get proPlan1 => '1 month';

  @override
  String get proPlan3 => '3 months';

  @override
  String get proPlan6 => '6 months';

  @override
  String get proPlanDay1 => '1 day (test)';

  @override
  String get proPlanDay7 => '7 days (test)';

  @override
  String priceToman(String price) {
    return '$price Toman';
  }

  @override
  String get proBuy => 'Buy';

  @override
  String get proExtend => 'Extend';

  @override
  String get proStackNote =>
      'A new purchase keeps your remaining days and adds the new period on top.';

  @override
  String get proRestore => 'Restore purchases';

  @override
  String proRestored(String n) {
    return '$n purchase(s) restored';
  }

  @override
  String get proNothingToRestore => 'No unrestored purchases found.';

  @override
  String get proPurchaseSuccess => 'Pro activated 🎉';

  @override
  String get proPurchaseCancelled => 'Purchase cancelled.';

  @override
  String get proPurchaseUnavailable =>
      'Billing is unavailable. Check the Cafe Bazaar app.';

  @override
  String get proPurchaseFailed => 'The purchase failed. Please try again.';

  @override
  String get proTamper =>
      'Subscription data was invalid and was reset. If you purchased, tap \"Restore purchases\".';

  @override
  String get proF1 => 'Advanced smart pick';

  @override
  String get proF2 => 'Smart filters & advanced search';

  @override
  String get proF3 => 'Full statistics & history';

  @override
  String get proF4 => 'More custom categories';

  @override
  String get proF5 => 'Recurring & advanced reminders';

  @override
  String get proF6 => 'Advanced widgets';

  @override
  String get proF7 => 'More themes & icons';

  @override
  String get proF8 => 'Auto backups & more exports';

  @override
  String get proLockedTitle => 'This is a Pro feature';

  @override
  String get proLockedBody =>
      'Pro unlocks this and more. The free version remains complete.';

  @override
  String get proSeePlans => 'See plans';

  @override
  String get notNow => 'Not now';

  @override
  String get qaTitle => 'Test tools (test build only)';

  @override
  String get qaNote => 'This section does not exist in the store build.';

  @override
  String qaGrantPlan(String plan) {
    return 'Simulate buying $plan';
  }

  @override
  String get qaClearPro => 'Remove Pro';

  @override
  String qaAdvance(String n) {
    return 'Advance app clock: $n days';
  }

  @override
  String get qaResetTime => 'Reset simulated clock';

  @override
  String qaClock(String date) {
    return 'App clock: $date';
  }

  @override
  String qaSeed(String n) {
    return 'Add $n sample items';
  }

  @override
  String qaSeeded(String n) {
    return '$n items added.';
  }

  @override
  String get qaNotifNow => 'Notification now';

  @override
  String qaNotifIn(String s) {
    return 'Notification in $s seconds';
  }

  @override
  String qaProState(String state) {
    return 'Pro state: $state';
  }

  @override
  String get notifChannelName => 'Reminders';

  @override
  String get notifChannelDescription =>
      'Reminders for the items you kept for later';

  @override
  String get notifActionDone => 'Done';

  @override
  String get notifActionTomorrow => 'Tomorrow';

  @override
  String get notifPrivateBody => 'An item is waiting for you';

  @override
  String get notifBodyGeneric => 'Later';

  @override
  String get notifTestTitle => 'Test notification';

  @override
  String get notifTestBody => 'If you can see this, notifications work ✓';

  @override
  String get reminderPermissionBanner =>
      'Notification permission isn\'t granted; reminders won\'t show.';

  @override
  String get reminderSyncFailed => 'Some reminders couldn\'t be scheduled.';

  @override
  String get reminderApproximate =>
      'Reminders are approximate; allow \"exact alarms\" for better accuracy.';

  @override
  String get permissionDeniedTitle => 'Notification permission needed';

  @override
  String get permissionDeniedBody =>
      'Enable notifications so I can remind you later.';

  @override
  String get openSettings => 'Open settings';

  @override
  String shareAdded(String title) {
    return '\"$title\" added to Later';
  }

  @override
  String widgetWaiting(String n) {
    return '$n waiting';
  }

  @override
  String get widgetEmpty => 'Nothing waiting 🌱';

  @override
  String get widgetAdd => '+ Add';

  @override
  String get widgetPick => '🎯 Pick';

  @override
  String get widgetProOnly => 'The advanced widget is a Pro feature';

  @override
  String get widgetSuggestion => 'Suggestion';

  @override
  String get shortcutAdd => 'Add';

  @override
  String get shortcutPick => 'Give me one';

  @override
  String get shortcutSearch => 'Search';

  @override
  String get licensesLegalese => 'Built with Flutter. Vazirmatn font (OFL).';
}
