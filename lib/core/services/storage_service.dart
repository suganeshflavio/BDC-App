import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFavorites = 'favorite_song_ids';
  static const String _keyFontSize = 'preferred_font_size';
  static const String _keyReadNotifications = 'read_notification_ids';
  static const String _keyAuthToken = 'auth_token';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Favorite Songs
  static Set<int> getFavoriteIds() {
    final list = _prefs?.getStringList(_keyFavorites) ?? ['4', '5', '32'];
    return list.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toSet();
  }

  static Future<void> saveFavoriteIds(Set<int> ids) async {
    final list = ids.map((e) => e.toString()).toList();
    await _prefs?.setStringList(_keyFavorites, list);
  }

  static Future<bool> toggleFavorite(int songId) async {
    final ids = getFavoriteIds();
    final isFav = ids.contains(songId);
    if (isFav) {
      ids.remove(songId);
    } else {
      ids.add(songId);
    }
    await saveFavoriteIds(ids);
    return !isFav;
  }

  // Font Size
  static double getFontSize() {
    return _prefs?.getDouble(_keyFontSize) ?? 18.0;
  }

  static Future<void> saveFontSize(double size) async {
    await _prefs?.setDouble(_keyFontSize, size);
  }

  // Read Notifications
  static Set<int> getReadNotificationIds() {
    final list = _prefs?.getStringList(_keyReadNotifications) ?? ['1'];
    return list.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toSet();
  }

  static Future<void> markNotificationRead(int id) async {
    final ids = getReadNotificationIds();
    ids.add(id);
    await _prefs?.setStringList(_keyReadNotifications, ids.map((e) => e.toString()).toList());
  }

  // Auth Token (Optional for user side)
  static String? getAuthToken() {
    return _prefs?.getString(_keyAuthToken);
  }

  static Future<void> saveAuthToken(String token) async {
    await _prefs?.setString(_keyAuthToken, token);
  }

  static Future<void> clearAuthToken() async {
    await _prefs?.remove(_keyAuthToken);
  }

  // Custom Base URL / Environment Override
  static const String _keyCustomBaseUrl = 'custom_base_url';

  static String? getCustomBaseUrl() {
    return _prefs?.getString(_keyCustomBaseUrl);
  }

  static Future<void> saveCustomBaseUrl(String url) async {
    await _prefs?.setString(_keyCustomBaseUrl, url);
  }

  static Future<void> clearCustomBaseUrl() async {
    await _prefs?.remove(_keyCustomBaseUrl);
  }
}
