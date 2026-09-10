import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../data/mock_data.dart';
import '../../models/song.dart';
import '../../models/notification_item.dart';
import '../../models/about_us.dart';
import 'storage_service.dart';

class ApiService {
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

  /// GET /songs?q=&page=
  Future<List<Song>> fetchSongs({String? query, int page = 1}) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.songs}').replace(
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        'page': page.toString(),
      },
    );

    try {
      final response = await _client.get(uri, headers: _buildHeaders()).timeout(
        const Duration(seconds: 3),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['songs'] as List<dynamic>?) ?? [];
        final favIds = StorageService.getFavoriteIds();
        return list.map((item) {
          final song = Song.fromJson(item as Map<String, dynamic>);
          // Blend with local favorites for guest responsiveness
          if (favIds.contains(song.id)) {
            song.isFavorite = true;
          }
          return song;
        }).toList();
      }
    } catch (e) {
      debugPrint('ApiService.fetchSongs fallback: $e');
    }

    // Offline / Fallback handling
    final favIds = StorageService.getFavoriteIds();
    var songs = List<Song>.from(MockData.defaultSongs);

    // Apply query search (Tamil and Thanglish)
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      songs = songs.where((s) {
        return s.title.toLowerCase().contains(q) ||
            s.titleThanglish.toLowerCase().contains(q);
      }).toList();
    }

    // Sort ascending by song number/title
    songs.sort((a, b) => a.songNumber.compareTo(b.songNumber));

    // Update local favorite state
    for (var s in songs) {
      s.isFavorite = favIds.contains(s.id);
    }
    return songs;
  }

  /// GET /songs/:id
  Future<Song?> fetchSongDetail(int songId) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.songDetail(songId)}');

    try {
      final response = await _client.get(uri, headers: _buildHeaders()).timeout(
        const Duration(seconds: 3),
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

    // Offline Fallback
    final favIds = StorageService.getFavoriteIds();
    final found = MockData.defaultSongs.firstWhere(
      (s) => s.id == songId,
      orElse: () => MockData.defaultSongs.first,
    );
    final songCopy = found.copyWith(isFavorite: favIds.contains(found.id));
    return songCopy;
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
          const Duration(seconds: 3),
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

    // Fallback: Local Favorites
    final favIds = StorageService.getFavoriteIds();
    final allSongs = MockData.defaultSongs;
    return allSongs
        .where((s) => favIds.contains(s.id))
        .map((s) => s.copyWith(isFavorite: true))
        .toList();
  }

  /// GET /notifications?page=
  Future<Map<String, dynamic>> fetchNotifications({int page = 1}) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.notifications}').replace(
      queryParameters: {'page': page.toString()},
    );

    try {
      final response = await _client.get(uri, headers: _buildHeaders()).timeout(
        const Duration(seconds: 3),
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

    // Fallback
    final readIds = StorageService.getReadNotificationIds();
    final items = MockData.defaultNotifications.map((n) {
      return n.copyWith(isRead: readIds.contains(n.id));
    }).toList();

    final unread = items.where((n) => !n.isRead).length;
    return {
      'notifications': items,
      'unread_count': unread,
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
  Future<AboutUs> fetchAboutUs() async {
    final uri = Uri.parse('$baseUrl${ApiConstants.aboutUs}');
    try {
      final response = await _client.get(uri, headers: _buildHeaders()).timeout(
        const Duration(seconds: 3),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AboutUs.fromJson(data);
      }
    } catch (e) {
      debugPrint('ApiService.fetchAboutUs fallback: $e');
    }
    return MockData.defaultAboutUs;
  }
}
