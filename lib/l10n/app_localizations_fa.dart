// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppL10nFa extends AppL10n {
  AppL10nFa([String locale = 'fa']) : super(locale);

  @override
  String get appName => 'بعداً';

  @override
  String get tagline => 'الان لازم نیست؛ فقط فراموشش نکن.';

  @override
  String get ok => 'باشه';

  @override
  String get cancel => 'انصراف';

  @override
  String get save => 'ذخیره';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'ویرایش';

  @override
  String get close => 'بستن';

  @override
  String get retry => 'تلاش دوباره';

  @override
  String get done => 'انجام شد';

  @override
  String get next => 'بعدی';

  @override
  String get skip => 'رد کردن';

  @override
  String get continueLabel => 'ادامه';

  @override
  String get undo => 'برگردان';

  @override
  String get add => 'اضافه کن';

  @override
  String get search => 'جستجو';

  @override
  String get all => 'همه';

  @override
  String get none => 'هیچ‌کدام';

  @override
  String get proBadge => 'Pro';

  @override
  String get loading => 'در حال بارگذاری…';

  @override
  String get errorGeneric => 'یه مشکلی پیش اومد. دوباره تلاش کن.';

  @override
  String get errorLoad => 'بارگذاری اطلاعات ناموفق بود.';

  @override
  String get navHome => 'خانه';

  @override
  String get navList => 'بعداً';

  @override
  String get navHistory => 'تاریخچه';

  @override
  String get navSettings => 'تنظیمات';

  @override
  String get semAdd => 'افزودن مورد جدید';

  @override
  String get onb1Title => 'الان لازم نیست.';

  @override
  String get onb1Body => 'ذهنت را از هزارتا کار نیمه‌کاره خالی کن.';

  @override
  String get onb2Title => 'هر چیزی را که نمی‌خواهی فراموش کنی، اینجا نگه دار.';

  @override
  String get onb2Body =>
      'مقاله، فیلم، خرید، ایده، لینک، یه تماس… فقط بنویس یا از هر برنامه‌ای «اشتراک‌گذاری» کن.';

  @override
  String get onb3Title => 'بعداً خودش به تو یادآوری می‌کند.';

  @override
  String get onb3Body =>
      'یه تاریخ و ساعت بده؛ یا نده و هر وقت وقت آزاد داشتی بگو «یه مورد بهم بده».';

  @override
  String get onb4Title => 'بدون حساب کاربری، بدون سرور.';

  @override
  String get onb4Body =>
      'اطلاعاتت فقط روی دستگاه خودت می‌ماند و حتی بدون اینترنت کار می‌کند.';

  @override
  String get onb5Title => 'آماده‌ای؟';

  @override
  String get onb5Body => 'هر چیزی که الان وقتش نیست را همین‌جا بگذار.';

  @override
  String get onbStart => 'بزن بریم';

  @override
  String get legalTitle => 'قبل از شروع';

  @override
  String get legalIntro =>
      'لطفاً قوانین استفاده و سیاست حریم خصوصی را بخوان و تأیید کن.';

  @override
  String get termsTitle => 'قوانین استفاده';

  @override
  String get privacyTitle => 'سیاست حریم خصوصی';

  @override
  String get legalAccept =>
      'قوانین استفاده و سیاست حریم خصوصی را خوانده‌ام و می‌پذیرم.';

  @override
  String get legalContinue => 'تأیید و ورود';

  @override
  String get legalLoadError => 'بارگذاری متن ناموفق بود.';

  @override
  String get legalUpdatedTitle => 'به‌روزرسانی قوانین';

  @override
  String homeWaiting(String count) {
    return '$count مورد منتظر توست';
  }

  @override
  String get homeWaitingOne => 'یک مورد منتظر توست';

  @override
  String get homeEmptyTitle => 'هنوز چیزی برای بعداً نداری.';

  @override
  String get homeEmptyBody => 'چه خوب. فعلاً ذهنت آزاده. 🌱';

  @override
  String get homeEmptyCta => 'اولین مورد را اضافه کن';

  @override
  String get statToday => 'امروز';

  @override
  String get statWeek => 'این هفته';

  @override
  String get statNoDate => 'بدون تاریخ';

  @override
  String get statOverdue => 'عقب‌افتاده';

  @override
  String get statStale => 'مانده‌ها';

  @override
  String get pickCardTitle => '🎯 یه مورد بهم بده';

  @override
  String get pickCardSub => 'نمی‌دونی الان چی کار کنی؟ من انتخاب می‌کنم.';

  @override
  String get timeCardTitle => 'الان چقدر وقت داری؟';

  @override
  String minutesN(String n) {
    return '$n دقیقه';
  }

  @override
  String get hourOne => '۱ ساعت';

  @override
  String get anyTime => 'مهم نیست';

  @override
  String get homeTodaySection => 'امروز و عقب‌افتاده‌ها';

  @override
  String get homeSeeAll => 'همه';

  @override
  String staleBannerTitle(String count) {
    return '$count مورد مدت‌هاست منتظرند';
  }

  @override
  String get staleBannerBody => 'یه نگاه سریع بنداز؛ نگه دار یا رها کن.';

  @override
  String get decideTitle => 'تصمیم نگیر';

  @override
  String get decideIntro => 'نمی‌دونم الان چی کار کنم.';

  @override
  String get decideLabel => '🎯 پیشنهاد بعدی تو:';

  @override
  String decideAbout(String n) {
    return 'حدود $n دقیقه';
  }

  @override
  String get decideDo => 'انجامش می‌دم';

  @override
  String get decideLater => 'بعداً';

  @override
  String get decideAnother => 'مورد دیگری بده';

  @override
  String get decideNone => 'چیزی برای پیشنهاد ندارم';

  @override
  String get decideNoneBody => 'لیستت خالیه یا چیزی به این زمان نمی‌خوره. 🌱';

  @override
  String get decideNoMore => 'مورد دیگری نمانده.';

  @override
  String get decideDoneToast => 'آفرین! انجام شد ✓';

  @override
  String get smartPickTitle => 'پیشنهاد هوشمند';

  @override
  String get smartPickHeader => 'الان چقدر وقت داری؟';

  @override
  String smartPickResultsFor(String time) {
    return 'مناسب $time';
  }

  @override
  String get smartPickResultsAny => 'پیشنهادها';

  @override
  String get smartPickEmpty => 'برای این مدت چیزی پیدا نکردم.';

  @override
  String get smartPickProHint => 'پیشنهاد پیشرفته (اولویت و فیلتر دسته) با Pro';

  @override
  String get smartPickCategory => 'فقط از دسته‌ی…';

  @override
  String get smartPickAllCategories => 'همه‌ی دسته‌ها';

  @override
  String get listTitle => 'بعداً';

  @override
  String get searchHint => 'جستجو در بعداً…';

  @override
  String get searchAdvancedHint =>
      'جستجوی پیشرفته (برچسب، لینک، یادداشت) با Pro';

  @override
  String get filterAll => 'همه';

  @override
  String get filterToday => 'امروز';

  @override
  String get filterWeek => 'این هفته';

  @override
  String get filterNoDate => 'بدون تاریخ';

  @override
  String get filterOverdue => 'عقب‌افتاده';

  @override
  String get filterHigh => 'اولویت بالا';

  @override
  String get filterStale => 'مانده‌ها';

  @override
  String get sortTitle => 'مرتب‌سازی';

  @override
  String get sortNewest => 'جدیدترین';

  @override
  String get sortOldest => 'قدیمی‌ترین';

  @override
  String get sortDeadline => 'نزدیک‌ترین موعد';

  @override
  String get sortPriority => 'اولویت';

  @override
  String get sortShortest => 'کوتاه‌ترین کار';

  @override
  String get sortLongest => 'طولانی‌ترین کار';

  @override
  String get listEmptyFiltered => 'چیزی پیدا نشد';

  @override
  String get listEmptyFilteredBody => 'فیلتر یا عبارت جستجو را عوض کن.';

  @override
  String get smartFiltersPro => 'فیلترهای هوشمند با Pro';

  @override
  String get overdue => 'عقب‌افتاده';

  @override
  String waitingDays(String n) {
    return '$n روز است منتظر';
  }

  @override
  String get dueToday => 'امروز';

  @override
  String get dueTomorrow => 'فردا';

  @override
  String atTime(String time) {
    return 'ساعت $time';
  }

  @override
  String get noDate => 'بدون تاریخ';

  @override
  String get priorityHigh => 'اولویت بالا';

  @override
  String get priorityNormal => 'عادی';

  @override
  String get priorityLow => 'کم';

  @override
  String get priority => 'اولویت';

  @override
  String get duration => 'زمان تخمینی';

  @override
  String minutesShort(String n) {
    return '$n د';
  }

  @override
  String get reminder => 'یادآوری';

  @override
  String get repeat => 'تکرار';

  @override
  String get repeatNone => 'یک‌بار';

  @override
  String get repeatDaily => 'هر روز';

  @override
  String get repeatWeekly => 'هر هفته';

  @override
  String get repeatMonthly => 'هر ماه';

  @override
  String snoozedTimes(String n) {
    return '$n بار به بعد رفته';
  }

  @override
  String get itemDone => 'انجام شد';

  @override
  String get itemSnooze => 'بعداً';

  @override
  String get itemDrop => 'بی‌خیالش شدم';

  @override
  String get itemOpenLink => 'باز کردن لینک';

  @override
  String get itemLinkFailed => 'لینک باز نشد.';

  @override
  String get toastDone => 'انجام شد ✓';

  @override
  String get toastDropped => 'کنار گذاشته شد';

  @override
  String get toastDeleted => 'حذف شد';

  @override
  String toastSnoozed(String when) {
    return 'منتقل شد به $when';
  }

  @override
  String get toastSaved => 'ذخیره شد';

  @override
  String get toastAdded => 'به بعداً اضافه شد';

  @override
  String get toastReopened => 'به لیست برگشت';

  @override
  String get confirmDeleteTitle => 'حذف این مورد؟';

  @override
  String get confirmDeleteBody => 'این مورد برای همیشه پاک می‌شود.';

  @override
  String createdOn(String date) {
    return 'ثبت‌شده در $date';
  }

  @override
  String get itemNotFound => 'این مورد دیگر وجود ندارد.';

  @override
  String get addTitle => 'چیزی برای بعداً';

  @override
  String get editTitle => 'ویرایش';

  @override
  String get titleHint => 'چی رو بذارم برای بعداً؟';

  @override
  String get titleRequired => 'یه عنوان بنویس';

  @override
  String get moreOptions => 'گزینه‌های بیشتر';

  @override
  String get lessOptions => 'کمتر';

  @override
  String get fieldDescription => 'توضیح';

  @override
  String get fieldNote => 'یادداشت';

  @override
  String get fieldUrl => 'لینک';

  @override
  String get urlInvalid => 'لینک معتبر نیست (فقط http و https).';

  @override
  String get fieldTags => 'برچسب‌ها';

  @override
  String get fieldTagsHint => 'با کاما جدا کن';

  @override
  String get fieldCategory => 'دسته';

  @override
  String get fieldDate => 'تاریخ';

  @override
  String get fieldTime => 'ساعت';

  @override
  String get datePick => 'انتخاب تاریخ…';

  @override
  String get timePick => 'انتخاب ساعت…';

  @override
  String get timeNone => 'بدون ساعت';

  @override
  String get reminderOff => 'بدون یادآوری';

  @override
  String get reminderAtTime => 'سر وقت';

  @override
  String get reminderBefore10 => '۱۰ دقیقه قبل';

  @override
  String get reminderBefore60Label => '۱ ساعت قبل';

  @override
  String get reminderBefore1d => '۱ روز قبل';

  @override
  String get reminderNeedsDate => 'برای یادآوری یه تاریخ لازمه.';

  @override
  String reminderAtDefault(String time) {
    return 'ساعت $time (پیش‌فرض)';
  }

  @override
  String get repeatProHint => 'یادآوری تکرارشونده با Pro';

  @override
  String get durationUnknown => 'نامشخص';

  @override
  String get durationCustom => 'دلخواه';

  @override
  String get durationCustomHint => 'چند دقیقه؟';

  @override
  String get quickToday => 'امروز';

  @override
  String get quickTomorrow => 'فردا';

  @override
  String get quickWeekend => 'آخر هفته';

  @override
  String get quickNextWeek => 'هفته بعد';

  @override
  String get quickNoDate => 'بدون تاریخ';

  @override
  String get quickCustom => 'تاریخ دیگر';

  @override
  String get discardTitle => 'تغییرات ذخیره نشود؟';

  @override
  String get discardBody => 'چیزی که نوشته‌ای ذخیره نشده.';

  @override
  String get discard => 'دور بینداز';

  @override
  String get snoozeTitle => 'به کِی موکولش کنم؟';

  @override
  String get snoozeTonight => 'امشب';

  @override
  String get snoozeTomorrow => 'فردا';

  @override
  String get snoozeWeekend => 'آخر هفته';

  @override
  String get snoozeNextWeek => 'هفته بعد';

  @override
  String get snoozeNextMonth => 'ماه بعد';

  @override
  String get snoozeCustom => 'تاریخ دلخواه';

  @override
  String get snoozeNoDate => 'بدون تاریخ';

  @override
  String get datePickerTitle => 'انتخاب تاریخ';

  @override
  String get prevMonth => 'ماه قبل';

  @override
  String get nextMonth => 'ماه بعد';

  @override
  String get today => 'امروز';

  @override
  String get clear => 'پاک کردن';

  @override
  String get staleTitle => 'بعداً، نه هیچ‌وقت';

  @override
  String staleQuestion(String days) {
    return 'این مورد $days روز است منتظر توست.\nهنوز می‌خواهی نگهش داری؟';
  }

  @override
  String get staleKeep => 'نگه دار';

  @override
  String get staleSnooze => 'برای بعداً تنظیم کن';

  @override
  String get staleDone => 'انجام شد';

  @override
  String get staleDrop => 'بی‌خیالش شدم';

  @override
  String staleProgress(String i, String n) {
    return '$i از $n';
  }

  @override
  String get staleAllDone => 'همه‌چی مرتبه ✨';

  @override
  String get staleAllDoneBody => 'لیستت سبک‌تر شد.';

  @override
  String get staleNoPressure => 'بدون عجله؛ هیچ تصمیمی اشتباه نیست.';

  @override
  String get historyTitle => 'تاریخچه';

  @override
  String get periodToday => 'امروز';

  @override
  String get periodWeek => 'این هفته';

  @override
  String get periodMonth => 'این ماه';

  @override
  String get periodAll => 'همه';

  @override
  String get historyEmpty => 'هنوز چیزی در تاریخچه نیست';

  @override
  String get historyEmptyBody =>
      'کارهای انجام‌شده و کنار گذاشته‌شده اینجا می‌مانند.';

  @override
  String historyDoneAt(String date) {
    return 'انجام شد · $date';
  }

  @override
  String historyDroppedAt(String date) {
    return 'کنار گذاشته شد · $date';
  }

  @override
  String get historyRestore => 'برگردان به لیست';

  @override
  String get historyProNote => 'تاریخچه‌ی کامل (ماه و همه) با Pro';

  @override
  String get historyDisabled =>
      'ثبت تاریخچه خاموش است؛ فقط آمار ناشناس نگه داشته می‌شود.';

  @override
  String get statsTitle => 'آمار';

  @override
  String get statsDone => 'انجام‌شده';

  @override
  String get statsDropped => 'کنار گذاشته‌شده';

  @override
  String get statsDeleted => 'حذف‌شده';

  @override
  String get statsSnoozed => 'بار به تعویق افتاده';

  @override
  String get statsActive => 'فعال';

  @override
  String get statsAvgWait => 'میانگین ماندن تا انجام';

  @override
  String statsDaysValue(String n) {
    return '$n روز';
  }

  @override
  String get statsTopCategory => 'محبوب‌ترین دسته';

  @override
  String get statsThisWeek => 'انجام‌شده در این هفته';

  @override
  String get statsProLocked => 'آمار کامل با Pro';

  @override
  String get statsNoData => '—';

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get secAppearance => 'ظاهر';

  @override
  String get theme => 'تم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تیره';

  @override
  String get themeSystem => 'پیش‌فرض سیستم';

  @override
  String get accent => 'رنگ اصلی';

  @override
  String get accentIndigo => 'بنفش';

  @override
  String get accentTeal => 'فیروزه‌ای';

  @override
  String get accentRose => 'رُز';

  @override
  String get accentAmber => 'کهربایی';

  @override
  String get accentSlate => 'خاکستری';

  @override
  String get appIcon => 'آیکون برنامه';

  @override
  String get iconClassic => 'کلاسیک';

  @override
  String get iconTeal => 'فیروزه‌ای';

  @override
  String get iconRose => 'رُز';

  @override
  String get iconDark => 'تیره';

  @override
  String get iconChangeNote =>
      'با تغییر آیکون ممکن است چند لحظه‌ی دیگر در لانچر عوض شود.';

  @override
  String get secReminders => 'یادآوری';

  @override
  String get remindersToggle => 'یادآوری‌ها';

  @override
  String get defaultReminderTime => 'ساعت پیش‌فرض یادآوری';

  @override
  String get privateNotifications => 'پنهان کردن متن در اعلان';

  @override
  String get privateNotificationsSub =>
      'عنوان موردها روی صفحه‌ی قفل دیده نشود.';

  @override
  String get notifPermission => 'دسترسی اعلان';

  @override
  String get notifPermissionOn => 'فعال است';

  @override
  String get notifPermissionOff => 'غیرفعال است؛ برای باز کردن تنظیمات بزن';

  @override
  String get exactAlarm => 'دقت یادآوری';

  @override
  String get exactAlarmOk => 'دقیق';

  @override
  String get exactAlarmOff => 'تقریبی؛ «هشدار دقیق» مجاز نشده';

  @override
  String get batteryOptimization => 'محدودیت باتری';

  @override
  String get batteryOptimizationSub =>
      'بعضی گوشی‌ها یادآوری را می‌بندند؛ بزن تا تنظیمات باز شود.';

  @override
  String get sendTestNotification => 'ارسال اعلان آزمایشی';

  @override
  String get testNotificationSent => 'اعلان آزمایشی ارسال شد.';

  @override
  String get secGeneral => 'عمومی';

  @override
  String get language => 'زبان';

  @override
  String get langFa => 'فارسی';

  @override
  String get langEn => 'English';

  @override
  String get calendar => 'تقویم';

  @override
  String get calJalali => 'شمسی';

  @override
  String get calGregorian => 'میلادی';

  @override
  String get weekStart => 'شروع هفته';

  @override
  String get weekendDay => 'روز آخر هفته';

  @override
  String get keepHistory => 'نگه داشتن تاریخچه';

  @override
  String get keepHistorySub =>
      'موردهای انجام‌شده و کنار گذاشته‌شده در آرشیو بمانند.';

  @override
  String get staleAfter => 'مرور مانده‌ها بعد از';

  @override
  String daysN(String n) {
    return '$n روز';
  }

  @override
  String get secData => 'اطلاعات';

  @override
  String get backupRestore => 'پشتیبان‌گیری و بازیابی';

  @override
  String get categoriesManage => 'مدیریت دسته‌ها';

  @override
  String get secAbout => 'درباره';

  @override
  String get proSettingsTitle => 'بعداً Pro';

  @override
  String get proSettingsFree => 'نسخه‌ی رایگان';

  @override
  String proSettingsActive(String date) {
    return 'فعال تا $date';
  }

  @override
  String get about => 'درباره‌ی برنامه';

  @override
  String get aboutBody =>
      'بعداً یک برنامه‌ی کوچک و سریع برای نگه‌داشتن چیزهایی است که الان وقتشان نیست؛ بدون حساب کاربری و بدون سرور.';

  @override
  String get aboutOffline => 'همه‌ی اطلاعات فقط روی دستگاه تو ذخیره می‌شود.';

  @override
  String get aboutLicenses => 'مجوزهای متن‌باز';

  @override
  String get aboutContact => 'پشتیبانی';

  @override
  String get version => 'نسخه';

  @override
  String versionValue(String v) {
    return 'نسخه $v';
  }

  @override
  String get resetApp => 'پاک کردن همه‌ی اطلاعات';

  @override
  String get resetAppSub => 'همه‌ی موردها، دسته‌ها، تاریخچه و تنظیمات';

  @override
  String get resetConfirmTitle => 'همه‌چیز پاک شود؟';

  @override
  String get resetConfirmBody =>
      'همه‌ی موردها، دسته‌ها، تاریخچه و تنظیمات این برنامه برای همیشه پاک می‌شود. این کار قابل بازگشت نیست.\n(اشتراک Pro از بین نمی‌رود.)\nپیشنهاد می‌کنیم اول پشتیبان بگیری.';

  @override
  String resetTypeHint(String word) {
    return 'برای تأیید، کلمه‌ی «$word» را بنویس';
  }

  @override
  String get resetWord => 'پاک';

  @override
  String get resetAction => 'پاک کردن همه‌چیز';

  @override
  String get resetDone => 'همه‌چیز پاک شد.';

  @override
  String categoryName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'work': 'کار',
      'read': 'خواندنی',
      'watch': 'دیدنی',
      'buy': 'خرید',
      'idea': 'ایده',
      'link': 'لینک',
      'people': 'افراد',
      'other': 'سایر',
    });
    return '$_temp0';
  }

  @override
  String get categoryNew => 'دسته‌ی جدید';

  @override
  String get categoryEdit => 'ویرایش دسته';

  @override
  String get categoryNameHint => 'نام دسته';

  @override
  String get categoryEmojiHint => 'ایموجی';

  @override
  String categoryLimit(String free, String pro) {
    return 'در نسخه‌ی رایگان تا $free دسته‌ی سفارشی می‌توانی بسازی؛ Pro تا $pro دسته.';
  }

  @override
  String get categoryDeleteTitle => 'این دسته حذف شود؟';

  @override
  String get categoryDeleteBody => 'موردهای این دسته به «سایر» منتقل می‌شوند.';

  @override
  String get categoryBuiltin => 'دسته‌ی پیش‌فرض';

  @override
  String get backupTitle => 'پشتیبان‌گیری و بازیابی';

  @override
  String get backupIntro =>
      'اطلاعات فقط روی همین دستگاه است. برای جابه‌جایی یا نصب مجدد، از آن‌ها فایل پشتیبان بگیر.';

  @override
  String get backupExport => 'خروجی گرفتن از اطلاعات';

  @override
  String get backupExportSub =>
      'یک فایل ‎.later‎ با همه‌ی موردها، دسته‌ها، تاریخچه و تنظیمات';

  @override
  String get backupImport => 'بازیابی از فایل';

  @override
  String get backupImportSub => 'فایل پشتیبانِ قبلی را انتخاب کن';

  @override
  String backupLast(String date) {
    return 'آخرین پشتیبان: $date';
  }

  @override
  String get backupNever => 'هنوز پشتیبان نگرفته‌ای';

  @override
  String get backupExported => 'پشتیبان ذخیره شد ✓';

  @override
  String get backupAuto => 'پشتیبان خودکار هفتگی';

  @override
  String get backupAutoSub =>
      'تا ۵ نسخه در حافظه‌ی خصوصی برنامه نگه داشته می‌شود (Pro).';

  @override
  String get backupAdvancedExport => 'خروجی‌های بیشتر (Pro)';

  @override
  String get exportCsv => 'خروجی CSV';

  @override
  String get exportText => 'خروجی متنی (Markdown)';

  @override
  String get exportSaved => 'فایل ذخیره شد ✓';

  @override
  String get restoreConfirmTitle => 'بازیابی اطلاعات؟';

  @override
  String restoreConfirmReplace(String current, String date, String incoming) {
    return 'اطلاعات فعلی ($current مورد) با محتوای فایل ($incoming مورد، ساخته‌شده در $date) جایگزین می‌شود.\nپیش از آن یک نسخه‌ی ایمنی از اطلاعات فعلی نگه داشته می‌شود.';
  }

  @override
  String restoreConfirmEmpty(String date, String incoming) {
    return 'فایل شامل $incoming مورد است (ساخته‌شده در $date).';
  }

  @override
  String get restoreAction => 'بازیابی';

  @override
  String get restoreDone => 'اطلاعات بازیابی شد ✓';

  @override
  String get restoreProRestored => 'اشتراک Pro هم از پشتیبان بازیابی شد.';

  @override
  String get backupErrEmpty => 'فایل خالی است.';

  @override
  String get backupErrTooLarge => 'فایل خیلی بزرگ است.';

  @override
  String get backupErrNotJson => 'فایل خراب یا ناقص است.';

  @override
  String get backupErrNotBackup => 'این فایل پشتیبان «بعداً» نیست.';

  @override
  String get backupErrMissing => 'فایل ناقص است.';

  @override
  String get backupErrFuture =>
      'این پشتیبان با نسخه‌ی جدیدتری از برنامه ساخته شده. برنامه را به‌روزرسانی کن.';

  @override
  String get backupErrUnsupported => 'قالب این پشتیبان دیگر پشتیبانی نمی‌شود.';

  @override
  String get backupErrChecksum => 'فایل آسیب دیده یا ویرایش شده است.';

  @override
  String get backupErrInvalid => 'محتوای فایل معتبر نیست.';

  @override
  String get backupErrMigration => 'به‌روزرسانی قالب فایل ناموفق بود.';

  @override
  String get backupErrGeneric =>
      'بازیابی انجام نشد. اطلاعات فعلی دست‌نخورده ماند.';

  @override
  String get backupNoChange => 'اطلاعات فعلی تغییری نکرد.';

  @override
  String get proTitle => 'بعداً Pro';

  @override
  String get proHeadline =>
      'امکانات بیشتر برای کسانی که «بعداً» را زیاد استفاده می‌کنند.';

  @override
  String get proFreeNote =>
      'نسخه‌ی رایگان همچنان کامل قابل استفاده است و هیچ اطلاعاتی محدود یا حذف نمی‌شود.';

  @override
  String proActiveUntil(String date) {
    return 'فعال تا $date';
  }

  @override
  String proRemaining(String n) {
    return '$n روز باقی مانده';
  }

  @override
  String get proExpiredNote =>
      'اشتراک Pro تمام شده؛ اطلاعاتت سالم است و فقط امکانات Pro غیرفعال شده‌اند.';

  @override
  String get proPlan1 => '۱ ماهه';

  @override
  String get proPlan3 => '۳ ماهه';

  @override
  String get proPlan6 => '۶ ماهه';

  @override
  String get proPlanDay1 => '۱ روزه (آزمایشی)';

  @override
  String get proPlanDay7 => '۷ روزه (آزمایشی)';

  @override
  String priceToman(String price) {
    return '$price تومان';
  }

  @override
  String get proBuy => 'خرید';

  @override
  String get proExtend => 'تمدید';

  @override
  String get proStackNote =>
      'با خرید جدید، روزهای باقی‌مانده حفظ می‌شود و مدت تازه به آن اضافه می‌شود.';

  @override
  String get proRestore => 'بازیابی خریدها';

  @override
  String proRestored(String n) {
    return '$n خرید بازیابی شد';
  }

  @override
  String get proNothingToRestore => 'خرید بازیابی‌نشده‌ای پیدا نشد.';

  @override
  String get proPurchaseSuccess => 'Pro فعال شد 🎉';

  @override
  String get proPurchaseCancelled => 'خرید لغو شد.';

  @override
  String get proPurchaseUnavailable =>
      'سرویس پرداخت در دسترس نیست. برنامه‌ی کافه‌بازار را بررسی کن.';

  @override
  String get proPurchaseFailed => 'خرید انجام نشد. دوباره تلاش کن.';

  @override
  String get proTamper =>
      'اطلاعات اشتراک معتبر نبود و بازنشانی شد. اگر خرید کرده‌ای، «بازیابی خریدها» را بزن.';

  @override
  String get proF1 => 'پیشنهاد هوشمند پیشرفته';

  @override
  String get proF2 => 'فیلترها و جستجوی پیشرفته';

  @override
  String get proF3 => 'آمار و تاریخچه‌ی کامل';

  @override
  String get proF4 => 'دسته‌های سفارشی بیشتر';

  @override
  String get proF5 => 'یادآوری تکرارشونده و پیشرفته';

  @override
  String get proF6 => 'ویجت‌های پیشرفته';

  @override
  String get proF7 => 'تم‌ها و آیکون‌های بیشتر';

  @override
  String get proF8 => 'پشتیبان خودکار و خروجی‌های بیشتر';

  @override
  String get proLockedTitle => 'این امکان مخصوص Pro است';

  @override
  String get proLockedBody =>
      'با Pro این و چند امکان دیگر باز می‌شود. نسخه‌ی رایگان همچنان کامل است.';

  @override
  String get proSeePlans => 'دیدن پلن‌ها';

  @override
  String get notNow => 'حالا نه';

  @override
  String get qaTitle => 'ابزار تست (فقط نسخه‌ی آزمایشی)';

  @override
  String get qaNote => 'این بخش در نسخه‌ی بازار وجود ندارد.';

  @override
  String qaGrantPlan(String plan) {
    return 'شبیه‌سازی خرید $plan';
  }

  @override
  String get qaClearPro => 'حذف Pro';

  @override
  String qaAdvance(String n) {
    return 'جلو بردن ساعت برنامه: $n روز';
  }

  @override
  String get qaResetTime => 'بازنشانی ساعت شبیه‌سازی‌شده';

  @override
  String qaClock(String date) {
    return 'ساعت برنامه: $date';
  }

  @override
  String qaSeed(String n) {
    return 'افزودن $n مورد نمونه';
  }

  @override
  String qaSeeded(String n) {
    return '$n مورد اضافه شد.';
  }

  @override
  String get qaNotifNow => 'اعلان همین حالا';

  @override
  String qaNotifIn(String s) {
    return 'اعلان تا $s ثانیه‌ی دیگر';
  }

  @override
  String qaProState(String state) {
    return 'وضعیت Pro: $state';
  }

  @override
  String get notifChannelName => 'یادآوری‌ها';

  @override
  String get notifChannelDescription =>
      'یادآوری موردهایی که برای بعداً گذاشته‌ای';

  @override
  String get notifActionDone => 'انجام شد';

  @override
  String get notifActionTomorrow => 'فردا';

  @override
  String get notifPrivateBody => 'یه مورد منتظر توست';

  @override
  String get notifBodyGeneric => 'بعداً';

  @override
  String get notifTestTitle => 'اعلان آزمایشی';

  @override
  String get notifTestBody => 'اگر این را می‌بینی، اعلان‌ها کار می‌کنند ✓';

  @override
  String get reminderPermissionBanner =>
      'اجازه‌ی اعلان داده نشده؛ یادآوری‌ها نمایش داده نمی‌شوند.';

  @override
  String get reminderSyncFailed => 'برخی یادآوری‌ها ثبت نشدند.';

  @override
  String get reminderApproximate =>
      'یادآوری‌ها تقریبی‌اند؛ برای دقت بیشتر «هشدار دقیق» را مجاز کن.';

  @override
  String get permissionDeniedTitle => 'اجازه‌ی اعلان لازم است';

  @override
  String get permissionDeniedBody =>
      'برای اینکه بعداً بتونم یادت بندازم، اجازه‌ی اعلان را فعال کن.';

  @override
  String get openSettings => 'باز کردن تنظیمات';

  @override
  String shareAdded(String title) {
    return '«$title» به بعداً اضافه شد';
  }

  @override
  String widgetWaiting(String n) {
    return '$n مورد منتظرند';
  }

  @override
  String get widgetEmpty => 'چیزی منتظر نیست 🌱';

  @override
  String get widgetAdd => '+ اضافه کن';

  @override
  String get widgetPick => '🎯 پیشنهاد';

  @override
  String get widgetProOnly => 'ویجت پیشرفته مخصوص Pro است';

  @override
  String get widgetSuggestion => 'پیشنهاد';

  @override
  String get shortcutAdd => 'اضافه کردن';

  @override
  String get shortcutPick => 'یه مورد بهم بده';

  @override
  String get shortcutSearch => 'جستجو';

  @override
  String get licensesLegalese => 'ساخته‌شده با فلاتر. فونت وزیرمتن (مجوز OFL).';
}
