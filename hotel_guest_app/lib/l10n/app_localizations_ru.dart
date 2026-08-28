// ignore: unused_import
import 'package:intl/intl.dart' as intl;
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
  String landingWelcomeWithName(String hotel) {
    return 'Добро пожаловать в $hotel';
  }

  @override
  String get landingSubtitle => 'Введите данные, чтобы начать';

  @override
  String get landingNameHint => 'Ваше полное имя';

  @override
  String get landingRoomHint => 'Номер комнаты';

  @override
  String get landingEnter => 'Войти →';

  @override
  String get landingAddToHome =>
      '+ Добавьте на главный экран для быстрого доступа';

  @override
  String get landingErrorMissingFields =>
      'Пожалуйста, введите имя и номер комнаты';

  @override
  String get landingErrorMissingHotel =>
      'Код отеля отсутствует — отсканируйте QR снова';

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
  String get newRequestQuickSelectLabel => 'Быстрый выбор';

  @override
  String get newRequestSomethingElse => 'Что-то другое';

  @override
  String get newRequestNoteLabel => 'Добавить примечание (необязательно)';

  @override
  String get newRequestNoteHint =>
      'Что-нибудь ещё, что нам следует знать? (необязательно)';

  @override
  String get serviceExtraTowels => 'Дополнительные полотенца';

  @override
  String get serviceExtraPillows => 'Дополнительные подушки';

  @override
  String get serviceCleanRoom => 'Убрать номер сейчас';

  @override
  String get serviceDoNotDisturb => 'Не беспокоить';

  @override
  String get serviceToiletries => 'Туалетные принадлежности';

  @override
  String get serviceIceWater => 'Лёд и вода';

  @override
  String get serviceAcIssue => 'Кондиционер не работает';

  @override
  String get serviceTvIssue => 'Телевизор не работает';

  @override
  String get serviceWifiIssue => 'Проблема с Wi-Fi';

  @override
  String get servicePlumbingIssue => 'Проблема с сантехникой';

  @override
  String get serviceLightBulb => 'Лампочка перегорела';

  @override
  String get servicePowerOutlet => 'Розетка не работает';

  @override
  String get serviceLateCheckout => 'Поздний выезд';

  @override
  String get serviceExtraKey => 'Дополнительный ключ';

  @override
  String get serviceTaxiRequest => 'Заказать такси';

  @override
  String get serviceLuggageHelp => 'Помощь с багажом';

  @override
  String get serviceWakeUpCall => 'Звонок-будильник';

  @override
  String get serviceInvoiceRequest => 'Счёт / квитанция';

  @override
  String get feedbackTitle => 'Отзыв о пребывании';

  @override
  String get feedbackQuestion => 'Как прошло ваше пребывание?';

  @override
  String get feedbackCommentHint =>
      'Расскажите о своём опыте (необязательно)...';

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

  @override
  String get homeAmenitiesButton => 'Дополнительные услуги';

  @override
  String get amenitiesTitle => 'Дополнительные услуги';

  @override
  String get amenitiesEmpty => 'Сейчас нет доступных позиций';

  @override
  String get categoryRestaurant => 'Ресторан';

  @override
  String get categorySpa => 'Спа';

  @override
  String get categoryRoomService => 'Room Service';

  @override
  String get amenitiesOrderButton => 'Заказать';

  @override
  String get amenitiesQuantityLabel => 'Количество';

  @override
  String get amenitiesNotesHint => 'Комментарий (необязательно)';

  @override
  String get amenitiesOrderSuccessTitle => 'Заказ отправлен!';

  @override
  String get amenitiesOrderSuccessSubtitle =>
      'Наша команда скоро этим займётся';

  @override
  String get amenitiesBackToMenu => 'Назад';
}
