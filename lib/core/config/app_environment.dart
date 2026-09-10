import '../services/storage_service.dart';

/// Environment configuration management.
/// Supports compile-time `--dart-define=API_BASE_URL=...` as well as
/// runtime persistence and defaults to the user's active backend endpoint.
class AppEnvironment {
  AppEnvironment._();

  /// Environment URL configured at compile time or defaults to:
  /// http://192.168.1.64:3099/api/v1
  static const String defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.39:3099/api/v1',
  );

  /// Current active Base URL (checks runtime override first, then environment default)
  static String get baseUrl {
    final customUrl = StorageService.getCustomBaseUrl();
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return customUrl.trim();
    }
    return defaultUrl;
  }

  /// Override environment URL at runtime
  static Future<void> setBaseUrl(String url) async {
    await StorageService.saveCustomBaseUrl(url);
  }

  /// Reset to default environment URL
  static Future<void> resetBaseUrl() async {
    await StorageService.clearCustomBaseUrl();
  }
}
