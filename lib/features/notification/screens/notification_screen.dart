import 'dart:ui';
import 'package:chat_jyotishi/features/app_widgets/show_top_snackBar.dart';
import 'package:chat_jyotishi/features/notification/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/star_field_background.dart';
import '../../app_widgets/glass_icon_button.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_events.dart';
import '../bloc/notification_states.dart';
import '../models/notification_model.dart';
import '../repository/notification_repository.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatelessWidget {
  final String userType; // 'client' or 'astrologer'

  const NotificationScreen({super.key, this.userType = 'client'});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationBloc(
        notificationRepository: NotificationRepository(NotificationService()),
      )..add(FetchNotificationsEvent()),
      child: NotificationScreenContent(userType: userType),
    );
  }
}

class NotificationScreenContent extends StatefulWidget {
  final String userType;

  const NotificationScreenContent({super.key, required this.userType});

  @override
  State<NotificationScreenContent> createState() =>
      _NotificationScreenContentState();
}

class _NotificationScreenContentState extends State<NotificationScreenContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  String selectedFilter = 'All';
  final List<String> filters = [
    'All',
    'CHAT_MESSAGE',
    'APPOINTMENT',
    'PAYMENT',
    'SYSTEM',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupScrollListener();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        final state = context.read<NotificationBloc>().state;
        if (state is NotificationLoadedState && state.hasMore) {
          context.read<NotificationBloc>().add(
            FetchNotificationsEvent(
              limit: 20,
              offset: state.notifications.length,
              isLoadMore: true,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlay();

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Stack(
        children: [
          const StarFieldBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryBlack,
                  AppColors.cosmicPurple.withOpacity(0.15),
                  AppColors.primaryBlack,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFilterChips(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildNotificationsList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.primaryBlack,
      ),
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        int unreadCount = 0;
        if (state is NotificationLoadedState) {
          unreadCount = state.unreadCount;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              GlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSubtitle(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              GlassIconButton(
                icon: Icons.done_all_rounded,
                onTap: () {
                  if (unreadCount > 0) {
                    _handleMarkAllRead(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSubtitle() {
    if (widget.userType == 'astrologer') {
      return 'Stay updated with your consultations';
    }
    return 'Stay connected with cosmic updates';
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final index = entry.key;
          final filter = entry.value;
          final isSelected = selectedFilter == filter;

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    selectedFilter = filter;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFDB2777).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _getFilterDisplayName(filter),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'CHAT_MESSAGE':
        return 'Messages';
      case 'APPOINTMENT':
        return 'Appointments';
      case 'PAYMENT':
        return 'Payments';
      case 'SYSTEM':
        return 'System';
      default:
        return filter;
    }
  }

  Widget _buildNotificationsList() {
    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.error,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }

        if (state is NotificationMarkAsReadSuccessState) {
          // Refresh list after marking as read
          context.read<NotificationBloc>().add(RefreshNotificationsEvent());
        }

        if (state is NotificationDeleteSuccessState) {
          // Already handled in BLoC
        }
      },
      builder: (context, state) {
        if (state is NotificationLoadingState) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.cosmicPurple),
          );
        }

        if (state is NotificationLoadedState ||
            state is NotificationLoadMoreState) {
          final notifications = state is NotificationLoadedState
              ? state.notifications
              : (state as NotificationLoadMoreState).notifications;

          final filteredNotifications = _getFilteredNotifications(
            notifications,
          );

          if (filteredNotifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AppColors.cosmicPurple,
            backgroundColor: AppColors.cardMedium,
            onRefresh: () async {
              context.read<NotificationBloc>().add(RefreshNotificationsEvent());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount:
                  filteredNotifications.length +
                  (state is NotificationLoadMoreState ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredNotifications.length) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.cosmicPurple,
                      ),
                    ),
                  );
                }
                return _buildNotificationCard(
                  filteredNotifications[index],
                  index,
                );
              },
            ),
          );
        }

        return _buildEmptyState();
      },
    );
  }

  List<NotificationModel> _getFilteredNotifications(
    List<NotificationModel> notifications,
  ) {
    if (selectedFilter == 'All') {
      return notifications;
    }

    return notifications
        .where((notification) => notification.type == selectedFilter)
        .toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF9333EA).withOpacity(0.2),
                  const Color(0xFFDB2777).withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedFilter == 'All'
                ? 'You\'re all caught up!'
                : 'No ${_getFilterDisplayName(selectedFilter).toLowerCase()} notifications',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildNotificationCard(NotificationModel notification, int index) {
  //   final isUnread = !notification.isRead;
  //
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 12),
  //     child: TweenAnimationBuilder(
  //       duration: Duration(milliseconds: 400 + (index * 80)),
  //       curve: Curves.easeOutCubic,
  //       tween: Tween<double>(begin: 0, end: 1),
  //       builder: (context, double value, child) {
  //         return Transform.scale(
  //           scale: 0.8 + (0.2 * value),
  //           child: Opacity(opacity: value, child: child),
  //         );
  //       },
  //       child: Dismissible(
  //         key: Key(notification.id),
  //         direction: DismissDirection.endToStart,
  //         background: Container(
  //           alignment: Alignment.centerRight,
  //           padding: const EdgeInsets.only(right: 20),
  //           decoration: BoxDecoration(
  //             gradient: const LinearGradient(
  //               begin: Alignment.centerLeft,
  //               end: Alignment.centerRight,
  //               colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
  //             ),
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           child: const Icon(
  //             Icons.delete_rounded,
  //             color: Colors.white,
  //             size: 24,
  //           ),
  //         ),
  //         onDismissed: (direction) {
  //           _handleDeleteNotification(context, notification);
  //         },
  //         child: GestureDetector(
  //           onTap: () {
  //             HapticFeedback.lightImpact();
  //             _handleNotificationTap(context, notification);
  //           },
  //           child: Container(
  //             padding: const EdgeInsets.all(16),
  //             decoration: BoxDecoration(
  //               gradient: isUnread
  //                   ? LinearGradient(
  //                       begin: Alignment.centerLeft,
  //                       end: Alignment.centerRight,
  //                       colors: [
  //                         const Color(0xFF9333EA).withOpacity(0.25),
  //                         const Color(0xFFDB2777).withOpacity(0.25),
  //                       ],
  //                     )
  //                   : null,
  //               color: isUnread ? null : Colors.white.withOpacity(0.05),
  //               borderRadius: BorderRadius.circular(20),
  //               border: Border.all(
  //                 color: isUnread
  //                     ? Colors.white.withOpacity(0.15)
  //                     : Colors.white.withOpacity(0.08),
  //                 width: 1,
  //               ),
  //               boxShadow: isUnread
  //                   ? [
  //                       BoxShadow(
  //                         color: const Color(0xFFDB2777).withOpacity(0.2),
  //                         blurRadius: 20,
  //                         offset: const Offset(0, 8),
  //                       ),
  //                     ]
  //                   : null,
  //             ),
  //             child: Row(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 _buildNotificationIcon(notification.type),
  //                 const SizedBox(width: 16),
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Row(
  //                         children: [
  //                           Expanded(
  //                             child: Text(
  //                               notification.title,
  //                               style: TextStyle(
  //                                 color: Colors.white,
  //                                 fontSize: 15,
  //                                 fontWeight: isUnread
  //                                     ? FontWeight.w700
  //                                     : FontWeight.w600,
  //                                 letterSpacing: -0.3,
  //                               ),
  //                             ),
  //                           ),
  //                           if (isUnread)
  //                             Container(
  //                               width: 8,
  //                               height: 8,
  //                               decoration: BoxDecoration(
  //                                 gradient: const LinearGradient(
  //                                   colors: [
  //                                     Color(0xFF9333EA),
  //                                     Color(0xFFDB2777),
  //                                   ],
  //                                 ),
  //                                 shape: BoxShape.circle,
  //                                 boxShadow: [
  //                                   BoxShadow(
  //                                     color: const Color(
  //                                       0xFFDB2777,
  //                                     ).withOpacity(0.5),
  //                                     blurRadius: 6,
  //                                     spreadRadius: 1,
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 6),
  //                       Text(
  //                         notification.message,
  //                         style: TextStyle(
  //                           color: Colors.white.withOpacity(0.8),
  //                           fontSize: 13,
  //                           height: 1.4,
  //                           fontWeight: FontWeight.w400,
  //                         ),
  //                         maxLines: 2,
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                       const SizedBox(height: 10),
  //                       Row(
  //                         children: [
  //                           Icon(
  //                             Icons.access_time_rounded,
  //                             size: 12,
  //                             color: Colors.white.withOpacity(0.5),
  //                           ),
  //                           const SizedBox(width: 4),
  //                           Text(
  //                             timeago.format(
  //                               notification.createdAt,
  //                               locale: 'en_short',
  //                             ),
  //                             style: TextStyle(
  //                               color: Colors.white.withOpacity(0.5),
  //                               fontSize: 11,
  //                               fontWeight: FontWeight.w400,
  //                             ),
  //                           ),
  //                           if (notification.count > 1) ...[
  //                             const SizedBox(width: 8),
  //                             Container(
  //                               padding: const EdgeInsets.symmetric(
  //                                 horizontal: 6,
  //                                 vertical: 2,
  //                               ),
  //                               decoration: BoxDecoration(
  //                                 color: AppColors.cosmicPurple.withOpacity(
  //                                   0.3,
  //                                 ),
  //                                 borderRadius: BorderRadius.circular(8),
  //                               ),
  //                               child: Text(
  //                                 '${notification.count}',
  //                                 style: TextStyle(
  //                                   color: Colors.white.withOpacity(0.8),
  //                                   fontSize: 10,
  //                                   fontWeight: FontWeight.w600,
  //                                 ),
  //                               ),
  //                             ),
  //                           ],
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildNotificationCard(NotificationModel notification, int index) {
    final isUnread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: 400 + (index * 80)),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.delete_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          onDismissed: (direction) {
            _handleDeleteNotification(context, notification);
          },
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _handleNotificationTap(context, notification);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isUnread
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFF9333EA).withOpacity(0.25),
                          const Color(0xFFDB2777).withOpacity(0.25),
                        ],
                      )
                    : null,
                color: isUnread ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUnread
                      ? Colors.white.withOpacity(0.15)
                      : Colors.white.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: isUnread
                    ? [
                        BoxShadow(
                          color: const Color(0xFFDB2777).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon container with badge (only for count > 1)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: _buildNotificationIcon(notification.type),
                      ),
                      // Unread badge - only shown when count > 1
                      if (notification.count > 1)
                        Positioned(
                          top: -4, // Position above the icon container
                          right: -4, // Position to the right of icon container
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFDB2777,
                                  ).withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${notification.count}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            // Small unread dot for single unread notifications
                            if (isUnread && notification.count <= 1)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF9333EA),
                                      Color(0xFFDB2777),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFDB2777,
                                      ).withOpacity(0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeago.format(
                                notification.createdAt,
                                locale: 'en_short',
                              ),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type.toUpperCase()) {
      case 'APPOINTMENT':
        icon = Icons.calendar_today_rounded;
        color = AppColors.primaryPurple;
        break;
      case 'CHAT_MESSAGE':
        icon = Icons.chat_bubble_rounded;
        color = Colors.blue;
        break;
      case 'PAYMENT':
        icon = Icons.payment_rounded;
        color = Colors.green;
        break;
      case 'REMINDER':
        icon = Icons.notifications_active_rounded;
        color = Colors.orange;
        break;
      case 'SYSTEM':
        icon = Icons.info_rounded;
        color = AppColors.lightPurple;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = AppColors.primaryPurple;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  void _handleMarkAllRead(BuildContext context) {
    context.read<NotificationBloc>().add(MarkAllNotificationsAsReadEvent());

    showTopSnackBar(
      context: context,
      message: 'All notifications marked as read',
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) {
    // Mark as read if unread
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
        MarkNotificationAsReadEvent(notificationId: notification.id),
      );
    }

    // Navigate based on notification type and metadata
    if (notification.metadata != null) {
      final metadata = notification.metadata!;

      switch (notification.type.toUpperCase()) {
        case 'CHAT_MESSAGE':
          if (metadata.containsKey('chatId')) {
            // Navigate to chat screen
            debugPrint('Navigate to chat: ${metadata['chatId']}');
          }
          break;
        case 'APPOINTMENT':
          if (metadata.containsKey('appointmentId')) {
            // Navigate to appointment details
            debugPrint('Navigate to appointment: ${metadata['appointmentId']}');
          }
          break;
        case 'PAYMENT':
          if (metadata.containsKey('transactionId')) {
            // Navigate to payment details
            debugPrint('Navigate to payment: ${metadata['transactionId']}');
          }
          break;
        default:
          debugPrint('Notification tapped: ${notification.title}');
      }
    }
  }

  void _handleDeleteNotification(
    BuildContext context,
    NotificationModel notification,
  ) {
    context.read<NotificationBloc>().add(
      DeleteNotificationEvent(notificationId: notification.id),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Notification deleted',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white.withOpacity(0.1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
