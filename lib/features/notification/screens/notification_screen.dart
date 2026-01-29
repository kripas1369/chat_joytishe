import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/star_field_background.dart';
import '../../app_widgets/glass_icon_button.dart';

class NotificationScreen extends StatefulWidget {
  final String userType; // 'client' or 'astrologer'

  const NotificationScreen({super.key, this.userType = 'client'});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String selectedFilter = 'All';
  final List<String> filters = ['All', 'Appointments', 'Messages', 'Payments'];

  @override
  void initState() {
    super.initState();
    _initAnimations();
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

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlay();

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Stack(
        children: [
          // Background matching home dashboard
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
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
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
            onTap: _handleMarkAllRead,
          ),
        ],
      ),
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
                        ? LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              const Color(0xFF9333EA),
                              const Color(0xFFDB2777),
                            ],
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
                    filter,
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

  Widget _buildNotificationsList() {
    final notifications = _getFilteredNotifications();

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(notifications[index], index);
      },
    );
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
            'You\'re all caught up!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final isUnread = notification['isUnread'] ?? false;

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
          key: Key(notification['id']),
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
            _handleDeleteNotification(notification);
          },
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _handleNotificationTap(notification);
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNotificationIcon(notification['type']),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification['title'],
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
                                if (isUnread)
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
                              notification['message'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w400,
                              ),
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
                                  notification['time'],
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
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'appointment':
        icon = Icons.calendar_today_rounded;
        color = AppColors.primaryPurple;
        break;
      case 'message':
        icon = Icons.chat_bubble_rounded;
        color = Colors.blue;
        break;
      case 'payment':
        icon = Icons.payment_rounded;
        color = Colors.green;
        break;
      case 'reminder':
        icon = Icons.notifications_active_rounded;
        color = Colors.orange;
        break;
      case 'update':
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

  List<Map<String, dynamic>> _getFilteredNotifications() {
    final notifications = widget.userType == 'astrologer'
        ? _getAstrologerNotifications()
        : _getClientNotifications();

    if (selectedFilter == 'All') {
      return notifications;
    }

    return notifications
        .where(
          (notification) =>
              notification['category'].toString().toLowerCase() ==
              selectedFilter.toLowerCase(),
        )
        .toList();
  }

  List<Map<String, dynamic>> _getClientNotifications() {
    return [
      {
        'id': '1',
        'type': 'appointment',
        'category': 'Appointments',
        'title': 'Appointment Confirmed',
        'message':
            'Your session with Dr. Ravi Sharma is scheduled for tomorrow at 10:00 AM',
        'time': '2 hours ago',
        'isUnread': true,
      },
      {
        'id': '2',
        'type': 'message',
        'category': 'Messages',
        'title': 'New Message from Priya Devi',
        'message': 'Your kundli analysis is ready. Please check your messages.',
        'time': '5 hours ago',
        'isUnread': true,
      },
      {
        'id': '3',
        'type': 'payment',
        'category': 'Payments',
        'title': 'Payment Successful',
        'message': '₹500 has been added to your wallet successfully',
        'time': '1 day ago',
        'isUnread': false,
      },
      {
        'id': '4',
        'type': 'reminder',
        'category': 'Appointments',
        'title': 'Consultation Reminder',
        'message': 'Your appointment with Acharya Suresh starts in 30 minutes',
        'time': '2 days ago',
        'isUnread': false,
      },
      {
        'id': '5',
        'type': 'update',
        'category': 'Messages',
        'title': 'Daily Horoscope Available',
        'message': 'Your personalized horoscope for today is ready to view',
        'time': '3 days ago',
        'isUnread': false,
      },
      {
        'id': '6',
        'type': 'appointment',
        'category': 'Appointments',
        'title': 'Appointment Completed',
        'message':
            'Thank you for consulting with Meera Joshi. Please rate your experience.',
        'time': '4 days ago',
        'isUnread': false,
      },
      {
        'id': '7',
        'type': 'payment',
        'category': 'Payments',
        'title': 'Refund Processed',
        'message':
            '₹200 has been refunded to your wallet for cancelled appointment',
        'time': '5 days ago',
        'isUnread': false,
      },
    ];
  }

  List<Map<String, dynamic>> _getAstrologerNotifications() {
    return [
      {
        'id': '1',
        'type': 'appointment',
        'category': 'Appointments',
        'title': 'New Appointment Request',
        'message':
            'Praveen Shrestha has requested an appointment for tomorrow at 2:00 PM',
        'time': '1 hour ago',
        'isUnread': true,
      },
      {
        'id': '2',
        'type': 'message',
        'category': 'Messages',
        'title': 'New Message from Client',
        'message': 'You have received a new message from Anjali Verma',
        'time': '3 hours ago',
        'isUnread': true,
      },
      {
        'id': '3',
        'type': 'payment',
        'category': 'Payments',
        'title': 'Payment Received',
        'message': '₹800 has been credited to your account for consultation',
        'time': '6 hours ago',
        'isUnread': false,
      },
      {
        'id': '4',
        'type': 'reminder',
        'category': 'Appointments',
        'title': 'Upcoming Consultation',
        'message': 'Your session with Ravi Kumar starts in 15 minutes',
        'time': '1 day ago',
        'isUnread': false,
      },
      {
        'id': '5',
        'type': 'appointment',
        'category': 'Appointments',
        'title': 'Appointment Cancelled',
        'message': 'Client has cancelled the appointment scheduled for today',
        'time': '2 days ago',
        'isUnread': false,
      },
      {
        'id': '6',
        'type': 'update',
        'category': 'Messages',
        'title': 'New Review Received',
        'message':
            'Pooja Singh has rated your consultation 5 stars with a positive review',
        'time': '3 days ago',
        'isUnread': false,
      },
      {
        'id': '7',
        'type': 'payment',
        'category': 'Payments',
        'title': 'Weekly Earnings Report',
        'message': 'Your total earnings for this week: ₹12,500',
        'time': '4 days ago',
        'isUnread': false,
      },
    ];
  }

  void _handleMarkAllRead() {
    setState(() {
      // Mark all notifications as read
      debugPrint('Marking all notifications as read');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'All notifications marked as read',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF9333EA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    debugPrint('Notification tapped: ${notification['title']}');
    // Navigate to relevant screen based on notification type
  }

  void _handleDeleteNotification(Map<String, dynamic> notification) {
    debugPrint('Notification deleted: ${notification['title']}');

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
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFFDB2777),
          onPressed: () {
            debugPrint('Undo delete notification');
          },
        ),
      ),
    );
  }
}
