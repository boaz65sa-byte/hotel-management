// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Управление отелем';

  @override
  String get login => 'Вход';

  @override
  String get staffLoginSubtitle => 'Войдите, чтобы перейти к управлению отелем';

  @override
  String get changePassword => 'Изменить пароль';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get save => 'Сохранить';

  @override
  String get passwordChangedSuccess => 'Пароль успешно обновлён';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get passwordTooShort => 'Пароль должен содержать не менее 8 символов';

  @override
  String get email => 'Электронная почта';

  @override
  String get password => 'Пароль';

  @override
  String get logout => 'Выйти';

  @override
  String get myTickets => 'Мои заявки';

  @override
  String get deptQueue => 'Очередь отдела';

  @override
  String get newTicket => 'Новая заявка';

  @override
  String get rooms => 'Номера';

  @override
  String get profile => 'Профиль';

  @override
  String get offline => 'Нет подключения к интернету';

  @override
  String get claimTicket => 'Взять заявку';

  @override
  String get claimRequiresConnection =>
      'Для взятия заявки необходимо интернет-соединение';

  @override
  String get ticketFixed => 'Устранено';

  @override
  String get ticketOnHold => 'На удержании';

  @override
  String get ticketRoomClosed => 'Номер закрыт';

  @override
  String get pendingApproval => 'Ожидает подтверждения';

  @override
  String get approve => 'Подтвердить';

  @override
  String get reject => 'Отклонить';

  @override
  String get addPhoto => 'Добавить фото';

  @override
  String get addComment => 'Добавить комментарий';

  @override
  String get analytics => 'Аналитика';

  @override
  String get users => 'Пользователи';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get cancel => 'Отменить';

  @override
  String get loading => 'Загрузка...';

  @override
  String get errorGeneric => 'Что-то пошло не так';

  @override
  String get available => 'Свободен';

  @override
  String get onHold => 'На удержании';

  @override
  String get closed => 'Закрыто';

  @override
  String get priority_low => 'Низкий';

  @override
  String get priority_normal => 'Обычный';

  @override
  String get priority_high => 'Высокий';

  @override
  String get priority_urgent => 'Срочный';

  @override
  String get noTickets => 'Заявки не найдены';
}
