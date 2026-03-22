import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'إدارة الفندق';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get myTickets => 'طلباتي';

  @override
  String get deptQueue => 'قائمة القسم';

  @override
  String get newTicket => 'طلب جديد';

  @override
  String get rooms => 'الغرف';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get offline => 'لا يوجد اتصال بالإنترنت';

  @override
  String get claimTicket => 'استلام الطلب';

  @override
  String get claimRequiresConnection => 'استلام الطلب يتطلب اتصالاً بالإنترنت';

  @override
  String get ticketFixed => 'تم الإصلاح';

  @override
  String get ticketOnHold => 'في الانتظار';

  @override
  String get ticketRoomClosed => 'الغرفة مغلقة';

  @override
  String get pendingApproval => 'في انتظار الموافقة';

  @override
  String get approve => 'موافقة';

  @override
  String get reject => 'رفض';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get addComment => 'إضافة تعليق';

  @override
  String get analytics => 'التحليلات';

  @override
  String get users => 'المستخدمون';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get cancel => 'إلغاء';

  @override
  String get loading => 'جار التحميل...';

  @override
  String get errorGeneric => 'حدث خطأ ما';

  @override
  String get available => 'متاح';

  @override
  String get onHold => 'في الانتظار';

  @override
  String get closed => 'مغلق';

  @override
  String get priority_low => 'منخفض';

  @override
  String get priority_normal => 'عادي';

  @override
  String get priority_high => 'مرتفع';

  @override
  String get priority_urgent => 'عاجل';
}
