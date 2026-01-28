import 'dart:convert';
import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_bloc.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_events.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_states.dart';
import 'package:chat_jyotishi/features/chat/models/active_user_model.dart';
import 'package:chat_jyotishi/features/chat/repository/chat_repository.dart';
import 'package:chat_jyotishi/features/chat/screens/chat_screen.dart';
import 'package:chat_jyotishi/features/chat/service/chat_service.dart';
import 'package:chat_jyotishi/features/payment/services/coin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

/// Decode JWT token to get user info
Map<String, dynamic>? _decodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    String payload = parts[1];
    switch (payload.length % 4) {
      case 1:
        payload += '===';
        break;
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }

    final decoded = utf8.decode(base64Url.decode(payload));
    return json.decode(decoded);
  } catch (e) {
    debugPrint('Error decoding JWT: $e');
    return null;
  }
}

class JyotishListScreen extends StatefulWidget {
  const JyotishListScreen({super.key});

  @override
  State<JyotishListScreen> createState() => _JyotishListScreenState();
}

class _JyotishListScreenState extends State<JyotishListScreen>
    with TickerProviderStateMixin {
  final CoinService _coinService = CoinService();
  int _coinBalance = 0;
  bool _isLoading = true;
  int? _selectedCardIndex;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Default astrologers when no data available
  final List<Map<String, dynamic>> _defaultAstrologers = [
    {
      'id': 'default_1',
      'name': 'Pandit Sharma',
      'profilePhoto': '',
      'specialization': 'Vedic Astrology',
      'experience': 15,
      'rating': 4.8,
      'isOnline': true,
    },
    {
      'id': 'default_2',
      'name': 'Acharya Mishra',
      'profilePhoto': '',
      'specialization': 'Kundali Expert',
      'experience': 12,
      'rating': 4.6,
      'isOnline': true,
    },
    {
      'id': 'default_3',
      'name': 'Guru Patel',
      'profilePhoto': '',
      'specialization': 'Numerology',
      'experience': 10,
      'rating': 4.7,
      'isOnline': false,
    },
    {
      'id': 'default_4',
      'name': 'Jyotishi Verma',
      'profilePhoto': '',
      'specialization': 'Palmistry',
      'experience': 8,
      'rating': 4.5,
      'isOnline': true,
    },
    {
      'id': 'default_5',
      'name': 'Pandit Trivedi',
      'profilePhoto': '',
      'specialization': 'Vastu Shastra',
      'experience': 20,
      'rating': 4.9,
      'isOnline': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final balance = await _coinService.getBalance();
    setState(() {
      _coinBalance = balance;
      _isLoading = false;
    });
  }

  void _onCardTap(int index) {
    setState(() {
      _selectedCardIndex = index;
    });
    _glowController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _glowController.reverse();
        }
      });
    });
  }

  void _showInsufficientCoinsDialog(int required) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cosmicRed, AppColors.cosmicPink],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  AppColors.purple300,
                  AppColors.pink300,
                  AppColors.red300,
                ],
              ).createShader(bounds),
              child: const Text(
                'Insufficient Coins',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'You need $required coin(s) but only have $_coinBalance.\nPlease add more coins to continue.',
          style: const TextStyle(color: AppColors.textGray300, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textGray400),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.cosmicHeroGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cosmicRed.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/payment_page');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add Coins',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChatTap(dynamic astrologer) async {
    if (_coinBalance >= 200) {
      try {
        // Get tokens and user ID from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('accessToken');
        final refreshToken = prefs.getString('refreshToken');

        if (accessToken == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please login to start chatting'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Decode JWT to get current user ID
        final decoded = _decodeJwt(accessToken);
        final currentUserId = decoded?['id']?.toString() ?? '';

        if (currentUserId.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to get user info. Please login again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Get astrologer details
        final String astrologerId;
        final String astrologerName;
        final String? astrologerPhoto;
        final bool isOnline;

        if (astrologer is ActiveAstrologerModel) {
          astrologerId = astrologer.id;
          astrologerName = astrologer.name;
          astrologerPhoto = astrologer.profilePhoto;
          isOnline = astrologer.isOnline;
        } else {
          astrologerId = astrologer['id']?.toString() ?? '';
          astrologerName = astrologer['name']?.toString() ?? 'Unknown';
          astrologerPhoto = astrologer['profilePhoto']?.toString();
          isOnline = astrologer['isOnline'] == true;
        }

        if (astrologerId.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid astrologer selected'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Navigate to ChatScreen for one-to-one chat
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: '',
                otherUserId: astrologerId,
                otherUserName: astrologerName,
                otherUserPhoto: astrologerPhoto,
                currentUserId: currentUserId,
                accessToken: accessToken,
                refreshToken: refreshToken,
                isOnline: isOnline,
              ),
            ),
          ).then((_) {
            // Refresh coin balance when returning from chat
            _loadBalance();
          });
        }
      } catch (e) {
        debugPrint('Error opening chat: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open chat: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      _showInsufficientCoinsDialog(200);
    }
  }

  void _handleViewProfile(dynamic astrologer) {
    // Show profile dialog or navigate to profile page
    final name = astrologer is ActiveAstrologerModel
        ? astrologer.name
        : astrologer['name'];
    final specialization = astrologer is ActiveAstrologerModel
        ? 'Expert Astrologer'
        : astrologer['specialization'];
    final experience = astrologer is ActiveAstrologerModel
        ? 5
        : astrologer['experience'];
    final rating = astrologer is ActiveAstrologerModel
        ? 4.5
        : astrologer['rating'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProfileBottomSheet(
        name: name,
        specialization: specialization,
        experience: experience,
        rating: rating,
        profilePhoto: astrologer is ActiveAstrologerModel
            ? astrologer.profilePhoto
            : astrologer['profilePhoto'],
      ),
    );
  }

  Widget _buildProfileBottomSheet({
    required String name,
    required String specialization,
    required int experience,
    required double rating,
    required String profilePhoto,
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cosmicPurple.withOpacity(0.3),
                AppColors.cosmicPink.withOpacity(0.2),
                Colors.black.withOpacity(0.8),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppColors.cosmicPurple.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.cosmicPink, AppColors.cosmicPurple],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cosmicPink.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.cosmicPurple.withOpacity(0.3),
                  backgroundImage: profilePhoto.isNotEmpty
                      ? NetworkImage(profilePhoto)
                      : null,
                  child: profilePhoto.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.purple300, AppColors.pink300],
                ).createShader(bounds),
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                specialization,
                style: const TextStyle(
                  color: AppColors.textGray300,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildProfileStat(
                    icon: Icons.work_history_rounded,
                    value: '$experience yrs',
                    label: 'Experience',
                  ),
                  _buildProfileStat(
                    icon: Icons.star_rounded,
                    value: rating.toStringAsFixed(1),
                    label: 'Rating',
                  ),
                  _buildProfileStat(
                    icon: Icons.monetization_on_rounded,
                    value: '200',
                    label: 'Coins',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cosmicPurple.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleChatTap({'name': name});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Start Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cosmicPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.cosmicPurple.withOpacity(0.3),
            ),
          ),
          child: Icon(icon, color: AppColors.cosmicPink, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textGray400,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlay();

    return BlocProvider(
      create: (context) =>
          ChatBloc(chatRepository: ChatRepository(ChatService()))
            ..add(FetchActiveUsersEvent()),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Stack(
          children: [
            // Star field background
            const StarFieldBackground(),
            // Cosmic gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    AppColors.cosmicPurple.withOpacity(0.3),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: _buildHeader(),
                  ),
                  Expanded(
                    child: BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        List<ActiveAstrologerModel> astrologers = [];
                        if (state is ActiveUsersLoaded) {
                          astrologers = state.astrologers;
                        }

                        // Use default astrologers if no real data
                        final displayList = astrologers.isNotEmpty
                            ? astrologers
                            : _defaultAstrologers;

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final item = displayList[index];
                            if (item is ActiveAstrologerModel) {
                              return _buildAstrologerCard(
                                index: index,
                                astrologer: item,
                              );
                            } else {
                              return _buildDefaultAstrologerCard(
                                index: index,
                                data: item as Map<String, dynamic>,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.cosmicPurple,
                  ),
                ),
              ),
          ],
        ),
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
    return Row(
      children: [
        GlassIconButton(
          onTap: () => Navigator.pop(context),
          icon: Icons.arrow_back_ios_new_rounded,
        ),
        const SizedBox(width: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.purple300, AppColors.pink300, AppColors.red300],
          ).createShader(bounds),
          child: const Text(
            'Expert Jyotish',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            const Icon(Icons.monetization_on, color: gold, size: 24),
            const SizedBox(width: 4),
            Text(
              '$_coinBalance',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAstrologerCard({
    required int index,
    required ActiveAstrologerModel astrologer,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final isSelected = _selectedCardIndex == index;
        final glowIntensity = isSelected ? _glowAnimation.value : 0.0;

        return GestureDetector(
          onTap: () => _onCardTap(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.cosmicPink.withOpacity(0.2 + glowIntensity * 0.2),
                        AppColors.cosmicPurple.withOpacity(0.15 + glowIntensity * 0.15),
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.cosmicPink.withOpacity(0.4 + glowIntensity * 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cosmicPink.withOpacity(0.3 + glowIntensity * 0.4),
                        blurRadius: 20 + glowIntensity * 15,
                        spreadRadius: 2 + glowIntensity * 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Circular Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.cosmicPink.withOpacity(0.8 + glowIntensity * 0.2),
                              AppColors.cosmicPurple.withOpacity(0.8 + glowIntensity * 0.2),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cosmicPink.withOpacity(0.4 + glowIntensity * 0.3),
                              blurRadius: 12 + glowIntensity * 8,
                              spreadRadius: 2 + glowIntensity * 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: AppColors.cosmicPurple.withOpacity(0.3),
                          backgroundImage: astrologer.profilePhoto.isNotEmpty
                              ? NetworkImage(astrologer.profilePhoto)
                              : null,
                          child: astrologer.profilePhoto.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 35,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name and Coins
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // View Profile at top
                            GestureDetector(
                              onTap: () => _handleViewProfile(astrologer),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.visibility_rounded,
                                    color: AppColors.cosmicPink.withOpacity(0.8),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'View Profile',
                                    style: TextStyle(
                                      color: AppColors.cosmicPink.withOpacity(0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Name
                            Text(
                              astrologer.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Online status
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: astrologer.isOnline
                                        ? Colors.greenAccent
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                    boxShadow: astrologer.isOnline
                                        ? [
                                            BoxShadow(
                                              color: Colors.greenAccent.withOpacity(0.5),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  astrologer.isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    color: astrologer.isOnline
                                        ? Colors.greenAccent
                                        : AppColors.textGray400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Coins
                            Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: gold,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '200 coins',
                                  style: TextStyle(
                                    color: gold,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Chat Button
                      GestureDetector(
                        onTap: () => _handleChatTap(astrologer),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.cosmicPurple.withOpacity(0.9 + glowIntensity * 0.1),
                                AppColors.cosmicPink.withOpacity(0.9 + glowIntensity * 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cosmicPurple.withOpacity(0.5 + glowIntensity * 0.3),
                                blurRadius: 10 + glowIntensity * 6,
                                spreadRadius: 1 + glowIntensity * 2,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Chat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultAstrologerCard({
    required int index,
    required Map<String, dynamic> data,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final isSelected = _selectedCardIndex == index;
        final glowIntensity = isSelected ? _glowAnimation.value : 0.0;

        return GestureDetector(
          onTap: () => _onCardTap(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.cosmicPink.withOpacity(0.2 + glowIntensity * 0.2),
                        AppColors.cosmicPurple.withOpacity(0.15 + glowIntensity * 0.15),
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.cosmicPink.withOpacity(0.4 + glowIntensity * 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cosmicPink.withOpacity(0.3 + glowIntensity * 0.4),
                        blurRadius: 20 + glowIntensity * 15,
                        spreadRadius: 2 + glowIntensity * 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Circular Avatar with default icon
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.cosmicPink.withOpacity(0.8 + glowIntensity * 0.2),
                              AppColors.cosmicPurple.withOpacity(0.8 + glowIntensity * 0.2),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cosmicPink.withOpacity(0.4 + glowIntensity * 0.3),
                              blurRadius: 12 + glowIntensity * 8,
                              spreadRadius: 2 + glowIntensity * 2,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: AppColors.cosmicPurple.withOpacity(0.3),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name and Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // View Profile at top
                            GestureDetector(
                              onTap: () => _handleViewProfile(data),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.visibility_rounded,
                                    color: AppColors.cosmicPink.withOpacity(0.8),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'View Profile',
                                    style: TextStyle(
                                      color: AppColors.cosmicPink.withOpacity(0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Name
                            Text(
                              data['name'] ?? 'Unknown Jyotish',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Specialization
                            Text(
                              data['specialization'] ?? 'Astrology Expert',
                              style: const TextStyle(
                                color: AppColors.textGray300,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Online status
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: (data['isOnline'] ?? false)
                                        ? Colors.greenAccent
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                    boxShadow: (data['isOnline'] ?? false)
                                        ? [
                                            BoxShadow(
                                              color: Colors.greenAccent.withOpacity(0.5),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  (data['isOnline'] ?? false) ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    color: (data['isOnline'] ?? false)
                                        ? Colors.greenAccent
                                        : AppColors.textGray400,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.star_rounded,
                                  color: gold,
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${data['rating'] ?? 4.5}',
                                  style: const TextStyle(
                                    color: gold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Coins
                            Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: gold,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '200 coins',
                                  style: TextStyle(
                                    color: gold,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Chat Button
                      GestureDetector(
                        onTap: () => _handleChatTap(data),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.cosmicPurple.withOpacity(0.9 + glowIntensity * 0.1),
                                AppColors.cosmicPink.withOpacity(0.9 + glowIntensity * 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cosmicPurple.withOpacity(0.5 + glowIntensity * 0.3),
                                blurRadius: 10 + glowIntensity * 6,
                                spreadRadius: 1 + glowIntensity * 2,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Chat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
