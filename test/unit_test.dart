import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

      // Search in Tamil
      final tamilResults = await apiService.fetchSongs(query: 'அக்கினி');
      expect(tamilResults.isNotEmpty, isTrue);
      for (final s in tamilResults) {
        expect(s.title.contains('அக்கினி'), isTrue);
      }

      // Search in Thanglish
      final thanglishResults = await apiService.fetchSongs(query: 'Akkini');
      expect(thanglishResults.isNotEmpty, isTrue);

      // Search for Song 32
      final appaResults = await apiService.fetchSongs(query: 'Appa');
      expect(appaResults.isNotEmpty, isTrue);
      expect(appaResults.first.songNumber, 32);
    });

    test('Song detail includes intro, chorus, and numbered verses', () async {
      final apiService = ApiService();
      final song32 = await apiService.fetchSongDetail(32);

      expect(song32, isNotNull);
      expect(song32!.songVerses.isNotEmpty, isTrue);
      expect(song32.songVerses.any((v) => v.isIntro), isTrue);
      expect(song32.songVerses.any((v) => v.isChorus), isTrue);
      expect(song32.songVerses.any((v) => v.isVerse), isTrue);
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

    test('About Us information is loaded properly', () async {
      final apiService = ApiService();
      final about = await apiService.fetchAboutUs();

      expect(about.churchName, 'Bethesda Deliverance Church');
      expect(about.ministryName, 'The Feet of Heavenly Father Ministries');
      expect(about.contactNumber, '94436-94891');
    });

    test('Notification items and unread count are parsed correctly', () async {
      final apiService = ApiService();
      final res = await apiService.fetchNotifications();

      expect(res['notifications'], isNotEmpty);
      expect(res['unread_count'], greaterThanOrEqualTo(0));
    });
  });
}
