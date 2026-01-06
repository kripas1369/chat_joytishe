import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/chat/screens/chat_list_screen.dart';
import 'package:chat_jyotishi/features/payment/screens/broadcast_page.dart';
import 'package:chat_jyotishi/features/payment/services/coin_service.dart';
import 'package:flutter/material.dart';

class ChatOptionsPage extends StatefulWidget {
  const ChatOptionsPage({super.key});

  @override
  State<ChatOptionsPage> createState() => _ChatOptionsPageState();
}

class _ChatOptionsPageState extends State<ChatOptionsPage> {
  final CoinService _coinService = CoinService();
  int _coinBalance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final balance = await _coinService.getBalance();
    setState(() {
      _coinBalance = balance;
      _isLoading = false;
    });
  }

  Future<void> _handleSingleChat() async {
    if (_coinBalance < 1) {
      _showInsufficientCoinsDialog(1);
      return;
    }

    final success = await _coinService.deductCoins(1);
    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatListScreen()),
      );
    }
  }

  Future<void> _handleBroadcast() async {
    if (_coinBalance < 5) {
      _showInsufficientCoinsDialog(5);
      return;
    }

    final success = await _coinService.deductCoins(5);
    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BroadcastPage()),
      );
    }
  }

  void _showInsufficientCoinsDialog(int required) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text(
              'Insufficient Coins',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'You need $required coin(s) but only have $_coinBalance.\nPlease add more coins to continue.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/payment_page');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Add Coins',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StarFieldBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient.withOpacity(0.9),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  _buildHeader(),
                  SizedBox(height: 24),
                  _buildBalanceCard(),
                  SizedBox(height: 32),
                  _buildOptionsTitle(),
                  SizedBox(height: 20),
                  _buildOptionCard(
                    icon: Icons.chat_bubble_rounded,
                    title: 'Single Chat',
                    subtitle: 'Chat with one astrologer',
                    coinCost: 1,
                    color: AppColors.primaryPurple,
                    onTap: _handleSingleChat,
                  ),
                  SizedBox(height: 16),
                  _buildOptionCard(
                    icon: Icons.campaign_rounded,
                    title: 'Broadcast Message',
                    subtitle: 'Send to all astrologers at once',
                    coinCost: 5,
                    color: Colors.orange,
                    onTap: _handleBroadcast,
                    isPremium: true,
                  ),
                  Spacer(),
                  _buildInfoText(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GlassIconButton(
          onTap: () => Navigator.pop(context),
          icon: Icons.arrow_back,
        ),
        SizedBox(width: 16),
        Text(
          'Chat Options',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.monetization_on_rounded,
              color: gold,
              size: 32,
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.monetization_on, color: gold, size: 24),
                  SizedBox(width: 4),
                  Text(
                    '$_coinBalance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'coins',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/payment_page'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _buildOptionsTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Option',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Select how you want to connect with astrologers',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int coinCost,
    required Color color,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    final hasEnoughCoins = _coinBalance >= coinCost;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isPremium) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: gold, size: 18),
                      SizedBox(width: 4),
                      Text(
                        '$coinCost coin${coinCost > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!hasEnoughCoins) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Insufficient',
                            style: TextStyle(
                              color: Colors.red,
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
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoText() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Single chat connects you with one astrologer. Broadcast sends your query to all available astrologers.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
