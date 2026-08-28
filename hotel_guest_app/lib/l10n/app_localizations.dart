import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_he.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('ar'),
    Locale('en'),
    Locale('he'),
    Locale('ru')
  ];

  /// Application title
  ///
  /// In he, this message translates to:
  /// **'Hotel Guest'**
  String get appTitle;

  /// Landing screen welcome heading
  ///
  /// In he, this message translates to:
  /// **'ברוכים הבאים'**
  String get landingWelcome;

  /// Landing screen welcome with hotel name
  ///
  /// In he, this message translates to:
  /// **'ברוכים הבאים ל{hotel}'**
  String landingWelcomeWithName(String hotel);

  /// Landing screen subtitle
  ///
  /// In he, this message translates to:
  /// **'מלאו את הפרטים כדי להתחיל'**
  String get landingSubtitle;

  /// Name field placeholder
  ///
  /// In he, this message translates to:
  /// **'שמך המלא'**
  String get landingNameHint;

  /// Room number field placeholder
  ///
  /// In he, this message translates to:
  /// **'מספר חדר'**
  String get landingRoomHint;

  /// Check-in button label
  ///
  /// In he, this message translates to:
  /// **'כניסה →'**
  String get landingEnter;

  /// PWA install hint
  ///
  /// In he, this message translates to:
  /// **'+ ניתן להוסיף לדף הבית לגישה מהירה'**
  String get landingAddToHome;

  /// Validation error when name or room is empty
  ///
  /// In he, this message translates to:
  /// **'נא למלא שם ומספר חדר'**
  String get landingErrorMissingFields;

  /// Error when hotel ID is absent from URL
  ///
  /// In he, this message translates to:
  /// **'קוד מלון חסר — סרקו שוב את ה-QR'**
  String get landingErrorMissingHotel;

  /// Greeting on home screen
  ///
  /// In he, this message translates to:
  /// **'שלום {name} 👋'**
  String homeGreeting(String name);

  /// Room number label on home screen
  ///
  /// In he, this message translates to:
  /// **'חדר {room}'**
  String homeRoom(String room);

  /// Feedback banner heading on home screen
  ///
  /// In he, this message translates to:
  /// **'איך הייתה השהייה?'**
  String get homeFeedbackTitle;

  /// Feedback banner subtext
  ///
  /// In he, this message translates to:
  /// **'השאירו לנו משוב קצר'**
  String get homeFeedbackSubtitle;

  /// Push notification opt-in banner text
  ///
  /// In he, this message translates to:
  /// **'הפעל התראות ועקוב אחר הבקשות שלך'**
  String get homePushBanner;

  /// Push enable button label
  ///
  /// In he, this message translates to:
  /// **'הפעל'**
  String get homePushEnable;

  /// New request button on home screen
  ///
  /// In he, this message translates to:
  /// **'בקשה חדשה'**
  String get homeNewRequest;

  /// Section heading for the requests list
  ///
  /// In he, this message translates to:
  /// **'הבקשות שלי'**
  String get homeMyRequests;

  /// Empty state for the requests list
  ///
  /// In he, this message translates to:
  /// **'אין בקשות עדיין'**
  String get homeNoRequests;

  /// Housekeeping category name
  ///
  /// In he, this message translates to:
  /// **'חדרניות'**
  String get categoryHousekeeping;

  /// Maintenance category name
  ///
  /// In he, this message translates to:
  /// **'תחזוקה'**
  String get categoryMaintenance;

  /// Reception category name
  ///
  /// In he, this message translates to:
  /// **'קבלה'**
  String get categoryReception;

  /// Request status: open
  ///
  /// In he, this message translates to:
  /// **'פתוחה'**
  String get statusOpen;

  /// Request status: assigned / in progress
  ///
  /// In he, this message translates to:
  /// **'בטיפול'**
  String get statusInProgress;

  /// Request status: resolved
  ///
  /// In he, this message translates to:
  /// **'טופלה ✓'**
  String get statusResolved;

  /// Request status: cancelled
  ///
  /// In he, this message translates to:
  /// **'בוטלה'**
  String get statusCancelled;

  /// New request screen AppBar title
  ///
  /// In he, this message translates to:
  /// **'בקשה חדשה'**
  String get newRequestTitle;

  /// Category section label
  ///
  /// In he, this message translates to:
  /// **'קטגוריה'**
  String get newRequestCategoryLabel;

  /// Details section label
  ///
  /// In he, this message translates to:
  /// **'פרטים (אופציונלי)'**
  String get newRequestDetailsLabel;

  /// Details text field hint
  ///
  /// In he, this message translates to:
  /// **'ספרו לנו במה תרצו עזרה...'**
  String get newRequestDetailsHint;

  /// Submit request button
  ///
  /// In he, this message translates to:
  /// **'שלח בקשה'**
  String get newRequestSubmit;

  /// Quick-select service tiles section label
  ///
  /// In he, this message translates to:
  /// **'בחירה מהירה'**
  String get newRequestQuickSelectLabel;

  /// Fallback tile for a request not covered by the predefined tiles
  ///
  /// In he, this message translates to:
  /// **'משהו אחר'**
  String get newRequestSomethingElse;

  /// Note field label shown once a predefined service tile is selected
  ///
  /// In he, this message translates to:
  /// **'הוסיפו הערה (אופציונלי)'**
  String get newRequestNoteLabel;

  /// Note field hint shown once a predefined service tile is selected
  ///
  /// In he, this message translates to:
  /// **'יש עוד משהו שכדאי שנדע? (אופציונלי)'**
  String get newRequestNoteHint;

  /// Housekeeping quick-select tile: extra towels
  ///
  /// In he, this message translates to:
  /// **'מגבות נוספות'**
  String get serviceExtraTowels;

  /// Housekeeping quick-select tile: extra pillows
  ///
  /// In he, this message translates to:
  /// **'כריות נוספות'**
  String get serviceExtraPillows;

  /// Housekeeping quick-select tile: clean the room now
  ///
  /// In he, this message translates to:
  /// **'ניקיון החדר עכשיו'**
  String get serviceCleanRoom;

  /// Housekeeping quick-select tile: do not disturb
  ///
  /// In he, this message translates to:
  /// **'נא לא להפריע'**
  String get serviceDoNotDisturb;

  /// Housekeeping quick-select tile: toiletries
  ///
  /// In he, this message translates to:
  /// **'מוצרי טיפוח'**
  String get serviceToiletries;

  /// Housekeeping quick-select tile: ice and water
  ///
  /// In he, this message translates to:
  /// **'קרח ומים'**
  String get serviceIceWater;

  /// Maintenance quick-select tile: AC not working
  ///
  /// In he, this message translates to:
  /// **'מיזוג לא עובד'**
  String get serviceAcIssue;

  /// Maintenance quick-select tile: TV not working
  ///
  /// In he, this message translates to:
  /// **'טלוויזיה לא עובדת'**
  String get serviceTvIssue;

  /// Maintenance quick-select tile: WiFi issue
  ///
  /// In he, this message translates to:
  /// **'בעיית WiFi'**
  String get serviceWifiIssue;

  /// Maintenance quick-select tile: plumbing issue
  ///
  /// In he, this message translates to:
  /// **'בעיית אינסטלציה'**
  String get servicePlumbingIssue;

  /// Maintenance quick-select tile: light bulb
  ///
  /// In he, this message translates to:
  /// **'נורה שרופה'**
  String get serviceLightBulb;

  /// Maintenance quick-select tile: power outlet
  ///
  /// In he, this message translates to:
  /// **'שקע חשמל'**
  String get servicePowerOutlet;

  /// Reception quick-select tile: late checkout
  ///
  /// In he, this message translates to:
  /// **'צ\'ק-אאוט מאוחר'**
  String get serviceLateCheckout;

  /// Reception quick-select tile: extra key
  ///
  /// In he, this message translates to:
  /// **'מפתח נוסף'**
  String get serviceExtraKey;

  /// Reception quick-select tile: book a taxi
  ///
  /// In he, this message translates to:
  /// **'הזמנת מונית'**
  String get serviceTaxiRequest;

  /// Reception quick-select tile: luggage help
  ///
  /// In he, this message translates to:
  /// **'עזרה עם מזוודות'**
  String get serviceLuggageHelp;

  /// Reception quick-select tile: wake-up call
  ///
  /// In he, this message translates to:
  /// **'שיחת השכמה'**
  String get serviceWakeUpCall;

  /// Reception quick-select tile: invoice or receipt
  ///
  /// In he, this message translates to:
  /// **'חשבונית / קבלה'**
  String get serviceInvoiceRequest;

  /// Feedback screen AppBar title
  ///
  /// In he, this message translates to:
  /// **'משוב שהייה'**
  String get feedbackTitle;

  /// Feedback question heading
  ///
  /// In he, this message translates to:
  /// **'איך הייתה השהייה?'**
  String get feedbackQuestion;

  /// Feedback comment text field hint
  ///
  /// In he, this message translates to:
  /// **'ספרו לנו על החוויה שלכם (אופציונלי)...'**
  String get feedbackCommentHint;

  /// Submit feedback button
  ///
  /// In he, this message translates to:
  /// **'שלח משוב'**
  String get feedbackSubmit;

  /// Post-submit thank-you heading
  ///
  /// In he, this message translates to:
  /// **'תודה על המשוב!'**
  String get feedbackThanksTitle;

  /// Post-submit thank-you subtext
  ///
  /// In he, this message translates to:
  /// **'תודה שבחרתם בנו 🙏'**
  String get feedbackThanksSubtitle;

  /// Back to home button after feedback
  ///
  /// In he, this message translates to:
  /// **'חזרה לדף הבית'**
  String get feedbackBackHome;

  /// Validation error when no star rating selected
  ///
  /// In he, this message translates to:
  /// **'נא לבחור דירוג'**
  String get feedbackErrorNoRating;

  /// Generic error snackbar text
  ///
  /// In he, this message translates to:
  /// **'שגיאה: {error}'**
  String errorGeneric(String error);

  /// Error when no guest session exists
  ///
  /// In he, this message translates to:
  /// **'אין סשן'**
  String get errorNoSession;

  /// No description provided for @homeAmenitiesButton.
  ///
  /// In he, this message translates to:
  /// **'שירותים נוספים'**
  String get homeAmenitiesButton;

  /// No description provided for @amenitiesTitle.
  ///
  /// In he, this message translates to:
  /// **'שירותים נוספים'**
  String get amenitiesTitle;

  /// No description provided for @amenitiesEmpty.
  ///
  /// In he, this message translates to:
  /// **'אין כרגע פריטים זמינים'**
  String get amenitiesEmpty;

  /// No description provided for @categoryRestaurant.
  ///
  /// In he, this message translates to:
  /// **'מסעדה'**
  String get categoryRestaurant;

  /// No description provided for @categorySpa.
  ///
  /// In he, this message translates to:
  /// **'ספא'**
  String get categorySpa;

  /// No description provided for @categoryRoomService.
  ///
  /// In he, this message translates to:
  /// **'רום סרוויס'**
  String get categoryRoomService;

  /// No description provided for @amenitiesOrderButton.
  ///
  /// In he, this message translates to:
  /// **'הזמן'**
  String get amenitiesOrderButton;

  /// No description provided for @amenitiesQuantityLabel.
  ///
  /// In he, this message translates to:
  /// **'כמות'**
  String get amenitiesQuantityLabel;

  /// No description provided for @amenitiesNotesHint.
  ///
  /// In he, this message translates to:
  /// **'הערות (אופציונלי)'**
  String get amenitiesNotesHint;

  /// No description provided for @amenitiesOrderSuccessTitle.
  ///
  /// In he, this message translates to:
  /// **'ההזמנה נשלחה!'**
  String get amenitiesOrderSuccessTitle;

  /// No description provided for @amenitiesOrderSuccessSubtitle.
  ///
  /// In he, this message translates to:
  /// **'הצוות שלנו יטפל בבקשה בהקדם'**
  String get amenitiesOrderSuccessSubtitle;

  /// No description provided for @amenitiesBackToMenu.
  ///
  /// In he, this message translates to:
  /// **'חזרה'**
  String get amenitiesBackToMenu;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'he', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
