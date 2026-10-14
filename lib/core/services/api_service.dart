import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/song.dart';
import '../../models/notification_item.dart';
import '../../models/about_us.dart';
import '../../models/device_auth.dart';
import '../../models/feedback_question.dart';
import '../../models/prayer_request.dart';
import '../../models/announcement.dart';
import 'api_exception.dart';
import 'storage_service.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 10);
  final String? _customBaseUrl;
  final http.Client _client;

  // In-flight deduplication future for device authentication
  static Future<String?>? _authInFlight;

  ApiService({
    String? baseUrl,
    http.Client? client,
  })  : _customBaseUrl = baseUrl,
        _client = client ?? http.Client();

  String get baseUrl => _customBaseUrl ?? ApiConstants.defaultBaseUrl;

  /// Builds common JSON headers with Authorization token.
  /// If token is not present in local storage, calls `/auth/device` FIRST before proceeding.
  Future<Map<String, String>> _buildHeaders({
    bool skipAuth = false,
    String? name,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (!skipAuth) {
      var token = StorageService.getAuthToken();
      if (token == null || token.trim().isEmpty) {
        try {
          token = await ensureDeviceAuth(name: name);
        } catch (e) {
          debugPrint('Auto device auth in _buildHeaders note: $e');
        }
      }
      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  List<Song>? _cachedSongs;
  AboutUs? _cachedAboutUs;

  List<Song>? get cachedSongs => _cachedSongs;
  AboutUs? get cachedAboutUs => _cachedAboutUs;

  /// GET /songs?q=&page=
  Future<List<Song>> fetchSongs({
    String? query,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final favIds = StorageService.getFavoriteIds();

    // 1. Refresh master cache if not loaded or forceRefresh is requested
    if (_cachedSongs == null || forceRefresh) {
      final uri = Uri.parse('$baseUrl${ApiConstants.songs}');
      try {
        var headers = await _buildHeaders();
        var response = await _client.get(uri, headers: headers).timeout(
          _timeout,
        );

        if (response.statusCode == 401) {
          await ensureDeviceAuth(forceRefresh: true);
          headers = await _buildHeaders();
          response = await _client.get(uri, headers: headers).timeout(_timeout);
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final list = (data['songs'] as List<dynamic>?) ?? [];
          _cachedSongs = list.map((item) {
            return Song.fromJson(item as Map<String, dynamic>);
          }).toList();
        }
      } catch (e) {
        debugPrint('ApiService.fetchSongs master load fallback: $e');
      }
    }

    // Source pool is cached songs
    final pool = _cachedSongs ?? [];

    // If query is empty, return all songs sorted by songNumber
    if (query == null || query.trim().isEmpty) {
      if (pool.isEmpty) return [];
      final all = pool.map((s) {
        return s.copyWith(isFavorite: favIds.contains(s.id));
      }).toList();
      all.sort((a, b) => a.songNumber.compareTo(b.songNumber));
      return all;
    }

    // 2. Perform comprehensive search (Song #, Tamil, and Thanglish)
    final q = query.trim().toLowerCase();
    final digits = q.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanText = q.replaceAll('#', '').trim();

    // Server-side query for text when digits are not the primary query
    List<Song> serverMatches = [];
    if (digits.isEmpty) {
      try {
        final uri = Uri.parse('$baseUrl${ApiConstants.songs}').replace(
          queryParameters: {
            'q': q,
            'page': page.toString(),
          },
        );
        var headers = await _buildHeaders();
        var response = await _client.get(uri, headers: headers).timeout(
          _timeout,
        );

        if (response.statusCode == 401) {
          await ensureDeviceAuth(forceRefresh: true);
          headers = await _buildHeaders();
          response = await _client.get(uri, headers: headers).timeout(_timeout);
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final list = (data['songs'] as List<dynamic>?) ?? [];
          serverMatches = list
              .map((item) => Song.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('ApiService.fetchSongs server query note: $e');
      }
    }

    final Map<int, Song> resultMap = {};

    // First, add any server matches
    for (final s in serverMatches) {
      resultMap[s.id] = s;
    }

    // Filter master pool by number, title, and thanglish
    for (final song in pool) {
      final songNumStr = song.songNumber.toString();
      final matchesNumber = digits.isNotEmpty &&
          (songNumStr == digits ||
              songNumStr.startsWith(digits) ||
              songNumStr.contains(digits));
      final matchesTitle = song.title.toLowerCase().contains(q) ||
          (cleanText.isNotEmpty &&
              song.title.toLowerCase().contains(cleanText));
      final matchesThanglish = song.titleThanglish.toLowerCase().contains(q) ||
          (cleanText.isNotEmpty &&
              song.titleThanglish.toLowerCase().contains(cleanText));

      if (matchesNumber || matchesTitle || matchesThanglish) {
        resultMap[song.id] = song;
      }
    }

    final results = resultMap.values.map((s) {
      return s.copyWith(isFavorite: favIds.contains(s.id));
    }).toList();

    // Sort prioritizing exact song number match, then prefix match, then ascending number
    results.sort((a, b) {
      if (digits.isNotEmpty) {
        final aExact = a.songNumber.toString() == digits;
        final bExact = b.songNumber.toString() == digits;
        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;

        final aPrefix = a.songNumber.toString().startsWith(digits);
        final bPrefix = b.songNumber.toString().startsWith(digits);
        if (aPrefix && !bPrefix) return -1;
        if (!aPrefix && bPrefix) return 1;
      }
      return a.songNumber.compareTo(b.songNumber);
    });

    return results;
  }

  /// GET /songs/:id
  Future<Song?> fetchSongDetail(int songId) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.songDetail(songId)}');

    try {
      var headers = await _buildHeaders();
      var response = await _client.get(uri, headers: headers).timeout(
        _timeout,
      );

      if (response.statusCode == 401) {
        await ensureDeviceAuth(forceRefresh: true);
        headers = await _buildHeaders();
        response = await _client.get(uri, headers: headers).timeout(_timeout);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final song = Song.fromJson(data);
        final favIds = StorageService.getFavoriteIds();
        song.isFavorite = favIds.contains(song.id);
        return song;
      }
    } catch (e) {
      debugPrint('ApiService.fetchSongDetail fallback: $e');
    }

    // Fallback to cached songs if available
    if (_cachedSongs != null && _cachedSongs!.isNotEmpty) {
      final favIds = StorageService.getFavoriteIds();
      final matches = _cachedSongs!.where((s) => s.id == songId);
      if (matches.isNotEmpty) {
        return matches.first.copyWith(isFavorite: favIds.contains(matches.first.id));
      }
    }
    return null;
  }

  /// Toggle Favorite POST / DELETE /songs/:id/favorite
  Future<bool> toggleFavorite(int songId, bool makeFavorite) async {
    // 1. Always update local storage first
    final isFav = await StorageService.toggleFavorite(songId);

    // 2. Server sync with token header
    try {
      var headers = await _buildHeaders();
      final uri = Uri.parse('$baseUrl${ApiConstants.toggleFavorite(songId)}');
      var response = makeFavorite
          ? await _client.post(uri, headers: headers).timeout(
              const Duration(seconds: 4),
            )
          : await _client.delete(uri, headers: headers).timeout(
              const Duration(seconds: 4),
            );

      if (response.statusCode == 401) {
        await ensureDeviceAuth(forceRefresh: true);
        headers = await _buildHeaders();
        response = makeFavorite
            ? await _client.post(uri, headers: headers).timeout(
                const Duration(seconds: 4),
              )
            : await _client.delete(uri, headers: headers).timeout(
                const Duration(seconds: 4),
              );
      }
    } catch (e) {
      debugPrint('Remote favorite sync note: $e');
    }
    return isFav;
  }

  /// GET /favorites?page=
  Future<List<Song>> fetchFavorites({int page = 1}) async {
    try {
      var headers = await _buildHeaders();
      final uri = Uri.parse('$baseUrl${ApiConstants.favorites}').replace(
        queryParameters: {'page': page.toString()},
      );
      var response = await _client.get(uri, headers: headers).timeout(
        _timeout,
      );

      if (response.statusCode == 401) {
        await ensureDeviceAuth(forceRefresh: true);
        headers = await _buildHeaders();
        response = await _client.get(uri, headers: headers).timeout(_timeout);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['songs'] as List<dynamic>?) ?? [];
        return list.map((item) {
          final song = Song.fromJson(item as Map<String, dynamic>);
          song.isFavorite = true;
          return song;
        }).toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchFavorites fallback: $e');
    }

    // Local Favorites fallback (stored IDs matching live songs)
    final favIds = StorageService.getFavoriteIds();
    if (favIds.isEmpty) {
      return [];
    }

    try {
      final allSongs = await fetchSongs();
      return allSongs
          .where((s) => favIds.contains(s.id))
          .map((s) => s.copyWith(isFavorite: true))
          .toList();
    } catch (e) {
      debugPrint('ApiService.fetchFavorites local matching error: $e');
    }

    return [];
  }

  /// GET /notifications?page=
  Future<Map<String, dynamic>> fetchNotifications({int page = 1}) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.notifications}').replace(
      queryParameters: {'page': page.toString()},
    );

    try {
      var headers = await _buildHeaders();
      var response = await _client.get(uri, headers: headers).timeout(
        _timeout,
      );

      if (response.statusCode == 401) {
        await ensureDeviceAuth(forceRefresh: true);
        headers = await _buildHeaders();
        response = await _client.get(uri, headers: headers).timeout(_timeout);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['notifications'] as List<dynamic>?) ?? [];
        final readIds = StorageService.getReadNotificationIds();

        final parsedList = list.map((item) {
          final notif = NotificationItem.fromJson(item as Map<String, dynamic>);
          if (readIds.contains(notif.id)) {
            notif.isRead = true;
          }
          return notif;
        }).toList();

        final unreadCount = parsedList.where((n) => !n.isRead).length;

        return {
          'notifications': parsedList,
          'unread_count': unreadCount,
        };
      }
    } catch (e) {
      debugPrint('ApiService.fetchNotifications fallback: $e');
    }

    return {
      'notifications': <NotificationItem>[],
      'unread_count': 0,
    };
  }

  /// POST /notifications/:id/read
  Future<void> markNotificationRead(int id) async {
    await StorageService.markNotificationRead(id);
    try {
      var headers = await _buildHeaders();
      final uri = Uri.parse('$baseUrl${ApiConstants.markNotificationRead(id)}');
      var response = await _client.post(uri, headers: headers).timeout(
        const Duration(seconds: 4),
      );

      if (response.statusCode == 401) {
        await ensureDeviceAuth(forceRefresh: true);
        headers = await _buildHeaders();
        response = await _client.post(uri, headers: headers).timeout(
          const Duration(seconds: 4),
        );
      }
    } catch (e) {
      debugPrint('Mark read API sync note: $e');
    }
  }

  /// GET /about_us
  Future<AboutUs?> fetchAboutUs({bool forceRefresh = false}) async {
    if (_cachedAboutUs != null && !forceRefresh) {
      return _cachedAboutUs;
    }

    final uri = Uri.parse('$baseUrl${ApiConstants.aboutUs}');
    try {
      var headers = await _buildHeaders();
      var response = await _client.get(uri, headers: headers).timeout(
        _timeout,
      );

      if (response.statusCode == 401) {
        await ensureDeviceAuth(forceRefresh: true);
        headers = await _buildHeaders();
        response = await _client.get(uri, headers: headers).timeout(_timeout);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          _cachedAboutUs = AboutUs.fromJson(data);
          return _cachedAboutUs;
        }
      }
    } catch (e) {
      debugPrint('ApiService.fetchAboutUs error: $e');
    }
    return _cachedAboutUs;
  }

  // ==========================================
  // AUTH / DEVICE API
  // ==========================================

  /// POST /auth/device
  /// Authenticates using the client-generated stable device id.
  /// Stores token and user profile in persistent storage.
  /// Deduplicates concurrent in-flight auth requests.
  /// Throws [ApiException] if disabled (403), invalid (400), or on network failure.
  Future<String?> ensureDeviceAuth({
    bool forceRefresh = false,
    String? name,
  }) async {
    if (!forceRefresh) {
      final existingToken = StorageService.getAuthToken();
      if (existingToken != null && existingToken.trim().isNotEmpty) {
        return existingToken;
      }
    }

    if (_authInFlight != null) {
      return await _authInFlight!;
    }

    final future = _executeDeviceAuth(name: name);
    _authInFlight = future;
    try {
      final token = await future;
      return token;
    } finally {
      _authInFlight = null;
    }
  }

  Future<String?> _executeDeviceAuth({String? name}) async {
    final deviceId = StorageService.getDeviceId();
    if (deviceId.isEmpty) {
      throw const ApiException('Device ID is required', statusCode: 400);
    }

    final clientName = name ?? StorageService.getUserName();
    final uri = Uri.parse('$baseUrl${ApiConstants.authDevice}');
    final body = jsonEncode({
      'device_id': deviceId,
      if (clientName != null && clientName.trim().isNotEmpty)
        'name': clientName.trim(),
    });

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authRes = DeviceAuthResponse.fromJson(data);

        await StorageService.saveAuthToken(authRes.token);
        await StorageService.saveUserId(authRes.user.id);
        final uName = authRes.user.name.trim();
        if (uName.isNotEmpty &&
            uName.toLowerCase() != 'guest' &&
            uName.toLowerCase() != 'guest user') {
          await StorageService.saveUserName(uName);
        }
        if (authRes.user.email.isNotEmpty) {
          await StorageService.saveUserEmail(authRes.user.email);
        }
        if (authRes.user.phone != null && authRes.user.phone!.isNotEmpty) {
          await StorageService.saveUserPhone(authRes.user.phone!);
        }
        await StorageService.saveUserRole(authRes.user.role);

        debugPrint('Device authenticated successfully: userId=${authRes.user.id}');
        return authRes.token;
      } else {
        throw ApiException.fromResponse(response.statusCode, response.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Device auth network error: $e');
      throw ApiException(
        'Unable to connect to auth service. Please check internet connection.',
        details: e,
      );
    }
  }

  // ==========================================
  // FEEDBACK APIS
  // ==========================================

  /// GET /feedback_questions
  /// Retrieves list of feedback questions for attendees/members.
  /// Sends `Authorization: Bearer <token>` in header.
  /// Throws [ApiException] on error.
  Future<List<FeedbackQuestion>> fetchFeedbackQuestions() async {
    final uri = Uri.parse('$baseUrl${ApiConstants.feedbackQuestions}');
    try {
      var headers = await _buildHeaders();
      var response = await _client.get(uri, headers: headers).timeout(
        _timeout,
      );

      if (response.statusCode == 401) {
        await ensureDeviceAuth(forceRefresh: true);
        headers = await _buildHeaders();
        response = await _client.get(uri, headers: headers).timeout(_timeout);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['feedback_questions'] as List<dynamic>?) ?? [];
        return list
            .map((item) => FeedbackQuestion.fromJson(item as Map<String, dynamic>))
            .where((q) => q.active)
            .toList();
      } else {
        throw ApiException.fromResponse(response.statusCode, response.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('ApiService.fetchFeedbackQuestions error: $e');
      throw ApiException(
        'Unable to load feedback questions. Please check connection.',
        details: e,
      );
    }
  }

  /// POST /feedback_answers
  /// Submits member responses to one or more feedback questions.
  /// Sends `Authorization: Bearer <token>` in header.
  /// Throws [ApiException] on validation (422) or server error.
  Future<bool> submitFeedbackAnswers(
    List<Map<String, dynamic>> answers, {
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const ApiException(
        'Name is required to submit feedback. (பெயர் உள்ளிடுவது அவசியம்)',
        statusCode: 422,
      );
    }

    if (answers.isEmpty) {
      throw const ApiException('Please provide an answer before submitting.', statusCode: 422);
    }

    for (final ans in answers) {
      final text = ans['answer_text']?.toString().trim();
      if (text == null || text.isEmpty) {
        throw const ApiException('Answer text cannot be blank.', statusCode: 422);
      }
    }

    final uri = Uri.parse('$baseUrl${ApiConstants.feedbackAnswers}');
    final body = jsonEncode({
      'name': trimmedName,
      'answers': answers,
    });

    try {
      var headers = await _buildHeaders();
      var response = await _client.post(
        uri,
        headers: headers,
        body: body,
      ).timeout(_timeout);

      if (response.statusCode == 401) {
        await ensureDeviceAuth(forceRefresh: true);
        headers = await _buildHeaders();
        response = await _client.post(
          uri,
          headers: headers,
          body: body,
        ).timeout(_timeout);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw ApiException.fromResponse(response.statusCode, response.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('ApiService.submitFeedbackAnswers error: $e');
      throw ApiException(
        'Unable to submit feedback. Please check connection.',
        details: e,
      );
    }
  }

  // ==========================================
  // PRAYER REQUESTS APIS
  // ==========================================

  /// GET /prayer_requests?page=
  /// Retrieves paginated list of prayer requests submitted by this member.
  /// Sends `Authorization: Bearer <token>` in header.
  /// Throws [ApiException] on error.
  Future<PrayerRequestsResponse> fetchPrayerRequests({int page = 1}) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.prayerRequests}').replace(
      queryParameters: {'page': page.toString()},
    );

    try {
      var headers = await _buildHeaders();
      var response = await _client.get(uri, headers: headers).timeout(
        _timeout,
      );

      if (response.statusCode == 401) {
        await ensureDeviceAuth(forceRefresh: true);
        headers = await _buildHeaders();
        response = await _client.get(uri, headers: headers).timeout(_timeout);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PrayerRequestsResponse.fromJson(data);
      } else {
        throw ApiException.fromResponse(response.statusCode, response.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('ApiService.fetchPrayerRequests error: $e');
      throw ApiException(
        'Unable to load prayer requests. Please check connection.',
        details: e,
      );
    }
  }

  /// POST /prayer_requests
  /// Submits a new prayer request.
  /// Sends `Authorization: Bearer <token>` in header.
  /// Throws [ApiException] if required fields are missing (422) or server fails.
  Future<PrayerRequest?> createPrayerRequest({
    required String name,
    required String mobile,
    required String description,
    required String location,
    String? voiceNoteUrl,
  }) async {
    if (name.trim().isEmpty ||
        mobile.trim().isEmpty ||
        description.trim().isEmpty ||
        location.trim().isEmpty) {
      throw const ApiException(
        'Name, mobile number, location, and prayer need are required fields.',
        statusCode: 422,
      );
    }

    final uri = Uri.parse('$baseUrl${ApiConstants.prayerRequests}');
    final payload = {
      'prayer_request': {
        'name': name.trim(),
        'mobile': mobile.trim(),
        'location': location.trim(),
        'description': description.trim(),
        if (voiceNoteUrl != null && voiceNoteUrl.trim().isNotEmpty)
          'voice_note_url': voiceNoteUrl.trim(),
      },
    };
    final payloadJson = jsonEncode(payload);

    try {
      var headers = await _buildHeaders(name: name.trim());
      print('====================================================');
      print('>>> [PrayerRequest POST URL]: $uri');
      print('>>> [PrayerRequest POST Headers]: $headers');
      print('>>> [PrayerRequest POST Payload]: $payloadJson');
      print('====================================================');
      debugPrint('====================================================');
      debugPrint('>>> [PrayerRequest POST URL]: $uri');
      debugPrint('>>> [PrayerRequest POST Headers]: $headers');
      debugPrint('>>> [PrayerRequest POST Payload]: $payloadJson');
      debugPrint('====================================================');

      var response = await _client.post(
        uri,
        headers: headers,
        body: payloadJson,
      ).timeout(_timeout);

      if (response.statusCode == 401) {
        await ensureDeviceAuth(forceRefresh: true, name: name.trim());
        headers = await _buildHeaders(name: name.trim());
        response = await _client.post(
          uri,
          headers: headers,
          body: payloadJson,
        ).timeout(_timeout);
      }

      print('====================================================');
      print('<<< [PrayerRequest Response Status]: ${response.statusCode}');
      print('<<< [PrayerRequest Response Body]: ${response.body}');
      print('====================================================');
      debugPrint('====================================================');
      debugPrint('<<< [PrayerRequest Response Status]: ${response.statusCode}');
      debugPrint('<<< [PrayerRequest Response Body]: ${response.body}');
      debugPrint('====================================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await StorageService.saveUserName(name.trim());
        await StorageService.saveUserPhone(mobile.trim());
        if (location != null && location.trim().isNotEmpty) {
          await StorageService.saveUserLocation(location.trim());
        }
        return PrayerRequest.fromJson(data);
      } else {
        throw ApiException.fromResponse(response.statusCode, response.body);
      }
    } on ApiException catch (e) {
      print('!!! [PrayerRequest ApiException]: ${e.message} (status: ${e.statusCode})');
      rethrow;
    } catch (e) {
      print('====================================================');
      print('!!! [PrayerRequest POST Error]: $e');
      print('====================================================');
      debugPrint('====================================================');
      debugPrint('!!! [PrayerRequest POST Error]: $e');
      debugPrint('====================================================');
      throw ApiException(
        'Unable to submit prayer request. Please check connection.',
        details: e,
      );
    }
  }

  // ==========================================
  // ANNOUNCEMENTS / BANNERS API
  // ==========================================

  /// GET /admin/announcements
  /// Retrieves dynamic announcements and banners.
  /// Sends `Authorization: Bearer <token>` in header.
  /// If /admin/announcements returns 403 (e.g. non-admin device token) or 404,
  /// seamlessly falls back to /announcements.
  Future<List<Announcement>> fetchAnnouncements({int page = 1}) async {
    final adminUri = page > 1
        ? Uri.parse('$baseUrl${ApiConstants.adminAnnouncements}?page=$page')
        : Uri.parse('$baseUrl${ApiConstants.adminAnnouncements}');

    try {
      var headers = await _buildHeaders();
      debugPrint('>>> [Announcements GET URL]: $adminUri');
      var response = await _client.get(adminUri, headers: headers).timeout(_timeout);

      if (response.statusCode == 401) {
        await ensureDeviceAuth(forceRefresh: true);
        headers = await _buildHeaders();
        response = await _client.get(adminUri, headers: headers).timeout(_timeout);
      }

      debugPrint('<<< [Announcements Status]: ${response.statusCode}');
      debugPrint('<<< [Announcements Body]: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final parsed = AnnouncementsResponse.fromJson(data);
        return parsed.announcements;
      }

      // If /admin/announcements is Forbidden (403), Unauthorized (401), or Not Found (404),
      // fallback to the congregation endpoint /announcements
      if (response.statusCode == 403 || response.statusCode == 401 || response.statusCode == 404) {
        final fallbackUri = page > 1
            ? Uri.parse('$baseUrl${ApiConstants.announcements}?page=$page')
            : Uri.parse('$baseUrl${ApiConstants.announcements}');
        debugPrint('>>> [Announcements Fallback GET URL]: $fallbackUri');
        final fallbackRes = await _client.get(fallbackUri, headers: headers).timeout(_timeout);
        debugPrint('<<< [Announcements Fallback Status]: ${fallbackRes.statusCode}');
        debugPrint('<<< [Announcements Fallback Body]: ${fallbackRes.body}');

        if (fallbackRes.statusCode == 200) {
          final data = jsonDecode(fallbackRes.body) as Map<String, dynamic>;
          final parsed = AnnouncementsResponse.fromJson(data);
          return parsed.announcements;
        }
      }
    } catch (e) {
      debugPrint('ApiService.fetchAnnouncements error: $e');
    }

    return [];
  }

  /// DELETE /prayer_requests/:id
  /// Deletes a pending prayer request.
  /// Sends `Authorization: Bearer <token>` in header.
  /// Throws [ApiException] if request not found (404), not pending (422), or network fails.
  Future<bool> deletePrayerRequest(int id) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.prayerRequestDetail(id)}');

    try {
      var headers = await _buildHeaders();
      var response = await _client.delete(uri, headers: headers).timeout(
        _timeout,
      );

      if (response.statusCode == 401) {
        await ensureDeviceAuth(forceRefresh: true);
        headers = await _buildHeaders();
        response = await _client.delete(uri, headers: headers).timeout(_timeout);
      }

      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      } else {
        throw ApiException.fromResponse(response.statusCode, response.body);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('ApiService.deletePrayerRequest error: $e');
      throw ApiException(
        'Unable to delete prayer request. Please check connection.',
        details: e,
      );
    }
  }
}
