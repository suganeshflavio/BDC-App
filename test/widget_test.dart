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
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:chruch_coir/core/services/api_service.dart';
import 'package:chruch_coir/screens/feedback/feedback_screen.dart';
import 'package:chruch_coir/providers/feedback_provider.dart';
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

  testWidgets('MainNavigationScreen displays 5 bottom navigation items including Songs and Prayer',
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
    expect(find.text('Prayer'), findsWidgets);
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

  testWidgets('AboutUsScreen renders screen header and elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AboutUsScreen(showBackButton: false),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('About Us'), findsOneWidget);
  });

  testWidgets('FeedbackScreen validates mandatory name field and prevents submit without name',
      (WidgetTester tester) async {
    int submitCount = 0;
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/feedback_questions')) {
        return http.Response(
          jsonEncode({
            'feedback_questions': [
              {
                'id': 101,
                'question_text': 'How was the service?',
                'active': true,
                'answered': false,
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.path.endsWith('/feedback_answers')) {
        submitCount++;
        return http.Response('{"message":"ok"}', 201, headers: {'content-type': 'application/json'});
      }
      return http.Response('{"error":"not found"}', 404);
    });

    final apiService = ApiService(baseUrl: 'https://test.api/v1', client: mockClient);
    final feedbackProvider = FeedbackProvider(apiService: apiService);

    await tester.pumpWidget(
      MaterialApp(
        home: FeedbackScreen(provider: feedbackProvider),
      ),
    );

    // Allow questions to load
    await tester.pumpAndSettle();

    // Verify name field is present with required label
    expect(find.textContaining('உங்கள் பெயர் (Your Name) *'), findsOneWidget);
    expect(find.textContaining('Name is required to submit'), findsOneWidget);

    // Tap submit button without entering name (ensure visible in scroll view)
    final submitButton = find.byType(ElevatedButton);
    expect(submitButton, findsOneWidget);
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify submit API was NOT called
    expect(submitCount, 0);

    // Verify inline validation error is shown
    expect(find.textContaining('Please enter your name'), findsWidgets);
  });
}
