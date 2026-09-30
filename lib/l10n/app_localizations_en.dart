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
  String get onb1Body =>
      'Not everything has to be done right now. Put aside what isn\'t for now.';

  @override
  String get onb2Title =>
      'Keep anything you don\'t want to forget, right here.';

  @override
  String get onb2Body =>
      'An article, a movie, something to buy, an idea, a call. Type it, or hit Share in any app.';

  @override
  String get onb3Title => 'Later reminds you by itself.';

  @override
  String get onb3Body =>
      'Give it a date and it\'ll remind you. No date? Spin the roulette when you have a moment.';

  @override
  String get onb4Title => 'No account, no server.';

  @override
  String get onb4Body =>
      'Your data stays on your phone and works without internet.';

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
      'Before you start, please read and accept the Terms of Use and Privacy Policy.';

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
    return '$count things are waiting for you';
  }

  @override
  String get homeWaitingOne => 'One thing is waiting for you';

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
  String get pickCardTitle => 'Later roulette';

  @override
  String get pickCardSub =>
      'Can\'t decide what to do? Let the roulette choose.';

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
  String get decideLabel => 'The roulette picked';

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
  String get decideDoneToast => 'Done ✓';

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
  String get smartPickProHint => 'Category and priority filters need Pro';

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
  String get reminderBefore60Label => '1 hour before';

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
    return 'It\'s been waiting $days days.\nDo you still want to keep it?';
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
  String get staleAllDone => 'All clear';

  @override
  String get staleAllDoneBody => 'Your list just got lighter.';

  @override
  String get staleNoPressure => 'No rush. Whatever you decide is fine.';

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
  String get historyProNote => 'Full history (month and all time) with Pro';

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
  String get keepHistorySub => 'Keep finished and set-aside items in history.';

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
      'Later is where things go when it isn\'t the time yet. No account, no server.';

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
      'Everything in this app is deleted for good and can\'t be brought back. Your Pro plan isn\'t affected. Make a backup first.';

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
    return 'The free plan allows $free custom categories. Pro allows up to $pro.';
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
      'Your data lives only on this phone. Before switching phones or reinstalling, make a backup file.';

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
  String get proHeadline => 'If you use Later a lot, Pro makes it easier.';

  @override
  String get proFreeNote =>
      'The free version isn\'t crippled. If Pro ends, nothing you saved is deleted or locked.';

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
      'Your Pro has ended. Your data is still here; only the Pro features are off.';

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
      'If you buy again during a plan, your remaining days aren\'t lost; the new period is added on top.';

  @override
  String get proRestore => 'Restore purchases';

  @override
  String proRestored(String n) {
    return '$n purchase(s) restored';
  }

  @override
  String get proNothingToRestore => 'No unrestored purchases found.';

  @override
  String get proPurchaseSuccess => 'Pro is active';

  @override
  String get proPurchaseCancelled => 'Purchase cancelled.';

  @override
  String get proPurchaseUnavailable =>
      'Billing is unavailable. Check the Cafe Bazaar app.';

  @override
  String get proPurchaseFailed => 'The purchase failed. Please try again.';

  @override
  String get proTamper =>
      'The subscription data was invalid and was cleared. If you had bought Pro, tap \"Restore purchases\".';

  @override
  String get proF1 => 'Smart roulette and smart inbox';

  @override
  String get proF2 => 'Advanced search and filters';

  @override
  String get proF3 => 'Full statistics and history';

  @override
  String get proF4 => 'More custom categories';

  @override
  String get proF5 => 'Repeating reminders';

  @override
  String get proF6 => 'List widget';

  @override
  String get proF7 => 'More colours and icons';

  @override
  String get proF8 => 'Auto backup and CSV export';

  @override
  String get proLockedTitle => 'This is a Pro feature';

  @override
  String get proLockedBody =>
      'This one is part of Pro. Everything else works fully without it.';

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
  String get qaSeedShelves => 'Sample shelves, people and capsule';

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
      'Notifications aren\'t allowed, so reminders won\'t show.';

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

  @override
  String get repeatYearly => 'Every year';

  @override
  String get defaultCapsuleTitle => 'Untitled capsule';

  @override
  String get defaultMessageTitle => 'Untitled message';

  @override
  String typeName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'task': 'Task',
      'read': 'Article',
      'watch': 'Video',
      'wishlist': 'Wish',
      'idea': 'Idea',
      'person': 'Person',
      'capsule': 'Capsule',
      'future': 'Message',
      'other': 'Item',
    });
    return '$_temp0';
  }

  @override
  String daysAgo(String n) {
    return '$n days ago';
  }

  @override
  String get dashRoulette => 'Later roulette';

  @override
  String get dashInbox => 'Inbox';

  @override
  String dashInboxCount(String n) {
    return '$n items waiting to be sorted';
  }

  @override
  String get dashInboxEmpty => 'Your inbox is empty';

  @override
  String get dashShelves => 'Shelves';

  @override
  String get shelfReadTitle => 'Read later';

  @override
  String get shelfWatchTitle => 'Watch later';

  @override
  String get shelfWishTitle => 'Wishlist';

  @override
  String get shelfIdeaTitle => 'Ideas';

  @override
  String get shelfPeopleTitle => 'People';

  @override
  String get shelfFutureTitle => 'Future';

  @override
  String get returnedBanner => 'Something came back from the past';

  @override
  String get returnedBannerBody => 'Open it and see what it was.';

  @override
  String ideaReviewBanner(String n) {
    return '$n ideas are due for review';
  }

  @override
  String get searchEverywhere => 'Search everything';

  @override
  String get searchEverywhereHint => 'Tasks, articles, ideas, people…';

  @override
  String get searchNothing => 'Nothing found';

  @override
  String get searchStartTyping => 'Type a word.';

  @override
  String get searchDone => 'Finished';

  @override
  String get addTypeLabel => 'What is it?';

  @override
  String get addTypeAuto => 'I\'ll sort it later';

  @override
  String get fieldPrice => 'Price';

  @override
  String get fieldCurrency => 'Currency';

  @override
  String get currencyDefault => 'Toman';

  @override
  String get fieldWatchKind => 'Kind';

  @override
  String get kindVideo => 'Video';

  @override
  String get kindMovie => 'Movie';

  @override
  String get kindSeries => 'Series';

  @override
  String get kindOther => 'Other';

  @override
  String get stageUnread => 'Unread';

  @override
  String get stageReading => 'Reading';

  @override
  String get stageRead => 'Read';

  @override
  String get stageArchived => 'Archived';

  @override
  String get stageUnwatched => 'Unwatched';

  @override
  String get stageWatching => 'Watching';

  @override
  String get stageWatched => 'Watched';

  @override
  String get stageInterested => 'Interested';

  @override
  String get stageMaybe => 'Maybe';

  @override
  String get stageBought => 'Bought';

  @override
  String get stageNotInterested => 'No longer interested';

  @override
  String get stageIdeaNew => 'New';

  @override
  String get stageThinking => 'Thinking';

  @override
  String get stageDeveloping => 'Developing';

  @override
  String get stageIdeaArchived => 'Archived';

  @override
  String get stageIdeaDropped => 'Dropped';

  @override
  String get stageSealed => 'Sealed';

  @override
  String get stageOpened => 'Opened';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get markAsWatched => 'Mark as watched';

  @override
  String get markAsBought => 'Mark as bought';

  @override
  String get itemStage => 'Status';

  @override
  String get moveToShelf => 'Move to…';

  @override
  String movedTo(String shelf) {
    return 'Moved to \"$shelf\"';
  }

  @override
  String get shelfEmptyReadTitle => 'Nothing to read yet';

  @override
  String get shelfEmptyReadBody => 'Share an article link to Later.';

  @override
  String get shelfEmptyWatchTitle => 'Nothing to watch yet';

  @override
  String get shelfEmptyWatchBody =>
      'Keep a YouTube link or a movie title here.';

  @override
  String get shelfEmptyWishTitle => 'Your wishlist is empty';

  @override
  String get shelfEmptyWishBody =>
      'Put something you might buy here. After a while I\'ll ask if you still want it.';

  @override
  String get shelfEmptyIdeaTitle => 'No ideas yet';

  @override
  String get shelfEmptyIdeaBody => 'Ideas wait here until their time comes.';

  @override
  String get shelfWaiting => 'Waiting';

  @override
  String get shelfHistory => 'History';

  @override
  String get shelfAllStages => 'All';

  @override
  String get shelfStatsTitle => 'Statistics';

  @override
  String get shelfAdvancedFilters => 'Advanced filters';

  @override
  String get shelfHistoryPro => 'This shelf\'s history with Pro';

  @override
  String get shelfCollections => 'Lists';

  @override
  String get shelfCollectionMain => 'Main';

  @override
  String get collectionNew => 'New list';

  @override
  String get collectionName => 'List name';

  @override
  String get collectionProHint => 'Several separate lists with Pro';

  @override
  String get sortByPrice => 'Price';

  @override
  String get sortByScore => 'Score';

  @override
  String get sortByTime => 'Estimated time';

  @override
  String get statsWaiting => 'Waiting';

  @override
  String get statsFinished => 'Finished';

  @override
  String get statsThisMonth => 'This month';

  @override
  String get statsMinutesWaiting => 'Total time waiting';

  @override
  String get statsAvgFinish => 'Average until finished';

  @override
  String get statsTotalPrice => 'Total price';

  @override
  String readTimeEstimate(String n) {
    return 'About $n min';
  }

  @override
  String linkHost(String host) {
    return 'from $host';
  }

  @override
  String get priceNow => 'Price';

  @override
  String get priceSetNew => 'Record a new price';

  @override
  String get priceTarget => 'Target price';

  @override
  String get priceTargetReached => 'Target price reached';

  @override
  String get priceHistoryTitle => 'Price history';

  @override
  String get priceHistoryEmpty => 'No price recorded yet.';

  @override
  String get priceHint => 'e.g. 1200000';

  @override
  String get wishProHint => 'Target price and price history with Pro';

  @override
  String get wishReviewTitle => 'Do you still want it?';

  @override
  String wishReviewQuestion(String days) {
    return 'It\'s been on your list for $days days.\nDo you still want to buy it?';
  }

  @override
  String get wishStill => 'I still want it';

  @override
  String get wishUnsure => 'I\'m not sure';

  @override
  String get wishNo => 'I don\'t want it anymore';

  @override
  String get ideaReviewTitle => 'Idea review';

  @override
  String get ideaReviewNone => 'Nothing to review.';

  @override
  String get ideaReviewIntro =>
      'Take a look at each idea and decide what to do.';

  @override
  String get ideaScore => 'Score';

  @override
  String get ideaLinks => 'Related ideas';

  @override
  String get ideaAddLink => 'Link another idea';

  @override
  String get ideaToTask => 'Turn into a task';

  @override
  String get ideaConverted => 'It\'s a task now';

  @override
  String get ideaKeepThinking => 'Still thinking';

  @override
  String get ideaDevelop => 'Let\'s develop it';

  @override
  String get ideaArchiveIt => 'Archive';

  @override
  String get ideaDropIt => 'Let it go';

  @override
  String ideaLastReviewed(String when) {
    return 'Last reviewed: $when';
  }

  @override
  String get ideaNeverReviewed => 'Not reviewed yet';

  @override
  String get ideaProHint => 'Score, linking and review with Pro';

  @override
  String get peopleTitle => 'People';

  @override
  String get peopleEmptyTitle => 'You haven\'t added anyone yet';

  @override
  String get peopleEmptyBody =>
      'For example \"call Ali later\". Pick someone from your contacts or type a name.';

  @override
  String get personAdd => 'Add a person';

  @override
  String get personFromContacts => 'Pick from contacts';

  @override
  String get personTypeName => 'Just type a name';

  @override
  String get personName => 'Name';

  @override
  String get personNote => 'Note';

  @override
  String personLast(String when) {
    return 'Last contact: $when';
  }

  @override
  String get personNever => 'No contact logged yet';

  @override
  String personNext(String when) {
    return 'Next: $when';
  }

  @override
  String get personNoNext => 'No reminder';

  @override
  String get personTalked => 'We just talked';

  @override
  String get personAddReminder => 'New reminder';

  @override
  String get personReminderHint => 'e.g. send a message';

  @override
  String get personOpenContact => 'Open contact';

  @override
  String get personDeleteTitle => 'Delete this person?';

  @override
  String get personDeleteBody =>
      'Its reminders stay, but they\'re no longer linked to this person.';

  @override
  String get personHistory => 'Contact history';

  @override
  String get personFollowUp => 'Follow up';

  @override
  String personFollowUpDays(String n) {
    return 'Remind me in $n days';
  }

  @override
  String get personGroup => 'Group';

  @override
  String get personDueTitle => 'Time to reach out';

  @override
  String get personLinked => 'Reminders';

  @override
  String get personPickerFailed =>
      'Couldn\'t pick a contact. Type the name instead.';

  @override
  String get interactionNoteHint => 'What did you talk about? (optional)';

  @override
  String get peopleProHint =>
      'History, follow-ups and \"time to reach out\" with Pro';

  @override
  String get personContactRef => 'From your contacts';

  @override
  String get futureTitle => 'Future';

  @override
  String get futureTabCapsules => 'Time capsules';

  @override
  String get futureTabMessages => 'Messages to me';

  @override
  String get capsuleEmptyTitle => 'No capsules';

  @override
  String get capsuleEmptyBody =>
      'Hide something until a date. It comes back that day.';

  @override
  String get messageEmptyTitle => 'You haven\'t written any message';

  @override
  String get messageEmptyBody => 'Write to your future self.';

  @override
  String get capsuleNew => 'New capsule';

  @override
  String get messageNew => 'New message';

  @override
  String get sealTitleHint => 'Title';

  @override
  String get capsuleBodyHint => 'What do you want to see later?';

  @override
  String get messageBodyHint => 'What do you tell your future self?';

  @override
  String sealOpenOn(String date) {
    return 'Opens: $date';
  }

  @override
  String get sealPickDate => 'Opening date';

  @override
  String get sealQuick1m => 'In 1 month';

  @override
  String get sealQuick3m => 'In 3 months';

  @override
  String get sealQuick6m => 'In 6 months';

  @override
  String get sealQuick1y => 'In 1 year';

  @override
  String sealSaved(String date) {
    return 'Sealed. You won\'t see it until $date.';
  }

  @override
  String sealLimitFree(String n) {
    return 'The free plan allows $n sealed items at a time. Pro is unlimited.';
  }

  @override
  String get sealNeedsFuture => 'The date must be in the future.';

  @override
  String lockedUntil(String date) {
    return 'Locked until $date';
  }

  @override
  String get openIt => 'Open it';

  @override
  String get returnedTitle => 'Something came back from the past';

  @override
  String get messageReturnedTitle => 'You have a message from your past self';

  @override
  String writtenOn(String date) {
    return 'Written on $date';
  }

  @override
  String get sealRepeat => 'Repeat';

  @override
  String get sealAttach => 'Attachments';

  @override
  String get sealAttachAdd => 'Add a photo or file';

  @override
  String sealAttachLimit(String mb, String n) {
    return 'Up to $n files, $mb MB each. They stay on this phone only.';
  }

  @override
  String get sealAttachTooBig => 'This file is over the size limit.';

  @override
  String get sealAttachFailed => 'The file couldn\'t be added.';

  @override
  String get sealProHint =>
      'Unlimited capsules and messages, attachments, tags and repeats with Pro';

  @override
  String get sealThisItem => 'Keep for the future';

  @override
  String get sealItemQuestion => 'Hide it until when?';

  @override
  String timelineOpened(String date) {
    return 'Opened on $date';
  }

  @override
  String get notifCapsuleTitle => 'Something came back from the past';

  @override
  String get notifCapsuleBody => 'Open it and see what it was.';

  @override
  String get notifFutureTitle => 'You have a message from your past self';

  @override
  String get notifFutureBody => 'Open it and read it.';

  @override
  String get notifIdeaReviewTitle => 'Time to review your ideas';

  @override
  String get notifIdeaReviewBody => 'A few ideas are waiting for another look.';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get inboxIntro =>
      'Whatever you saved quickly waits here until you decide what to do with it.';

  @override
  String get inboxEmptyTitle => 'The inbox is empty';

  @override
  String get inboxEmptyBody => 'Everything is in its place.';

  @override
  String get triageToday => 'Today';

  @override
  String get triageWeek => 'This week';

  @override
  String get triageNoDate => 'No date';

  @override
  String get triageRead => 'Read later';

  @override
  String get triageWatch => 'Watch later';

  @override
  String get triageWish => 'Wishlist';

  @override
  String get triageIdea => 'Idea';

  @override
  String get triageDone => 'Done';

  @override
  String get triageDelete => 'Delete';

  @override
  String inboxSuggest(String what) {
    return 'This looks like $what. Move it?';
  }

  @override
  String get inboxSuggestYes => 'Yes, move it';

  @override
  String get suggestWhatRead => 'an article';

  @override
  String get suggestWhatWatch => 'a video';

  @override
  String get suggestWhatWish => 'something to buy';

  @override
  String get suggestWhatIdea => 'an idea';

  @override
  String get suggestWhatPerson => 'a reminder about a person';

  @override
  String get inboxProHint => 'Automatic destination suggestions with Pro';

  @override
  String get rouletteTitle => 'Later roulette';

  @override
  String get roulettePick => 'Pick one';

  @override
  String get rouletteSpinning => 'Picking…';

  @override
  String get rouletteStart => 'Start';

  @override
  String get rouletteLater => 'Later';

  @override
  String get rouletteAgain => 'Another one';

  @override
  String get rouletteEmptyTitle => 'Nothing to draw from';

  @override
  String get rouletteEmptyBody =>
      'Your list is empty or nothing matches the filters.';

  @override
  String get rouletteFilters => 'Filters';

  @override
  String get rouletteTime => 'Time';

  @override
  String get rouletteEnergy => 'Energy';

  @override
  String get energyLow => 'Low';

  @override
  String get energyHigh => 'High';

  @override
  String get rouletteCats => 'Roulette categories';

  @override
  String get rouletteHistoryTitle => 'Roulette history';

  @override
  String get rouletteHistoryEmpty => 'You haven\'t spun yet.';

  @override
  String get rouletteProHint =>
      'Time, category, priority and energy filters and history with Pro';

  @override
  String get rouletteOpenLink => 'Open link';

  @override
  String get shareWhere => 'Where should I keep it?';

  @override
  String get shareInbox => 'Inbox';

  @override
  String get shareSavedInbox => 'Saved to your inbox.';

  @override
  String get shareSuggested => 'Suggested';

  @override
  String get proWhatYouGet => 'What you get with Pro';

  @override
  String get proFreeHeader => 'Free already includes';

  @override
  String get proFreeList =>
      'Unlimited saving, inbox, basic roulette, read / watch / wishlist, ideas, people, capsules and messages (up to 2), search, reminders, sharing, light and dark themes, backup.';

  @override
  String get proFT1 => 'Smart roulette';

  @override
  String get proFD1 =>
      'Picks from the categories you choose, by time, priority and energy, and keeps a roulette history.';

  @override
  String get proFT2 => 'Smart inbox';

  @override
  String get proFD2 =>
      'Suggests a destination for each item (article, video, purchase, idea). You always confirm.';

  @override
  String get proFT3 => 'Fuller shelves';

  @override
  String get proFD3 =>
      'Reading and watching history and stats, advanced filters and sorting, several separate lists.';

  @override
  String get proFT4 => 'Smarter wishlist';

  @override
  String get proFD4 =>
      'Target price, a price history you record, stats and re-check reminders.';

  @override
  String get proFT5 => 'Ideas with review';

  @override
  String get proFD5 =>
      'Scores, linking ideas, periodic review, a monthly reminder and turning an idea into a task.';

  @override
  String get proFT6 => 'People who matter';

  @override
  String get proFD6 =>
      'Contact history, automatic follow-ups, custom groups and a \"time to reach out\" list.';

  @override
  String get proFT7 => 'More future';

  @override
  String get proFD7 =>
      'Unlimited capsules and messages, small photo and file attachments, tags and repeats (e.g. yearly).';

  @override
  String get proFT8 => 'Search and filters';

  @override
  String get proFD8 =>
      'Search in tags, links and notes, plus the \"waiting long\" filter.';

  @override
  String get proFT9 => 'Full stats and history';

  @override
  String get proFD9 =>
      'All months and full statistics instead of only the last 7 days.';

  @override
  String get proFT10 => 'Repeating reminders';

  @override
  String get proFD10 => 'Daily, weekly, monthly or yearly, until you do it.';

  @override
  String get proFT11 => 'Look and widget';

  @override
  String get proFD11 =>
      'More colours and icons, and a list widget for your home screen.';

  @override
  String get proFT12 => 'More backup';

  @override
  String get proFD12 => 'Weekly automatic backup and CSV / text export.';

  @override
  String get settingsRouletteCats => 'Roulette categories';

  @override
  String get settingsRouletteCatsAll => 'All categories';

  @override
  String get wishlistReviewAfter => 'Ask \"still want it?\" after';

  @override
  String get askWhereOnShare => 'After sharing, ask where it goes';

  @override
  String get askWhereOnShareSub => 'If off, everything goes to the inbox.';

  @override
  String get ideaReviewEvery => 'Review ideas every';

  @override
  String get ideaReviewMonthly => 'Monthly review reminder';
}
