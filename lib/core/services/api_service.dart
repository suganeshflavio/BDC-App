import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/song.dart';
import '../../models/notification_item.dart';
import '../../models/about_us.dart';
import 'storage_service.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 10);
  final String? _customBaseUrl;
  final http.Client _client;

  ApiService({
    String? baseUrl,
    http.Client? client,
  })  : _customBaseUrl = baseUrl,
        _client = client ?? http.Client();

  String get baseUrl => _customBaseUrl ?? ApiConstants.defaultBaseUrl;

  Map<String, String> _buildHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
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
        final response = await _client.get(uri, headers: _buildHeaders()).timeout(
          _timeout,
        );

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
        final response = await _client.get(uri, headers: _buildHeaders()).timeout(
          _timeout,
        );
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
      final response = await _client.get(uri, headers: _buildHeaders()).timeout(
        _timeout,
      );

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
    // 1. Always update local storage first for guest users
    final isFav = await StorageService.toggleFavorite(songId);

    // 2. Attempt server sync if token available
    final token = StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      try {
        final uri = Uri.parse('$baseUrl${ApiConstants.toggleFavorite(songId)}');
        if (makeFavorite) {
          await _client.post(uri, headers: _buildHeaders()).timeout(
            const Duration(seconds: 3),
          );
        } else {
          await _client.delete(uri, headers: _buildHeaders()).timeout(
            const Duration(seconds: 3),
          );
        }
      } catch (e) {
        debugPrint('Remote favorite sync note: $e');
      }
    }
    return isFav;
  }

  /// GET /favorites?page=
  Future<List<Song>> fetchFavorites({int page = 1}) async {
    final token = StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      try {
        final uri = Uri.parse('$baseUrl${ApiConstants.favorites}').replace(
          queryParameters: {'page': page.toString()},
        );
        final response = await _client.get(uri, headers: _buildHeaders()).timeout(
          _timeout,
        );
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
    }

    // Local Favorites (stored IDs matching live songs)
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
      final response = await _client.get(uri, headers: _buildHeaders()).timeout(
        _timeout,
      );

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
    final token = StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      try {
        final uri = Uri.parse('$baseUrl${ApiConstants.markNotificationRead(id)}');
        await _client.post(uri, headers: _buildHeaders()).timeout(
          const Duration(seconds: 3),
        );
      } catch (e) {
        debugPrint('Mark read API sync note: $e');
      }
    }
  }

  /// GET /about_us
  Future<AboutUs?> fetchAboutUs({bool forceRefresh = false}) async {
    if (_cachedAboutUs != null && !forceRefresh) {
      return _cachedAboutUs;
    }

    final uri = Uri.parse('$baseUrl${ApiConstants.aboutUs}');
    try {
      final response = await _client.get(uri, headers: _buildHeaders()).timeout(
        _timeout,
      );
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
}
