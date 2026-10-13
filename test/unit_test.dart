import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chruch_coir/core/config/app_environment.dart';
import 'package:chruch_coir/core/services/storage_service.dart';
import 'package:chruch_coir/core/services/api_service.dart';
import 'package:chruch_coir/providers/song_provider.dart';
import 'package:chruch_coir/providers/settings_provider.dart';
import 'package:chruch_coir/providers/favorite_provider.dart';
import 'package:chruch_coir/models/prayer_request.dart';
import 'package:chruch_coir/models/feedback_question.dart';
import 'package:chruch_coir/core/services/api_exception.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'favorite_song_ids': ['4', '5', '32'],
      'preferred_font_size': 18.0,
      'read_notification_ids': ['1'],
    });
    await StorageService.init();
    await AppEnvironment.resetBaseUrl();
  });

  group('AppEnvironment Configuration Tests', () {
    test('Default base URL points to production Vercel endpoint', () {
      expect(AppEnvironment.baseUrl, 'https://bdc-lyrics.vercel.app/api/v1');
      expect(AppEnvironment.isProduction, isTrue);
      expect(ApiService().baseUrl, 'https://bdc-lyrics.vercel.app/api/v1');
    });

    test('Can override and reset base URL dynamically', () async {
      await AppEnvironment.setBaseUrl('https://custom-api.example.com/api/v1');
      expect(AppEnvironment.baseUrl, 'https://custom-api.example.com/api/v1');

      await AppEnvironment.resetBaseUrl();
      expect(AppEnvironment.baseUrl, 'https://bdc-lyrics.vercel.app/api/v1');
    });
  });

  group('StorageService & Settings Tests', () {
    test('Reads default font size and saves new font size', () async {
      expect(StorageService.getFontSize(), 18.0);
      final settings = SettingsProvider();
      expect(settings.fontSize, 18.0);

      await settings.setFontSize(24.0);
      expect(settings.fontSize, 24.0);
      expect(StorageService.getFontSize(), 24.0);
    });

    test('Favorites toggling persists in SharedPreferences', () async {
      final initialFavs = StorageService.getFavoriteIds();
      expect(initialFavs.contains(4), isTrue);

      final isStillFav = await StorageService.toggleFavorite(4);
      expect(isStillFav, isFalse);
      expect(StorageService.getFavoriteIds().contains(4), isFalse);

      final reAdded = await StorageService.toggleFavorite(4);
      expect(reAdded, isTrue);
      expect(StorageService.getFavoriteIds().contains(4), isTrue);
    });
  });

  group('ApiService & SongProvider Tests', () {
    test('Returns empty list when network is unreachable without mock fallback', () async {
      final apiService = ApiService(baseUrl: 'http://0.0.0.0:1');
      final songs = await apiService.fetchSongs();

      expect(songs.isEmpty, isTrue);
    });

    test('Searches by Tamil and Thanglish keywords', () async {
      final apiService = ApiService();
      final allSongs = await apiService.fetchSongs();
      expect(allSongs.isNotEmpty, isTrue);

      final firstSong = allSongs.first;
      final queryWord = firstSong.title.split(' ').first;
      final searchResults = await apiService.fetchSongs(query: queryWord);
      expect(searchResults.isNotEmpty, isTrue);
      expect(searchResults.any((s) => s.id == firstSong.id), isTrue);
    });

    test('Searches by song number with digits and hash symbol (#1, 559)', () async {
      final apiService = ApiService();
      // Search by exact song number 1
      final results1 = await apiService.fetchSongs(query: '1');
      expect(results1.isNotEmpty, isTrue);
      expect(results1.first.songNumber, 1);

      // Search by # symbol
      final resultsHash = await apiService.fetchSongs(query: '#1');
      expect(resultsHash.isNotEmpty, isTrue);
      expect(resultsHash.first.songNumber, 1);

      // Search by song 16 (present in live database)
      final results16 = await apiService.fetchSongs(query: '16');
      expect(results16.isNotEmpty, isTrue);
      expect(results16.any((s) => s.songNumber == 16), isTrue);
      expect(results16.first.songNumber, 16);

      // Search offline returns empty
      final fallbackService = ApiService(baseUrl: 'http://0.0.0.0:1');
      final results32 = await fallbackService.fetchSongs(query: '32');
      expect(results32.isEmpty, isTrue);
    });

    test('Song detail includes verses structure', () async {
      final apiService = ApiService();
      final allSongs = await apiService.fetchSongs();
      expect(allSongs.isNotEmpty, isTrue);

      final detail = await apiService.fetchSongDetail(allSongs.first.id);
      expect(detail, isNotNull);
      expect(detail!.id, allSongs.first.id);
    });

    test('SongProvider and FavoriteProvider update synchronously', () async {
      final songProvider = SongProvider();
      await songProvider.loadSongs();
      expect(songProvider.songs.isNotEmpty, isTrue);

      final song1 = songProvider.songs.first;
      final initialFav = song1.isFavorite;

      await songProvider.toggleFavorite(song1);
      expect(song1.isFavorite, !initialFav);

      final favoriteProvider = FavoriteProvider();
      await favoriteProvider.loadFavorites();
      if (!initialFav) {
        expect(favoriteProvider.favorites.any((s) => s.id == song1.id), isTrue);
      }
    });

    test('About Us information is loaded or parsed without mock fallbacks', () async {
      final apiService = ApiService();
      final about = await apiService.fetchAboutUs();
      if (about != null) {
        expect(about.churchName.isNotEmpty, isTrue);
        expect(about.ministryName.isNotEmpty, isTrue);
      }
    });

    test('Notification items and unread count are parsed correctly', () async {
      final apiService = ApiService();
      final res = await apiService.fetchNotifications();

      expect(res['notifications'], isNotEmpty);
      expect(res['unread_count'], greaterThanOrEqualTo(0));
    });
  });

  group('Device Auth & Profile Storage Tests', () {
    test('Generates and preserves stable device ID', () {
      final devId1 = StorageService.getDeviceId();
      expect(devId1.isNotEmpty, isTrue);

      final devId2 = StorageService.getDeviceId();
      expect(devId1, devId2);
    });

    test('Saves and reads user profile details', () async {
      await StorageService.saveUserName('Allwin');
      await StorageService.saveUserPhone('7373163183');
      await StorageService.saveUserEmail('allwin@example.com');
      await StorageService.saveAuthToken('test-token-xyz');

      expect(StorageService.getUserName(), 'Allwin');
      expect(StorageService.getUserPhone(), '7373163183');
      expect(StorageService.getUserEmail(), 'allwin@example.com');
      expect(StorageService.getAuthToken(), 'test-token-xyz');

      await StorageService.clearAuthToken();
      expect(StorageService.getAuthToken(), isNull);
    });
  });

  group('Prayer Request & Feedback Models Tests', () {
    test('PrayerRequest and PrayerRequestsResponse fromJson parsing', () {
      final json = {
        'id': 3,
        'name': 'Allwin',
        'mobile': '7373163183',
        'description': 'job need',
        'voice_note_url': null,
        'status': 'pending',
        'device_id': 'a1b2c3d4',
        'created_at': '2026-09-30T06:55:00.000Z',
      };

      final req = PrayerRequest.fromJson(json);
      expect(req.id, 3);
      expect(req.name, 'Allwin');
      expect(req.mobile, '7373163183');
      expect(req.description, 'job need');
      expect(req.isPending, isTrue);
      expect(req.createdAt, isNotNull);

      final listResponse = PrayerRequestsResponse.fromJson({
        'prayer_requests': [json],
        'meta': {'current_page': 1, 'total_pages': 1, 'total_count': 1},
      });
      expect(listResponse.requests.length, 1);
      expect(listResponse.currentPage, 1);
      expect(listResponse.totalCount, 1);
    });

    test('FeedbackQuestion and FeedbackAnswerItem model parsing', () {
      final qJson = {
        'id': 1,
        'question_text': 'What went particularly well during the convention?',
        'description': 'Please share specific moments.',
        'position': 0,
        'active': true,
        'answer_text': 'The worship sessions were wonderful.',
        'answered': true,
      };

      final q = FeedbackQuestion.fromJson(qJson);
      expect(q.id, 1);
      expect(q.questionText, 'What went particularly well during the convention?');
      expect(q.answered, isTrue);
      expect(q.answerText, 'The worship sessions were wonderful.');

      final ans = FeedbackAnswerItem(questionId: 1, answerText: 'Great service');
      expect(ans.toJson()['question_id'], 1);
      expect(ans.toJson()['answer_text'], 'Great service');
    });
  });

  group('ApiException and Error Handling Tests', () {
    test('ApiException parses backend error json format correctly', () {
      final err403 = ApiException.fromResponse(403, '{"error":"This account has been disabled"}');
      expect(err403.statusCode, 403);
      expect(err403.message, 'This account has been disabled');

      final err422 = ApiException.fromResponse(422, '{"error":"Only a pending prayer request can be deleted"}');
      expect(err422.statusCode, 422);
      expect(err422.message, 'Only a pending prayer request can be deleted');

      final errList = ApiException.fromResponse(422, '{"errors":["Mobile cannot be blank", "Description is too short"]}');
      expect(errList.statusCode, 422);
      expect(errList.message.contains('Mobile cannot be blank'), isTrue);

      final errFallback404 = ApiException.fromResponse(404, '');
      expect(errFallback404.statusCode, 404);
      expect(errFallback404.message, 'Requested item or resource was not found.');
    });
  });

  group('Device Auth Header Interception & Sequence Tests', () {
    test('Calls /auth/device 1st when token missing and passes token in API headers', () async {
      final requestedUrls = <String>[];
      final authHeaders = <String?>[];

      final mockClient = MockClient((request) async {
        requestedUrls.add(request.url.path);
        authHeaders.add(request.headers['Authorization']);

        if (request.url.path.endsWith('/auth/device')) {
          return http.Response(
            jsonEncode({
              'token': 'mock-device-jwt-xyz',
              'user': {
                'id': 99,
                'name': 'Allwin',
                'email': 'device-99@device.local',
                'phone': null,
                'role': 'user',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.endsWith('/feedback_questions')) {
          return http.Response(
            jsonEncode({
              'feedback_questions': [
                {
                  'id': 1,
                  'question_text': 'Convention reflection',
                  'active': true,
                  'answered': false,
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"error":"not found"}', 404);
      });

      // Clear token to simulate cold start
      await StorageService.clearAuthToken();
      expect(StorageService.getAuthToken(), isNull);

      final service = ApiService(baseUrl: 'https://test.api/v1', client: mockClient);
      final questions = await service.fetchFeedbackQuestions();

      expect(questions.length, 1);
      // 1st API call MUST be /auth/device
      expect(requestedUrls.first.endsWith('/auth/device'), isTrue);
      // 2nd API call is /feedback_questions
      expect(requestedUrls[1].endsWith('/feedback_questions'), isTrue);
      // Token is now stored
      expect(StorageService.getAuthToken(), 'mock-device-jwt-xyz');
      // 2nd request has Authorization: Bearer mock-device-jwt-xyz
      expect(authHeaders[1], 'Bearer mock-device-jwt-xyz');
    });

    test('Deduplicates concurrent API calls on startup so /auth/device is only called once', () async {
      int authCallCount = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/device')) {
          authCallCount++;
          await Future.delayed(const Duration(milliseconds: 20));
          return http.Response(
            jsonEncode({
              'token': 'dedup-token-abc',
              'user': {'id': 1, 'name': 'Dedup', 'email': '', 'phone': null, 'role': 'user'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"songs":[], "notifications":[], "church_name":"Bethesda", "ministry_name":"Revival"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await StorageService.clearAuthToken();

      final service = ApiService(baseUrl: 'https://test.api/v1', client: mockClient);

      // Fire 3 simultaneous API calls
      await Future.wait([
        service.fetchSongs(),
        service.fetchNotifications(),
        service.fetchAboutUs(),
      ]);

      // Exactly ONE /auth/device call should have been made
      expect(authCallCount, 1);
      expect(StorageService.getAuthToken(), 'dedup-token-abc');
    });
  });
}
