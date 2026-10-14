import '../config/app_environment.dart';

class ApiConstants {
  ApiConstants._();

  /// Active environment base URL
  static String get defaultBaseUrl => AppEnvironment.baseUrl;

  // Endpoints
  static const String songs = '/songs';
  static const String favorites = '/favorites';
  static const String notifications = '/notifications';
  static const String aboutUs = '/about_us';
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  // Device Auth
  static const String authDevice = '/auth/device';

  // Feedback
  static const String feedbackQuestions = '/feedback_questions';
  static const String feedbackAnswers = '/feedback_answers';

  // Prayer Requests
  static const String prayerRequests = '/prayer_requests';
  static String prayerRequestDetail(int id) => '/prayer_requests/$id';

  // Announcements
  static const String announcements = '/announcements';
  static const String adminAnnouncements = '/admin/announcements';

  static String songDetail(int id) => '/songs/$id';
  static String toggleFavorite(int id) => '/songs/$id/favorite';
  static String markNotificationRead(int id) => '/notifications/$id/read';
}
