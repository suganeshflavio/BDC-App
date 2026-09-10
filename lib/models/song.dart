import 'song_verse.dart';

class Song {
  final int id;
  final int songNumber;
  final String title;
  final String titleThanglish;
  bool isFavorite;
  final int favoritesCount;
  final List<SongVerse> songVerses;

  Song({
    required this.id,
    required this.songNumber,
    required this.title,
    required this.titleThanglish,
    this.isFavorite = false,
    this.favoritesCount = 0,
    this.songVerses = const [],
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    var versesJson = json['song_verses'] as List<dynamic>?;
    List<SongVerse> parsedVerses = [];
    if (versesJson != null) {
      parsedVerses = versesJson
          .map((v) => SongVerse.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    return Song(
      id: json['id'] as int? ?? 0,
      songNumber: json['song_number'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      titleThanglish: json['title_thanglish'] as String? ?? '',
      isFavorite: json['is_favorite'] as bool? ?? false,
      favoritesCount: json['favorites_count'] as int? ?? 0,
      songVerses: parsedVerses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'song_number': songNumber,
      'title': title,
      'title_thanglish': titleThanglish,
      'is_favorite': isFavorite,
      'favorites_count': favoritesCount,
      'song_verses': songVerses.map((v) => v.toJson()).toList(),
    };
  }

  Song copyWith({
    int? id,
    int? songNumber,
    String? title,
    String? titleThanglish,
    bool? isFavorite,
    int? favoritesCount,
    List<SongVerse>? songVerses,
  }) {
    return Song(
      id: id ?? this.id,
      songNumber: songNumber ?? this.songNumber,
      title: title ?? this.title,
      titleThanglish: titleThanglish ?? this.titleThanglish,
      isFavorite: isFavorite ?? this.isFavorite,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      songVerses: songVerses ?? this.songVerses,
    );
  }
}
