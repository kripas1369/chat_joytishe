// lib/features/history/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/app_background_gradient.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';

class HistoryScreenClient extends StatefulWidget {
  const HistoryScreenClient({super.key});

  @override
  State<HistoryScreenClient> createState() => _HistoryScreenClientState();
}

class _HistoryScreenClientState extends State<HistoryScreenClient>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          buildGradientBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildTabBar(),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildChatHistory(),
                      _buildAppointmentHistory(),
                      _buildTransactionHistory(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          const Text(
            'History',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Chats'),
          Tab(text: 'Appointments'),
          Tab(text: 'Transactions'),
        ],
      ),
    );
  }

  Widget _buildChatHistory() {
    final chats = [
      {
        'astrologer': 'Pandit Sharma',
        'date': '2 days ago',
        'duration': '45 min',
        'type': 'Chat',
        'topic': 'Career Guidance',
        'coins': 150,
      },
      {
        'astrologer': 'Dr. Gupta',
        'date': '1 week ago',
        'duration': '30 min',
        'type': 'Chat',
        'topic': 'Love & Relationship',
        'coins': 100,
      },
      {
        'astrologer': 'Jyotish Acharya',
        'date': '2 weeks ago',
        'duration': '60 min',
        'type': 'Video',
        'topic': 'Health Issues',
        'coins': 200,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return _buildHistoryCard(
          icon: chat['type'] == 'Chat'
              ? Icons.chat_bubble_rounded
              : Icons.videocam_rounded,
          title: chat['astrologer'] as String,
          subtitle: chat['topic'] as String,
          date: chat['date'] as String,
          duration: chat['duration'] as String,
          coins: chat['coins'] as int,
          type: chat['type'] as String,
        );
      },
    );
  }

  Widget _buildAppointmentHistory() {
    final appointments = [
      {
        'astrologer': 'Pandit Sharma',
        'date': 'Jan 15, 2026',
        'time': '10:00 AM',
        'status': 'Completed',
        'type': 'Video Call',
        'coins': 300,
      },
      {
        'astrologer': 'Dr. Gupta',
        'date': 'Jan 10, 2026',
        'time': '2:00 PM',
        'status': 'Completed',
        'type': 'Chat',
        'coins': 150,
      },
      {
        'astrologer': 'Jyotish Acharya',
        'date': 'Jan 20, 2026',
        'time': '4:00 PM',
        'status': 'Upcoming',
        'type': 'Video Call',
        'coins': 300,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final apt = appointments[index];
        return _buildAppointmentCard(
          astrologer: apt['astrologer'] as String,
          date: apt['date'] as String,
          time: apt['time'] as String,
          status: apt['status'] as String,
          type: apt['type'] as String,
          coins: apt['coins'] as int,
        );
      },
    );
  }

  Widget _buildTransactionHistory() {
    final transactions = [
      {
        'title': 'Coin Purchase',
        'date': 'Jan 16, 2026',
        'amount': '+500',
        'type': 'credit',
        'method': 'Khalti',
      },
      {
        'title': 'Chat with Pandit Sharma',
        'date': 'Jan 14, 2026',
        'amount': '-150',
        'type': 'debit',
        'method': null,
      },
      {
        'title': 'Coin Purchase',
        'date': 'Jan 10, 2026',
        'amount': '+1000',
        'type': 'credit',
        'method': 'eSewa',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final txn = transactions[index];
        return _buildTransactionCard(
          title: txn['title'] as String,
          date: txn['date'] as String,
          amount: txn['amount'] as String,
          isCredit: txn['type'] == 'credit',
          method: txn['method'] as String?,
        );
      },
    );
  }

  Widget _buildHistoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String date,
    required String duration,
    required int coins,
    required String type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 14,
                      color: AppColors.primaryPurple,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$coins',
                      style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                type,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard({
    required String astrologer,
    required String date,
    required String time,
    required String status,
    required String type,
    required int coins,
  }) {
    final isUpcoming = status == 'Upcoming';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                astrologer,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? Colors.green.withOpacity(0.2)
                      : AppColors.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isUpcoming ? Colors.green : AppColors.primaryPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    type == 'Video Call'
                        ? Icons.videocam_rounded
                        : Icons.chat_bubble_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    type,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.monetization_on,
                    size: 16,
                    color: AppColors.primaryPurple,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$coins coins',
                    style: const TextStyle(
                      color: AppColors.primaryPurple,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard({
    required String title,
    required String date,
    required String amount,
    required bool isCredit,
    String? method,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCredit
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isCredit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    if (method != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          method,
                          style: const TextStyle(
                            color: AppColors.primaryPurple,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isCredit ? Colors.green : Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
