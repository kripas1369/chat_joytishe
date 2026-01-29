import 'package:chat_jyotishi/features/notification/models/notification_model.dart';
import 'package:chat_jyotishi/features/notification/services/notification_service.dart';

class NotificationRepository {
  final NotificationService _notificationService;

  NotificationRepository(this._notificationService);

  // Get notifications with mapped model
  Future<NotificationResponse> getNotifications({
    int limit = 5,
    int offset = 0,
  }) async {
    try {
      final response = await _notificationService.getNotifications(
        limit: limit,
        offset: offset,
      );
      return NotificationResponse.fromJson(response);
    } catch (e) {
      throw Exception('Repository Error: $e');
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _notificationService.markAsRead(notificationId);
      return response['success'] ?? false;
    } catch (e) {
      throw Exception('Repository Error: $e');
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await _notificationService.markAllAsRead();
      return response['success'] ?? false;
    } catch (e) {
      throw Exception('Repository Error: $e');
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _notificationService.deleteNotification(notificationId);
      return response['success'] ?? false;
    } catch (e) {
      throw Exception('Repository Error: $e');
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    try {
      return await _notificationService.getUnreadCount();
    } catch (e) {
      throw Exception('Repository Error: $e');
    }
  }
}