import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نزيل الفندق';

  @override
  String get landingWelcome => 'مرحباً بكم';

  @override
  String landingWelcomeWithName(String hotel) {
    return 'مرحباً بكم في $hotel';
  }

  @override
  String get landingSubtitle => 'أدخل بياناتك للبدء';

  @override
  String get landingNameHint => 'اسمك الكامل';

  @override
  String get landingRoomHint => 'رقم الغرفة';

  @override
  String get landingEnter => 'تسجيل الدخول →';

  @override
  String get landingAddToHome => '+ أضفه إلى الشاشة الرئيسية للوصول السريع';

  @override
  String get landingErrorMissingFields => 'يرجى إدخال الاسم ورقم الغرفة';

  @override
  String get landingErrorMissingHotel => 'رمز الفندق مفقود — امسح رمز QR مجدداً';

  @override
  String homeGreeting(String name) {
    return 'مرحباً $name 👋';
  }

  @override
  String homeRoom(String room) {
    return 'غرفة $room';
  }

  @override
  String get homeFeedbackTitle => 'كيف كانت إقامتك؟';

  @override
  String get homeFeedbackSubtitle => 'اترك لنا تقييماً سريعاً';

  @override
  String get homePushBanner => 'فعّل الإشعارات وتابع طلباتك';

  @override
  String get homePushEnable => 'تفعيل';

  @override
  String get homeNewRequest => 'طلب جديد';

  @override
  String get homeMyRequests => 'طلباتي';

  @override
  String get homeNoRequests => 'لا توجد طلبات بعد';

  @override
  String get categoryHousekeeping => 'خدمة الغرف';

  @override
  String get categoryMaintenance => 'الصيانة';

  @override
  String get categoryReception => 'الاستقبال';

  @override
  String get statusOpen => 'مفتوح';

  @override
  String get statusInProgress => 'قيد التنفيذ';

  @override
  String get statusResolved => 'تم الحل ✓';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get newRequestTitle => 'طلب جديد';

  @override
  String get newRequestCategoryLabel => 'الفئة';

  @override
  String get newRequestDetailsLabel => 'التفاصيل (اختياري)';

  @override
  String get newRequestDetailsHint => 'أخبرنا كيف يمكننا مساعدتك...';

  @override
  String get newRequestSubmit => 'إرسال الطلب';

  @override
  String get feedbackTitle => 'تقييم الإقامة';

  @override
  String get feedbackQuestion => 'كيف كانت إقامتك؟';

  @override
  String get feedbackCommentHint => 'أخبرنا عن تجربتك (اختياري)...';

  @override
  String get feedbackSubmit => 'إرسال التقييم';

  @override
  String get feedbackThanksTitle => 'شكراً على تقييمك!';

  @override
  String get feedbackThanksSubtitle => 'شكراً لاختياركم لنا 🙏';

  @override
  String get feedbackBackHome => 'العودة إلى الرئيسية';

  @override
  String get feedbackErrorNoRating => 'يرجى اختيار تقييم';

  @override
  String errorGeneric(String error) {
    return 'خطأ: $error';
  }

  @override
  String get errorNoSession => 'لا توجد جلسة';
}
