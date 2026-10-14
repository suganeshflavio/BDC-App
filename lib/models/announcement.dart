class Announcement {
  final int id;
  final String subject;
  final String description;
  final List<String> bannerImages;
  final DateTime? createdAt;

  const Announcement({
    required this.id,
    required this.subject,
    required this.description,
    required this.bannerImages,
    this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final images = extractImageUrls(json['banner_images']);

    DateTime? parsedDate;
    if (json['created_at'] != null) {
      try {
        parsedDate = DateTime.parse(json['created_at'].toString());
      } catch (_) {}
    }

    return Announcement(
      id: json['id'] as int? ?? 0,
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      bannerImages: images,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'description': description,
      'banner_images': bannerImages,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  static List<String> extractImageUrls(dynamic rawImages) {
    final List<String> result = [];
    if (rawImages == null) return result;

    final List<String> items = [];
    if (rawImages is List) {
      for (final item in rawImages) {
        if (item != null) items.add(item.toString());
      }
    } else if (rawImages is String) {
      items.add(rawImages);
    }

    // Matches src="url" or src='url' from HTML <img> tags
    final imgRegex = RegExp(r'''src\s*=\s*["']([^"']+)["']''', caseSensitive: false);

    for (final item in items) {
      final matches = imgRegex.allMatches(item);
      if (matches.isNotEmpty) {
        for (final match in matches) {
          final url = match.group(1)?.trim();
          if (url != null && url.isNotEmpty) {
            result.add(url);
          }
        }
      } else {
        // Direct image URL or relative path without <img> tags
        final trimmed = item.trim();
        final clean = trimmed.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (clean.isNotEmpty &&
            (clean.startsWith('http://') ||
                clean.startsWith('https://') ||
                clean.startsWith('/') ||
                clean.endsWith('.jpg') ||
                clean.endsWith('.jpeg') ||
                clean.endsWith('.png') ||
                clean.endsWith('.webp') ||
                clean.endsWith('.gif'))) {
          result.add(clean);
        }
      }
    }

    return result;
  }
}

class AnnouncementsResponse {
  final List<Announcement> announcements;

  const AnnouncementsResponse({
    required this.announcements,
  });

  factory AnnouncementsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['announcements'] as List<dynamic>?) ?? [];
    return AnnouncementsResponse(
      announcements: list
          .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
