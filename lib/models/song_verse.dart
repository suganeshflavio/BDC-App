class SongVerse {
  final int id;
  final String verseType; // 'intro', 'chorus', 'verse'
  final int? verseNumber;
  final String content;
  final int? position;

  SongVerse({
    required this.id,
    required this.verseType,
    this.verseNumber,
    required this.content,
    this.position,
  });

  factory SongVerse.fromJson(Map<String, dynamic> json) {
    return SongVerse(
      id: json['id'] as int? ?? 0,
      verseType: json['verse_type'] as String? ?? 'verse',
      verseNumber: json['verse_number'] as int?,
      content: json['content'] as String? ?? '',
      position: json['position'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'verse_type': verseType,
      'verse_number': verseNumber,
      'content': content,
      'position': position,
    };
  }

  bool get isIntro => verseType.toLowerCase() == 'intro';
  bool get isChorus => verseType.toLowerCase() == 'chorus';
  bool get isVerse => verseType.toLowerCase() == 'verse';
}
