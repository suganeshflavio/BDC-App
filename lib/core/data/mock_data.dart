import '../../models/song.dart';
import '../../models/song_verse.dart';
import '../../models/notification_item.dart';
import '../../models/about_us.dart';

class MockData {
  MockData._();

  static final AboutUs defaultAboutUs = AboutUs(
    id: 1,
    churchName: "Bethesda Deliverance Church",
    ministryName: "The Feet of Heavenly Father Ministries",
    description: "இந்த ஊழியத்தின் மூலமாக 'பரமனின் கீதங்கள்' என்ற பாடல் செயலியை வெளியிடுவதில் மகிழ்ச்சியடைகிறோம்.",
    contactNumber: "94436-94891",
  );

  static final List<NotificationItem> defaultNotifications = [
    NotificationItem(
      id: 4,
      title: "ஞாயிறு ஆராதனை (30.4.2023)",
      preacherName: "Rev. எட்வின் சத்தியநாதன்",
      description: "ஞாயிறு ஆராதனை நேரலை மற்றும் செய்தி.",
      scriptureText: "கனியுள்ள ஜீவியம்",
      youtubeUrl: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      notificationDate: "2023-04-30",
      isRead: false,
    ),
    NotificationItem(
      id: 3,
      title: "Sunday service",
      preacherName: "Rev. M. Edwin Sathiyanathan",
      description: "Join us in worship and praise.",
      scriptureText: "காயின் வழி",
      youtubeUrl: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      notificationDate: "2023-04-23",
      isRead: false,
    ),
    NotificationItem(
      id: 2,
      title: "Friday Fasting Prayer",
      preacherName: "Rev. M. Edwin Sathiyanathan",
      description: "Special fasting and deliverance prayer service.",
      scriptureText: "வனாந்திரத்தில் வழி",
      youtubeUrl: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      notificationDate: "2023-04-21",
      isRead: false,
    ),
    NotificationItem(
      id: 1,
      title: "Sunday service",
      preacherName: "Rev. Edwin Sathiyanathan",
      description: "Sunday morning special deliverance worship.",
      scriptureText: "தோல்வியின் ஆர்ப்பரிப்பு",
      youtubeUrl: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      notificationDate: "2023-04-21",
      isRead: true,
    ),
  ];

