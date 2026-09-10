import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/api_service.dart';
import '../models/notification_item.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  NotificationProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiService.fetchNotifications();
      _notifications = (res['notifications'] as List<NotificationItem>?) ?? [];
      _unreadCount = (res['unread_count'] as int?) ?? 0;
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openNotification(NotificationItem item) async {
    if (!item.isRead) {
      item.isRead = true;
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
      await _apiService.markNotificationRead(item.id);
    }

    if (item.youtubeUrl.isNotEmpty) {
      final uri = Uri.tryParse(item.youtubeUrl);
      if (uri != null) {
        try {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!launched) {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        } catch (e) {
          debugPrint('Could not launch youtube url: $e');
        }
      }
    }
  }
}
