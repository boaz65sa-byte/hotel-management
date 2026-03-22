import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'ניהול מלון';

  @override
  String get login => 'כניסה';

  @override
  String get email => 'אימייל';

  @override
  String get password => 'סיסמה';

  @override
  String get logout => 'יציאה';

  @override
  String get myTickets => 'הקריאות שלי';

  @override
  String get deptQueue => 'תור המחלקה';

  @override
  String get newTicket => 'קריאה חדשה';

  @override
  String get rooms => 'חדרים';

  @override
  String get profile => 'פרופיל';

  @override
  String get offline => 'אין חיבור לאינטרנט';

  @override
  String get claimTicket => 'קח אחריות';

  @override
  String get claimRequiresConnection => 'לקיחת אחריות דורשת חיבור לאינטרנט';

  @override
  String get ticketFixed => 'תוקן';

  @override
  String get ticketOnHold => 'בהמתנה';

  @override
  String get ticketRoomClosed => 'חדר סגור';

  @override
  String get pendingApproval => 'ממתין לאישור';

  @override
  String get approve => 'אשר';

  @override
  String get reject => 'דחה';

  @override
  String get addPhoto => 'הוסף תמונה';

  @override
  String get addComment => 'הוסף הערה';

  @override
  String get analytics => 'נתונים';

  @override
  String get users => 'משתמשים';

  @override
  String get saveChanges => 'שמור שינויים';

  @override
  String get cancel => 'ביטול';

  @override
  String get loading => 'טוען...';

  @override
  String get errorGeneric => 'משהו השתבש';

  @override
  String get available => 'פנוי';

  @override
  String get onHold => 'בהמתנה';

  @override
  String get closed => 'סגור';

  @override
  String get priority_low => 'נמוך';

  @override
  String get priority_normal => 'רגיל';

  @override
  String get priority_high => 'גבוה';

  @override
  String get priority_urgent => 'דחוף';
}
