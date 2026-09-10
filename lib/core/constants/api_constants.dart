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

  static String songDetail(int id) => '/songs/$id';
  static String toggleFavorite(int id) => '/songs/$id/favorite';
  static String markNotificationRead(int id) => '/notifications/$id/read';
}
