class NotificationItem {
  final int id;
  final String title;
  final String preacherName;
  final String? description;
  final String scriptureText;
  final String youtubeUrl;
  final String notificationDate;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.preacherName,
    this.description,
    required this.scriptureText,
    required this.youtubeUrl,
    required this.notificationDate,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      preacherName: json['preacher_name'] as String? ?? '',
      description: json['description'] as String?,
      scriptureText: json['scripture_text'] as String? ?? '',
      youtubeUrl: json['youtube_url'] as String? ?? '',
      notificationDate: json['notification_date'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'preacher_name': preacherName,
      'description': description,
      'scripture_text': scriptureText,
      'youtube_url': youtubeUrl,
      'notification_date': notificationDate,
      'is_read': isRead,
    };
  }

  NotificationItem copyWith({
    int? id,
    String? title,
    String? preacherName,
    String? description,
    String? scriptureText,
    String? youtubeUrl,
    String? notificationDate,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      preacherName: preacherName ?? this.preacherName,
      description: description ?? this.description,
      scriptureText: scriptureText ?? this.scriptureText,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      notificationDate: notificationDate ?? this.notificationDate,
      isRead: isRead ?? this.isRead,
    );
  }
}
