import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Гость отеля';

  @override
  String get landingWelcome => 'Добро пожаловать';

  @override
  String get landingSubtitle => 'Введите данные, чтобы начать';

  @override
  String get landingNameHint => 'Ваше полное имя';

  @override
  String get landingRoomHint => 'Номер комнаты';

  @override
  String get landingEnter => 'Войти →';

  @override
  String get landingAddToHome => '+ Добавьте на главный экран для быстрого доступа';

  @override
  String get landingErrorMissingFields => 'Пожалуйста, введите имя и номер комнаты';

  @override
  String get landingErrorMissingHotel => 'Код отеля отсутствует — отсканируйте QR снова';

  @override
  String homeGreeting(String name) {
    return 'Привет, $name 👋';
  }

  @override
  String homeRoom(String room) {
    return 'Комната $room';
  }

  @override
  String get homeFeedbackTitle => 'Как прошло ваше пребывание?';

  @override
  String get homeFeedbackSubtitle => 'Оставьте нам краткий отзыв';

  @override
  String get homePushBanner => 'Включите уведомления и отслеживайте запросы';

  @override
  String get homePushEnable => 'Включить';

  @override
  String get homeNewRequest => 'Новый запрос';

  @override
  String get homeMyRequests => 'Мои запросы';

  @override
  String get homeNoRequests => 'Запросов пока нет';

  @override
  String get categoryHousekeeping => 'Горничная';

  @override
  String get categoryMaintenance => 'Техобслуживание';

  @override
  String get categoryReception => 'Ресепшн';

  @override
  String get statusOpen => 'Открыт';

  @override
  String get statusInProgress => 'В работе';

  @override
  String get statusResolved => 'Выполнено ✓';

  @override
  String get statusCancelled => 'Отменено';

  @override
  String get newRequestTitle => 'Новый запрос';

  @override
  String get newRequestCategoryLabel => 'Категория';

  @override
  String get newRequestDetailsLabel => 'Детали (необязательно)';

  @override
  String get newRequestDetailsHint => 'Расскажите, чем мы можем помочь...';

  @override
  String get newRequestSubmit => 'Отправить запрос';

  @override
  String get feedbackTitle => 'Отзыв о пребывании';

  @override
  String get feedbackQuestion => 'Как прошло ваше пребывание?';

  @override
  String get feedbackCommentHint => 'Расскажите о своём опыте (необязательно)...';

  @override
  String get feedbackSubmit => 'Отправить отзыв';

  @override
  String get feedbackThanksTitle => 'Спасибо за ваш отзыв!';

  @override
  String get feedbackThanksSubtitle => 'Спасибо, что выбрали нас 🙏';

  @override
  String get feedbackBackHome => 'На главную';

  @override
  String get feedbackErrorNoRating => 'Пожалуйста, выберите оценку';

  @override
  String errorGeneric(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get errorNoSession => 'Нет сеанса';
}
