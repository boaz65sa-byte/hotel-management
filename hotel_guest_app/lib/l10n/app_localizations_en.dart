import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hotel Guest';

  @override
  String get landingWelcome => 'Welcome';

  @override
  String landingWelcomeWithName(String hotel) {
    return 'Welcome to $hotel';
  }

  @override
  String get landingSubtitle => 'Fill in your details to get started';

  @override
  String get landingNameHint => 'Your full name';

  @override
  String get landingRoomHint => 'Room number';

  @override
  String get landingEnter => 'Check In →';

  @override
  String get landingAddToHome => '+ Add to home screen for quick access';

  @override
  String get landingErrorMissingFields => 'Please fill in your name and room number';

  @override
  String get landingErrorMissingHotel => 'Hotel code missing — scan the QR again';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name 👋';
  }

  @override
  String homeRoom(String room) {
    return 'Room $room';
  }

  @override
  String get homeFeedbackTitle => 'How was your stay?';

  @override
  String get homeFeedbackSubtitle => 'Leave us a quick review';

  @override
  String get homePushBanner => 'Enable notifications and track your requests';

  @override
  String get homePushEnable => 'Enable';

  @override
  String get homeNewRequest => 'New Request';

  @override
  String get homeMyRequests => 'My Requests';

  @override
  String get homeNoRequests => 'No requests yet';

  @override
  String get categoryHousekeeping => 'Housekeeping';

  @override
  String get categoryMaintenance => 'Maintenance';

  @override
  String get categoryReception => 'Reception';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusResolved => 'Resolved ✓';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get newRequestTitle => 'New Request';

  @override
  String get newRequestCategoryLabel => 'Category';

  @override
  String get newRequestDetailsLabel => 'Details (optional)';

  @override
  String get newRequestDetailsHint => 'Tell us how we can help you...';

  @override
  String get newRequestSubmit => 'Submit Request';

  @override
  String get feedbackTitle => 'Stay Feedback';

  @override
  String get feedbackQuestion => 'How was your stay?';

  @override
  String get feedbackCommentHint => 'Tell us about your experience (optional)...';

  @override
  String get feedbackSubmit => 'Submit Feedback';

  @override
  String get feedbackThanksTitle => 'Thank you for your feedback!';

  @override
  String get feedbackThanksSubtitle => 'Thank you for choosing us 🙏';

  @override
  String get feedbackBackHome => 'Back to Home';

  @override
  String get feedbackErrorNoRating => 'Please select a rating';

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get errorNoSession => 'No session';
}