  static final List<Song> defaultSongs = [
    Song(
      id: 1,
      songNumber: 1,
      title: "அக்கினி அக்கினி எழுப்புதல்",
      titleThanglish: "Akkini Akkini Ezhuppudhal",
      isFavorite: false,
      favoritesCount: 15,
      songVerses: [
        SongVerse(
          id: 101,
          verseType: "chorus",
          verseNumber: null,
          content: "அக்கினி அக்கினி எழுப்புதல் அக்கினி\nதேசமெங்கும் பற்றியெரிய வேண்டுமே\nஆவியானவரே அக்கினி அபிஷேகமே\nஇப்போதே இறங்கி வந்திடுமே",
          position: 0,
        ),
        SongVerse(
          id: 102,
          verseType: "verse",
          verseNumber: 1,
          content: "எலியாவின் தேவன் அக்கினியின் தேவன்\nஎங்கள் நடுவில் இன்று வந்திடுமே\nபலிபீடம் மீது அக்கினி இறங்கி\nபரிசுத்தம் எங்களை மாற்றிடுமே",
          position: 1,
        ),
        SongVerse(
          id: 103,
          verseType: "verse",
          verseNumber: 2,
          content: "பெந்தேகோஸ்தே நாளில் இறங்கின அக்கினி\nஎங்கள் சபைகளில் பற்றிட வேண்டுமே\nஅன்னிய பாஷை வரங்களோடு\nவல்லமை தந்து நடத்திடுமே",
          position: 2,
        ),
      ],
    ),
    Song(
      id: 2,
      songNumber: 2,
      title: "அக்கினி அபிஷேகம் ஈந்திடும்",
      titleThanglish: "Akkini Abishegam Eenthidum",
      isFavorite: false,
      favoritesCount: 8,
      songVerses: [
        SongVerse(
          id: 201,
          verseType: "chorus",
          verseNumber: null,
          content: "அக்கினி அபிஷேகம் ஈந்திடும் தேவா\nஆவியின் மழையினால் நனைத்திடும் ஐயா\nஉந்தன் வல்லமை என்னில் விளங்கவே\nஅக்கினி ஜோதியாய் மாற்றிடுமே",
          position: 0,
        ),
        SongVerse(
          id: 202,
          verseType: "verse",
          verseNumber: 1,
          content: "சாம்பலை எடுத்து சிங்காரமாக்கும்\nதூயனின் கரம் என்னை தொட்டுவிட்டதே\nதுயரங்கள் நீக்கி ஆனந்த தைலம்\nநிறைவாய் என்னில் ஊற்றிடுமே",
          position: 1,
        ),
      ],
    ),
    Song(
      id: 3,
      songNumber: 3,
      title: "அக்கினி ஊற்றும் அக்கினி ஊற்றும்",
      titleThanglish: "Akkini Ootrum Akkini Ootrum",
      isFavorite: false,
      favoritesCount: 12,
      songVerses: [
        SongVerse(
          id: 301,
          verseType: "chorus",
          verseNumber: null,
          content: "அக்கினி ஊற்றும் அக்கினி ஊற்றும்\nஎன் பாத்திரம் நிரம்பி வழியட்டுமே\nஜீவ நதியாய் பாய்ந்து செல்ல\nஜெபத்தின் ஆவியை ஊற்றிடுமே",
          position: 0,
        ),
        SongVerse(
          id: 302,
          verseType: "verse",
          verseNumber: 1,
          content: "சோர்ந்து போன என் ஆத்துமாவை\nதேற்றிட வந்த தூய ஆவியே\nஉயிர்ப்பியும் நாதா உயிர்ப்பியும் இன்றே\nஉயிருள்ள சாட்சியாய் மாற்றிடுமே",
          position: 1,
        ),
      ],
    ),
    Song(
      id: 4,
      songNumber: 4,
      title: "அகிலமெங்கும் போற்றும் எங்கள்",
      titleThanglish: "Agilamengum Potrum Engal",
      isFavorite: true,
      favoritesCount: 24,
      songVerses: [
        SongVerse(
          id: 401,
          verseType: "chorus",
          verseNumber: null,
          content: "அகிலமெங்கும் போற்றும் எங்கள் அன்பின் இயேசுவே\nஅளவில்லாத கிருபையினால் அணைத்துக் கொண்டீரே\nஅல்லேலூயா துதி உமக்கே என்றென்றும் பாடுவோம்\nஅதிசயமானவரே உம் நாமம் வாழ்கவே",
          position: 0,
        ),
        SongVerse(
          id: 402,
          verseType: "verse",
          verseNumber: 1,
          content: "வானம் பூமி யாவும் படைத்த வல்லவரே\nவார்த்தையினால் வாழ்வு தந்த நல்லவரே\nபூமியின் எல்லைகள் உம்மை வணங்கிடுமே\nதுதிகளின் மத்தியில் வாசம் செய்பவரே",
          position: 1,
        ),
      ],
    ),
    Song(
      id: 5,
      songNumber: 5,
      title: "அசைந்தாடேன் நான் அசைந்திடேன்",
      titleThanglish: "Asaindhaaden Naan Asaindhiden",
      isFavorite: true,
      favoritesCount: 19,
      songVerses: [
        SongVerse(
          id: 501,
          verseType: "chorus",
          verseNumber: null,
          content: "அசைந்தாடேன் நான் அசைந்திடேன்\nகன்மலையாம் இயேசுவின் மேல் நிற்கின்றேன்\nசூறாவளி காற்று மோதி அடித்தாலும்\nஅசைக்க முடியாத ஜீவன் என்னில் உண்டு",
          position: 0,
        ),
        SongVerse(
          id: 502,
          verseType: "verse",
          verseNumber: 1,
          content: "சத்துருவின் அம்பு என்னை சேதப்படுத்தாது\nகர்த்தரின் கரம் என்னை தாங்கி நடத்துது\nஆயிரம் பேர் வலப்பக்கம் விழுந்தாலும்\nஅணுகாது எந்த ஒரு பொல்லாப்பும் என்னை",
          position: 1,
        ),
      ],
    ),
    Song(
      id: 6,
      songNumber: 6,
      title: "அசைவாடும் ஆவியே",
      titleThanglish: "Asaivaadum Aaviye",
      isFavorite: false,
      favoritesCount: 30,
      songVerses: [
        SongVerse(
          id: 601,
          verseType: "chorus",
          verseNumber: null,
          content: "அசைவாடும் ஆவியே தூய ஆவியே\nஆழத்தின் மேலே அசைவாடினவரே\nஇப்போதே என்னில் அசைவாடிடுமே\nஇருளான வாழ்வை ஒளியாக்குமே",
          position: 0,
        ),
        SongVerse(
          id: 602,
          verseType: "verse",
          verseNumber: 1,
          content: "வெறுமையும் பாழுமாய் கிடந்த என்னை\nவார்த்தையினால் அழகாய் மாற்றினீரே\nஉயிரற்ற எலும்புகள் உயிருடன் எழும்ப\nசுவாசித்து ஆவியே ஜீவன் தாரும்",
          position: 1,
        ),
      ],
    ),
    Song(
      id: 7,
      songNumber: 7,
      title: "அடைக்கலமே உமதுழன்மை தானே",
      titleThanglish: "Adaikkalame Umathunmai Thaane",
      isFavorite: false,
      favoritesCount: 11,
      songVerses: [
        SongVerse(
          id: 701,
          verseType: "chorus",
          verseNumber: null,
          content: "அடைக்கலமே உமது உண்மை தானே\nகேடகமும் பரிசையுமாய் காப்பவரே\nஇரவின் பயங்கரத்திற்கும் பகலில் பறக்கும் அம்புக்கும்\nபயப்படாமல் நிழலில் இளைப்பாறுவேன்",
          position: 0,
        ),
        SongVerse(
          id: 702,
          verseType: "verse",
          verseNumber: 1,
          content: "உன்னதமானவரின் மறைவில் தங்கிடுவேன்\nசர்வ வல்லவரின் நிழலில் வாழ்ந்திடுவேன்\nஎன் நம்பிக்கையும் என் கோட்டையுமாம்\nதேவன் நீர் ஒருவரே என்றென்றும் போற்றுவேன்",
          position: 1,
        ),
      ],
    ),
    Song(
      id: 32,
      songNumber: 32,
      title: "அப்பா வீட்டில் எப்போதும்",
      titleThanglish: "Appa Veetil Eppothum",
      isFavorite: true,
      favoritesCount: 45,
      songVerses: [
        SongVerse(
          id: 3201,
          verseType: "intro",
          verseNumber: null,
          content: "அப்பா வீட்டில் எப்போதும்\nசந்தோஷமே\nஆடலும் பாடலும் இங்கு தானே - நம்ம",
          position: 0,
        ),
        SongVerse(
          id: 3202,
          verseType: "chorus",
          verseNumber: null,
          content: "ஆடுவோம், கொண்டாடுவோம்\nபாடுவோம் நடனமாடுவோம்\nஅல்லேலூயா ஆனந்தமே\nஎல்லையில்லா பேரின்பமே",
          position: 1,
        ),
        SongVerse(
          id: 3203,
          verseType: "verse",
          verseNumber: 1,
          content: "காத்திருந்தார் கண்டு கொண்டார்\nகண்ணீரெல்லாம் துடைத்துவிட்டார்",
          position: 2,
        ),
        SongVerse(
          id: 3204,
          verseType: "verse",
          verseNumber: 2,
          content: "பரிசுத்த முத்தம் தந்து\nபாவமெல்லாம் போக்கிவிட்டார்",
          position: 3,
        ),
        SongVerse(
          id: 3205,
          verseType: "verse",
          verseNumber: 3,
          content: "பாவத்திலே மரித்திருந்தேன்\nபுதிய மனிதனாய் உயிர்த்து விட்டேன்",
          position: 4,
        ),
        SongVerse(
          id: 3206,
          verseType: "verse",
          verseNumber: 4,
          content: "ஆவியென்னும் ஆடை தந்தார்\nஅதிகாரம் என்னும் மோதிரம் தந்தார்",
          position: 5,
        ),
        SongVerse(
          id: 3207,
          verseType: "verse",
          verseNumber: 5,
          content: "வானமென்னும் சத்துணவை\nவாழ்நாளெல்லாம் ஊட்டுகிறார்",
          position: 6,
        ),
      ],
    ),
  ];
}
