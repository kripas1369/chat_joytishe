import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chat_jyotishi/features/notification/bloc/notification_events.dart';
import 'package:chat_jyotishi/features/notification/bloc/notification_states.dart';
import 'package:chat_jyotishi/features/notification/repository/notification_repository.dart';
import 'package:chat_jyotishi/features/notification/models/notification_model.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;
  List<NotificationModel> _allNotifications = [];
  int _currentOffset = 0;
  static const int _pageSize = 20;

  NotificationBloc({required this.notificationRepository})
      : super(NotificationInitialState()) {
    on<FetchNotificationsEvent>(_onFetchNotifications);
    on<MarkNotificationAsReadEvent>(_onMarkAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<RefreshNotificationsEvent>(_onRefreshNotifications);
    on<FetchUnreadCountEvent>(_onFetchUnreadCount);
  }

  Future<void> _onFetchNotifications(
      FetchNotificationsEvent event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      if (!event.isLoadMore) {
        emit(NotificationLoadingState());
        _currentOffset = 0;
        _allNotifications = [];
      } else {
        if (state is NotificationLoadedState) {
          emit(NotificationLoadMoreState(
            notifications: _allNotifications,
            total: (state as NotificationLoadedState).total,
            unreadCount: (state as NotificationLoadedState).unreadCount,
          ));
        }
      }

      final response = await notificationRepository.getNotifications(
        limit: event.limit,
        offset: event.isLoadMore ? _currentOffset : 0,
      );

      if (event.isLoadMore) {
        _allNotifications.addAll(response.notifications);
      } else {
        _allNotifications = response.notifications;
      }

      _currentOffset = _allNotifications.length;

      final hasMore = _allNotifications.length < response.total;

      emit(NotificationLoadedState(
        notifications: List.from(_allNotifications),
        total: response.total,
        unreadCount: response.unreadCount,
        hasMore: hasMore,
      ));
    } catch (e) {
      emit(NotificationErrorState(error: e.toString()));
    }
  }

  Future<void> _onMarkAsRead(
      MarkNotificationAsReadEvent event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      final success = await notificationRepository.markAsRead(event.notificationId);

      if (success) {
        // Update local list
        final updatedNotifications = _allNotifications.map((notification) {
          if (notification.id == event.notificationId) {
            return notification.copyWith(isRead: true);
          }
          return notification;
        }).toList();

        _allNotifications = updatedNotifications;

        final currentState = state;
        if (currentState is NotificationLoadedState) {
          final newUnreadCount = currentState.unreadCount > 0
              ? currentState.unreadCount - 1
              : 0;

          emit(currentState.copyWith(
            notifications: List.from(_allNotifications),
            unreadCount: newUnreadCount,
          ));
        }

        emit(NotificationMarkAsReadSuccessState(notificationId: event.notificationId));
      }
    } catch (e) {
      emit(NotificationErrorState(error: e.toString()));
    }
  }

  Future<void> _onMarkAllAsRead(
      MarkAllNotificationsAsReadEvent event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      final success = await notificationRepository.markAllAsRead();

      if (success) {
        // Mark all as read locally
        final updatedNotifications = _allNotifications.map((notification) {
          return notification.copyWith(isRead: true);
        }).toList();

        _allNotifications = updatedNotifications;

        final currentState = state;
        if (currentState is NotificationLoadedState) {
          emit(currentState.copyWith(
            notifications: List.from(_allNotifications),
            unreadCount: 0,
          ));
        }
      }
    } catch (e) {
      emit(NotificationErrorState(error: e.toString()));
    }
  }

  Future<void> _onDeleteNotification(
      DeleteNotificationEvent event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      final success = await notificationRepository.deleteNotification(event.notificationId);

      if (success) {
        // Remove from local list
        final notification = _allNotifications.firstWhere(
              (n) => n.id == event.notificationId,
        );

        _allNotifications.removeWhere((n) => n.id == event.notificationId);

        final currentState = state;
        if (currentState is NotificationLoadedState) {
          final newUnreadCount = !notification.isRead && currentState.unreadCount > 0
              ? currentState.unreadCount - 1
              : currentState.unreadCount;

          emit(currentState.copyWith(
            notifications: List.from(_allNotifications),
            total: currentState.total - 1,
            unreadCount: newUnreadCount,
          ));
        }

        emit(NotificationDeleteSuccessState(notificationId: event.notificationId));
      }
    } catch (e) {
      emit(NotificationErrorState(error: e.toString()));
    }
  }

  Future<void> _onRefreshNotifications(
      RefreshNotificationsEvent event,
      Emitter<NotificationState> emit,
      ) async {
    add(FetchNotificationsEvent(limit: _pageSize, offset: 0, isLoadMore: false));
  }

  Future<void> _onFetchUnreadCount(
      FetchUnreadCountEvent event,
      Emitter<NotificationState> emit,
      ) async {
    try {
      final unreadCount = await notificationRepository.getUnreadCount();
      emit(NotificationUnreadCountUpdatedState(unreadCount: unreadCount));
    } catch (e) {
      emit(NotificationErrorState(error: e.toString()));
    }
  }
}