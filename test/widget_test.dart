import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chruch_coir/core/services/storage_service.dart';
import 'package:chruch_coir/screens/splash_screen.dart';
import 'package:chruch_coir/screens/main_navigation_screen.dart';
import 'package:chruch_coir/screens/lyrics/lyrics_screen.dart';
import 'package:chruch_coir/screens/settings/about_us_screen.dart';
import 'package:chruch_coir/models/song.dart';
import 'package:chruch_coir/models/song_verse.dart';
import 'package:chruch_coir/providers/settings_provider.dart';
import 'package:chruch_coir/providers/song_provider.dart';
import 'package:chruch_coir/providers/favorite_provider.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'favorite_song_ids': <String>[],
      'preferred_font_size': 18.0,
      'read_notification_ids': <String>[],
    });
    await StorageService.init();
  });

  testWidgets('SplashScreen renders full-screen cover image and skip button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    await tester.pump();

    // Verify Image widget is present for splash cover
    expect(find.byType(Image), findsOneWidget);

    // Verify skip button is present
    expect(find.textContaining('Skip'), findsOneWidget);
  });

  testWidgets('MainNavigationScreen displays 5 bottom navigation items including Songs and About',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavigationScreen(),
      ),
    );

    await tester.pump();

    // Verify bottom navigation bar items
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Songs'), findsWidgets);
    expect(find.text('Favourite'), findsWidgets);
    expect(find.text('Notification'), findsWidgets);
    expect(find.text('About'), findsWidgets);
  });

  testWidgets('LyricsScreen has copy lyrics button and displays copy feedback',
      (WidgetTester tester) async {
    final sampleSong = Song(
      id: 1,
      songNumber: 1,
      title: 'அக்கினி நதியே பாய்ந்து வா',
      titleThanglish: 'Akkini Nadhiye Paaindhu Vaa',
      songVerses: [
        SongVerse(
          id: 1,
          verseType: 'verse',
          verseNumber: 1,
          content: 'அக்கினி நதியே பாய்ந்து வா\nஆவியின் மழையே பொழிந்து வா',
        ),
      ],
    );

    final settingsProvider = SettingsProvider();
    final songProvider = SongProvider();
    final favoriteProvider = FavoriteProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: LyricsScreen(
          song: sampleSong,
          settingsProvider: settingsProvider,
          songProvider: songProvider,
          favoriteProvider: favoriteProvider,
        ),
      ),
    );

    await tester.pump();

    // Verify copy icon button exists
    expect(find.byIcon(Icons.copy_rounded), findsWidgets);
    expect(find.text('Copy Lyrics'), findsOneWidget);

    // Tap the copy button
    await tester.tap(find.byIcon(Icons.copy_rounded).first);
    await tester.pump();

    // Verify SnackBar appears
    expect(find.textContaining('நகலெடுக்கப்பட்டது'), findsOneWidget);
  });

  testWidgets('AboutUsScreen renders ministry information directly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AboutUsScreen(showBackButton: false),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('About Us'), findsOneWidget);
    expect(find.textContaining('Bethesda Deliverance Church'), findsWidgets);
    expect(find.textContaining('94436-94891'), findsWidgets);
    expect(find.text('Call Prayer Line'), findsOneWidget);
  });
}
