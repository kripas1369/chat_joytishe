abstract class NotificationEvent {}

class FetchNotificationsEvent extends NotificationEvent {
  final int limit;
  final int offset;
  final bool isLoadMore;

  FetchNotificationsEvent({
    this.limit = 20,
    this.offset = 0,
    this.isLoadMore = false,
  });
}

class MarkNotificationAsReadEvent extends NotificationEvent {
  final String notificationId;

  MarkNotificationAsReadEvent({required this.notificationId});
}

class MarkAllNotificationsAsReadEvent extends NotificationEvent {}

class DeleteNotificationEvent extends NotificationEvent {
  final String notificationId;

  DeleteNotificationEvent({required this.notificationId});
}

class RefreshNotificationsEvent extends NotificationEvent {}

class FetchUnreadCountEvent extends NotificationEvent {}