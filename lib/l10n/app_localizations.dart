import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa'),
  ];

  /// No description provided for @appName.
  ///
  /// In fa, this message translates to:
  /// **'بعداً'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In fa, this message translates to:
  /// **'الان لازم نیست؛ فقط فراموشش نکن.'**
  String get tagline;

  /// No description provided for @ok.
  ///
  /// In fa, this message translates to:
  /// **'باشه'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In fa, this message translates to:
  /// **'انصراف'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In fa, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In fa, this message translates to:
  /// **'بستن'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In fa, this message translates to:
  /// **'تلاش دوباره'**
  String get retry;

  /// No description provided for @done.
  ///
  /// In fa, this message translates to:
  /// **'انجام شد'**
  String get done;

  /// No description provided for @next.
  ///
  /// In fa, this message translates to:
  /// **'بعدی'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In fa, this message translates to:
  /// **'رد کردن'**
  String get skip;

  /// No description provided for @continueLabel.
  ///
  /// In fa, this message translates to:
  /// **'ادامه'**
  String get continueLabel;

  /// No description provided for @undo.
  ///
  /// In fa, this message translates to:
  /// **'برگردان'**
  String get undo;

  /// No description provided for @add.
  ///
  /// In fa, this message translates to:
  /// **'اضافه کن'**
  String get add;

  /// No description provided for @search.
  ///
  /// In fa, this message translates to:
  /// **'جستجو'**
  String get search;

  /// No description provided for @all.
  ///
  /// In fa, this message translates to:
  /// **'همه'**
  String get all;

  /// No description provided for @none.
  ///
  /// In fa, this message translates to:
  /// **'هیچ‌کدام'**
  String get none;

  /// No description provided for @proBadge.
  ///
  /// In fa, this message translates to:
  /// **'Pro'**
  String get proBadge;

  /// No description provided for @loading.
  ///
  /// In fa, this message translates to:
  /// **'در حال بارگذاری…'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In fa, this message translates to:
  /// **'یه مشکلی پیش اومد. دوباره امتحان کن.'**
  String get errorGeneric;

  /// No description provided for @errorLoad.
  ///
  /// In fa, this message translates to:
  /// **'بارگذاری اطلاعات ناموفق بود.'**
  String get errorLoad;

  /// No description provided for @navHome.
  ///
  /// In fa, this message translates to:
  /// **'خانه'**
  String get navHome;

  /// No description provided for @navList.
  ///
  /// In fa, this message translates to:
  /// **'بعداً'**
  String get navList;

  /// No description provided for @navHistory.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In fa, this message translates to:
  /// **'تنظیمات'**
  String get navSettings;

  /// No description provided for @semAdd.
  ///
  /// In fa, this message translates to:
  /// **'افزودن مورد جدید'**
  String get semAdd;

  /// No description provided for @onb1Title.
  ///
  /// In fa, this message translates to:
  /// **'الان لازم نیست.'**
  String get onb1Title;

  /// No description provided for @onb1Body.
  ///
  /// In fa, this message translates to:
  /// **'لازم نیست همه‌چیز همین الان تموم بشه. چیزی که وقتش نیست رو بذار کنار.'**
  String get onb1Body;

  /// No description provided for @onb2Title.
  ///
  /// In fa, this message translates to:
  /// **'هر چیزی را که نمی‌خواهی فراموش کنی، اینجا نگه دار.'**
  String get onb2Title;

  /// No description provided for @onb2Body.
  ///
  /// In fa, this message translates to:
  /// **'مقاله، فیلم، خرید، ایده، یه تماس. بنویس، یا از هر برنامه‌ای «اشتراک‌گذاری» رو بزن.'**
  String get onb2Body;

  /// No description provided for @onb3Title.
  ///
  /// In fa, this message translates to:
  /// **'بعداً خودش به تو یادآوری می‌کند.'**
  String get onb3Title;

  /// No description provided for @onb3Body.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ و ساعت بده تا خودش یادآوری کنه. ندادی هم مهم نیست، وقتی وقت داشتی قرعه بزن.'**
  String get onb3Body;

  /// No description provided for @onb4Title.
  ///
  /// In fa, this message translates to:
  /// **'بدون حساب کاربری، بدون سرور.'**
  String get onb4Title;

  /// No description provided for @onb4Body.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعاتت فقط روی گوشی خودته و بدون اینترنت هم کار می‌کنه.'**
  String get onb4Body;

  /// No description provided for @onb5Title.
  ///
  /// In fa, this message translates to:
  /// **'آماده‌ای؟'**
  String get onb5Title;

  /// No description provided for @onb5Body.
  ///
  /// In fa, this message translates to:
  /// **'هر چی الان وقتش نیست رو همین‌جا بذار.'**
  String get onb5Body;

  /// No description provided for @onbStart.
  ///
  /// In fa, this message translates to:
  /// **'بزن بریم'**
  String get onbStart;

  /// No description provided for @legalTitle.
  ///
  /// In fa, this message translates to:
  /// **'قبل از شروع'**
  String get legalTitle;

  /// No description provided for @legalIntro.
  ///
  /// In fa, this message translates to:
  /// **'قبل از شروع، قوانین استفاده و سیاست حریم خصوصی رو بخون و تأیید کن.'**
  String get legalIntro;

  /// No description provided for @termsTitle.
  ///
  /// In fa, this message translates to:
  /// **'قوانین استفاده'**
  String get termsTitle;

  /// No description provided for @privacyTitle.
  ///
  /// In fa, this message translates to:
  /// **'سیاست حریم خصوصی'**
  String get privacyTitle;

  /// No description provided for @legalAccept.
  ///
  /// In fa, this message translates to:
  /// **'قوانین استفاده و سیاست حریم خصوصی را خوانده‌ام و می‌پذیرم.'**
  String get legalAccept;

  /// No description provided for @legalContinue.
  ///
  /// In fa, this message translates to:
  /// **'تأیید و ورود'**
  String get legalContinue;

  /// No description provided for @legalLoadError.
  ///
  /// In fa, this message translates to:
  /// **'بارگذاری متن ناموفق بود.'**
  String get legalLoadError;

  /// No description provided for @legalUpdatedTitle.
  ///
  /// In fa, this message translates to:
  /// **'به‌روزرسانی قوانین'**
  String get legalUpdatedTitle;

  /// No description provided for @homeWaiting.
  ///
  /// In fa, this message translates to:
  /// **'{count} چیز منتظرته'**
  String homeWaiting(String count);

  /// No description provided for @homeWaitingOne.
  ///
  /// In fa, this message translates to:
  /// **'یه چیز منتظرته'**
  String get homeWaitingOne;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز چیزی برای بعداً نداری.'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In fa, this message translates to:
  /// **'چه خوب. فعلاً ذهنت آزاده. 🌱'**
  String get homeEmptyBody;

  /// No description provided for @homeEmptyCta.
  ///
  /// In fa, this message translates to:
  /// **'اولین مورد را اضافه کن'**
  String get homeEmptyCta;

  /// No description provided for @statToday.
  ///
  /// In fa, this message translates to:
  /// **'امروز'**
  String get statToday;

  /// No description provided for @statWeek.
  ///
  /// In fa, this message translates to:
  /// **'این هفته'**
  String get statWeek;

  /// No description provided for @statNoDate.
  ///
  /// In fa, this message translates to:
  /// **'بدون تاریخ'**
  String get statNoDate;

  /// No description provided for @statOverdue.
  ///
  /// In fa, this message translates to:
  /// **'عقب‌افتاده'**
  String get statOverdue;

  /// No description provided for @statStale.
  ///
  /// In fa, this message translates to:
  /// **'مانده‌ها'**
  String get statStale;

  /// No description provided for @pickCardTitle.
  ///
  /// In fa, this message translates to:
  /// **'قرعه بعداً'**
  String get pickCardTitle;

  /// No description provided for @pickCardSub.
  ///
  /// In fa, this message translates to:
  /// **'نمی‌دونی الان چی‌کار کنی؟ بذار قرعه تصمیم بگیره.'**
  String get pickCardSub;

  /// No description provided for @timeCardTitle.
  ///
  /// In fa, this message translates to:
  /// **'الان چقدر وقت داری؟'**
  String get timeCardTitle;

  /// No description provided for @minutesN.
  ///
  /// In fa, this message translates to:
  /// **'{n} دقیقه'**
  String minutesN(String n);

  /// No description provided for @hourOne.
  ///
  /// In fa, this message translates to:
  /// **'۱ ساعت'**
  String get hourOne;

  /// No description provided for @anyTime.
  ///
  /// In fa, this message translates to:
  /// **'مهم نیست'**
  String get anyTime;

  /// No description provided for @homeTodaySection.
  ///
  /// In fa, this message translates to:
  /// **'امروز و عقب‌افتاده‌ها'**
  String get homeTodaySection;

  /// No description provided for @homeSeeAll.
  ///
  /// In fa, this message translates to:
  /// **'همه'**
  String get homeSeeAll;

  /// No description provided for @staleBannerTitle.
  ///
  /// In fa, this message translates to:
  /// **'{count} مورد مدت‌هاست منتظرند'**
  String staleBannerTitle(String count);

  /// No description provided for @staleBannerBody.
  ///
  /// In fa, this message translates to:
  /// **'یه نگاه سریع بنداز؛ نگه دار یا رها کن.'**
  String get staleBannerBody;

  /// No description provided for @decideTitle.
  ///
  /// In fa, this message translates to:
  /// **'تصمیم نگیر'**
  String get decideTitle;

  /// No description provided for @decideIntro.
  ///
  /// In fa, this message translates to:
  /// **'نمی‌دونم الان چی کار کنم.'**
  String get decideIntro;

  /// No description provided for @decideLabel.
  ///
  /// In fa, this message translates to:
  /// **'قرعه این شد'**
  String get decideLabel;

  /// No description provided for @decideAbout.
  ///
  /// In fa, this message translates to:
  /// **'حدود {n} دقیقه'**
  String decideAbout(String n);

  /// No description provided for @decideDo.
  ///
  /// In fa, this message translates to:
  /// **'انجامش می‌دم'**
  String get decideDo;

  /// No description provided for @decideLater.
  ///
  /// In fa, this message translates to:
  /// **'بعداً'**
  String get decideLater;

  /// No description provided for @decideAnother.
  ///
  /// In fa, this message translates to:
  /// **'مورد دیگری بده'**
  String get decideAnother;

  /// No description provided for @decideNone.
  ///
  /// In fa, this message translates to:
  /// **'چیزی برای پیشنهاد ندارم'**
  String get decideNone;

  /// No description provided for @decideNoneBody.
  ///
  /// In fa, this message translates to:
  /// **'لیستت خالیه یا چیزی به این زمان نمی‌خوره. 🌱'**
  String get decideNoneBody;

  /// No description provided for @decideNoMore.
  ///
  /// In fa, this message translates to:
  /// **'مورد دیگری نمانده.'**
  String get decideNoMore;

  /// No description provided for @decideDoneToast.
  ///
  /// In fa, this message translates to:
  /// **'انجام شد ✓'**
  String get decideDoneToast;

  /// No description provided for @smartPickTitle.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد هوشمند'**
  String get smartPickTitle;

  /// No description provided for @smartPickHeader.
  ///
  /// In fa, this message translates to:
  /// **'الان چقدر وقت داری؟'**
  String get smartPickHeader;

  /// No description provided for @smartPickResultsFor.
  ///
  /// In fa, this message translates to:
  /// **'مناسب {time}'**
  String smartPickResultsFor(String time);

  /// No description provided for @smartPickResultsAny.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهادها'**
  String get smartPickResultsAny;

  /// No description provided for @smartPickEmpty.
  ///
  /// In fa, this message translates to:
  /// **'برای این مدت چیزی پیدا نکردم.'**
  String get smartPickEmpty;

  /// No description provided for @smartPickProHint.
  ///
  /// In fa, this message translates to:
  /// **'فیلتر دسته و اولویت با Pro'**
  String get smartPickProHint;

  /// No description provided for @smartPickCategory.
  ///
  /// In fa, this message translates to:
  /// **'فقط از دسته‌ی…'**
  String get smartPickCategory;

  /// No description provided for @smartPickAllCategories.
  ///
  /// In fa, this message translates to:
  /// **'همه‌ی دسته‌ها'**
  String get smartPickAllCategories;

  /// No description provided for @listTitle.
  ///
  /// In fa, this message translates to:
  /// **'بعداً'**
  String get listTitle;

  /// No description provided for @searchHint.
  ///
  /// In fa, this message translates to:
  /// **'جستجو در بعداً…'**
  String get searchHint;

  /// No description provided for @searchAdvancedHint.
  ///
  /// In fa, this message translates to:
  /// **'جستجوی پیشرفته (برچسب، لینک، یادداشت) با Pro'**
  String get searchAdvancedHint;

  /// No description provided for @filterAll.
  ///
  /// In fa, this message translates to:
  /// **'همه'**
  String get filterAll;

  /// No description provided for @filterToday.
  ///
  /// In fa, this message translates to:
  /// **'امروز'**
  String get filterToday;

  /// No description provided for @filterWeek.
  ///
  /// In fa, this message translates to:
  /// **'این هفته'**
  String get filterWeek;

  /// No description provided for @filterNoDate.
  ///
  /// In fa, this message translates to:
  /// **'بدون تاریخ'**
  String get filterNoDate;

  /// No description provided for @filterOverdue.
  ///
  /// In fa, this message translates to:
  /// **'عقب‌افتاده'**
  String get filterOverdue;

  /// No description provided for @filterHigh.
  ///
  /// In fa, this message translates to:
  /// **'اولویت بالا'**
  String get filterHigh;

  /// No description provided for @filterStale.
  ///
  /// In fa, this message translates to:
  /// **'مانده‌ها'**
  String get filterStale;

  /// No description provided for @sortTitle.
  ///
  /// In fa, this message translates to:
  /// **'مرتب‌سازی'**
  String get sortTitle;

  /// No description provided for @sortNewest.
  ///
  /// In fa, this message translates to:
  /// **'جدیدترین'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In fa, this message translates to:
  /// **'قدیمی‌ترین'**
  String get sortOldest;

  /// No description provided for @sortDeadline.
  ///
  /// In fa, this message translates to:
  /// **'نزدیک‌ترین موعد'**
  String get sortDeadline;

  /// No description provided for @sortPriority.
  ///
  /// In fa, this message translates to:
  /// **'اولویت'**
  String get sortPriority;

  /// No description provided for @sortShortest.
  ///
  /// In fa, this message translates to:
  /// **'کوتاه‌ترین کار'**
  String get sortShortest;

  /// No description provided for @sortLongest.
  ///
  /// In fa, this message translates to:
  /// **'طولانی‌ترین کار'**
  String get sortLongest;

  /// No description provided for @listEmptyFiltered.
  ///
  /// In fa, this message translates to:
  /// **'چیزی پیدا نشد'**
  String get listEmptyFiltered;

  /// No description provided for @listEmptyFilteredBody.
  ///
  /// In fa, this message translates to:
  /// **'فیلتر یا عبارت جستجو را عوض کن.'**
  String get listEmptyFilteredBody;

  /// No description provided for @smartFiltersPro.
  ///
  /// In fa, this message translates to:
  /// **'فیلترهای هوشمند با Pro'**
  String get smartFiltersPro;

  /// No description provided for @overdue.
  ///
  /// In fa, this message translates to:
  /// **'عقب‌افتاده'**
  String get overdue;

  /// No description provided for @waitingDays.
  ///
  /// In fa, this message translates to:
  /// **'{n} روز است منتظر'**
  String waitingDays(String n);

  /// No description provided for @dueToday.
  ///
  /// In fa, this message translates to:
  /// **'امروز'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In fa, this message translates to:
  /// **'فردا'**
  String get dueTomorrow;

  /// No description provided for @atTime.
  ///
  /// In fa, this message translates to:
  /// **'ساعت {time}'**
  String atTime(String time);

  /// No description provided for @noDate.
  ///
  /// In fa, this message translates to:
  /// **'بدون تاریخ'**
  String get noDate;

  /// No description provided for @priorityHigh.
  ///
  /// In fa, this message translates to:
  /// **'اولویت بالا'**
  String get priorityHigh;

  /// No description provided for @priorityNormal.
  ///
  /// In fa, this message translates to:
  /// **'عادی'**
  String get priorityNormal;

  /// No description provided for @priorityLow.
  ///
  /// In fa, this message translates to:
  /// **'کم'**
  String get priorityLow;

  /// No description provided for @priority.
  ///
  /// In fa, this message translates to:
  /// **'اولویت'**
  String get priority;

  /// No description provided for @duration.
  ///
  /// In fa, this message translates to:
  /// **'زمان تخمینی'**
  String get duration;

  /// No description provided for @minutesShort.
  ///
  /// In fa, this message translates to:
  /// **'{n} د'**
  String minutesShort(String n);

  /// No description provided for @reminder.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری'**
  String get reminder;

  /// No description provided for @repeat.
  ///
  /// In fa, this message translates to:
  /// **'تکرار'**
  String get repeat;

  /// No description provided for @repeatNone.
  ///
  /// In fa, this message translates to:
  /// **'یک‌بار'**
  String get repeatNone;

  /// No description provided for @repeatDaily.
  ///
  /// In fa, this message translates to:
  /// **'هر روز'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In fa, this message translates to:
  /// **'هر هفته'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In fa, this message translates to:
  /// **'هر ماه'**
  String get repeatMonthly;

  /// No description provided for @snoozedTimes.
  ///
  /// In fa, this message translates to:
  /// **'{n} بار به بعد رفته'**
  String snoozedTimes(String n);

  /// No description provided for @itemDone.
  ///
  /// In fa, this message translates to:
  /// **'انجام شد'**
  String get itemDone;

  /// No description provided for @itemSnooze.
  ///
  /// In fa, this message translates to:
  /// **'بعداً'**
  String get itemSnooze;

  /// No description provided for @itemDrop.
  ///
  /// In fa, this message translates to:
  /// **'بی‌خیالش شدم'**
  String get itemDrop;

  /// No description provided for @itemOpenLink.
  ///
  /// In fa, this message translates to:
  /// **'باز کردن لینک'**
  String get itemOpenLink;

  /// No description provided for @itemLinkFailed.
  ///
  /// In fa, this message translates to:
  /// **'لینک باز نشد.'**
  String get itemLinkFailed;

  /// No description provided for @toastDone.
  ///
  /// In fa, this message translates to:
  /// **'انجام شد ✓'**
  String get toastDone;

  /// No description provided for @toastDropped.
  ///
  /// In fa, this message translates to:
  /// **'کنار گذاشته شد'**
  String get toastDropped;

  /// No description provided for @toastDeleted.
  ///
  /// In fa, this message translates to:
  /// **'حذف شد'**
  String get toastDeleted;

  /// No description provided for @toastSnoozed.
  ///
  /// In fa, this message translates to:
  /// **'منتقل شد به {when}'**
  String toastSnoozed(String when);

  /// No description provided for @toastSaved.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره شد'**
  String get toastSaved;

  /// No description provided for @toastAdded.
  ///
  /// In fa, this message translates to:
  /// **'به بعداً اضافه شد'**
  String get toastAdded;

  /// No description provided for @toastReopened.
  ///
  /// In fa, this message translates to:
  /// **'به لیست برگشت'**
  String get toastReopened;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In fa, this message translates to:
  /// **'حذف این مورد؟'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteBody.
  ///
  /// In fa, this message translates to:
  /// **'این مورد برای همیشه پاک می‌شود.'**
  String get confirmDeleteBody;

  /// No description provided for @createdOn.
  ///
  /// In fa, this message translates to:
  /// **'ثبت‌شده در {date}'**
  String createdOn(String date);

  /// No description provided for @itemNotFound.
  ///
  /// In fa, this message translates to:
  /// **'این مورد دیگر وجود ندارد.'**
  String get itemNotFound;

  /// No description provided for @addTitle.
  ///
  /// In fa, this message translates to:
  /// **'چیزی برای بعداً'**
  String get addTitle;

  /// No description provided for @editTitle.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش'**
  String get editTitle;

  /// No description provided for @titleHint.
  ///
  /// In fa, this message translates to:
  /// **'چی رو بذارم برای بعداً؟'**
  String get titleHint;

  /// No description provided for @titleRequired.
  ///
  /// In fa, this message translates to:
  /// **'یه عنوان بنویس'**
  String get titleRequired;

  /// No description provided for @moreOptions.
  ///
  /// In fa, this message translates to:
  /// **'گزینه‌های بیشتر'**
  String get moreOptions;

  /// No description provided for @lessOptions.
  ///
  /// In fa, this message translates to:
  /// **'کمتر'**
  String get lessOptions;

  /// No description provided for @fieldDescription.
  ///
  /// In fa, this message translates to:
  /// **'توضیح'**
  String get fieldDescription;

  /// No description provided for @fieldNote.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت'**
  String get fieldNote;

  /// No description provided for @fieldUrl.
  ///
  /// In fa, this message translates to:
  /// **'لینک'**
  String get fieldUrl;

  /// No description provided for @urlInvalid.
  ///
  /// In fa, this message translates to:
  /// **'لینک معتبر نیست (فقط http و https).'**
  String get urlInvalid;

  /// No description provided for @fieldTags.
  ///
  /// In fa, this message translates to:
  /// **'برچسب‌ها'**
  String get fieldTags;

  /// No description provided for @fieldTagsHint.
  ///
  /// In fa, this message translates to:
  /// **'با کاما جدا کن'**
  String get fieldTagsHint;

  /// No description provided for @fieldCategory.
  ///
  /// In fa, this message translates to:
  /// **'دسته'**
  String get fieldCategory;

  /// No description provided for @fieldDate.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ'**
  String get fieldDate;

  /// No description provided for @fieldTime.
  ///
  /// In fa, this message translates to:
  /// **'ساعت'**
  String get fieldTime;

  /// No description provided for @datePick.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب تاریخ…'**
  String get datePick;

  /// No description provided for @timePick.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب ساعت…'**
  String get timePick;

  /// No description provided for @timeNone.
  ///
  /// In fa, this message translates to:
  /// **'بدون ساعت'**
  String get timeNone;

  /// No description provided for @reminderOff.
  ///
  /// In fa, this message translates to:
  /// **'بدون یادآوری'**
  String get reminderOff;

  /// No description provided for @reminderAtTime.
  ///
  /// In fa, this message translates to:
  /// **'سر وقت'**
  String get reminderAtTime;

  /// No description provided for @reminderBefore10.
  ///
  /// In fa, this message translates to:
  /// **'۱۰ دقیقه قبل'**
  String get reminderBefore10;

  /// No description provided for @reminderBefore60Label.
  ///
  /// In fa, this message translates to:
  /// **'۱ ساعت قبل'**
  String get reminderBefore60Label;

  /// No description provided for @reminderBefore1d.
  ///
  /// In fa, this message translates to:
  /// **'۱ روز قبل'**
  String get reminderBefore1d;

  /// No description provided for @reminderNeedsDate.
  ///
  /// In fa, this message translates to:
  /// **'برای یادآوری یه تاریخ لازمه.'**
  String get reminderNeedsDate;

  /// No description provided for @reminderAtDefault.
  ///
  /// In fa, this message translates to:
  /// **'ساعت {time} (پیش‌فرض)'**
  String reminderAtDefault(String time);

  /// No description provided for @repeatProHint.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری تکرارشونده با Pro'**
  String get repeatProHint;

  /// No description provided for @durationUnknown.
  ///
  /// In fa, this message translates to:
  /// **'نامشخص'**
  String get durationUnknown;

  /// No description provided for @durationCustom.
  ///
  /// In fa, this message translates to:
  /// **'دلخواه'**
  String get durationCustom;

  /// No description provided for @durationCustomHint.
  ///
  /// In fa, this message translates to:
  /// **'چند دقیقه؟'**
  String get durationCustomHint;

  /// No description provided for @quickToday.
  ///
  /// In fa, this message translates to:
  /// **'امروز'**
  String get quickToday;

  /// No description provided for @quickTomorrow.
  ///
  /// In fa, this message translates to:
  /// **'فردا'**
  String get quickTomorrow;

  /// No description provided for @quickWeekend.
  ///
  /// In fa, this message translates to:
  /// **'آخر هفته'**
  String get quickWeekend;

  /// No description provided for @quickNextWeek.
  ///
  /// In fa, this message translates to:
  /// **'هفته بعد'**
  String get quickNextWeek;

  /// No description provided for @quickNoDate.
  ///
  /// In fa, this message translates to:
  /// **'بدون تاریخ'**
  String get quickNoDate;

  /// No description provided for @quickCustom.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ دیگر'**
  String get quickCustom;

  /// No description provided for @discardTitle.
  ///
  /// In fa, this message translates to:
  /// **'تغییرات ذخیره نشود؟'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In fa, this message translates to:
  /// **'چیزی که نوشته‌ای ذخیره نشده.'**
  String get discardBody;

  /// No description provided for @discard.
  ///
  /// In fa, this message translates to:
  /// **'دور بینداز'**
  String get discard;

  /// No description provided for @snoozeTitle.
  ///
  /// In fa, this message translates to:
  /// **'به کِی موکولش کنم؟'**
  String get snoozeTitle;

  /// No description provided for @snoozeTonight.
  ///
  /// In fa, this message translates to:
  /// **'امشب'**
  String get snoozeTonight;

  /// No description provided for @snoozeTomorrow.
  ///
  /// In fa, this message translates to:
  /// **'فردا'**
  String get snoozeTomorrow;

  /// No description provided for @snoozeWeekend.
  ///
  /// In fa, this message translates to:
  /// **'آخر هفته'**
  String get snoozeWeekend;

  /// No description provided for @snoozeNextWeek.
  ///
  /// In fa, this message translates to:
  /// **'هفته بعد'**
  String get snoozeNextWeek;

  /// No description provided for @snoozeNextMonth.
  ///
  /// In fa, this message translates to:
  /// **'ماه بعد'**
  String get snoozeNextMonth;

  /// No description provided for @snoozeCustom.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ دلخواه'**
  String get snoozeCustom;

  /// No description provided for @snoozeNoDate.
  ///
  /// In fa, this message translates to:
  /// **'بدون تاریخ'**
  String get snoozeNoDate;

  /// No description provided for @datePickerTitle.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب تاریخ'**
  String get datePickerTitle;

  /// No description provided for @prevMonth.
  ///
  /// In fa, this message translates to:
  /// **'ماه قبل'**
  String get prevMonth;

  /// No description provided for @nextMonth.
  ///
  /// In fa, this message translates to:
  /// **'ماه بعد'**
  String get nextMonth;

  /// No description provided for @today.
  ///
  /// In fa, this message translates to:
  /// **'امروز'**
  String get today;

  /// No description provided for @clear.
  ///
  /// In fa, this message translates to:
  /// **'پاک کردن'**
  String get clear;

  /// No description provided for @staleTitle.
  ///
  /// In fa, this message translates to:
  /// **'بعداً، نه هیچ‌وقت'**
  String get staleTitle;

  /// No description provided for @staleQuestion.
  ///
  /// In fa, this message translates to:
  /// **'این {days} روزه منتظرته.\nهنوز می‌خوای نگهش داری؟'**
  String staleQuestion(String days);

  /// No description provided for @staleKeep.
  ///
  /// In fa, this message translates to:
  /// **'نگه دار'**
  String get staleKeep;

  /// No description provided for @staleSnooze.
  ///
  /// In fa, this message translates to:
  /// **'برای بعداً تنظیم کن'**
  String get staleSnooze;

  /// No description provided for @staleDone.
  ///
  /// In fa, this message translates to:
  /// **'انجام شد'**
  String get staleDone;

  /// No description provided for @staleDrop.
  ///
  /// In fa, this message translates to:
  /// **'بی‌خیالش شدم'**
  String get staleDrop;

  /// No description provided for @staleProgress.
  ///
  /// In fa, this message translates to:
  /// **'{i} از {n}'**
  String staleProgress(String i, String n);

  /// No description provided for @staleAllDone.
  ///
  /// In fa, this message translates to:
  /// **'همه‌چی مرتبه'**
  String get staleAllDone;

  /// No description provided for @staleAllDoneBody.
  ///
  /// In fa, this message translates to:
  /// **'لیستت سبک‌تر شد.'**
  String get staleAllDoneBody;

  /// No description provided for @staleNoPressure.
  ///
  /// In fa, this message translates to:
  /// **'عجله‌ای نیست. هر تصمیمی بگیری درسته.'**
  String get staleNoPressure;

  /// No description provided for @historyTitle.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه'**
  String get historyTitle;

  /// No description provided for @periodToday.
  ///
  /// In fa, this message translates to:
  /// **'امروز'**
  String get periodToday;

  /// No description provided for @periodWeek.
  ///
  /// In fa, this message translates to:
  /// **'این هفته'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In fa, this message translates to:
  /// **'این ماه'**
  String get periodMonth;

  /// No description provided for @periodAll.
  ///
  /// In fa, this message translates to:
  /// **'همه'**
  String get periodAll;

  /// No description provided for @historyEmpty.
  ///
  /// In fa, this message translates to:
  /// **'هنوز چیزی در تاریخچه نیست'**
  String get historyEmpty;

  /// No description provided for @historyEmptyBody.
  ///
  /// In fa, this message translates to:
  /// **'کارهای انجام‌شده و کنار گذاشته‌شده اینجا می‌مانند.'**
  String get historyEmptyBody;

  /// No description provided for @historyDoneAt.
  ///
  /// In fa, this message translates to:
  /// **'انجام شد · {date}'**
  String historyDoneAt(String date);

  /// No description provided for @historyDroppedAt.
  ///
  /// In fa, this message translates to:
  /// **'کنار گذاشته شد · {date}'**
  String historyDroppedAt(String date);

  /// No description provided for @historyRestore.
  ///
  /// In fa, this message translates to:
  /// **'برگردان به لیست'**
  String get historyRestore;

  /// No description provided for @historyProNote.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه‌ی کامل (ماه و همه‌ی زمان‌ها) با Pro'**
  String get historyProNote;

  /// No description provided for @historyDisabled.
  ///
  /// In fa, this message translates to:
  /// **'ثبت تاریخچه خاموش است؛ فقط آمار ناشناس نگه داشته می‌شود.'**
  String get historyDisabled;

  /// No description provided for @statsTitle.
  ///
  /// In fa, this message translates to:
  /// **'آمار'**
  String get statsTitle;

  /// No description provided for @statsDone.
  ///
  /// In fa, this message translates to:
  /// **'انجام‌شده'**
  String get statsDone;

  /// No description provided for @statsDropped.
  ///
  /// In fa, this message translates to:
  /// **'کنار گذاشته‌شده'**
  String get statsDropped;

  /// No description provided for @statsDeleted.
  ///
  /// In fa, this message translates to:
  /// **'حذف‌شده'**
  String get statsDeleted;

  /// No description provided for @statsSnoozed.
  ///
  /// In fa, this message translates to:
  /// **'بار به تعویق افتاده'**
  String get statsSnoozed;

  /// No description provided for @statsActive.
  ///
  /// In fa, this message translates to:
  /// **'فعال'**
  String get statsActive;

  /// No description provided for @statsAvgWait.
  ///
  /// In fa, this message translates to:
  /// **'میانگین ماندن تا انجام'**
  String get statsAvgWait;

  /// No description provided for @statsDaysValue.
  ///
  /// In fa, this message translates to:
  /// **'{n} روز'**
  String statsDaysValue(String n);

  /// No description provided for @statsTopCategory.
  ///
  /// In fa, this message translates to:
  /// **'محبوب‌ترین دسته'**
  String get statsTopCategory;

  /// No description provided for @statsThisWeek.
  ///
  /// In fa, this message translates to:
  /// **'انجام‌شده در این هفته'**
  String get statsThisWeek;

  /// No description provided for @statsProLocked.
  ///
  /// In fa, this message translates to:
  /// **'آمار کامل با Pro'**
  String get statsProLocked;

  /// No description provided for @statsNoData.
  ///
  /// In fa, this message translates to:
  /// **'—'**
  String get statsNoData;

  /// No description provided for @settingsTitle.
  ///
  /// In fa, this message translates to:
  /// **'تنظیمات'**
  String get settingsTitle;

  /// No description provided for @secAppearance.
  ///
  /// In fa, this message translates to:
  /// **'ظاهر'**
  String get secAppearance;

  /// No description provided for @theme.
  ///
  /// In fa, this message translates to:
  /// **'تم'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In fa, this message translates to:
  /// **'روشن'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fa, this message translates to:
  /// **'تیره'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In fa, this message translates to:
  /// **'پیش‌فرض سیستم'**
  String get themeSystem;

  /// No description provided for @accent.
  ///
  /// In fa, this message translates to:
  /// **'رنگ اصلی'**
  String get accent;

  /// No description provided for @accentIndigo.
  ///
  /// In fa, this message translates to:
  /// **'بنفش'**
  String get accentIndigo;

  /// No description provided for @accentTeal.
  ///
  /// In fa, this message translates to:
  /// **'فیروزه‌ای'**
  String get accentTeal;

  /// No description provided for @accentRose.
  ///
  /// In fa, this message translates to:
  /// **'رُز'**
  String get accentRose;

  /// No description provided for @accentAmber.
  ///
  /// In fa, this message translates to:
  /// **'کهربایی'**
  String get accentAmber;

  /// No description provided for @accentSlate.
  ///
  /// In fa, this message translates to:
  /// **'خاکستری'**
  String get accentSlate;

  /// No description provided for @appIcon.
  ///
  /// In fa, this message translates to:
  /// **'آیکون برنامه'**
  String get appIcon;

  /// No description provided for @iconClassic.
  ///
  /// In fa, this message translates to:
  /// **'کلاسیک'**
  String get iconClassic;

  /// No description provided for @iconTeal.
  ///
  /// In fa, this message translates to:
  /// **'فیروزه‌ای'**
  String get iconTeal;

  /// No description provided for @iconRose.
  ///
  /// In fa, this message translates to:
  /// **'رُز'**
  String get iconRose;

  /// No description provided for @iconDark.
  ///
  /// In fa, this message translates to:
  /// **'تیره'**
  String get iconDark;

  /// No description provided for @iconChangeNote.
  ///
  /// In fa, this message translates to:
  /// **'با تغییر آیکون ممکن است چند لحظه‌ی دیگر در لانچر عوض شود.'**
  String get iconChangeNote;

  /// No description provided for @secReminders.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری'**
  String get secReminders;

  /// No description provided for @remindersToggle.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌ها'**
  String get remindersToggle;

  /// No description provided for @defaultReminderTime.
  ///
  /// In fa, this message translates to:
  /// **'ساعت پیش‌فرض یادآوری'**
  String get defaultReminderTime;

  /// No description provided for @privateNotifications.
  ///
  /// In fa, this message translates to:
  /// **'پنهان کردن متن در اعلان'**
  String get privateNotifications;

  /// No description provided for @privateNotificationsSub.
  ///
  /// In fa, this message translates to:
  /// **'عنوان موردها روی صفحه‌ی قفل دیده نشود.'**
  String get privateNotificationsSub;

  /// No description provided for @notifPermission.
  ///
  /// In fa, this message translates to:
  /// **'دسترسی اعلان'**
  String get notifPermission;

  /// No description provided for @notifPermissionOn.
  ///
  /// In fa, this message translates to:
  /// **'فعال است'**
  String get notifPermissionOn;

  /// No description provided for @notifPermissionOff.
  ///
  /// In fa, this message translates to:
  /// **'غیرفعال است؛ برای باز کردن تنظیمات بزن'**
  String get notifPermissionOff;

  /// No description provided for @exactAlarm.
  ///
  /// In fa, this message translates to:
  /// **'دقت یادآوری'**
  String get exactAlarm;

  /// No description provided for @exactAlarmOk.
  ///
  /// In fa, this message translates to:
  /// **'دقیق'**
  String get exactAlarmOk;

  /// No description provided for @exactAlarmOff.
  ///
  /// In fa, this message translates to:
  /// **'تقریبی؛ «هشدار دقیق» مجاز نشده'**
  String get exactAlarmOff;

  /// No description provided for @batteryOptimization.
  ///
  /// In fa, this message translates to:
  /// **'محدودیت باتری'**
  String get batteryOptimization;

  /// No description provided for @batteryOptimizationSub.
  ///
  /// In fa, this message translates to:
  /// **'بعضی گوشی‌ها یادآوری را می‌بندند؛ بزن تا تنظیمات باز شود.'**
  String get batteryOptimizationSub;

  /// No description provided for @sendTestNotification.
  ///
  /// In fa, this message translates to:
  /// **'ارسال اعلان آزمایشی'**
  String get sendTestNotification;

  /// No description provided for @testNotificationSent.
  ///
  /// In fa, this message translates to:
  /// **'اعلان آزمایشی ارسال شد.'**
  String get testNotificationSent;

  /// No description provided for @secGeneral.
  ///
  /// In fa, this message translates to:
  /// **'عمومی'**
  String get secGeneral;

  /// No description provided for @language.
  ///
  /// In fa, this message translates to:
  /// **'زبان'**
  String get language;

  /// No description provided for @langFa.
  ///
  /// In fa, this message translates to:
  /// **'فارسی'**
  String get langFa;

  /// No description provided for @langEn.
  ///
  /// In fa, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @calendar.
  ///
  /// In fa, this message translates to:
  /// **'تقویم'**
  String get calendar;

  /// No description provided for @calJalali.
  ///
  /// In fa, this message translates to:
  /// **'شمسی'**
  String get calJalali;

  /// No description provided for @calGregorian.
  ///
  /// In fa, this message translates to:
  /// **'میلادی'**
  String get calGregorian;

  /// No description provided for @weekStart.
  ///
  /// In fa, this message translates to:
  /// **'شروع هفته'**
  String get weekStart;

  /// No description provided for @weekendDay.
  ///
  /// In fa, this message translates to:
  /// **'روز آخر هفته'**
  String get weekendDay;

  /// No description provided for @keepHistory.
  ///
  /// In fa, this message translates to:
  /// **'نگه داشتن تاریخچه'**
  String get keepHistory;

  /// No description provided for @keepHistorySub.
  ///
  /// In fa, this message translates to:
  /// **'کارهای انجام‌شده و کنار گذاشته‌شده تو تاریخچه بمونن.'**
  String get keepHistorySub;

  /// No description provided for @staleAfter.
  ///
  /// In fa, this message translates to:
  /// **'مرور مانده‌ها بعد از'**
  String get staleAfter;

  /// No description provided for @daysN.
  ///
  /// In fa, this message translates to:
  /// **'{n} روز'**
  String daysN(String n);

  /// No description provided for @secData.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات'**
  String get secData;

  /// No description provided for @backupRestore.
  ///
  /// In fa, this message translates to:
  /// **'پشتیبان‌گیری و بازیابی'**
  String get backupRestore;

  /// No description provided for @categoriesManage.
  ///
  /// In fa, this message translates to:
  /// **'مدیریت دسته‌ها'**
  String get categoriesManage;

  /// No description provided for @secAbout.
  ///
  /// In fa, this message translates to:
  /// **'درباره'**
  String get secAbout;

  /// No description provided for @proSettingsTitle.
  ///
  /// In fa, this message translates to:
  /// **'بعداً Pro'**
  String get proSettingsTitle;

  /// No description provided for @proSettingsFree.
  ///
  /// In fa, this message translates to:
  /// **'نسخه‌ی رایگان'**
  String get proSettingsFree;

  /// No description provided for @proSettingsActive.
  ///
  /// In fa, this message translates to:
  /// **'فعال تا {date}'**
  String proSettingsActive(String date);

  /// No description provided for @about.
  ///
  /// In fa, this message translates to:
  /// **'درباره‌ی برنامه'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In fa, this message translates to:
  /// **'بعداً جای چیزهاییه که الان وقتشون نیست. بدون حساب کاربری، بدون سرور.'**
  String get aboutBody;

  /// No description provided for @aboutOffline.
  ///
  /// In fa, this message translates to:
  /// **'همه‌ی اطلاعات فقط روی دستگاه تو ذخیره می‌شود.'**
  String get aboutOffline;

  /// No description provided for @aboutLicenses.
  ///
  /// In fa, this message translates to:
  /// **'مجوزهای متن‌باز'**
  String get aboutLicenses;

  /// No description provided for @aboutContact.
  ///
  /// In fa, this message translates to:
  /// **'پشتیبانی'**
  String get aboutContact;

  /// No description provided for @version.
  ///
  /// In fa, this message translates to:
  /// **'نسخه'**
  String get version;

  /// No description provided for @versionValue.
  ///
  /// In fa, this message translates to:
  /// **'نسخه {v}'**
  String versionValue(String v);

  /// No description provided for @resetApp.
  ///
  /// In fa, this message translates to:
  /// **'پاک کردن همه‌ی اطلاعات'**
  String get resetApp;

  /// No description provided for @resetAppSub.
  ///
  /// In fa, this message translates to:
  /// **'همه‌ی موردها، دسته‌ها، تاریخچه و تنظیمات'**
  String get resetAppSub;

  /// No description provided for @resetConfirmTitle.
  ///
  /// In fa, this message translates to:
  /// **'همه‌چیز پاک شود؟'**
  String get resetConfirmTitle;

  /// No description provided for @resetConfirmBody.
  ///
  /// In fa, this message translates to:
  /// **'همه‌ی موردها، دسته‌ها، تاریخچه و تنظیمات این برنامه برای همیشه پاک می‌شه و برنمی‌گرده. اشتراک Pro از بین نمی‌ره. بهتره اول یه پشتیبان بگیری.'**
  String get resetConfirmBody;

  /// No description provided for @resetTypeHint.
  ///
  /// In fa, this message translates to:
  /// **'برای تأیید، کلمه‌ی «{word}» را بنویس'**
  String resetTypeHint(String word);

  /// No description provided for @resetWord.
  ///
  /// In fa, this message translates to:
  /// **'پاک'**
  String get resetWord;

  /// No description provided for @resetAction.
  ///
  /// In fa, this message translates to:
  /// **'پاک کردن همه‌چیز'**
  String get resetAction;

  /// No description provided for @resetDone.
  ///
  /// In fa, this message translates to:
  /// **'همه‌چیز پاک شد.'**
  String get resetDone;

  /// No description provided for @categoryName.
  ///
  /// In fa, this message translates to:
  /// **'{id, select, work{کار} read{خواندنی} watch{دیدنی} buy{خرید} idea{ایده} link{لینک} people{افراد} other{سایر}}'**
  String categoryName(String id);

  /// No description provided for @categoryNew.
  ///
  /// In fa, this message translates to:
  /// **'دسته‌ی جدید'**
  String get categoryNew;

  /// No description provided for @categoryEdit.
  ///
  /// In fa, this message translates to:
  /// **'ویرایش دسته'**
  String get categoryEdit;

  /// No description provided for @categoryNameHint.
  ///
  /// In fa, this message translates to:
  /// **'نام دسته'**
  String get categoryNameHint;

  /// No description provided for @categoryEmojiHint.
  ///
  /// In fa, this message translates to:
  /// **'ایموجی'**
  String get categoryEmojiHint;

  /// No description provided for @categoryLimit.
  ///
  /// In fa, this message translates to:
  /// **'نسخه‌ی رایگان {free} دسته‌ی سفارشی داره. با Pro تا {pro} تا می‌شه.'**
  String categoryLimit(String free, String pro);

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In fa, this message translates to:
  /// **'این دسته حذف شود؟'**
  String get categoryDeleteTitle;

  /// No description provided for @categoryDeleteBody.
  ///
  /// In fa, this message translates to:
  /// **'موردهای این دسته به «سایر» منتقل می‌شوند.'**
  String get categoryDeleteBody;

  /// No description provided for @categoryBuiltin.
  ///
  /// In fa, this message translates to:
  /// **'دسته‌ی پیش‌فرض'**
  String get categoryBuiltin;

  /// No description provided for @backupTitle.
  ///
  /// In fa, this message translates to:
  /// **'پشتیبان‌گیری و بازیابی'**
  String get backupTitle;

  /// No description provided for @backupIntro.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعاتت فقط روی همین گوشیه. قبل از عوض کردن گوشی یا نصب دوباره، یه فایل پشتیبان بگیر.'**
  String get backupIntro;

  /// No description provided for @backupExport.
  ///
  /// In fa, this message translates to:
  /// **'خروجی گرفتن از اطلاعات'**
  String get backupExport;

  /// No description provided for @backupExportSub.
  ///
  /// In fa, this message translates to:
  /// **'یک فایل ‎.later‎ با همه‌ی موردها، دسته‌ها، تاریخچه و تنظیمات'**
  String get backupExportSub;

  /// No description provided for @backupImport.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی از فایل'**
  String get backupImport;

  /// No description provided for @backupImportSub.
  ///
  /// In fa, this message translates to:
  /// **'فایل پشتیبانِ قبلی را انتخاب کن'**
  String get backupImportSub;

  /// No description provided for @backupLast.
  ///
  /// In fa, this message translates to:
  /// **'آخرین پشتیبان: {date}'**
  String backupLast(String date);

  /// No description provided for @backupNever.
  ///
  /// In fa, this message translates to:
  /// **'هنوز پشتیبان نگرفته‌ای'**
  String get backupNever;

  /// No description provided for @backupExported.
  ///
  /// In fa, this message translates to:
  /// **'پشتیبان ذخیره شد ✓'**
  String get backupExported;

  /// No description provided for @backupAuto.
  ///
  /// In fa, this message translates to:
  /// **'پشتیبان خودکار هفتگی'**
  String get backupAuto;

  /// No description provided for @backupAutoSub.
  ///
  /// In fa, this message translates to:
  /// **'تا ۵ نسخه در حافظه‌ی خصوصی برنامه نگه داشته می‌شود (Pro).'**
  String get backupAutoSub;

  /// No description provided for @backupAdvancedExport.
  ///
  /// In fa, this message translates to:
  /// **'خروجی‌های بیشتر (Pro)'**
  String get backupAdvancedExport;

  /// No description provided for @exportCsv.
  ///
  /// In fa, this message translates to:
  /// **'خروجی CSV'**
  String get exportCsv;

  /// No description provided for @exportText.
  ///
  /// In fa, this message translates to:
  /// **'خروجی متنی (Markdown)'**
  String get exportText;

  /// No description provided for @exportSaved.
  ///
  /// In fa, this message translates to:
  /// **'فایل ذخیره شد ✓'**
  String get exportSaved;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی اطلاعات؟'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmReplace.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات فعلی ({current} مورد) با محتوای فایل ({incoming} مورد، ساخته‌شده در {date}) جایگزین می‌شود.\nپیش از آن یک نسخه‌ی ایمنی از اطلاعات فعلی نگه داشته می‌شود.'**
  String restoreConfirmReplace(String current, String date, String incoming);

  /// No description provided for @restoreConfirmEmpty.
  ///
  /// In fa, this message translates to:
  /// **'فایل شامل {incoming} مورد است (ساخته‌شده در {date}).'**
  String restoreConfirmEmpty(String date, String incoming);

  /// No description provided for @restoreAction.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی'**
  String get restoreAction;

  /// No description provided for @restoreDone.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات بازیابی شد ✓'**
  String get restoreDone;

  /// No description provided for @restoreProRestored.
  ///
  /// In fa, this message translates to:
  /// **'اشتراک Pro هم از پشتیبان بازیابی شد.'**
  String get restoreProRestored;

  /// No description provided for @backupErrEmpty.
  ///
  /// In fa, this message translates to:
  /// **'فایل خالی است.'**
  String get backupErrEmpty;

  /// No description provided for @backupErrTooLarge.
  ///
  /// In fa, this message translates to:
  /// **'فایل خیلی بزرگ است.'**
  String get backupErrTooLarge;

  /// No description provided for @backupErrNotJson.
  ///
  /// In fa, this message translates to:
  /// **'فایل خراب یا ناقص است.'**
  String get backupErrNotJson;

  /// No description provided for @backupErrNotBackup.
  ///
  /// In fa, this message translates to:
  /// **'این فایل پشتیبان «بعداً» نیست.'**
  String get backupErrNotBackup;

  /// No description provided for @backupErrMissing.
  ///
  /// In fa, this message translates to:
  /// **'فایل ناقص است.'**
  String get backupErrMissing;

  /// No description provided for @backupErrFuture.
  ///
  /// In fa, this message translates to:
  /// **'این پشتیبان با نسخه‌ی جدیدتری از برنامه ساخته شده. برنامه را به‌روزرسانی کن.'**
  String get backupErrFuture;

  /// No description provided for @backupErrUnsupported.
  ///
  /// In fa, this message translates to:
  /// **'قالب این پشتیبان دیگر پشتیبانی نمی‌شود.'**
  String get backupErrUnsupported;

  /// No description provided for @backupErrChecksum.
  ///
  /// In fa, this message translates to:
  /// **'فایل آسیب دیده یا ویرایش شده است.'**
  String get backupErrChecksum;

  /// No description provided for @backupErrInvalid.
  ///
  /// In fa, this message translates to:
  /// **'محتوای فایل معتبر نیست.'**
  String get backupErrInvalid;

  /// No description provided for @backupErrMigration.
  ///
  /// In fa, this message translates to:
  /// **'به‌روزرسانی قالب فایل ناموفق بود.'**
  String get backupErrMigration;

  /// No description provided for @backupErrGeneric.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی انجام نشد. اطلاعات فعلی دست‌نخورده ماند.'**
  String get backupErrGeneric;

  /// No description provided for @backupNoChange.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات فعلی تغییری نکرد.'**
  String get backupNoChange;

  /// No description provided for @proTitle.
  ///
  /// In fa, this message translates to:
  /// **'بعداً Pro'**
  String get proTitle;

  /// No description provided for @proHeadline.
  ///
  /// In fa, this message translates to:
  /// **'اگه زیاد از «بعداً» استفاده می‌کنی، Pro کارت رو راحت‌تر می‌کنه.'**
  String get proHeadline;

  /// No description provided for @proFreeNote.
  ///
  /// In fa, this message translates to:
  /// **'نسخه‌ی رایگان ناقص نیست. اگه Pro تموم بشه هم چیزی از اطلاعاتت پاک یا قفل نمی‌شه.'**
  String get proFreeNote;

  /// No description provided for @proActiveUntil.
  ///
  /// In fa, this message translates to:
  /// **'فعال تا {date}'**
  String proActiveUntil(String date);

  /// No description provided for @proRemaining.
  ///
  /// In fa, this message translates to:
  /// **'{n} روز باقی مانده'**
  String proRemaining(String n);

  /// No description provided for @proExpiredNote.
  ///
  /// In fa, this message translates to:
  /// **'اشتراک Pro تموم شده. اطلاعاتت سر جاشه؛ فقط قابلیت‌های Pro خاموش شدن.'**
  String get proExpiredNote;

  /// No description provided for @proPlan1.
  ///
  /// In fa, this message translates to:
  /// **'۱ ماهه'**
  String get proPlan1;

  /// No description provided for @proPlan3.
  ///
  /// In fa, this message translates to:
  /// **'۳ ماهه'**
  String get proPlan3;

  /// No description provided for @proPlan6.
  ///
  /// In fa, this message translates to:
  /// **'۶ ماهه'**
  String get proPlan6;

  /// No description provided for @proPlanDay1.
  ///
  /// In fa, this message translates to:
  /// **'۱ روزه (آزمایشی)'**
  String get proPlanDay1;

  /// No description provided for @proPlanDay7.
  ///
  /// In fa, this message translates to:
  /// **'۷ روزه (آزمایشی)'**
  String get proPlanDay7;

  /// No description provided for @priceToman.
  ///
  /// In fa, this message translates to:
  /// **'{price} تومان'**
  String priceToman(String price);

  /// No description provided for @proBuy.
  ///
  /// In fa, this message translates to:
  /// **'خرید'**
  String get proBuy;

  /// No description provided for @proExtend.
  ///
  /// In fa, this message translates to:
  /// **'تمدید'**
  String get proExtend;

  /// No description provided for @proStackNote.
  ///
  /// In fa, this message translates to:
  /// **'اگه وسط اشتراک دوباره بخری، روزهای مونده از بین نمی‌رن؛ مدت جدید بهشون اضافه می‌شه.'**
  String get proStackNote;

  /// No description provided for @proRestore.
  ///
  /// In fa, this message translates to:
  /// **'بازیابی خریدها'**
  String get proRestore;

  /// No description provided for @proRestored.
  ///
  /// In fa, this message translates to:
  /// **'{n} خرید برگشت'**
  String proRestored(String n);

  /// No description provided for @proNothingToRestore.
  ///
  /// In fa, this message translates to:
  /// **'خرید بازیابی‌نشده‌ای پیدا نشد.'**
  String get proNothingToRestore;

  /// No description provided for @proPurchaseSuccess.
  ///
  /// In fa, this message translates to:
  /// **'Pro فعال شد'**
  String get proPurchaseSuccess;

  /// No description provided for @proPurchaseCancelled.
  ///
  /// In fa, this message translates to:
  /// **'خرید لغو شد.'**
  String get proPurchaseCancelled;

  /// No description provided for @proPurchaseUnavailable.
  ///
  /// In fa, this message translates to:
  /// **'سرویس پرداخت در دسترس نیست. برنامه‌ی کافه‌بازار را بررسی کن.'**
  String get proPurchaseUnavailable;

  /// No description provided for @proPurchaseFailed.
  ///
  /// In fa, this message translates to:
  /// **'خرید انجام نشد. دوباره تلاش کن.'**
  String get proPurchaseFailed;

  /// No description provided for @proTamper.
  ///
  /// In fa, this message translates to:
  /// **'اطلاعات اشتراک درست نبود و پاک شد. اگه خرید کرده بودی «بازیابی خریدها» رو بزن.'**
  String get proTamper;

  /// No description provided for @proF1.
  ///
  /// In fa, this message translates to:
  /// **'قرعه‌ی هوشمند و صندوق ورودی هوشمند'**
  String get proF1;

  /// No description provided for @proF2.
  ///
  /// In fa, this message translates to:
  /// **'جستجو و فیلتر پیشرفته'**
  String get proF2;

  /// No description provided for @proF3.
  ///
  /// In fa, this message translates to:
  /// **'آمار و تاریخچه‌ی کامل'**
  String get proF3;

  /// No description provided for @proF4.
  ///
  /// In fa, this message translates to:
  /// **'دسته‌ی سفارشی بیشتر'**
  String get proF4;

  /// No description provided for @proF5.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری تکرارشونده'**
  String get proF5;

  /// No description provided for @proF6.
  ///
  /// In fa, this message translates to:
  /// **'ویجت لیستی'**
  String get proF6;

  /// No description provided for @proF7.
  ///
  /// In fa, this message translates to:
  /// **'رنگ و آیکون بیشتر'**
  String get proF7;

  /// No description provided for @proF8.
  ///
  /// In fa, this message translates to:
  /// **'پشتیبان خودکار و خروجی CSV'**
  String get proF8;

  /// No description provided for @proLockedTitle.
  ///
  /// In fa, this message translates to:
  /// **'این امکان مخصوص Pro است'**
  String get proLockedTitle;

  /// No description provided for @proLockedBody.
  ///
  /// In fa, this message translates to:
  /// **'این یکی مال Pro ـه. بقیه‌ی برنامه بدون Pro هم کامل کار می‌کنه.'**
  String get proLockedBody;

  /// No description provided for @proSeePlans.
  ///
  /// In fa, this message translates to:
  /// **'دیدن پلن‌ها'**
  String get proSeePlans;

  /// No description provided for @notNow.
  ///
  /// In fa, this message translates to:
  /// **'حالا نه'**
  String get notNow;

  /// No description provided for @qaTitle.
  ///
  /// In fa, this message translates to:
  /// **'ابزار تست (فقط نسخه‌ی آزمایشی)'**
  String get qaTitle;

  /// No description provided for @qaNote.
  ///
  /// In fa, this message translates to:
  /// **'این بخش در نسخه‌ی بازار وجود ندارد.'**
  String get qaNote;

  /// No description provided for @qaGrantPlan.
  ///
  /// In fa, this message translates to:
  /// **'شبیه‌سازی خرید {plan}'**
  String qaGrantPlan(String plan);

  /// No description provided for @qaClearPro.
  ///
  /// In fa, this message translates to:
  /// **'حذف Pro'**
  String get qaClearPro;

  /// No description provided for @qaAdvance.
  ///
  /// In fa, this message translates to:
  /// **'جلو بردن ساعت برنامه: {n} روز'**
  String qaAdvance(String n);

  /// No description provided for @qaResetTime.
  ///
  /// In fa, this message translates to:
  /// **'بازنشانی ساعت شبیه‌سازی‌شده'**
  String get qaResetTime;

  /// No description provided for @qaClock.
  ///
  /// In fa, this message translates to:
  /// **'ساعت برنامه: {date}'**
  String qaClock(String date);

  /// No description provided for @qaSeed.
  ///
  /// In fa, this message translates to:
  /// **'افزودن {n} مورد نمونه'**
  String qaSeed(String n);

  /// No description provided for @qaSeedShelves.
  ///
  /// In fa, this message translates to:
  /// **'نمونه‌ی قفسه‌ها، آدم‌ها و کپسول'**
  String get qaSeedShelves;

  /// No description provided for @qaSeeded.
  ///
  /// In fa, this message translates to:
  /// **'{n} مورد اضافه شد.'**
  String qaSeeded(String n);

  /// No description provided for @qaNotifNow.
  ///
  /// In fa, this message translates to:
  /// **'اعلان همین حالا'**
  String get qaNotifNow;

  /// No description provided for @qaNotifIn.
  ///
  /// In fa, this message translates to:
  /// **'اعلان تا {s} ثانیه‌ی دیگر'**
  String qaNotifIn(String s);

  /// No description provided for @qaProState.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت Pro: {state}'**
  String qaProState(String state);

  /// No description provided for @notifChannelName.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌ها'**
  String get notifChannelName;

  /// No description provided for @notifChannelDescription.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری موردهایی که برای بعداً گذاشته‌ای'**
  String get notifChannelDescription;

  /// No description provided for @notifActionDone.
  ///
  /// In fa, this message translates to:
  /// **'انجام شد'**
  String get notifActionDone;

  /// No description provided for @notifActionTomorrow.
  ///
  /// In fa, this message translates to:
  /// **'فردا'**
  String get notifActionTomorrow;

  /// No description provided for @notifPrivateBody.
  ///
  /// In fa, this message translates to:
  /// **'یه مورد منتظر توست'**
  String get notifPrivateBody;

  /// No description provided for @notifBodyGeneric.
  ///
  /// In fa, this message translates to:
  /// **'بعداً'**
  String get notifBodyGeneric;

  /// No description provided for @notifTestTitle.
  ///
  /// In fa, this message translates to:
  /// **'اعلان آزمایشی'**
  String get notifTestTitle;

  /// No description provided for @notifTestBody.
  ///
  /// In fa, this message translates to:
  /// **'اگر این را می‌بینی، اعلان‌ها کار می‌کنند ✓'**
  String get notifTestBody;

  /// No description provided for @reminderPermissionBanner.
  ///
  /// In fa, this message translates to:
  /// **'اجازه‌ی اعلان داده نشده، برای همین یادآوری‌ها نمایش داده نمی‌شن.'**
  String get reminderPermissionBanner;

  /// No description provided for @reminderSyncFailed.
  ///
  /// In fa, this message translates to:
  /// **'برخی یادآوری‌ها ثبت نشدند.'**
  String get reminderSyncFailed;

  /// No description provided for @reminderApproximate.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌ها تقریبی‌اند؛ برای دقت بیشتر «هشدار دقیق» را مجاز کن.'**
  String get reminderApproximate;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In fa, this message translates to:
  /// **'اجازه‌ی اعلان لازم است'**
  String get permissionDeniedTitle;

  /// No description provided for @permissionDeniedBody.
  ///
  /// In fa, this message translates to:
  /// **'برای اینکه بعداً بتونم یادت بندازم، اجازه‌ی اعلان را فعال کن.'**
  String get permissionDeniedBody;

  /// No description provided for @openSettings.
  ///
  /// In fa, this message translates to:
  /// **'باز کردن تنظیمات'**
  String get openSettings;

  /// No description provided for @shareAdded.
  ///
  /// In fa, this message translates to:
  /// **'«{title}» به بعداً اضافه شد'**
  String shareAdded(String title);

  /// No description provided for @widgetWaiting.
  ///
  /// In fa, this message translates to:
  /// **'{n} مورد منتظرند'**
  String widgetWaiting(String n);

  /// No description provided for @widgetEmpty.
  ///
  /// In fa, this message translates to:
  /// **'چیزی منتظر نیست 🌱'**
  String get widgetEmpty;

  /// No description provided for @widgetAdd.
  ///
  /// In fa, this message translates to:
  /// **'+ اضافه کن'**
  String get widgetAdd;

  /// No description provided for @widgetPick.
  ///
  /// In fa, this message translates to:
  /// **'🎯 پیشنهاد'**
  String get widgetPick;

  /// No description provided for @widgetProOnly.
  ///
  /// In fa, this message translates to:
  /// **'ویجت پیشرفته مخصوص Pro است'**
  String get widgetProOnly;

  /// No description provided for @widgetSuggestion.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد'**
  String get widgetSuggestion;

  /// No description provided for @shortcutAdd.
  ///
  /// In fa, this message translates to:
  /// **'اضافه کردن'**
  String get shortcutAdd;

  /// No description provided for @shortcutPick.
  ///
  /// In fa, this message translates to:
  /// **'یه مورد بهم بده'**
  String get shortcutPick;

  /// No description provided for @shortcutSearch.
  ///
  /// In fa, this message translates to:
  /// **'جستجو'**
  String get shortcutSearch;

  /// No description provided for @licensesLegalese.
  ///
  /// In fa, this message translates to:
  /// **'ساخته‌شده با فلاتر. فونت وزیرمتن (مجوز OFL).'**
  String get licensesLegalese;

  /// No description provided for @repeatYearly.
  ///
  /// In fa, this message translates to:
  /// **'هر سال'**
  String get repeatYearly;

  /// No description provided for @defaultCapsuleTitle.
  ///
  /// In fa, this message translates to:
  /// **'کپسول بی‌نام'**
  String get defaultCapsuleTitle;

  /// No description provided for @defaultMessageTitle.
  ///
  /// In fa, this message translates to:
  /// **'پیام بی‌نام'**
  String get defaultMessageTitle;

  /// No description provided for @typeName.
  ///
  /// In fa, this message translates to:
  /// **'{id, select, task{کار} read{مقاله} watch{ویدیو} wishlist{خرید} idea{ایده} person{آدم} capsule{کپسول} future{پیام} other{مورد}}'**
  String typeName(String id);

  /// No description provided for @daysAgo.
  ///
  /// In fa, this message translates to:
  /// **'{n} روز پیش'**
  String daysAgo(String n);

  /// No description provided for @dashRoulette.
  ///
  /// In fa, this message translates to:
  /// **'قرعه بعداً'**
  String get dashRoulette;

  /// No description provided for @dashInbox.
  ///
  /// In fa, this message translates to:
  /// **'صندوق ورودی'**
  String get dashInbox;

  /// No description provided for @dashInboxCount.
  ///
  /// In fa, this message translates to:
  /// **'{n} مورد منتظر مرتب شدنه'**
  String dashInboxCount(String n);

  /// No description provided for @dashInboxEmpty.
  ///
  /// In fa, this message translates to:
  /// **'صندوقت خالیه'**
  String get dashInboxEmpty;

  /// No description provided for @dashShelves.
  ///
  /// In fa, this message translates to:
  /// **'قفسه‌ها'**
  String get dashShelves;

  /// No description provided for @shelfReadTitle.
  ///
  /// In fa, this message translates to:
  /// **'بعداً بخون'**
  String get shelfReadTitle;

  /// No description provided for @shelfWatchTitle.
  ///
  /// In fa, this message translates to:
  /// **'بعداً ببین'**
  String get shelfWatchTitle;

  /// No description provided for @shelfWishTitle.
  ///
  /// In fa, this message translates to:
  /// **'بعداً بخر'**
  String get shelfWishTitle;

  /// No description provided for @shelfIdeaTitle.
  ///
  /// In fa, this message translates to:
  /// **'ایده‌ها'**
  String get shelfIdeaTitle;

  /// No description provided for @shelfPeopleTitle.
  ///
  /// In fa, this message translates to:
  /// **'آدم‌ها'**
  String get shelfPeopleTitle;

  /// No description provided for @shelfFutureTitle.
  ///
  /// In fa, this message translates to:
  /// **'آینده'**
  String get shelfFutureTitle;

  /// No description provided for @returnedBanner.
  ///
  /// In fa, this message translates to:
  /// **'یه چیز از گذشته برگشته'**
  String get returnedBanner;

  /// No description provided for @returnedBannerBody.
  ///
  /// In fa, this message translates to:
  /// **'بازش کن ببین چی بوده.'**
  String get returnedBannerBody;

  /// No description provided for @ideaReviewBanner.
  ///
  /// In fa, this message translates to:
  /// **'{n} ایده وقت مرور دارن'**
  String ideaReviewBanner(String n);

  /// No description provided for @searchEverywhere.
  ///
  /// In fa, this message translates to:
  /// **'جستجو در همه‌چیز'**
  String get searchEverywhere;

  /// No description provided for @searchEverywhereHint.
  ///
  /// In fa, this message translates to:
  /// **'کار، مقاله، ایده، آدم…'**
  String get searchEverywhereHint;

  /// No description provided for @searchNothing.
  ///
  /// In fa, this message translates to:
  /// **'چیزی پیدا نشد'**
  String get searchNothing;

  /// No description provided for @searchStartTyping.
  ///
  /// In fa, this message translates to:
  /// **'یه کلمه بنویس.'**
  String get searchStartTyping;

  /// No description provided for @searchDone.
  ///
  /// In fa, this message translates to:
  /// **'انجام‌شده'**
  String get searchDone;

  /// No description provided for @addTypeLabel.
  ///
  /// In fa, this message translates to:
  /// **'این چیه؟'**
  String get addTypeLabel;

  /// No description provided for @addTypeAuto.
  ///
  /// In fa, this message translates to:
  /// **'بعداً مرتبش می‌کنم'**
  String get addTypeAuto;

  /// No description provided for @fieldPrice.
  ///
  /// In fa, this message translates to:
  /// **'قیمت'**
  String get fieldPrice;

  /// No description provided for @fieldCurrency.
  ///
  /// In fa, this message translates to:
  /// **'واحد پول'**
  String get fieldCurrency;

  /// No description provided for @currencyDefault.
  ///
  /// In fa, this message translates to:
  /// **'تومان'**
  String get currencyDefault;

  /// No description provided for @fieldWatchKind.
  ///
  /// In fa, this message translates to:
  /// **'نوع'**
  String get fieldWatchKind;

  /// No description provided for @kindVideo.
  ///
  /// In fa, this message translates to:
  /// **'ویدیو'**
  String get kindVideo;

  /// No description provided for @kindMovie.
  ///
  /// In fa, this message translates to:
  /// **'فیلم'**
  String get kindMovie;

  /// No description provided for @kindSeries.
  ///
  /// In fa, this message translates to:
  /// **'سریال'**
  String get kindSeries;

  /// No description provided for @kindOther.
  ///
  /// In fa, this message translates to:
  /// **'دیگر'**
  String get kindOther;

  /// No description provided for @stageUnread.
  ///
  /// In fa, this message translates to:
  /// **'نخونده'**
  String get stageUnread;

  /// No description provided for @stageReading.
  ///
  /// In fa, this message translates to:
  /// **'دارم می‌خونم'**
  String get stageReading;

  /// No description provided for @stageRead.
  ///
  /// In fa, this message translates to:
  /// **'خونده'**
  String get stageRead;

  /// No description provided for @stageArchived.
  ///
  /// In fa, this message translates to:
  /// **'بایگانی'**
  String get stageArchived;

  /// No description provided for @stageUnwatched.
  ///
  /// In fa, this message translates to:
  /// **'ندیده'**
  String get stageUnwatched;

  /// No description provided for @stageWatching.
  ///
  /// In fa, this message translates to:
  /// **'دارم می‌بینم'**
  String get stageWatching;

  /// No description provided for @stageWatched.
  ///
  /// In fa, this message translates to:
  /// **'دیده'**
  String get stageWatched;

  /// No description provided for @stageInterested.
  ///
  /// In fa, this message translates to:
  /// **'می‌خوامش'**
  String get stageInterested;

  /// No description provided for @stageMaybe.
  ///
  /// In fa, this message translates to:
  /// **'شاید'**
  String get stageMaybe;

  /// No description provided for @stageBought.
  ///
  /// In fa, this message translates to:
  /// **'خریدم'**
  String get stageBought;

  /// No description provided for @stageNotInterested.
  ///
  /// In fa, this message translates to:
  /// **'دیگه نمی‌خوامش'**
  String get stageNotInterested;

  /// No description provided for @stageIdeaNew.
  ///
  /// In fa, this message translates to:
  /// **'تازه'**
  String get stageIdeaNew;

  /// No description provided for @stageThinking.
  ///
  /// In fa, this message translates to:
  /// **'دارم فکر می‌کنم'**
  String get stageThinking;

  /// No description provided for @stageDeveloping.
  ///
  /// In fa, this message translates to:
  /// **'دارم پرورشش می‌دم'**
  String get stageDeveloping;

  /// No description provided for @stageIdeaArchived.
  ///
  /// In fa, this message translates to:
  /// **'بایگانی'**
  String get stageIdeaArchived;

  /// No description provided for @stageIdeaDropped.
  ///
  /// In fa, this message translates to:
  /// **'ولش کردم'**
  String get stageIdeaDropped;

  /// No description provided for @stageSealed.
  ///
  /// In fa, this message translates to:
  /// **'قفل'**
  String get stageSealed;

  /// No description provided for @stageOpened.
  ///
  /// In fa, this message translates to:
  /// **'باز شده'**
  String get stageOpened;

  /// No description provided for @markAsRead.
  ///
  /// In fa, this message translates to:
  /// **'خوندم'**
  String get markAsRead;

  /// No description provided for @markAsWatched.
  ///
  /// In fa, this message translates to:
  /// **'دیدم'**
  String get markAsWatched;

  /// No description provided for @markAsBought.
  ///
  /// In fa, this message translates to:
  /// **'خریدم'**
  String get markAsBought;

  /// No description provided for @itemStage.
  ///
  /// In fa, this message translates to:
  /// **'وضعیت'**
  String get itemStage;

  /// No description provided for @moveToShelf.
  ///
  /// In fa, this message translates to:
  /// **'منتقل کن به…'**
  String get moveToShelf;

  /// No description provided for @movedTo.
  ///
  /// In fa, this message translates to:
  /// **'رفت به «{shelf}»'**
  String movedTo(String shelf);

  /// No description provided for @shelfEmptyReadTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز چیزی برای خوندن نذاشتی'**
  String get shelfEmptyReadTitle;

  /// No description provided for @shelfEmptyReadBody.
  ///
  /// In fa, this message translates to:
  /// **'لینک مقاله رو با «اشتراک‌گذاری» بفرست به بعداً.'**
  String get shelfEmptyReadBody;

  /// No description provided for @shelfEmptyWatchTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز ویدیویی نذاشتی'**
  String get shelfEmptyWatchTitle;

  /// No description provided for @shelfEmptyWatchBody.
  ///
  /// In fa, this message translates to:
  /// **'لینک یوتیوب یا اسم یه فیلم رو اینجا نگه دار.'**
  String get shelfEmptyWatchBody;

  /// No description provided for @shelfEmptyWishTitle.
  ///
  /// In fa, this message translates to:
  /// **'فهرست خریدت خالیه'**
  String get shelfEmptyWishTitle;

  /// No description provided for @shelfEmptyWishBody.
  ///
  /// In fa, this message translates to:
  /// **'چیزی که شاید بخوای بخری رو اینجا بذار. بعد از یه مدت می‌پرسم هنوز می‌خوایش یا نه.'**
  String get shelfEmptyWishBody;

  /// No description provided for @shelfEmptyIdeaTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز ایده‌ای نذاشتی'**
  String get shelfEmptyIdeaTitle;

  /// No description provided for @shelfEmptyIdeaBody.
  ///
  /// In fa, this message translates to:
  /// **'ایده‌ها اینجا می‌مونن تا وقتش برسه.'**
  String get shelfEmptyIdeaBody;

  /// No description provided for @shelfWaiting.
  ///
  /// In fa, this message translates to:
  /// **'در انتظار'**
  String get shelfWaiting;

  /// No description provided for @shelfHistory.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه'**
  String get shelfHistory;

  /// No description provided for @shelfAllStages.
  ///
  /// In fa, this message translates to:
  /// **'همه'**
  String get shelfAllStages;

  /// No description provided for @shelfStatsTitle.
  ///
  /// In fa, this message translates to:
  /// **'آمار'**
  String get shelfStatsTitle;

  /// No description provided for @shelfAdvancedFilters.
  ///
  /// In fa, this message translates to:
  /// **'فیلتر پیشرفته'**
  String get shelfAdvancedFilters;

  /// No description provided for @shelfHistoryPro.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه‌ی این قفسه با Pro'**
  String get shelfHistoryPro;

  /// No description provided for @shelfCollections.
  ///
  /// In fa, this message translates to:
  /// **'فهرست‌ها'**
  String get shelfCollections;

  /// No description provided for @shelfCollectionMain.
  ///
  /// In fa, this message translates to:
  /// **'اصلی'**
  String get shelfCollectionMain;

  /// No description provided for @collectionNew.
  ///
  /// In fa, this message translates to:
  /// **'فهرست جدید'**
  String get collectionNew;

  /// No description provided for @collectionName.
  ///
  /// In fa, this message translates to:
  /// **'اسم فهرست'**
  String get collectionName;

  /// No description provided for @collectionProHint.
  ///
  /// In fa, this message translates to:
  /// **'چند فهرست جدا با Pro'**
  String get collectionProHint;

  /// No description provided for @sortByPrice.
  ///
  /// In fa, this message translates to:
  /// **'قیمت'**
  String get sortByPrice;

  /// No description provided for @sortByScore.
  ///
  /// In fa, this message translates to:
  /// **'امتیاز'**
  String get sortByScore;

  /// No description provided for @sortByTime.
  ///
  /// In fa, this message translates to:
  /// **'زمان تخمینی'**
  String get sortByTime;

  /// No description provided for @statsWaiting.
  ///
  /// In fa, this message translates to:
  /// **'در انتظار'**
  String get statsWaiting;

  /// No description provided for @statsFinished.
  ///
  /// In fa, this message translates to:
  /// **'تموم‌شده'**
  String get statsFinished;

  /// No description provided for @statsThisMonth.
  ///
  /// In fa, this message translates to:
  /// **'این ماه'**
  String get statsThisMonth;

  /// No description provided for @statsMinutesWaiting.
  ///
  /// In fa, this message translates to:
  /// **'زمان کل منتظر'**
  String get statsMinutesWaiting;

  /// No description provided for @statsAvgFinish.
  ///
  /// In fa, this message translates to:
  /// **'میانگین تا تموم شدن'**
  String get statsAvgFinish;

  /// No description provided for @statsTotalPrice.
  ///
  /// In fa, this message translates to:
  /// **'جمع قیمت‌ها'**
  String get statsTotalPrice;

  /// No description provided for @readTimeEstimate.
  ///
  /// In fa, this message translates to:
  /// **'حدود {n} دقیقه'**
  String readTimeEstimate(String n);

  /// No description provided for @linkHost.
  ///
  /// In fa, this message translates to:
  /// **'از {host}'**
  String linkHost(String host);

  /// No description provided for @priceNow.
  ///
  /// In fa, this message translates to:
  /// **'قیمت'**
  String get priceNow;

  /// No description provided for @priceSetNew.
  ///
  /// In fa, this message translates to:
  /// **'ثبت قیمت تازه'**
  String get priceSetNew;

  /// No description provided for @priceTarget.
  ///
  /// In fa, this message translates to:
  /// **'قیمت هدف'**
  String get priceTarget;

  /// No description provided for @priceTargetReached.
  ///
  /// In fa, this message translates to:
  /// **'به قیمت هدفت رسیده'**
  String get priceTargetReached;

  /// No description provided for @priceHistoryTitle.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه‌ی قیمت'**
  String get priceHistoryTitle;

  /// No description provided for @priceHistoryEmpty.
  ///
  /// In fa, this message translates to:
  /// **'هنوز قیمتی ثبت نشده.'**
  String get priceHistoryEmpty;

  /// No description provided for @priceHint.
  ///
  /// In fa, this message translates to:
  /// **'مثلاً ۱۲۰۰۰۰۰'**
  String get priceHint;

  /// No description provided for @wishProHint.
  ///
  /// In fa, this message translates to:
  /// **'قیمت هدف و تاریخچه‌ی قیمت با Pro'**
  String get wishProHint;

  /// No description provided for @wishReviewTitle.
  ///
  /// In fa, this message translates to:
  /// **'واقعاً هنوز می‌خوایش؟'**
  String get wishReviewTitle;

  /// No description provided for @wishReviewQuestion.
  ///
  /// In fa, this message translates to:
  /// **'این {days} روزه تو فهرستته.\nهنوز می‌خوای بخریش؟'**
  String wishReviewQuestion(String days);

  /// No description provided for @wishStill.
  ///
  /// In fa, this message translates to:
  /// **'هنوز می‌خوام'**
  String get wishStill;

  /// No description provided for @wishUnsure.
  ///
  /// In fa, this message translates to:
  /// **'مطمئن نیستم'**
  String get wishUnsure;

  /// No description provided for @wishNo.
  ///
  /// In fa, this message translates to:
  /// **'دیگه نمی‌خوام'**
  String get wishNo;

  /// No description provided for @ideaReviewTitle.
  ///
  /// In fa, this message translates to:
  /// **'مرور ایده‌ها'**
  String get ideaReviewTitle;

  /// No description provided for @ideaReviewNone.
  ///
  /// In fa, this message translates to:
  /// **'چیزی برای مرور نیست.'**
  String get ideaReviewNone;

  /// No description provided for @ideaReviewIntro.
  ///
  /// In fa, this message translates to:
  /// **'هر ایده رو یه نگاه بنداز و بگو چیکارش کنیم.'**
  String get ideaReviewIntro;

  /// No description provided for @ideaScore.
  ///
  /// In fa, this message translates to:
  /// **'امتیاز'**
  String get ideaScore;

  /// No description provided for @ideaLinks.
  ///
  /// In fa, this message translates to:
  /// **'ایده‌های مرتبط'**
  String get ideaLinks;

  /// No description provided for @ideaAddLink.
  ///
  /// In fa, this message translates to:
  /// **'وصل کن به یه ایده‌ی دیگه'**
  String get ideaAddLink;

  /// No description provided for @ideaToTask.
  ///
  /// In fa, this message translates to:
  /// **'تبدیل به کار'**
  String get ideaToTask;

  /// No description provided for @ideaConverted.
  ///
  /// In fa, this message translates to:
  /// **'حالا یه کاره'**
  String get ideaConverted;

  /// No description provided for @ideaKeepThinking.
  ///
  /// In fa, this message translates to:
  /// **'هنوز فکر می‌کنم'**
  String get ideaKeepThinking;

  /// No description provided for @ideaDevelop.
  ///
  /// In fa, this message translates to:
  /// **'می‌خوام پرورشش بدم'**
  String get ideaDevelop;

  /// No description provided for @ideaArchiveIt.
  ///
  /// In fa, this message translates to:
  /// **'بایگانی'**
  String get ideaArchiveIt;

  /// No description provided for @ideaDropIt.
  ///
  /// In fa, this message translates to:
  /// **'ولش کن'**
  String get ideaDropIt;

  /// No description provided for @ideaLastReviewed.
  ///
  /// In fa, this message translates to:
  /// **'آخرین مرور: {when}'**
  String ideaLastReviewed(String when);

  /// No description provided for @ideaNeverReviewed.
  ///
  /// In fa, this message translates to:
  /// **'هنوز مرور نشده'**
  String get ideaNeverReviewed;

  /// No description provided for @ideaProHint.
  ///
  /// In fa, this message translates to:
  /// **'امتیاز، اتصال ایده‌ها و مرور با Pro'**
  String get ideaProHint;

  /// No description provided for @peopleTitle.
  ///
  /// In fa, this message translates to:
  /// **'آدم‌ها'**
  String get peopleTitle;

  /// No description provided for @peopleEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'هنوز کسی رو اضافه نکردی'**
  String get peopleEmptyTitle;

  /// No description provided for @peopleEmptyBody.
  ///
  /// In fa, this message translates to:
  /// **'مثلاً «بعداً به علی زنگ بزن». آدم رو از مخاطب‌ها انتخاب کن یا اسمش رو بنویس.'**
  String get peopleEmptyBody;

  /// No description provided for @personAdd.
  ///
  /// In fa, this message translates to:
  /// **'آدم جدید'**
  String get personAdd;

  /// No description provided for @personFromContacts.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب از مخاطب‌ها'**
  String get personFromContacts;

  /// No description provided for @personTypeName.
  ///
  /// In fa, this message translates to:
  /// **'فقط اسم بنویسم'**
  String get personTypeName;

  /// No description provided for @personName.
  ///
  /// In fa, this message translates to:
  /// **'اسم'**
  String get personName;

  /// No description provided for @personNote.
  ///
  /// In fa, this message translates to:
  /// **'یادداشت'**
  String get personNote;

  /// No description provided for @personLast.
  ///
  /// In fa, this message translates to:
  /// **'آخرین ارتباط: {when}'**
  String personLast(String when);

  /// No description provided for @personNever.
  ///
  /// In fa, this message translates to:
  /// **'هنوز ارتباطی ثبت نشده'**
  String get personNever;

  /// No description provided for @personNext.
  ///
  /// In fa, this message translates to:
  /// **'بعدی: {when}'**
  String personNext(String when);

  /// No description provided for @personNoNext.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌ای نداره'**
  String get personNoNext;

  /// No description provided for @personTalked.
  ///
  /// In fa, this message translates to:
  /// **'همین الان صحبت کردیم'**
  String get personTalked;

  /// No description provided for @personAddReminder.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری تازه'**
  String get personAddReminder;

  /// No description provided for @personReminderHint.
  ///
  /// In fa, this message translates to:
  /// **'مثلاً: پیام بده'**
  String get personReminderHint;

  /// No description provided for @personOpenContact.
  ///
  /// In fa, this message translates to:
  /// **'باز کردن مخاطب'**
  String get personOpenContact;

  /// No description provided for @personDeleteTitle.
  ///
  /// In fa, this message translates to:
  /// **'این آدم حذف بشه؟'**
  String get personDeleteTitle;

  /// No description provided for @personDeleteBody.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌هاش می‌مونن ولی دیگه به این آدم وصل نیستن.'**
  String get personDeleteBody;

  /// No description provided for @personHistory.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه‌ی ارتباط'**
  String get personHistory;

  /// No description provided for @personFollowUp.
  ///
  /// In fa, this message translates to:
  /// **'پیگیری'**
  String get personFollowUp;

  /// No description provided for @personFollowUpDays.
  ///
  /// In fa, this message translates to:
  /// **'بعد از {n} روز یادم بنداز'**
  String personFollowUpDays(String n);

  /// No description provided for @personGroup.
  ///
  /// In fa, this message translates to:
  /// **'گروه'**
  String get personGroup;

  /// No description provided for @personDueTitle.
  ///
  /// In fa, this message translates to:
  /// **'باید سر بزنی'**
  String get personDueTitle;

  /// No description provided for @personLinked.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری‌ها'**
  String get personLinked;

  /// No description provided for @personPickerFailed.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب مخاطب انجام نشد. اسم رو دستی بنویس.'**
  String get personPickerFailed;

  /// No description provided for @interactionNoteHint.
  ///
  /// In fa, this message translates to:
  /// **'چی گفتید؟ (اختیاری)'**
  String get interactionNoteHint;

  /// No description provided for @peopleProHint.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه، پیگیری و «باید سر بزنی» با Pro'**
  String get peopleProHint;

  /// No description provided for @personContactRef.
  ///
  /// In fa, this message translates to:
  /// **'از مخاطب‌های گوشی'**
  String get personContactRef;

  /// No description provided for @futureTitle.
  ///
  /// In fa, this message translates to:
  /// **'آینده'**
  String get futureTitle;

  /// No description provided for @futureTabCapsules.
  ///
  /// In fa, this message translates to:
  /// **'کپسول زمانی'**
  String get futureTabCapsules;

  /// No description provided for @futureTabMessages.
  ///
  /// In fa, this message translates to:
  /// **'پیام به خودم'**
  String get futureTabMessages;

  /// No description provided for @capsuleEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'کپسولی نداری'**
  String get capsuleEmptyTitle;

  /// No description provided for @capsuleEmptyBody.
  ///
  /// In fa, this message translates to:
  /// **'چیزی رو تا یه تاریخ از جلوی چشمت بردار. همون روز برمی‌گرده.'**
  String get capsuleEmptyBody;

  /// No description provided for @messageEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'پیامی ننوشتی'**
  String get messageEmptyTitle;

  /// No description provided for @messageEmptyBody.
  ///
  /// In fa, this message translates to:
  /// **'برای خودِ آینده‌ات بنویس.'**
  String get messageEmptyBody;

  /// No description provided for @capsuleNew.
  ///
  /// In fa, this message translates to:
  /// **'کپسول جدید'**
  String get capsuleNew;

  /// No description provided for @messageNew.
  ///
  /// In fa, this message translates to:
  /// **'پیام جدید'**
  String get messageNew;

  /// No description provided for @sealTitleHint.
  ///
  /// In fa, this message translates to:
  /// **'عنوان'**
  String get sealTitleHint;

  /// No description provided for @capsuleBodyHint.
  ///
  /// In fa, this message translates to:
  /// **'چی رو می‌خوای بعداً ببینی؟'**
  String get capsuleBodyHint;

  /// No description provided for @messageBodyHint.
  ///
  /// In fa, this message translates to:
  /// **'به خودِ آینده‌ات چی می‌گی؟'**
  String get messageBodyHint;

  /// No description provided for @sealOpenOn.
  ///
  /// In fa, this message translates to:
  /// **'باز می‌شه: {date}'**
  String sealOpenOn(String date);

  /// No description provided for @sealPickDate.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ باز شدن'**
  String get sealPickDate;

  /// No description provided for @sealQuick1m.
  ///
  /// In fa, this message translates to:
  /// **'۱ ماه دیگه'**
  String get sealQuick1m;

  /// No description provided for @sealQuick3m.
  ///
  /// In fa, this message translates to:
  /// **'۳ ماه دیگه'**
  String get sealQuick3m;

  /// No description provided for @sealQuick6m.
  ///
  /// In fa, this message translates to:
  /// **'۶ ماه دیگه'**
  String get sealQuick6m;

  /// No description provided for @sealQuick1y.
  ///
  /// In fa, this message translates to:
  /// **'۱ سال دیگه'**
  String get sealQuick1y;

  /// No description provided for @sealSaved.
  ///
  /// In fa, this message translates to:
  /// **'قفل شد. تا {date} دیده نمی‌شه.'**
  String sealSaved(String date);

  /// No description provided for @sealLimitFree.
  ///
  /// In fa, this message translates to:
  /// **'نسخه‌ی رایگان همزمان تا {n} مورد قفل‌شده داره. با Pro نامحدوده.'**
  String sealLimitFree(String n);

  /// No description provided for @sealNeedsFuture.
  ///
  /// In fa, this message translates to:
  /// **'تاریخ باید توی آینده باشه.'**
  String get sealNeedsFuture;

  /// No description provided for @lockedUntil.
  ///
  /// In fa, this message translates to:
  /// **'تا {date} قفله'**
  String lockedUntil(String date);

  /// No description provided for @openIt.
  ///
  /// In fa, this message translates to:
  /// **'بازش کن'**
  String get openIt;

  /// No description provided for @returnedTitle.
  ///
  /// In fa, this message translates to:
  /// **'یه چیز از گذشته برای تو برگشته'**
  String get returnedTitle;

  /// No description provided for @messageReturnedTitle.
  ///
  /// In fa, this message translates to:
  /// **'پیامی از خودِ گذشته‌ات داری'**
  String get messageReturnedTitle;

  /// No description provided for @writtenOn.
  ///
  /// In fa, this message translates to:
  /// **'نوشته‌شده در {date}'**
  String writtenOn(String date);

  /// No description provided for @sealRepeat.
  ///
  /// In fa, this message translates to:
  /// **'تکرار'**
  String get sealRepeat;

  /// No description provided for @sealAttach.
  ///
  /// In fa, this message translates to:
  /// **'پیوست'**
  String get sealAttach;

  /// No description provided for @sealAttachAdd.
  ///
  /// In fa, this message translates to:
  /// **'افزودن عکس یا فایل'**
  String get sealAttachAdd;

  /// No description provided for @sealAttachLimit.
  ///
  /// In fa, this message translates to:
  /// **'تا {n} فایل، هر کدوم حداکثر {mb} مگابایت. فقط روی همین گوشی می‌مونه.'**
  String sealAttachLimit(String mb, String n);

  /// No description provided for @sealAttachTooBig.
  ///
  /// In fa, this message translates to:
  /// **'این فایل از حد مجاز بزرگ‌تره.'**
  String get sealAttachTooBig;

  /// No description provided for @sealAttachFailed.
  ///
  /// In fa, this message translates to:
  /// **'فایل اضافه نشد.'**
  String get sealAttachFailed;

  /// No description provided for @sealProHint.
  ///
  /// In fa, this message translates to:
  /// **'کپسول و پیام نامحدود، پیوست، برچسب و تکرار با Pro'**
  String get sealProHint;

  /// No description provided for @sealThisItem.
  ///
  /// In fa, this message translates to:
  /// **'برای آینده نگه دار'**
  String get sealThisItem;

  /// No description provided for @sealItemQuestion.
  ///
  /// In fa, this message translates to:
  /// **'تا کِی نبینمش؟'**
  String get sealItemQuestion;

  /// No description provided for @timelineOpened.
  ///
  /// In fa, this message translates to:
  /// **'باز شده در {date}'**
  String timelineOpened(String date);

  /// No description provided for @notifCapsuleTitle.
  ///
  /// In fa, this message translates to:
  /// **'یه چیز از گذشته برای تو برگشته'**
  String get notifCapsuleTitle;

  /// No description provided for @notifCapsuleBody.
  ///
  /// In fa, this message translates to:
  /// **'بازش کن ببین چی بوده.'**
  String get notifCapsuleBody;

  /// No description provided for @notifFutureTitle.
  ///
  /// In fa, this message translates to:
  /// **'پیامی از خودِ گذشته‌ات داری'**
  String get notifFutureTitle;

  /// No description provided for @notifFutureBody.
  ///
  /// In fa, this message translates to:
  /// **'بازش کن و بخونش.'**
  String get notifFutureBody;

  /// No description provided for @notifIdeaReviewTitle.
  ///
  /// In fa, this message translates to:
  /// **'وقت مرور ایده‌هاست'**
  String get notifIdeaReviewTitle;

  /// No description provided for @notifIdeaReviewBody.
  ///
  /// In fa, this message translates to:
  /// **'چند تا ایده منتظر یه نگاه دوباره‌ان.'**
  String get notifIdeaReviewBody;

  /// No description provided for @inboxTitle.
  ///
  /// In fa, this message translates to:
  /// **'صندوق ورودی'**
  String get inboxTitle;

  /// No description provided for @inboxIntro.
  ///
  /// In fa, this message translates to:
  /// **'هر چی سریع ذخیره کردی اینجا می‌مونه تا تکلیفش رو روشن کنی.'**
  String get inboxIntro;

  /// No description provided for @inboxEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'صندوق خالیه'**
  String get inboxEmptyTitle;

  /// No description provided for @inboxEmptyBody.
  ///
  /// In fa, this message translates to:
  /// **'همه‌چیز جای خودشه.'**
  String get inboxEmptyBody;

  /// No description provided for @triageToday.
  ///
  /// In fa, this message translates to:
  /// **'امروز'**
  String get triageToday;

  /// No description provided for @triageWeek.
  ///
  /// In fa, this message translates to:
  /// **'این هفته'**
  String get triageWeek;

  /// No description provided for @triageNoDate.
  ///
  /// In fa, this message translates to:
  /// **'بدون تاریخ'**
  String get triageNoDate;

  /// No description provided for @triageRead.
  ///
  /// In fa, this message translates to:
  /// **'بعداً بخون'**
  String get triageRead;

  /// No description provided for @triageWatch.
  ///
  /// In fa, this message translates to:
  /// **'بعداً ببین'**
  String get triageWatch;

  /// No description provided for @triageWish.
  ///
  /// In fa, this message translates to:
  /// **'بعداً بخر'**
  String get triageWish;

  /// No description provided for @triageIdea.
  ///
  /// In fa, this message translates to:
  /// **'ایده'**
  String get triageIdea;

  /// No description provided for @triageDone.
  ///
  /// In fa, this message translates to:
  /// **'انجام شد'**
  String get triageDone;

  /// No description provided for @triageDelete.
  ///
  /// In fa, this message translates to:
  /// **'حذف'**
  String get triageDelete;

  /// No description provided for @inboxSuggest.
  ///
  /// In fa, this message translates to:
  /// **'شبیه {what} به نظر می‌رسه. منتقل بشه؟'**
  String inboxSuggest(String what);

  /// No description provided for @inboxSuggestYes.
  ///
  /// In fa, this message translates to:
  /// **'آره، منتقل کن'**
  String get inboxSuggestYes;

  /// No description provided for @suggestWhatRead.
  ///
  /// In fa, this message translates to:
  /// **'یه مقاله'**
  String get suggestWhatRead;

  /// No description provided for @suggestWhatWatch.
  ///
  /// In fa, this message translates to:
  /// **'یه ویدیو'**
  String get suggestWhatWatch;

  /// No description provided for @suggestWhatWish.
  ///
  /// In fa, this message translates to:
  /// **'یه چیز برای خرید'**
  String get suggestWhatWish;

  /// No description provided for @suggestWhatIdea.
  ///
  /// In fa, this message translates to:
  /// **'یه ایده'**
  String get suggestWhatIdea;

  /// No description provided for @suggestWhatPerson.
  ///
  /// In fa, this message translates to:
  /// **'یه یادآوری برای یه آدم'**
  String get suggestWhatPerson;

  /// No description provided for @inboxProHint.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد خودکار مقصد با Pro'**
  String get inboxProHint;

  /// No description provided for @rouletteTitle.
  ///
  /// In fa, this message translates to:
  /// **'قرعه بعداً'**
  String get rouletteTitle;

  /// No description provided for @roulettePick.
  ///
  /// In fa, this message translates to:
  /// **'انتخاب کن'**
  String get roulettePick;

  /// No description provided for @rouletteSpinning.
  ///
  /// In fa, this message translates to:
  /// **'دارم انتخاب می‌کنم…'**
  String get rouletteSpinning;

  /// No description provided for @rouletteStart.
  ///
  /// In fa, this message translates to:
  /// **'شروع'**
  String get rouletteStart;

  /// No description provided for @rouletteLater.
  ///
  /// In fa, this message translates to:
  /// **'بعداً'**
  String get rouletteLater;

  /// No description provided for @rouletteAgain.
  ///
  /// In fa, this message translates to:
  /// **'یکی دیگه'**
  String get rouletteAgain;

  /// No description provided for @rouletteEmptyTitle.
  ///
  /// In fa, this message translates to:
  /// **'چیزی برای قرعه نیست'**
  String get rouletteEmptyTitle;

  /// No description provided for @rouletteEmptyBody.
  ///
  /// In fa, this message translates to:
  /// **'لیستت خالیه یا چیزی با این فیلترها نمی‌خونه.'**
  String get rouletteEmptyBody;

  /// No description provided for @rouletteFilters.
  ///
  /// In fa, this message translates to:
  /// **'فیلترها'**
  String get rouletteFilters;

  /// No description provided for @rouletteTime.
  ///
  /// In fa, this message translates to:
  /// **'وقت'**
  String get rouletteTime;

  /// No description provided for @rouletteEnergy.
  ///
  /// In fa, this message translates to:
  /// **'حال و انرژی'**
  String get rouletteEnergy;

  /// No description provided for @energyLow.
  ///
  /// In fa, this message translates to:
  /// **'کم‌حالم'**
  String get energyLow;

  /// No description provided for @energyHigh.
  ///
  /// In fa, this message translates to:
  /// **'سرحالم'**
  String get energyHigh;

  /// No description provided for @rouletteCats.
  ///
  /// In fa, this message translates to:
  /// **'دسته‌های قرعه'**
  String get rouletteCats;

  /// No description provided for @rouletteHistoryTitle.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه‌ی قرعه'**
  String get rouletteHistoryTitle;

  /// No description provided for @rouletteHistoryEmpty.
  ///
  /// In fa, this message translates to:
  /// **'هنوز قرعه‌ای نزدی.'**
  String get rouletteHistoryEmpty;

  /// No description provided for @rouletteProHint.
  ///
  /// In fa, this message translates to:
  /// **'فیلتر وقت، دسته، اولویت و انرژی و تاریخچه‌ی قرعه با Pro'**
  String get rouletteProHint;

  /// No description provided for @rouletteOpenLink.
  ///
  /// In fa, this message translates to:
  /// **'باز کردن لینک'**
  String get rouletteOpenLink;

  /// No description provided for @shareWhere.
  ///
  /// In fa, this message translates to:
  /// **'کجا نگهش دارم؟'**
  String get shareWhere;

  /// No description provided for @shareInbox.
  ///
  /// In fa, this message translates to:
  /// **'صندوق ورودی'**
  String get shareInbox;

  /// No description provided for @shareSavedInbox.
  ///
  /// In fa, this message translates to:
  /// **'تو صندوق ورودی ذخیره شد.'**
  String get shareSavedInbox;

  /// No description provided for @shareSuggested.
  ///
  /// In fa, this message translates to:
  /// **'پیشنهاد'**
  String get shareSuggested;

  /// No description provided for @proWhatYouGet.
  ///
  /// In fa, this message translates to:
  /// **'با Pro چی می‌گیری'**
  String get proWhatYouGet;

  /// No description provided for @proFreeHeader.
  ///
  /// In fa, this message translates to:
  /// **'تو نسخه‌ی رایگان هم داری'**
  String get proFreeHeader;

  /// No description provided for @proFreeList.
  ///
  /// In fa, this message translates to:
  /// **'ذخیره‌ی نامحدود، صندوق ورودی، قرعه‌ی پایه، بعداً بخون / ببین / بخر، ایده‌ها، آدم‌ها، کپسول و پیام (تا ۲ تا)، جستجو، یادآوری، اشتراک‌گذاری، تم روشن و تیره، پشتیبان‌گیری.'**
  String get proFreeList;

  /// No description provided for @proFT1.
  ///
  /// In fa, this message translates to:
  /// **'قرعه‌ی هوشمند'**
  String get proFT1;

  /// No description provided for @proFD1.
  ///
  /// In fa, this message translates to:
  /// **'فقط از دسته‌های دلخواه، بر اساس وقت، اولویت و حال و انرژی‌ات انتخاب می‌کنه و تاریخچه‌ی قرعه‌ها رو نگه می‌داره.'**
  String get proFD1;

  /// No description provided for @proFT2.
  ///
  /// In fa, this message translates to:
  /// **'صندوق ورودی هوشمند'**
  String get proFT2;

  /// No description provided for @proFD2.
  ///
  /// In fa, this message translates to:
  /// **'برای هر مورد مقصد پیشنهاد می‌ده (مقاله، ویدیو، خرید، ایده). همیشه تأیید آخر با خودته.'**
  String get proFD2;

  /// No description provided for @proFT3.
  ///
  /// In fa, this message translates to:
  /// **'قفسه‌های کامل‌تر'**
  String get proFT3;

  /// No description provided for @proFD3.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه و آمار خوندن و دیدن، فیلتر و مرتب‌سازی پیشرفته، چند فهرست جدا.'**
  String get proFD3;

  /// No description provided for @proFT4.
  ///
  /// In fa, this message translates to:
  /// **'خرید حساب‌شده'**
  String get proFT4;

  /// No description provided for @proFD4.
  ///
  /// In fa, this message translates to:
  /// **'قیمت هدف، تاریخچه‌ی قیمتی که خودت ثبت کردی، آمار و یادآوری بررسی دوباره.'**
  String get proFD4;

  /// No description provided for @proFT5.
  ///
  /// In fa, this message translates to:
  /// **'ایده‌ها با مرور'**
  String get proFT5;

  /// No description provided for @proFD5.
  ///
  /// In fa, this message translates to:
  /// **'امتیاز، وصل کردن ایده‌ها به هم، مرور دوره‌ای، یادآوری ماهانه و تبدیل ایده به کار.'**
  String get proFD5;

  /// No description provided for @proFT6.
  ///
  /// In fa, this message translates to:
  /// **'آدم‌های مهم'**
  String get proFT6;

  /// No description provided for @proFD6.
  ///
  /// In fa, this message translates to:
  /// **'تاریخچه‌ی ارتباط، پیگیری خودکار، گروه‌های دلخواه و لیست «باید سر بزنی».'**
  String get proFD6;

  /// No description provided for @proFT7.
  ///
  /// In fa, this message translates to:
  /// **'آینده‌ی بیشتر'**
  String get proFT7;

  /// No description provided for @proFD7.
  ///
  /// In fa, this message translates to:
  /// **'کپسول و پیام بی‌شمار، پیوست عکس و فایل کوچک، برچسب و تکرار (مثلاً هر سال).'**
  String get proFD7;

  /// No description provided for @proFT8.
  ///
  /// In fa, this message translates to:
  /// **'جستجو و فیلتر'**
  String get proFT8;

  /// No description provided for @proFD8.
  ///
  /// In fa, this message translates to:
  /// **'جستجو تو برچسب، لینک و یادداشت و فیلتر «مانده‌ها».'**
  String get proFD8;

  /// No description provided for @proFT9.
  ///
  /// In fa, this message translates to:
  /// **'آمار و تاریخچه‌ی کامل'**
  String get proFT9;

  /// No description provided for @proFD9.
  ///
  /// In fa, this message translates to:
  /// **'همه‌ی ماه‌ها و آمار کامل، به‌جای فقط ۷ روز اخیر.'**
  String get proFD9;

  /// No description provided for @proFT10.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری تکرارشونده'**
  String get proFT10;

  /// No description provided for @proFD10.
  ///
  /// In fa, this message translates to:
  /// **'روزانه، هفتگی، ماهانه یا سالانه، تا وقتی انجامش بدی.'**
  String get proFD10;

  /// No description provided for @proFT11.
  ///
  /// In fa, this message translates to:
  /// **'ظاهر و ویجت'**
  String get proFT11;

  /// No description provided for @proFD11.
  ///
  /// In fa, this message translates to:
  /// **'چند رنگ و آیکون دیگه و ویجت لیستی برای صفحه‌ی اصلی گوشی.'**
  String get proFD11;

  /// No description provided for @proFT12.
  ///
  /// In fa, this message translates to:
  /// **'پشتیبان‌گیری بیشتر'**
  String get proFT12;

  /// No description provided for @proFD12.
  ///
  /// In fa, this message translates to:
  /// **'پشتیبان خودکار هفتگی و خروجی CSV و متن.'**
  String get proFD12;

  /// No description provided for @settingsRouletteCats.
  ///
  /// In fa, this message translates to:
  /// **'دسته‌های قرعه'**
  String get settingsRouletteCats;

  /// No description provided for @settingsRouletteCatsAll.
  ///
  /// In fa, this message translates to:
  /// **'همه‌ی دسته‌ها'**
  String get settingsRouletteCatsAll;

  /// No description provided for @wishlistReviewAfter.
  ///
  /// In fa, this message translates to:
  /// **'پرسیدن «هنوز می‌خوایش؟» بعد از'**
  String get wishlistReviewAfter;

  /// No description provided for @askWhereOnShare.
  ///
  /// In fa, this message translates to:
  /// **'بعد از اشتراک‌گذاری بپرس کجا بره'**
  String get askWhereOnShare;

  /// No description provided for @askWhereOnShareSub.
  ///
  /// In fa, this message translates to:
  /// **'اگه خاموشه، همه‌چیز می‌ره تو صندوق ورودی.'**
  String get askWhereOnShareSub;

  /// No description provided for @ideaReviewEvery.
  ///
  /// In fa, this message translates to:
  /// **'مرور ایده‌ها هر'**
  String get ideaReviewEvery;

  /// No description provided for @ideaReviewMonthly.
  ///
  /// In fa, this message translates to:
  /// **'یادآوری مرور ماهانه'**
  String get ideaReviewMonthly;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'fa':
      return AppL10nFa();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
