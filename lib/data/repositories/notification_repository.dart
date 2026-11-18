import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../models/notification_model.dart';

/// Notification & Alerts repository integrating real API GET /alerts.
class NotificationRepository {
  final ApiClient _apiClient;
  final List<NotificationModel> _notifications = [];

  NotificationRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches operational alerts from GET /alerts
  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiClient.get(ApiConfig.alerts);
    List<dynamic> items = [];
    if (response is List) {
      items = response;
    } else if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['alerts'] is List) {
        items = data['alerts'] as List;
      } else if (response['alerts'] is List) {
        items = response['alerts'] as List;
      }
    }

    // Filter to citizen-appropriate alerts
    final alerts = items
        .whereType<Map<String, dynamic>>()
        .where((json) {
          final audience = (json['audience'] ?? json['target'] ?? '').toString().toLowerCase();
          final isCitizen = json['is_citizen'];
          if (audience == 'admin' || audience == 'internal') return false;
          if (isCitizen == false || isCitizen == 'false') return false;
          return true;
        })
        .map((e) => NotificationModel.fromJson(e))
        .toList();

    _notifications.clear();
    _notifications.addAll(alerts);
    return List.unmodifiable(_notifications);
  }

  /// Returns unread count.
  Future<int> getUnreadCount() async {
    if (_notifications.isEmpty) {
      try {
        await getNotifications();
      } catch (_) {}
    }
    return _notifications.where((n) => !n.isRead).length;
  }

  /// Marks a notification as read.
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }
}
