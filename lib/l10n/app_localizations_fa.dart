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
  String get errorGeneric => 'یه مشکلی پیش اومد. دوباره امتحان کن.';

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
  String get onb1Body =>
      'لازم نیست همه‌چیز همین الان تموم بشه. چیزی که وقتش نیست رو بذار کنار.';

  @override
  String get onb2Title => 'هر چی نمی‌خوای یادت بره، اینجا بذارش.';

  @override
  String get onb2Body =>
      'مقاله، فیلم، خرید، ایده، یه تماس. بنویس، یا از هر برنامه‌ای «اشتراک‌گذاری» رو بزن.';

  @override
  String get onb3Title => 'بعداً خودش به تو یادآوری می‌کند.';

  @override
  String get onb3Body =>
      'تاریخ و ساعت بده تا خودش یادآوری کنه. ندادی هم مهم نیست، وقتی وقت داشتی قرعه بزن.';

  @override
  String get onb4Title => 'بدون حساب کاربری، بدون سرور.';

  @override
  String get onb4Body =>
      'اطلاعاتت فقط روی گوشی خودته و بدون اینترنت هم کار می‌کنه.';

  @override
  String get onb5Title => 'آماده‌ای؟';

  @override
  String get onb5Body => 'هر چی الان وقتش نیست رو همین‌جا بذار.';

  @override
  String get onbStart => 'بزن بریم';

  @override
  String get legalTitle => 'قبل از شروع';

  @override
  String get legalIntro =>
      'قبل از شروع، قوانین استفاده و سیاست حریم خصوصی رو بخون و تأیید کن.';

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
    return '$count چیز منتظرته';
  }

  @override
  String get homeWaitingOne => 'یه چیز منتظرته';

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
  String get pickCardTitle => 'قرعه بعداً';

  @override
  String get pickCardSub => 'نمی‌دونی الان چی‌کار کنی؟ بذار قرعه تصمیم بگیره.';

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
  String get decideLabel => 'قرعه این شد';

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
  String get decideDoneToast => 'انجام شد ✓';

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
  String get smartPickProHint => 'فیلتر دسته و اولویت با Pro';

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
    return 'این $days روزه منتظرته.\nهنوز می‌خوای نگهش داری؟';
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
  String get staleAllDone => 'همه‌چی مرتبه';

  @override
  String get staleAllDoneBody => 'لیستت سبک‌تر شد.';

  @override
  String get staleNoPressure => 'عجله‌ای نیست. هر تصمیمی بگیری درسته.';

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
  String get historyProNote => 'تاریخچه‌ی کامل (ماه و همه‌ی زمان‌ها) با Pro';

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
      'کارهای انجام‌شده و کنار گذاشته‌شده تو تاریخچه بمونن.';

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
      'بعداً جای چیزهاییه که الان وقتشون نیست. بدون حساب کاربری، بدون سرور.';

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
      'همه‌ی موردها، دسته‌ها، تاریخچه و تنظیمات این برنامه برای همیشه پاک می‌شه و برنمی‌گرده. اشتراک Pro از بین نمی‌ره. بهتره اول یه پشتیبان بگیری.';

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
    return 'نسخه‌ی رایگان $free دسته‌ی سفارشی داره. با Pro تا $pro تا می‌شه.';
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
      'اطلاعاتت فقط روی همین گوشیه. قبل از عوض کردن گوشی یا نصب دوباره، یه فایل پشتیبان بگیر.';

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
      'اگه زیاد از «بعداً» استفاده می‌کنی، Pro کارت رو راحت‌تر می‌کنه.';

  @override
  String get proFreeNote =>
      'نسخه‌ی رایگان ناقص نیست. اگه Pro تموم بشه هم چیزی از اطلاعاتت پاک یا قفل نمی‌شه.';

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
      'اشتراک Pro تموم شده. اطلاعاتت سر جاشه؛ فقط قابلیت‌های Pro خاموش شدن.';

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
      'اگه وسط اشتراک دوباره بخری، روزهای مونده از بین نمی‌رن؛ مدت جدید بهشون اضافه می‌شه.';

  @override
  String get proRestore => 'بازیابی خریدها';

  @override
  String proRestored(String n) {
    return '$n خرید برگشت';
  }

  @override
  String get proNothingToRestore => 'خرید بازیابی‌نشده‌ای پیدا نشد.';

  @override
  String get proPurchaseSuccess => 'Pro فعال شد';

  @override
  String get proPurchaseCancelled => 'خرید لغو شد.';

  @override
  String get proPurchaseUnavailable =>
      'سرویس پرداخت در دسترس نیست. برنامه‌ی کافه‌بازار را بررسی کن.';

  @override
  String get proPurchaseFailed => 'خرید انجام نشد. دوباره تلاش کن.';

  @override
  String get proTamper =>
      'اطلاعات اشتراک درست نبود و پاک شد. اگه خرید کرده بودی «بازیابی خریدها» رو بزن.';

  @override
  String get proF1 => 'قرعه‌ی هوشمند و صندوق ورودی هوشمند';

  @override
  String get proF2 => 'جستجو و فیلتر پیشرفته';

  @override
  String get proF3 => 'آمار و تاریخچه‌ی کامل';

  @override
  String get proF4 => 'دسته‌ی سفارشی بیشتر';

  @override
  String get proF5 => 'یادآوری تکرارشونده';

  @override
  String get proF6 => 'ویجت لیستی';

  @override
  String get proF7 => 'رنگ و آیکون بیشتر';

  @override
  String get proF8 => 'پشتیبان خودکار و خروجی CSV';

  @override
  String get proLockedTitle => 'این امکان مخصوص Pro است';

  @override
  String get proLockedBody =>
      'این یکی مال Pro ـه. بقیه‌ی برنامه بدون Pro هم کامل کار می‌کنه.';

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
  String get qaSeedShelves => 'نمونه‌ی قفسه‌ها، آدم‌ها و کپسول';

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
      'اجازه‌ی اعلان داده نشده، برای همین یادآوری‌ها نمایش داده نمی‌شن.';

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

  @override
  String get repeatYearly => 'هر سال';

  @override
  String get defaultCapsuleTitle => 'کپسول بی‌نام';

  @override
  String get defaultMessageTitle => 'پیام بی‌نام';

  @override
  String typeName(String id) {
    String _temp0 = intl.Intl.selectLogic(id, {
      'task': 'کار',
      'read': 'مقاله',
      'watch': 'ویدیو',
      'wishlist': 'خرید',
      'idea': 'ایده',
      'person': 'آدم',
      'capsule': 'کپسول',
      'future': 'پیام',
      'app': 'نرم‌افزار',
      'podcast': 'پادکست',
      'course': 'دوره',
      'game': 'بازی',
      'other': 'مورد',
    });
    return '$_temp0';
  }

  @override
  String daysAgo(String n) {
    return '$n روز پیش';
  }

  @override
  String get dashRoulette => 'قرعه بعداً';

  @override
  String get dashInbox => 'صندوق ورودی';

  @override
  String dashInboxCount(String n) {
    return '$n مورد منتظر مرتب شدنه';
  }

  @override
  String get dashInboxEmpty => 'صندوقت خالیه';

  @override
  String get dashShelves => 'قفسه‌ها';

  @override
  String get shelfReadTitle => 'بعداً بخون';

  @override
  String get shelfWatchTitle => 'بعداً ببین';

  @override
  String get shelfWishTitle => 'بعداً بخر';

  @override
  String get shelfIdeaTitle => 'ایده‌ها';

  @override
  String get shelfPeopleTitle => 'آدم‌ها';

  @override
  String get shelfFutureTitle => 'آینده';

  @override
  String get returnedBanner => 'یه چیز از گذشته برگشته';

  @override
  String get returnedBannerBody => 'بازش کن ببین چی بوده.';

  @override
  String ideaReviewBanner(String n) {
    return '$n ایده وقت مرور دارن';
  }

  @override
  String get searchEverywhere => 'جستجو در همه‌چیز';

  @override
  String get searchEverywhereHint => 'کار، مقاله، ایده، آدم…';

  @override
  String get searchNothing => 'چیزی پیدا نشد';

  @override
  String get searchStartTyping => 'یه کلمه بنویس.';

  @override
  String get searchDone => 'انجام‌شده';

  @override
  String get addTypeLabel => 'این چیه؟';

  @override
  String get addTypeAuto => 'بعداً مرتبش می‌کنم';

  @override
  String get fieldPrice => 'قیمت';

  @override
  String get fieldCurrency => 'واحد پول';

  @override
  String get currencyDefault => 'تومان';

  @override
  String get fieldWatchKind => 'نوع';

  @override
  String get kindVideo => 'ویدیو';

  @override
  String get kindMovie => 'فیلم';

  @override
  String get kindSeries => 'سریال';

  @override
  String get kindOther => 'دیگر';

  @override
  String get stageUnread => 'نخونده';

  @override
  String get stageReading => 'دارم می‌خونم';

  @override
  String get stageRead => 'خونده';

  @override
  String get stageArchived => 'بایگانی';

  @override
  String get stageUnwatched => 'ندیده';

  @override
  String get stageWatching => 'دارم می‌بینم';

  @override
  String get stageWatched => 'دیده';

  @override
  String get stageInterested => 'می‌خوامش';

  @override
  String get stageMaybe => 'شاید';

  @override
  String get stageBought => 'خریدم';

  @override
  String get stageNotInterested => 'دیگه نمی‌خوامش';

  @override
  String get stageIdeaNew => 'تازه';

  @override
  String get stageThinking => 'دارم فکر می‌کنم';

  @override
  String get stageDeveloping => 'دارم پرورشش می‌دم';

  @override
  String get stageIdeaArchived => 'بایگانی';

  @override
  String get stageIdeaDropped => 'ولش کردم';

  @override
  String get stageSealed => 'قفل';

  @override
  String get stageOpened => 'باز شده';

  @override
  String get markAsRead => 'خوندم';

  @override
  String get markAsWatched => 'دیدم';

  @override
  String get markAsBought => 'خریدم';

  @override
  String get itemStage => 'وضعیت';

  @override
  String get moveToShelf => 'منتقل کن به…';

  @override
  String movedTo(String shelf) {
    return 'رفت به «$shelf»';
  }

  @override
  String get shelfEmptyReadTitle => 'هنوز چیزی برای خوندن نذاشتی';

  @override
  String get shelfEmptyReadBody =>
      'لینک مقاله رو با «اشتراک‌گذاری» بفرست به بعداً.';

  @override
  String get shelfEmptyWatchTitle => 'هنوز ویدیویی نذاشتی';

  @override
  String get shelfEmptyWatchBody =>
      'لینک یوتیوب یا اسم یه فیلم رو اینجا نگه دار.';

  @override
  String get shelfEmptyWishTitle => 'فهرست خریدت خالیه';

  @override
  String get shelfEmptyWishBody =>
      'چیزی که شاید بخوای بخری رو اینجا بذار. بعد از یه مدت می‌پرسم هنوز می‌خوایش یا نه.';

  @override
  String get shelfEmptyIdeaTitle => 'هنوز ایده‌ای نذاشتی';

  @override
  String get shelfEmptyIdeaBody => 'ایده‌ها اینجا می‌مونن تا وقتش برسه.';

  @override
  String get shelfWaiting => 'در انتظار';

  @override
  String get shelfHistory => 'تاریخچه';

  @override
  String get shelfAllStages => 'همه';

  @override
  String get shelfStatsTitle => 'آمار';

  @override
  String get shelfAdvancedFilters => 'فیلتر پیشرفته';

  @override
  String get shelfHistoryPro => 'تاریخچه‌ی این قفسه با Pro';

  @override
  String get shelfCollections => 'فهرست‌ها';

  @override
  String get shelfCollectionMain => 'اصلی';

  @override
  String get collectionNew => 'فهرست جدید';

  @override
  String get collectionName => 'اسم فهرست';

  @override
  String get collectionProHint => 'چند فهرست جدا با Pro';

  @override
  String get sortByPrice => 'قیمت';

  @override
  String get sortByScore => 'امتیاز';

  @override
  String get sortByTime => 'زمان تخمینی';

  @override
  String get statsWaiting => 'در انتظار';

  @override
  String get statsFinished => 'تموم‌شده';

  @override
  String get statsThisMonth => 'این ماه';

  @override
  String get statsMinutesWaiting => 'زمان کل منتظر';

  @override
  String get statsAvgFinish => 'میانگین تا تموم شدن';

  @override
  String get statsTotalPrice => 'جمع قیمت‌ها';

  @override
  String readTimeEstimate(String n) {
    return 'حدود $n دقیقه';
  }

  @override
  String linkHost(String host) {
    return 'از $host';
  }

  @override
  String get priceNow => 'قیمت';

  @override
  String get priceSetNew => 'ثبت قیمت تازه';

  @override
  String get priceTarget => 'قیمت هدف';

  @override
  String get priceTargetReached => 'به قیمت هدفت رسیده';

  @override
  String get priceHistoryTitle => 'تاریخچه‌ی قیمت';

  @override
  String get priceHistoryEmpty => 'هنوز قیمتی ثبت نشده.';

  @override
  String get priceHint => 'مثلاً ۱۲۰۰۰۰۰';

  @override
  String get wishProHint => 'قیمت هدف و تاریخچه‌ی قیمت با Pro';

  @override
  String get wishReviewTitle => 'واقعاً هنوز می‌خوایش؟';

  @override
  String wishReviewQuestion(String days) {
    return 'این $days روزه تو فهرستته.\nهنوز می‌خوای بخریش؟';
  }

  @override
  String get wishStill => 'هنوز می‌خوام';

  @override
  String get wishUnsure => 'مطمئن نیستم';

  @override
  String get wishNo => 'دیگه نمی‌خوام';

  @override
  String get ideaReviewTitle => 'مرور ایده‌ها';

  @override
  String get ideaReviewNone => 'چیزی برای مرور نیست.';

  @override
  String get ideaReviewIntro => 'هر ایده رو یه نگاه بنداز و بگو چیکارش کنیم.';

  @override
  String get ideaScore => 'امتیاز';

  @override
  String get ideaLinks => 'ایده‌های مرتبط';

  @override
  String get ideaAddLink => 'وصل کن به یه ایده‌ی دیگه';

  @override
  String get ideaToTask => 'تبدیل به کار';

  @override
  String get ideaConverted => 'حالا یه کاره';

  @override
  String get ideaKeepThinking => 'هنوز فکر می‌کنم';

  @override
  String get ideaDevelop => 'می‌خوام پرورشش بدم';

  @override
  String get ideaArchiveIt => 'بایگانی';

  @override
  String get ideaDropIt => 'ولش کن';

  @override
  String ideaLastReviewed(String when) {
    return 'آخرین مرور: $when';
  }

  @override
  String get ideaNeverReviewed => 'هنوز مرور نشده';

  @override
  String get ideaProHint => 'امتیاز، اتصال ایده‌ها و مرور با Pro';

  @override
  String get peopleTitle => 'آدم‌ها';

  @override
  String get peopleEmptyTitle => 'هنوز کسی رو اضافه نکردی';

  @override
  String get peopleEmptyBody =>
      'مثلاً «بعداً به علی زنگ بزن». آدم رو از مخاطب‌ها انتخاب کن یا اسمش رو بنویس.';

  @override
  String get personAdd => 'آدم جدید';

  @override
  String get personFromContacts => 'انتخاب از مخاطب‌ها';

  @override
  String get personTypeName => 'فقط اسم بنویسم';

  @override
  String get personName => 'اسم';

  @override
  String get personNote => 'یادداشت';

  @override
  String personLast(String when) {
    return 'آخرین ارتباط: $when';
  }

  @override
  String get personNever => 'هنوز ارتباطی ثبت نشده';

  @override
  String personNext(String when) {
    return 'بعدی: $when';
  }

  @override
  String get personNoNext => 'یادآوری‌ای نداره';

  @override
  String get personTalked => 'همین الان صحبت کردیم';

  @override
  String get personAddReminder => 'یادآوری تازه';

  @override
  String get personReminderHint => 'مثلاً: پیام بده';

  @override
  String get personOpenContact => 'باز کردن مخاطب';

  @override
  String get personDeleteTitle => 'این آدم حذف بشه؟';

  @override
  String get personDeleteBody =>
      'یادآوری‌هاش می‌مونن ولی دیگه به این آدم وصل نیستن.';

  @override
  String get personHistory => 'تاریخچه‌ی ارتباط';

  @override
  String get personFollowUp => 'پیگیری';

  @override
  String personFollowUpDays(String n) {
    return 'بعد از $n روز یادم بنداز';
  }

  @override
  String get personGroup => 'گروه';

  @override
  String get personDueTitle => 'باید سر بزنی';

  @override
  String get personLinked => 'یادآوری‌ها';

  @override
  String get personPickerFailed => 'انتخاب مخاطب انجام نشد. اسم رو دستی بنویس.';

  @override
  String get interactionNoteHint => 'چی گفتید؟ (اختیاری)';

  @override
  String get peopleProHint => 'تاریخچه، پیگیری و «باید سر بزنی» با Pro';

  @override
  String get personContactRef => 'از مخاطب‌های گوشی';

  @override
  String get futureTitle => 'آینده';

  @override
  String get futureTabCapsules => 'کپسول زمانی';

  @override
  String get futureTabMessages => 'پیام به خودم';

  @override
  String get capsuleEmptyTitle => 'کپسولی نداری';

  @override
  String get capsuleEmptyBody =>
      'چیزی رو تا یه تاریخ از جلوی چشمت بردار. همون روز برمی‌گرده.';

  @override
  String get messageEmptyTitle => 'پیامی ننوشتی';

  @override
  String get messageEmptyBody => 'برای خودِ آینده‌ات بنویس.';

  @override
  String get capsuleNew => 'کپسول جدید';

  @override
  String get messageNew => 'پیام جدید';

  @override
  String get sealTitleHint => 'عنوان';

  @override
  String get capsuleBodyHint => 'چی رو می‌خوای بعداً ببینی؟';

  @override
  String get messageBodyHint => 'به خودِ آینده‌ات چی می‌گی؟';

  @override
  String sealOpenOn(String date) {
    return 'باز می‌شه: $date';
  }

  @override
  String get sealPickDate => 'تاریخ باز شدن';

  @override
  String get sealQuick1m => '۱ ماه دیگه';

  @override
  String get sealQuick3m => '۳ ماه دیگه';

  @override
  String get sealQuick6m => '۶ ماه دیگه';

  @override
  String get sealQuick1y => '۱ سال دیگه';

  @override
  String sealSaved(String date) {
    return 'قفل شد. تا $date دیده نمی‌شه.';
  }

  @override
  String sealLimitFree(String n) {
    return 'نسخه‌ی رایگان همزمان تا $n مورد قفل‌شده داره. با Pro نامحدوده.';
  }

  @override
  String get sealNeedsFuture => 'تاریخ باید توی آینده باشه.';

  @override
  String lockedUntil(String date) {
    return 'تا $date قفله';
  }

  @override
  String get openIt => 'بازش کن';

  @override
  String get returnedTitle => 'یه چیز از گذشته برای تو برگشته';

  @override
  String get messageReturnedTitle => 'پیامی از خودِ گذشته‌ات داری';

  @override
  String writtenOn(String date) {
    return 'نوشته‌شده در $date';
  }

  @override
  String get sealRepeat => 'تکرار';

  @override
  String get sealAttach => 'پیوست';

  @override
  String get sealAttachAdd => 'افزودن عکس یا فایل';

  @override
  String sealAttachLimit(String mb, String n) {
    return 'تا $n فایل، هر کدوم حداکثر $mb مگابایت. فقط روی همین گوشی می‌مونه.';
  }

  @override
  String get sealAttachTooBig => 'این فایل از حد مجاز بزرگ‌تره.';

  @override
  String get sealAttachFailed => 'فایل اضافه نشد.';

  @override
  String get sealProHint => 'کپسول و پیام نامحدود، پیوست، برچسب و تکرار با Pro';

  @override
  String get sealThisItem => 'برای آینده نگه دار';

  @override
  String get sealItemQuestion => 'تا کِی نبینمش؟';

  @override
  String timelineOpened(String date) {
    return 'باز شده در $date';
  }

  @override
  String get notifCapsuleTitle => 'یه چیز از گذشته برای تو برگشته';

  @override
  String get notifCapsuleBody => 'بازش کن ببین چی بوده.';

  @override
  String get notifFutureTitle => 'پیامی از خودِ گذشته‌ات داری';

  @override
  String get notifFutureBody => 'بازش کن و بخونش.';

  @override
  String get notifIdeaReviewTitle => 'وقت مرور ایده‌هاست';

  @override
  String get notifIdeaReviewBody => 'چند تا ایده منتظر یه نگاه دوباره‌ان.';

  @override
  String get inboxTitle => 'صندوق ورودی';

  @override
  String get inboxIntro =>
      'هر چی سریع ذخیره کردی اینجا می‌مونه تا تکلیفش رو روشن کنی.';

  @override
  String get inboxEmptyTitle => 'صندوق خالیه';

  @override
  String get inboxEmptyBody => 'همه‌چیز جای خودشه.';

  @override
  String get triageToday => 'امروز';

  @override
  String get triageWeek => 'این هفته';

  @override
  String get triageNoDate => 'بدون تاریخ';

  @override
  String get triageRead => 'بعداً بخون';

  @override
  String get triageWatch => 'بعداً ببین';

  @override
  String get triageWish => 'بعداً بخر';

  @override
  String get triageIdea => 'ایده';

  @override
  String get triageDone => 'انجام شد';

  @override
  String get triageDelete => 'حذف';

  @override
  String inboxSuggest(String what) {
    return 'شبیه $what به نظر می‌رسه. منتقل بشه؟';
  }

  @override
  String get inboxSuggestYes => 'آره، منتقل کن';

  @override
  String get suggestWhatRead => 'یه مقاله';

  @override
  String get suggestWhatWatch => 'یه ویدیو';

  @override
  String get suggestWhatWish => 'یه چیز برای خرید';

  @override
  String get suggestWhatIdea => 'یه ایده';

  @override
  String get suggestWhatPerson => 'یه یادآوری برای یه آدم';

  @override
  String get inboxProHint => 'پیشنهاد خودکار مقصد با Pro';

  @override
  String get rouletteTitle => 'قرعه بعداً';

  @override
  String get roulettePick => 'انتخاب کن';

  @override
  String get rouletteSpinning => 'دارم انتخاب می‌کنم…';

  @override
  String get rouletteStart => 'شروع';

  @override
  String get rouletteLater => 'بعداً';

  @override
  String get rouletteAgain => 'یکی دیگه';

  @override
  String get rouletteEmptyTitle => 'چیزی برای قرعه نیست';

  @override
  String get rouletteEmptyBody =>
      'لیستت خالیه یا چیزی با این فیلترها نمی‌خونه.';

  @override
  String get rouletteFilters => 'فیلترها';

  @override
  String get rouletteTime => 'وقت';

  @override
  String get rouletteEnergy => 'حال و انرژی';

  @override
  String get energyLow => 'کم‌حالم';

  @override
  String get energyHigh => 'سرحالم';

  @override
  String get rouletteCats => 'دسته‌های قرعه';

  @override
  String get rouletteHistoryTitle => 'تاریخچه‌ی قرعه';

  @override
  String get rouletteHistoryEmpty => 'هنوز قرعه‌ای نزدی.';

  @override
  String get rouletteProHint =>
      'فیلتر وقت، دسته، اولویت و انرژی و تاریخچه‌ی قرعه با Pro';

  @override
  String get rouletteOpenLink => 'باز کردن لینک';

  @override
  String get shareWhere => 'کجا نگهش دارم؟';

  @override
  String get shareInbox => 'صندوق ورودی';

  @override
  String get shareSavedInbox => 'تو صندوق ورودی ذخیره شد.';

  @override
  String get shareSuggested => 'پیشنهاد';

  @override
  String get proWhatYouGet => 'با Pro چی می‌گیری';

  @override
  String get proFreeHeader => 'تو نسخه‌ی رایگان هم داری';

  @override
  String get proFreeList =>
      'ذخیره‌ی نامحدود، صندوق ورودی، قرعه‌ی پایه، همه‌ی قفسه‌ها (مقاله، ویدیو، خرید، ایده، نرم‌افزار، پادکست، دوره، بازی)، آدم‌ها، کپسول و پیام (تا ۲ تا)، یه عکس برای هر مورد، جستجو، یادآوری، اشتراک‌گذاری، ویجت‌های خانه، تم روشن و تیره، پشتیبان‌گیری.';

  @override
  String get proFT1 => 'قرعه‌ی هوشمند';

  @override
  String get proFD1 =>
      'فقط از دسته‌های دلخواه، بر اساس وقت، اولویت و حال و انرژی‌ات انتخاب می‌کنه و تاریخچه‌ی قرعه‌ها رو نگه می‌داره.';

  @override
  String get proFT2 => 'صندوق ورودی هوشمند';

  @override
  String get proFD2 =>
      'برای هر مورد مقصد پیشنهاد می‌ده (مقاله، ویدیو، خرید، ایده). همیشه تأیید آخر با خودته.';

  @override
  String get proFT3 => 'قفسه‌های کامل‌تر';

  @override
  String get proFD3 =>
      'تاریخچه و آمار خوندن و دیدن، فیلتر و مرتب‌سازی پیشرفته، چند فهرست جدا.';

  @override
  String get proFT4 => 'خرید حساب‌شده';

  @override
  String get proFD4 =>
      'قیمت هدف، تاریخچه‌ی قیمتی که خودت ثبت کردی، آمار و یادآوری بررسی دوباره.';

  @override
  String get proFT5 => 'ایده‌ها با مرور';

  @override
  String get proFD5 =>
      'امتیاز، وصل کردن ایده‌ها به هم، مرور دوره‌ای، یادآوری ماهانه و تبدیل ایده به کار.';

  @override
  String get proFT6 => 'آدم‌های مهم';

  @override
  String get proFD6 =>
      'تاریخچه‌ی ارتباط، پیگیری خودکار، گروه‌های دلخواه و لیست «باید سر بزنی».';

  @override
  String get proFT7 => 'آینده‌ی بیشتر';

  @override
  String get proFD7 =>
      'کپسول و پیام بی‌شمار، پیوست عکس و فایل کوچک، برچسب و تکرار (مثلاً هر سال).';

  @override
  String get proFT8 => 'جستجو و فیلتر';

  @override
  String get proFD8 => 'جستجو تو برچسب، لینک و یادداشت و فیلتر «مانده‌ها».';

  @override
  String get proFT9 => 'آمار و تاریخچه‌ی کامل';

  @override
  String get proFD9 => 'همه‌ی ماه‌ها و آمار کامل، به‌جای فقط ۷ روز اخیر.';

  @override
  String get proFT10 => 'یادآوری تکرارشونده';

  @override
  String get proFD10 => 'روزانه، هفتگی، ماهانه یا سالانه، تا وقتی انجامش بدی.';

  @override
  String get proFT11 => 'ظاهر و ویجت';

  @override
  String get proFD11 =>
      'چند رنگ و آیکون دیگه و ویجت لیستی برای صفحه‌ی اصلی گوشی.';

  @override
  String get proFT12 => 'پشتیبان‌گیری بیشتر';

  @override
  String get proFD12 => 'پشتیبان خودکار هفتگی و خروجی CSV و متن.';

  @override
  String get settingsRouletteCats => 'دسته‌های قرعه';

  @override
  String get settingsRouletteCatsAll => 'همه‌ی دسته‌ها';

  @override
  String get wishlistReviewAfter => 'پرسیدن «هنوز می‌خوایش؟» بعد از';

  @override
  String get askWhereOnShare => 'بعد از اشتراک‌گذاری بپرس کجا بره';

  @override
  String get askWhereOnShareSub => 'اگه خاموشه، همه‌چیز می‌ره تو صندوق ورودی.';

  @override
  String get ideaReviewEvery => 'مرور ایده‌ها هر';

  @override
  String get ideaReviewMonthly => 'یادآوری مرور ماهانه';

  @override
  String get shelfAppTitle => 'بعداً نصب کن';

  @override
  String get shelfPodcastTitle => 'بعداً گوش بده';

  @override
  String get shelfCourseTitle => 'بعداً یاد بگیر';

  @override
  String get shelfGameTitle => 'بعداً بازی کن';

  @override
  String get shelfAppSub => 'نرم‌افزارهایی که بعداً نصب می‌کنم';

  @override
  String get shelfPodcastSub => 'پادکست‌هایی که بعداً گوش می‌کنم';

  @override
  String get shelfCourseSub => 'دوره‌ها و مهارت‌هایی که بعداً یاد می‌گیرم';

  @override
  String get shelfGameSub => 'بازی‌هایی که بعداً بازی می‌کنم';

  @override
  String get shelfEmptyAppTitle => 'هنوز نرم‌افزاری نذاشتی';

  @override
  String get shelfEmptyAppBody =>
      'لینک Google Play یا بازار رو بفرست به بعداً، تا وقتی نصبش کنی اینجا می‌مونه.';

  @override
  String get shelfEmptyPodcastTitle => 'هنوز پادکستی نذاشتی';

  @override
  String get shelfEmptyPodcastBody =>
      'یه قسمت رو نگه دار تا وقتی وقت داشتی ادامه‌اش بدی.';

  @override
  String get shelfEmptyCourseTitle => 'هنوز دوره‌ای نذاشتی';

  @override
  String get shelfEmptyCourseBody =>
      'دوره یا آموزشی که می‌خوای بعداً یاد بگیری رو اینجا بذار و بنویس چرا.';

  @override
  String get shelfEmptyGameTitle => 'هنوز بازی‌ای نذاشتی';

  @override
  String get shelfEmptyGameBody =>
      'بازی‌هایی که می‌خوای یه روز بازی کنی رو اینجا جمع کن.';

  @override
  String get stageNotInstalled => 'نصب نشده';

  @override
  String get stageWantInstall => 'می‌خوام نصب کنم';

  @override
  String get stageEvaluating => 'در حال بررسی';

  @override
  String get stageInstalled => 'نصب کردم';

  @override
  String get stageAppNotWanted => 'دیگه نمی‌خوام';

  @override
  String get stageNotListened => 'گوش نکرده‌ام';

  @override
  String get stageListening => 'در حال گوش دادن';

  @override
  String get stagePaused => 'متوقف شده';

  @override
  String get stageListened => 'گوش دادم';

  @override
  String get stageLearnLater => 'بعداً یاد می‌گیرم';

  @override
  String get stageLearning => 'در حال یادگیری';

  @override
  String get stageLearned => 'تمام شد';

  @override
  String get stageLearnAbandoned => 'رها کردم';

  @override
  String get stageWantPlay => 'می‌خوام بازی کنم';

  @override
  String get stagePlaying => 'در حال بازی';

  @override
  String get stageGameFinished => 'تمام شد';

  @override
  String get stageGameDropped => 'دیگه علاقه ندارم';

  @override
  String get markAsInstalled => 'نصبش کردم';

  @override
  String get markAsListened => 'گوش دادم';

  @override
  String get markAsLearned => 'تمومش کردم';

  @override
  String get fieldPlatforms => 'پلتفرم';

  @override
  String get platAndroid => 'اندروید';

  @override
  String get platWindows => 'ویندوز';

  @override
  String get platMac => 'macOS';

  @override
  String get platLinux => 'لینوکس';

  @override
  String get platIos => 'iOS';

  @override
  String get platWeb => 'وب';

  @override
  String get platOther => 'سایر';

  @override
  String get platformsProHint => 'چند پلتفرم برای یک نرم‌افزار با Pro';

  @override
  String get fieldShow => 'نام پادکست';

  @override
  String get fieldEpisodeHint => 'نام قسمت';

  @override
  String get fieldCreator => 'سازنده';

  @override
  String get fieldInstructor => 'مدرس یا سازنده';

  @override
  String get fieldGenre => 'ژانر';

  @override
  String get fieldLevel => 'سطح';

  @override
  String get levelBeginner => 'مقدماتی';

  @override
  String get levelIntermediate => 'متوسط';

  @override
  String get levelAdvanced => 'پیشرفته';

  @override
  String get fieldGoal => 'هدف من از یادگیری';

  @override
  String get goalHint => 'مثلاً: یادگیری Python برای ساخت AI';

  @override
  String get fieldDurationMin => 'مدت (دقیقه)';

  @override
  String get fieldGameMin => 'مدت یک دور بازی (دقیقه)';

  @override
  String get fieldProgress => 'پیشرفت';

  @override
  String podcastProgress(String p) {
    return '$p٪ گوش داده شده';
  }

  @override
  String podcastRemaining(String t) {
    return '$t باقی مانده';
  }

  @override
  String learnProgress(String p) {
    return '$p٪ پیشرفت';
  }

  @override
  String get continueListening => 'ادامه گوش دادن';

  @override
  String get continueFromWhere => 'ادامه از جایی که ماندم';

  @override
  String get lastPosition => 'آخرین نقطه';

  @override
  String get lastPositionHint => 'مثلاً ۱۸:۳۲';

  @override
  String get openLinkApp => 'باز کردن لینک';

  @override
  String get appStillNeed => 'آیا هنوز به این برنامه نیاز دارم؟';

  @override
  String appReviewQuestion(String days) {
    return 'این $days روزه تو فهرستته.\nهنوز ارزش نصب کردن داره؟';
  }

  @override
  String get appAnsInstalled => 'نصب کردم';

  @override
  String get appAnsStill => 'هنوز می‌خوام';

  @override
  String get appAnsLater => 'بعداً بررسی می‌کنم';

  @override
  String get appAnsNo => 'بی‌خیالش شدم';

  @override
  String get statusHistoryTitle => 'تاریخچه‌ی وضعیت';

  @override
  String get statusHistoryPro => 'تاریخچه‌ی تغییر وضعیت با Pro';

  @override
  String get appProHint =>
      'چند پلتفرم، مرور هوشمند، آمار و یادآوری مرور با Pro';

  @override
  String get podcastProHint =>
      'صف هوشمند، قسمت‌های کوتاه و آمار گوش‌دادن با Pro';

  @override
  String get learnProHint =>
      'هدف و برنامه، ثبت جلسه، رگه‌ی یادگیری و آمار با Pro';

  @override
  String get gameProHint => 'فیلتر زمان و ژانر و پیشنهاد هوشمند بازی با Pro';

  @override
  String get podcastQueueTitle => 'صف هوشمند';

  @override
  String get shortEpisodes => 'کوتاه برای وقت آزاد';

  @override
  String get queueEmpty => 'قسمتی که به این وقت بخوره نیست.';

  @override
  String get continueSection => 'ادامه بده';

  @override
  String get sessionLog => 'ثبت جلسه';

  @override
  String get sessionMinutes => 'چند دقیقه؟';

  @override
  String get sessionsTitle => 'جلسه‌ها';

  @override
  String get sessionLogged => 'ثبت شد.';

  @override
  String get statsStreak => 'پشت‌سرهم';

  @override
  String streakDays(String n) {
    return '$n روز';
  }

  @override
  String get statsWeekMinutes => 'این هفته';

  @override
  String get statsTotalTime => 'جمع زمان';

  @override
  String minutesTotal(String n) {
    return '$n دقیقه';
  }

  @override
  String get learnGoalTitle => 'هدف و برنامه';

  @override
  String get goalDate => 'تا تاریخ';

  @override
  String get weeklyGoal => 'هدف هفتگی (دقیقه)';

  @override
  String weekGoalProgress(String a, String b) {
    return 'این هفته: $a از $b دقیقه';
  }

  @override
  String get gamePickTitle => 'امروز چی بازی کنم؟';

  @override
  String get gamePickBtn => 'یه بازی انتخاب کن';

  @override
  String get gamePickLabel => 'امروز اینو بازی کن';

  @override
  String gameHowLong(String n) {
    return 'حدود $n دقیقه وقت داری؟';
  }

  @override
  String get gameStart => 'شروع';

  @override
  String get gameLater => 'بعداً';

  @override
  String get gameAnother => 'یکی دیگه';

  @override
  String get gameEmptyTitle => 'بازی‌ای برای پیشنهاد نیست';

  @override
  String get gameEmptyBody => 'بازی اضافه کن یا فیلترها رو شل‌تر کن.';

  @override
  String get gameFreeTime => 'وقت آزاد';

  @override
  String get gameStatusFilter => 'وضعیت';

  @override
  String get gameGenreFilter => 'ژانر';

  @override
  String get gameStarted => 'برو بازی کن! حالا در حال بازی ثبتش کردم.';

  @override
  String get imgAdd => 'افزودن عکس';

  @override
  String get imgTake => 'گرفتن عکس';

  @override
  String get imgGallery => 'انتخاب از گالری';

  @override
  String get imgChange => 'تغییر عکس';

  @override
  String get imgRemove => 'حذف عکس';

  @override
  String get imgSetCover => 'عکس اصلی کن';

  @override
  String get imgCover => 'اصلی';

  @override
  String get imgGalleryTitle => 'عکس‌ها';

  @override
  String get imgTooBig => 'این عکس خیلی بزرگه (حداکثر ۳۰ مگابایت).';

  @override
  String get imgInvalid => 'این فایل یه عکس معتبر نیست.';

  @override
  String get imgFailed => 'عکس اضافه نشد.';

  @override
  String get imgProMore => 'چند عکس برای هر مورد با Pro';

  @override
  String get imgAdded => 'عکس اضافه شد.';

  @override
  String get imgRemoved => 'عکس حذف شد.';

  @override
  String get imgNone => 'عکسی نداری';

  @override
  String get imgPrivacy => 'عکس‌ها فقط روی همین گوشی می‌مونن.';

  @override
  String get suggestWhatApp => 'یه نرم‌افزار';

  @override
  String get suggestWhatPodcast => 'یه پادکست';

  @override
  String get suggestWhatCourse => 'یه دوره';

  @override
  String get suggestWhatGame => 'یه بازی';

  @override
  String get triageMore => 'جای دیگه…';

  @override
  String get settingsAppReview => 'یادآوری ماهانه‌ی مرور نرم‌افزارها';

  @override
  String get notifAppReviewTitle => 'نرم‌افزارهای منتظر نصب';

  @override
  String get notifAppReviewBody => 'یه نگاه بنداز: هنوز همه‌شون رو می‌خوای؟';

  @override
  String get widgetTagline => 'الان لازم نیست؛ فراموشش نکن.';

  @override
  String get widgetInbox => 'صندوق ورودی';

  @override
  String get widgetToday => 'امروز';

  @override
  String get widgetLearn => 'یادگیری';

  @override
  String get widgetPodcasts => 'گوش‌دادنی';

  @override
  String get widgetGames => 'بازی‌ها';

  @override
  String get widgetWishlist => 'خرید';

  @override
  String get widgetIdeas => 'ایده';

  @override
  String get widgetRefresh => 'تازه‌سازی';

  @override
  String get widgetNothing => 'فعلاً چیزی نیست';

  @override
  String widgetSmartToday(String t) {
    return '🎯 امروز شاید اینو انجام بدی:\n$t';
  }

  @override
  String widgetSmartLearn(String t) {
    return '📚 ادامه‌ی یادگیری:\n$t';
  }

  @override
  String widgetSmartListen(String t) {
    return '🎧 ادامه بده:\n$t';
  }

  @override
  String widgetSmartFree(String m, String t) {
    return '🎧 برای وقت آزاد:\n$t · $m دقیقه';
  }

  @override
  String widgetSmartGame(String m, String t) {
    return '🎮 اگه $m دقیقه وقت داری:\n$t';
  }

  @override
  String widgetSmartWaiting(String t) {
    return '⏳ مدتیه منتظره:\n$t';
  }

  @override
  String get widgetQuickAdd => 'ذخیره‌ی سریع';

  @override
  String get captureHint => 'چی رو برای بعداً نگه دارم؟';

  @override
  String get captureSaved => 'ذخیره شد.';

  @override
  String get captureKinds => 'چه جور چیزیه؟';

  @override
  String get proFT13 => 'نرم‌افزارها با مرور';

  @override
  String get proFD13 =>
      'چند پلتفرم برای هر برنامه، مرور هوشمند، یادآوری ماهانه، آمار نصب‌شده و رهاشده و تاریخچه‌ی وضعیت.';

  @override
  String get proFT14 => 'پادکست با صف هوشمند';

  @override
  String get proFD14 =>
      'صف مرتب بر اساس وقتت، فیلتر قسمت‌های کوتاه، آمار گوش‌دادن، تاریخچه و مرور.';

  @override
  String get proFT15 => 'یادگیری با هدف';

  @override
  String get proFD15 =>
      'هدف تاریخ‌دار و برنامه‌ی هفتگی، ثبت جلسه‌های مطالعه، زمان صرف‌شده، رگه‌ی روزانه و آمار.';

  @override
  String get proFT16 => 'بازی با پیشنهاد هوشمند';

  @override
  String get proFD16 =>
      'پیشنهاد بر اساس وقت آزاد، ژانر، اولویت و وضعیت؛ تنوع ژانر، ثبت زمان بازی و آمار.';

  @override
  String get proFT17 => 'گالری عکس';

  @override
  String get proFD17 =>
      'تا ۸ عکس برای هر مورد، انتخاب عکس اصلی و نمایش بزرگ. یک عکس برای هر مورد رایگانه.';

  @override
  String get fieldCoursePlatform => 'پلتفرم یا سایت';

  @override
  String get fieldLinkStore => 'لینک (فروشگاه یا سایت)';

  @override
  String get fieldPositionHint => 'تا کجا رسیدم (مثلاً ۱۸:۳۲)';

  @override
  String get fieldDurationHint2 => 'مثلاً ۴۵ یا ۱:۲۰:۰۰';

  @override
  String get typeDetails => 'مشخصات';

  @override
  String get widgetRead => 'خواندنی';

  @override
  String get widgetOfferTitle => 'ویجت «بعداً» روی صفحه‌ی اصلی؟';

  @override
  String get widgetOfferBody =>
      'یه ویجت کوچیک و قشنگ که کارهای امروزت رو نشونت می‌ده و با یه لمس چیزی رو ذخیره می‌کنه. هر وقت خواستی می‌تونی برش داری.';

  @override
  String get widgetOfferYes => 'آره، اضافه کن';

  @override
  String get widgetOfferNo => 'نه، ممنون';

  @override
  String get widgetAddedToast =>
      'درخواست اضافه‌شدن ویجت فرستاده شد؛ تأییدش کن.';

  @override
  String get widgetManualHint =>
      'لانچر گوشی اضافه‌کردن خودکار رو پشتیبانی نمی‌کنه. روی صفحه‌ی اصلی نگه دار و «ویجت‌ها» رو بزن، بعد «بعداً» رو انتخاب کن.';

  @override
  String get settingsWidget => 'ویجت صفحه‌ی اصلی';

  @override
  String get settingsWidgetSub => 'کارهای امروز رو روی صفحه‌ی اصلی ببین.';

  @override
  String get widgetTodayEmpty => 'امروز چیزی نداری 🌿';

  @override
  String widgetMore(String n) {
    return '+$n مورد دیگه';
  }

  @override
  String get widgetOverdue => 'عقب‌افتاده';
}
