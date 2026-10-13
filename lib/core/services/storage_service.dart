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
    final list = _prefs?.getStringList(_keyFavorites) ?? <String>[];
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

  // Device ID & User Profile
  static const String _keyDeviceId = 'stable_device_id';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserName = 'auth_user_name';
  static const String _keyUserEmail = 'auth_user_email';
  static const String _keyUserPhone = 'auth_user_phone';
  static const String _keyUserRole = 'auth_user_role';

  // Auth Token
  static String? getAuthToken() {
    return _prefs?.getString(_keyAuthToken);
  }

  static Future<void> saveAuthToken(String token) async {
    await _prefs?.setString(_keyAuthToken, token);
  }

  static Future<void> clearAuthToken() async {
    await _prefs?.remove(_keyAuthToken);
  }

  // Stable Client Device ID
  static String getDeviceId() {
    var id = _prefs?.getString(_keyDeviceId);
    if (id == null || id.trim().isEmpty) {
      id = _generateStableDeviceId();
      _prefs?.setString(_keyDeviceId, id);
    }
    return id;
  }

  static Future<void> saveDeviceId(String id) async {
    await _prefs?.setString(_keyDeviceId, id.trim());
  }

  static String _generateStableDeviceId() {
    final rand = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final part2 = (100000 + (DateTime.now().microsecond % 900000)).toRadixString(16);
    return 'bdc-$rand-$part2';
  }

  // User Profile
  static String? getUserName() => _prefs?.getString(_keyUserName);
  static Future<void> saveUserName(String name) async =>
      await _prefs?.setString(_keyUserName, name);

  static String? getUserPhone() => _prefs?.getString(_keyUserPhone);
  static Future<void> saveUserPhone(String phone) async =>
      await _prefs?.setString(_keyUserPhone, phone);

  static String? getUserEmail() => _prefs?.getString(_keyUserEmail);
  static Future<void> saveUserEmail(String email) async =>
      await _prefs?.setString(_keyUserEmail, email);

  static int? getUserId() => _prefs?.getInt(_keyUserId);
  static Future<void> saveUserId(int id) async =>
      await _prefs?.setInt(_keyUserId, id);

  static String? getUserRole() => _prefs?.getString(_keyUserRole);
  static Future<void> saveUserRole(String role) async =>
      await _prefs?.setString(_keyUserRole, role);

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
