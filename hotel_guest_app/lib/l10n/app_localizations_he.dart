// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'Hotel Guest';

  @override
  String get landingWelcome => 'ברוכים הבאים';

  @override
  String landingWelcomeWithName(String hotel) {
    return 'ברוכים הבאים ל$hotel';
  }

  @override
  String get landingSubtitle => 'מלאו את הפרטים כדי להתחיל';

  @override
  String get landingNameHint => 'שמך המלא';

  @override
  String get landingRoomHint => 'מספר חדר';

  @override
  String get landingEnter => 'כניסה →';

  @override
  String get landingAddToHome => '+ ניתן להוסיף לדף הבית לגישה מהירה';

  @override
  String get landingErrorMissingFields => 'נא למלא שם ומספר חדר';

  @override
  String get landingErrorMissingHotel => 'קוד מלון חסר — סרקו שוב את ה-QR';

  @override
  String homeGreeting(String name) {
    return 'שלום $name 👋';
  }

  @override
  String homeRoom(String room) {
    return 'חדר $room';
  }

  @override
  String get homeFeedbackTitle => 'איך הייתה השהייה?';

  @override
  String get homeFeedbackSubtitle => 'השאירו לנו משוב קצר';

  @override
  String get homePushBanner => 'הפעל התראות ועקוב אחר הבקשות שלך';

  @override
  String get homePushEnable => 'הפעל';

  @override
  String get homeNewRequest => 'בקשה חדשה';

  @override
  String get homeMyRequests => 'הבקשות שלי';

  @override
  String get homeNoRequests => 'אין בקשות עדיין';

  @override
  String get categoryHousekeeping => 'חדרניות';

  @override
  String get categoryMaintenance => 'תחזוקה';

  @override
  String get categoryReception => 'קבלה';

  @override
  String get statusOpen => 'פתוחה';

  @override
  String get statusInProgress => 'בטיפול';

  @override
  String get statusResolved => 'טופלה ✓';

  @override
  String get statusCancelled => 'בוטלה';

  @override
  String get newRequestTitle => 'בקשה חדשה';

  @override
  String get newRequestCategoryLabel => 'קטגוריה';

  @override
  String get newRequestDetailsLabel => 'פרטים (אופציונלי)';

  @override
  String get newRequestDetailsHint => 'ספרו לנו במה תרצו עזרה...';

  @override
  String get newRequestSubmit => 'שלח בקשה';

  @override
  String get newRequestQuickSelectLabel => 'בחירה מהירה';

  @override
  String get newRequestSomethingElse => 'משהו אחר';

  @override
  String get newRequestNoteLabel => 'הוסיפו הערה (אופציונלי)';

  @override
  String get newRequestNoteHint => 'יש עוד משהו שכדאי שנדע? (אופציונלי)';

  @override
  String get serviceExtraTowels => 'מגבות נוספות';

  @override
  String get serviceExtraPillows => 'כריות נוספות';

  @override
  String get serviceCleanRoom => 'ניקיון החדר עכשיו';

  @override
  String get serviceDoNotDisturb => 'נא לא להפריע';

  @override
  String get serviceToiletries => 'מוצרי טיפוח';

  @override
  String get serviceIceWater => 'קרח ומים';

  @override
  String get serviceAcIssue => 'מיזוג לא עובד';

  @override
  String get serviceTvIssue => 'טלוויזיה לא עובדת';

  @override
  String get serviceWifiIssue => 'בעיית WiFi';

  @override
  String get servicePlumbingIssue => 'בעיית אינסטלציה';

  @override
  String get serviceLightBulb => 'נורה שרופה';

  @override
  String get servicePowerOutlet => 'שקע חשמל';

  @override
  String get serviceLateCheckout => 'צ\'ק-אאוט מאוחר';

  @override
  String get serviceExtraKey => 'מפתח נוסף';

  @override
  String get serviceTaxiRequest => 'הזמנת מונית';

  @override
  String get serviceLuggageHelp => 'עזרה עם מזוודות';

  @override
  String get serviceWakeUpCall => 'שיחת השכמה';

  @override
  String get serviceInvoiceRequest => 'חשבונית / קבלה';

  @override
  String get feedbackTitle => 'משוב שהייה';

  @override
  String get feedbackQuestion => 'איך הייתה השהייה?';

  @override
  String get feedbackCommentHint => 'ספרו לנו על החוויה שלכם (אופציונלי)...';

  @override
  String get feedbackSubmit => 'שלח משוב';

  @override
  String get feedbackThanksTitle => 'תודה על המשוב!';

  @override
  String get feedbackThanksSubtitle => 'תודה שבחרתם בנו 🙏';

  @override
  String get feedbackBackHome => 'חזרה לדף הבית';

  @override
  String get feedbackErrorNoRating => 'נא לבחור דירוג';

  @override
  String errorGeneric(String error) {
    return 'שגיאה: $error';
  }

  @override
  String get errorNoSession => 'אין סשן';

  @override
  String get homeAmenitiesButton => 'שירותים נוספים';

  @override
  String get amenitiesTitle => 'שירותים נוספים';

  @override
  String get amenitiesEmpty => 'אין כרגע פריטים זמינים';

  @override
  String get categoryRestaurant => 'מסעדה';

  @override
  String get categorySpa => 'ספא';

  @override
  String get categoryRoomService => 'רום סרוויס';

  @override
  String get amenitiesOrderButton => 'הזמן';

  @override
  String get amenitiesQuantityLabel => 'כמות';

  @override
  String get amenitiesNotesHint => 'הערות (אופציונלי)';

  @override
  String get amenitiesOrderSuccessTitle => 'ההזמנה נשלחה!';

  @override
  String get amenitiesOrderSuccessSubtitle => 'הצוות שלנו יטפל בבקשה בהקדם';

  @override
  String get amenitiesBackToMenu => 'חזרה';
}
