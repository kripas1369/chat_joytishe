import 'package:chat_jyotishi/features/chat/screens/chat_screen.dart';
import 'package:chat_jyotishi/features/chat/service/socket_service.dart';
import 'package:chat_jyotishi/features/home/widgets/drawer_item.dart';
import 'package:chat_jyotishi/features/home/widgets/notification_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/glass_icon_button.dart';

class HomeScreenAstrologer extends StatefulWidget {
  const HomeScreenAstrologer({super.key});

  @override
  State<HomeScreenAstrologer> createState() => _HomeScreenAstrologerState();
}

class _HomeScreenAstrologerState extends State<HomeScreenAstrologer>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SocketService _socketService = SocketService();

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  bool isOnline = false;
  String astrologerId = '';
  String accessToken = '';
  String refreshToken = '';

  // Broadcast notification state
  List<Map<String, dynamic>> _broadcastNotifications = [];

  final String astrologerName = 'Dr. Sharma';
  final String specialization = 'Vedic Astrology';
  final double rating = 4.8;
  final int totalConsultations = 1247;
  final String todayEarnings = 'NRs 8000';
  final String monthlyEarnings = 'NRs 87,340';
  final int pendingRequests = 5;
  final int activeChats = 3;
  final int todayConsultations = 12;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
    _initAnimations();
    _setupBroadcastListener();
  }

  void _setupBroadcastListener() {
    // Listen for new broadcast messages from clients
    _socketService.socket?.on('broadcast:newMessage', (data) {
      debugPrint('New broadcast received: $data');
      if (mounted) {
        setState(() {
          _broadcastNotifications.add(Map<String, dynamic>.from(data));
        });
        _showBroadcastDialog(Map<String, dynamic>.from(data));
      }
    });
  }

  Future<void> _connectSocket() async {
    if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
      if (!_socketService.connected) {
        await _socketService.connect(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
    }
  }

  void _showBroadcastDialog(Map<String, dynamic> broadcast) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BroadcastNotificationDialog(
        broadcast: broadcast,
        onAccept: () => _handleAcceptBroadcast(broadcast),
        onReject: () => _handleRejectBroadcast(broadcast),
      ),
    );
  }

  void _handleAcceptBroadcast(Map<String, dynamic> broadcast) async {
    Navigator.pop(context); // Close dialog

    final messageId = broadcast['messageId'] ?? broadcast['id'] ?? '';
    final clientId = broadcast['senderId'] ?? broadcast['userId'] ?? '';
    final clientName = broadcast['senderName'] ?? broadcast['userName'] ?? 'User';
    final clientPhoto = broadcast['senderPhoto'] ?? broadcast['userPhoto'];

    // Accept the broadcast via socket
    _socketService.acceptBroadcastMessage(messageId);

    // Remove from local notifications
    setState(() {
      _broadcastNotifications.removeWhere((b) =>
        (b['messageId'] ?? b['id']) == messageId);
    });

    // Navigate to chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: 'chat_${clientId}_$astrologerId',
          otherUserId: clientId,
          otherUserName: clientName,
          otherUserPhoto: clientPhoto,
          currentUserId: astrologerId,
          accessToken: accessToken,
          refreshToken: refreshToken,
          isOnline: true,
        ),
      ),
    );
  }

  void _handleRejectBroadcast(Map<String, dynamic> broadcast) {
    Navigator.pop(context); // Close dialog

    final messageId = broadcast['messageId'] ?? broadcast['id'] ?? '';

    // Remove from local notifications
    setState(() {
      _broadcastNotifications.removeWhere((b) =>
        (b['messageId'] ?? b['id']) == messageId);
    });
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
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlay();
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundDark,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildWelcomeSection(),
                          const SizedBox(height: 16),
                          _buildStatusCard(),
                          const SizedBox(height: 16),
                          _buildStatsGrid(),
                          const SizedBox(height: 24),
                          _buildPendingRequests(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildTodaySchedule(),
                          const SizedBox(height: 40),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Astrologer ID: $astrologerId',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Access Token: $accessToken',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Refresh Token: $refreshToken',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
        systemNavigationBarColor: AppColors.backgroundDark,
      ),
    );
  }

  Widget _buildAppLogo() {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, AppColors.lightPurple],
          ).createShader(bounds),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Chat',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                TextSpan(
                  text: 'Jyotishi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Icon(
              Icons.auto_awesome,
              size: 16,
              color: AppColors.primaryPurple.withOpacity(_pulseAnimation.value),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GlassIconButton(
              icon: Icons.menu_rounded,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            SizedBox(width: 16),
            _buildAppLogo(),
          ],
        ),
        NotificationButton(
          notificationCount: 4,
          onTap: () => _navigateTo('/notifications'),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacity(0.2),
            AppColors.deepPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGreetingBadge(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.orange
                          ..withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Welcome, $astrologerName',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            isOnline
                ? 'You\'re guiding seekers today. Ready to share cosmic wisdom\nwith those seeking celestial guidance.'
                : 'Take time to recharge your spiritual energy.\nToggle online when ready to guide seekers.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingBadge() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;

    if (hour < 12) {
      greeting = 'Good Morning';
      icon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      icon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Good Evening';
      icon = Icons.nightlight_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.lightPurple),
          SizedBox(width: 6),
          Text(
            greeting,
            style: TextStyle(
              color: AppColors.lightPurple,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isOnline
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            isOnline
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isOnline ? Colors.green : Colors.orange,
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        isOnline ? 'You\'re Online' : 'You\'re Offline',
                        style: TextStyle(
                          color: isOnline ? Colors.green : Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    isOnline
                        ? 'Available for consultations'
                        : 'Toggle to start receiving requests',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Switch(
                value: isOnline,
                onChanged: (value) => setState(() => isOnline = value),
                activeColor: Colors.green,
                inactiveThumbColor: Colors.orange,
              ),
            ],
          ),
          if (isOnline && pendingRequests > 0) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.primaryPurple,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You have $pendingRequests new consultation requests',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primaryPurple,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          icon: Icons.currency_rupee_rounded,
          title: 'Today\'s Earnings',
          value: todayEarnings,
          subtitle: 'from $todayConsultations consultations',
          color: Colors.green,
          onTap: () {},
        ),
        _buildStatCard(
          icon: Icons.trending_up_rounded,
          title: 'Monthly Earnings',
          value: monthlyEarnings,
          subtitle: 'This month',
          color: AppColors.primaryPurple,
          onTap: () {},
        ),
        _buildStatCard(
          icon: Icons.star_rounded,
          title: 'Rating',
          value: rating.toString(),
          subtitle: 'from $totalConsultations reviews',
          color: Colors.amber,
          onTap: () {},
        ),
        _buildStatCard(
          icon: Icons.chat_bubble_rounded,
          title: 'Active Chats',
          value: activeChats.toString(),
          subtitle: 'Ongoing conversations',
          color: AppColors.primaryPurple,
          onTap: () => Navigator.of(
            context,
          ).pushReplacementNamed('/astrologer_chat_list_screen'),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequests() {
    if (pendingRequests == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Pending Requests', '$pendingRequests new'),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 1,
          itemBuilder: (context, index) => _buildRequestCard(index),
        ),
      ],
    );
  }

  Widget _buildRequestCard(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacity(0.2),
            AppColors.deepPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.cardMedium,
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rahul Kumar',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Chat consultation',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '5 min ago',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAcceptRequest(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Accept'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleRejectRequest(index),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.account_balance_wallet_rounded,
        'label': 'Earnings',
        'route': '/earnings',
      },
      {
        'icon': Icons.calendar_today_rounded,
        'label': 'Schedule',
        'route': '/schedule',
      },
      {'icon': Icons.history_rounded, 'label': 'History', 'route': '/history'},
      {
        'icon': Icons.bar_chart_rounded,
        'label': 'Analytics',
        'route': '/analytics',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quick Actions', 'Manage your services'),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionButton(
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              onTap: () => _navigateTo(action['route'] as String),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryPurple, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Today\'s Schedule',
          '$todayConsultations consultations',
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Column(
            children: [
              _buildScheduleItem(
                '10:00 AM',
                'Priya Sharma',
                'Birth Chart Analysis',
              ),
              Divider(color: Colors.white.withOpacity(0.08)),
              _buildScheduleItem(
                '11:30 AM',
                'Amit Patel',
                'Career Consultation',
              ),
              Divider(color: Colors.white.withOpacity(0.08)),
              _buildScheduleItem(
                '02:00 PM',
                'Neha Gupta',
                'Love & Relationship',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(String time, String name, String type) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cardDark, AppColors.backgroundDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(),
              Divider(color: Colors.white.withOpacity(0.08)),
              Expanded(child: _buildDrawerItems()),
              Divider(color: Colors.white.withOpacity(0.08)),
              _buildDrawerLogout(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.cardMedium,
              child: Icon(
                Icons.person_rounded,
                color: AppColors.textSecondary,
                size: 40,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            astrologerName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            specialization,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                '$rating',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' ($totalConsultations reviews)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItems() {
    final items = [
      {'icon': Icons.home_rounded, 'title': 'Home', 'selected': true},
      {'icon': Icons.person_rounded, 'title': 'Profile', 'route': '/profile'},
      {
        'icon': Icons.account_balance_wallet_rounded,
        'title': 'Earnings',
        'route': '/earnings',
      },
      {
        'icon': Icons.calendar_today_rounded,
        'title': 'Schedule',
        'route': '/schedule',
      },
      {
        'icon': Icons.history_rounded,
        'title': 'Consultation History',
        'route': '/history',
      },
      {
        'icon': Icons.bar_chart_rounded,
        'title': 'Analytics',
        'route': '/analytics',
      },
      {
        'icon': Icons.settings_rounded,
        'title': 'Settings',
        'route': '/settings',
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'route': '/support',
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: items.map((item) {
        return DrawerItem(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          isSelected: item['selected'] as bool? ?? false,
          onTap: () {
            if (item['route'] != null) {
              _navigateTo(item['route'] as String);
            } else {
              Navigator.pop(context);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildDrawerLogout() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: DrawerItem(
        icon: Icons.logout_rounded,
        title: 'Logout',
        isDestructive: true,
        onTap: _handleLogout,
      ),
    );
  }

  void _navigateTo(String route) {
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      astrologerId = prefs.getString('astrologerId') ?? '';
      accessToken = prefs.getString('astrologerAccessToken') ?? '';
      refreshToken = prefs.getString('astrologerRefreshToken') ?? '';
    });

    // Connect to socket after loading auth data
    await _connectSocket();
    _setupBroadcastListener();
  }

  void _handleAcceptRequest(int index) async {}

  void _handleRejectRequest(int index) {
    debugPrint('Rejected request $index');
  }

  void _handleLogout() {
    debugPrint('Logout tapped');
  }
}

/// Dialog widget for broadcast notifications
class _BroadcastNotificationDialog extends StatelessWidget {
  final Map<String, dynamic> broadcast;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BroadcastNotificationDialog({
    required this.broadcast,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final senderName = broadcast['senderName'] ?? broadcast['userName'] ?? 'User';
    final message = broadcast['content'] ?? broadcast['message'] ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cardDark, AppColors.backgroundDark],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.orange.withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.campaign_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            SizedBox(height: 20),

            // Title
            Text(
              'New Broadcast Message',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

            // Sender info
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_rounded, color: Colors.white70, size: 16),
                  SizedBox(width: 6),
                  Text(
                    senderName,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Message
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onReject,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Reject',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onAccept,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.green.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
