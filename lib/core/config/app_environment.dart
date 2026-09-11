import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/storage_service.dart';

/// Global environment configuration management.
/// Supports .env file loading via `flutter_dotenv`, compile-time flags
/// (`--dart-define=API_BASE_URL=...` or `--dart-define-from-file=.env`),
/// and runtime overrides saved in offline persistent preferences.
class AppEnvironment {
  AppEnvironment._();

  /// Default production API base URL
  static const String fallbackBaseUrl = 'https://bdc-lyrics.vercel.app/api/v1';

  /// Compile-time define via `--dart-define=API_BASE_URL=...`
  static const String _compileTimeUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Default active URL resolved by hierarchy:
  /// 1. Compile-time `--dart-define`
  /// 2. `.env` asset file via `flutter_dotenv`
  /// 3. Production fallback endpoint
  static String get defaultUrl {
    if (_compileTimeUrl.trim().isNotEmpty) {
      return _compileTimeUrl.trim();
    }
    if (dotenv.isInitialized) {
      final envUrl = dotenv.maybeGet('API_BASE_URL');
      if (envUrl != null && envUrl.trim().isNotEmpty) {
        return envUrl.trim();
      }
    }
    return fallbackBaseUrl;
  }

  /// Current active Base URL globally used across all API requests.
  /// Checks runtime storage override first; if none or if stale local dev IP,
  /// falls back to `defaultUrl`.
  static String get baseUrl {
    final customUrl = StorageService.getCustomBaseUrl();
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      // If a legacy local subnet IP (192.168.x.x) is stored from previous debugging,
      // bypass it to avoid blocking access to production.
      if (!customUrl.contains('192.168.')) {
        return customUrl.trim();
      }
    }
    return defaultUrl;
  }

  /// Get any arbitrary environment variable from .env globally
  static String? get(String key, {String? fallback}) {
    if (dotenv.isInitialized) {
      final value = dotenv.maybeGet(key);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }

  /// Check whether app is currently pointing to production
  static bool get isProduction {
    final env = get('APP_ENV', fallback: 'production')?.toLowerCase();
    return env == 'production' || baseUrl.contains('bdc-lyrics.vercel.app');
  }

  /// Override environment URL at runtime (e.g., via Settings screen)
  static Future<void> setBaseUrl(String url) async {
    await StorageService.saveCustomBaseUrl(url.trim());
  }

  /// Reset to default environment URL
  static Future<void> resetBaseUrl() async {
    await StorageService.clearCustomBaseUrl();
  }
}
