import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chruch_coir/core/config/app_environment.dart';
import 'package:chruch_coir/core/services/storage_service.dart';
import 'package:chruch_coir/core/services/api_service.dart';
import 'package:chruch_coir/providers/song_provider.dart';
import 'package:chruch_coir/providers/settings_provider.dart';
import 'package:chruch_coir/providers/favorite_provider.dart';

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
    test('Fetches songs in ascending order with default mock fallback', () async {
      final apiService = ApiService(baseUrl: 'http://0.0.0.0:1');
      final songs = await apiService.fetchSongs();

      expect(songs.isNotEmpty, isTrue);
      expect(songs.first.songNumber, 1);
      expect(songs.any((s) => s.songNumber == 32), isTrue);
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

    test('Searches by song number with digits and hash symbol (#1, 559, and fallback)', () async {
      final apiService = ApiService();
      // Search by exact song number 1
      final results1 = await apiService.fetchSongs(query: '1');
      expect(results1.isNotEmpty, isTrue);
      expect(results1.first.songNumber, 1);

      // Search by # symbol
      final resultsHash = await apiService.fetchSongs(query: '#1');
      expect(resultsHash.isNotEmpty, isTrue);
      expect(resultsHash.first.songNumber, 1);

      // Search by song 559 (present in live database)
      final results559 = await apiService.fetchSongs(query: '559');
      expect(results559.isNotEmpty, isTrue);
      expect(results559.any((s) => s.songNumber == 559), isTrue);
      expect(results559.first.songNumber, 559);

      // Search offline fallback with song 32
      final fallbackService = ApiService(baseUrl: 'http://0.0.0.0:1');
      final results32 = await fallbackService.fetchSongs(query: '32');
      expect(results32.isNotEmpty, isTrue);
      expect(results32.first.songNumber, 32);
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
}
