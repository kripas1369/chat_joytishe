import 'package:chat_jyotishi/features/notification/models/notification_model.dart';

abstract class NotificationState {}

class NotificationInitialState extends NotificationState {}

class NotificationLoadingState extends NotificationState {}

class NotificationLoadedState extends NotificationState {
  final List<NotificationModel> notifications;
  final int total;
  final int unreadCount;
  final bool hasMore;

  NotificationLoadedState({
    required this.notifications,
    required this.total,
    required this.unreadCount,
    required this.hasMore,
  });

  NotificationLoadedState copyWith({
    List<NotificationModel>? notifications,
    int? total,
    int? unreadCount,
    bool? hasMore,
  }) {
    return NotificationLoadedState(
      notifications: notifications ?? this.notifications,
      total: total ?? this.total,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class NotificationLoadMoreState extends NotificationState {
  final List<NotificationModel> notifications;
  final int total;
  final int unreadCount;

  NotificationLoadMoreState({
    required this.notifications,
    required this.total,
    required this.unreadCount,
  });
}

class NotificationMarkAsReadSuccessState extends NotificationState {
  final String notificationId;

  NotificationMarkAsReadSuccessState({required this.notificationId});
}

class NotificationDeleteSuccessState extends NotificationState {
  final String notificationId;

  NotificationDeleteSuccessState({required this.notificationId});
}

class NotificationUnreadCountUpdatedState extends NotificationState {
  final int unreadCount;

  NotificationUnreadCountUpdatedState({required this.unreadCount});
}

class NotificationErrorState extends NotificationState {
  final String error;

  NotificationErrorState({required this.error});
}