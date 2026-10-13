class PrayerRequest {
  final int id;
  final String name;
  final String mobile;
  final String description;
  final String? voiceNoteUrl;
  final String status;
  final String deviceId;
  final DateTime? createdAt;

  const PrayerRequest({
    required this.id,
    required this.name,
    required this.mobile,
    required this.description,
    this.voiceNoteUrl,
    required this.status,
    required this.deviceId,
    this.createdAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';

  factory PrayerRequest.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['created_at'] != null) {
      try {
        parsedDate = DateTime.parse(json['created_at'].toString());
      } catch (_) {}
    }

    return PrayerRequest(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      description: json['description'] as String? ?? '',
      voiceNoteUrl: json['voice_note_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      deviceId: json['device_id'] as String? ?? '',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobile': mobile,
      'description': description,
      'voice_note_url': voiceNoteUrl,
    };
  }
}

class PrayerRequestsResponse {
  final List<PrayerRequest> requests;
  final int currentPage;
  final int totalPages;
  final int totalCount;

  const PrayerRequestsResponse({
    required this.requests,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
  });

  factory PrayerRequestsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['prayer_requests'] as List<dynamic>?) ?? [];
    final meta = (json['meta'] as Map<String, dynamic>?) ?? {};

    return PrayerRequestsResponse(
      requests: list
          .map((item) => PrayerRequest.fromJson(item as Map<String, dynamic>))
          .toList(),
      currentPage: meta['current_page'] as int? ?? 1,
      totalPages: meta['total_pages'] as int? ?? 1,
      totalCount: meta['total_count'] as int? ?? list.length,
    );
  }
}
