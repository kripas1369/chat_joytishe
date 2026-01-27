import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:chat_jyotishi/constants/api_endpoints.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_bloc.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_events.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_states.dart';
import 'package:chat_jyotishi/features/chat/models/active_user_model.dart';
import 'package:chat_jyotishi/features/chat/repository/chat_repository.dart';
import 'package:chat_jyotishi/features/chat/service/chat_service.dart';
import 'dart:convert';
import 'package:chat_jyotishi/features/chat/screens/chat_screen.dart';
import 'package:chat_jyotishi/features/chat/service/chat_lock_service.dart';
import 'package:chat_jyotishi/features/chat/service/socket_service.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/home/screens/home_dashboard_screen.dart';
import 'package:chat_jyotishi/features/payment/screens/chat_options_page.dart';
import 'package:chat_jyotishi/features/payment/screens/payment_page.dart';
import 'package:chat_jyotishi/features/payment/services/coin_service.dart';
import 'package:chat_jyotishi/features/home/widgets/drawer_item.dart';
import 'package:chat_jyotishi/features/home/widgets/notification_button.dart';
import 'package:chat_jyotishi/features/profile/bloc/profile_bloc.dart';
import 'package:chat_jyotishi/features/profile/bloc/profile_events.dart';
import 'package:chat_jyotishi/features/profile/bloc/profile_states.dart';
import 'package:chat_jyotishi/features/profile/repository/profile_repository.dart';
import 'package:chat_jyotishi/features/profile/service/profile_service.dart';
import 'package:chat_jyotishi/features/app_widgets/show_top_snackBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/constant.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              ChatBloc(chatRepository: ChatRepository(ChatService()))
                ..add(FetchActiveUsersEvent()),
        ),
        BlocProvider(
          create: (context) => ProfileBloc(
            profileRepository: ProfileRepository(ProfileService()),
          )..add(LoadCurrentUserProfileEvent()),
        ),
      ],
      child: const WelcomeScreenContent(),
    );
  }
}

class WelcomeScreenContent extends StatefulWidget {
  const WelcomeScreenContent({super.key});

  @override
  State<WelcomeScreenContent> createState() => _WelcomeScreenContentState();
}

class _WelcomeScreenContentState extends State<WelcomeScreenContent>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SocketService _socketService = SocketService();
  final ChatLockService _chatLockService = ChatLockService();
  final CoinService _coinService = CoinService();
  String? _userName;
  bool _isLoadingProfile = true;
  bool _isConnecting = false;
  bool _isChatsLocked = false;
  String? _lockedJyotishId;
  String? _lockedJyotishName;

  // Animation controllers
  late AnimationController _borderAnimationController;
  late AnimationController _scrollAnimationController;
  late AnimationController _buttonPulseController;
  late AnimationController _buttonShineController;
  late AnimationController _pulseController;
  late Animation<double> _borderAnimation;
  late Animation<double> _buttonPulseAnimation;
  late Animation<double> _buttonShineAnimation;

  // Ad banner controllers
  final PageController _adPageController = PageController();
  Timer? _adTimer;
  int _currentAdIndex = 0;

  // List of ad image URLs
  final List<String> _adImages = [
    'https://thumbs.dreamstime.com/b/pink-dahlia-flower-details-macro-photo-border-frame-wide-banner-background-message-wedding-background-pink-dahlia-flower-117406512.jpg?w=2048',
    'https://img.freepik.com/free-vector/stylish-glowing-digital-red-lines-banner_1017-23964.jpg?semt=ais_hybrid&w=740&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserProfile();
    _loadLockStatus();
    _startAdAutoSlide();
  }

  void _initAnimations() {
    // Border animation - 2cm linear line moving slowly around the border
    _borderAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _borderAnimationController, curve: Curves.linear),
    );

    // Scroll animation for astrologer list
    _scrollAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Button pulse animation
    _buttonPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _buttonPulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _buttonPulseController, curve: Curves.easeInOut),
    );

    // Button shine animation
    _buttonShineController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _buttonShineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _buttonShineController, curve: Curves.linear),
    );

    // Pulse animation for "Available Now" indicator
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _loadUserProfile() async {
    try {
      final profileBloc = context.read<ProfileBloc>();
      // Wait a bit for the bloc to emit state
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        final state = profileBloc.state;
        if (state is ProfileLoadedState) {
          setState(() {
            _userName = state.user.name;
            _isLoadingProfile = false;
          });
        } else if (state is ProfileErrorState) {
          setState(() {
            _userName = 'User';
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'User';
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadLockStatus() async {
    final locked = await _chatLockService.isLocked();
    final lockedId = await _chatLockService.getLockedJyotishId();
    final lockedName = await _chatLockService.getLockedJyotishName();
    if (mounted) {
      setState(() {
        _isChatsLocked = locked;
        _lockedJyotishId = lockedId;
        _lockedJyotishName = lockedName;
      });
    }
  }

  Map<String, dynamic>? decodeJwt(String token) {
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

  Future<void> _handleChatEntry(ActiveAstrologerModel astrologer) async {
    await _loadLockStatus();

    if (_isChatsLocked) {
      if (_lockedJyotishId != astrologer.id) {
        if (mounted) {
          showTopSnackBar(
            context: context,
            message:
                'Please wait for ${_lockedJyotishName ?? "Jyotish"} to reply first.',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }
    }

    _openChatWithAstrologer(astrologer);
  }

  Future<void> _openChatWithAstrologer(ActiveAstrologerModel astrologer) async {
    if (_isConnecting) return;

    setState(() => _isConnecting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final refreshToken = prefs.getString('refreshToken');

      if (accessToken == null || refreshToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isConnecting = false);
        }
        return;
      }

      final decodedToken = decodeJwt(accessToken);
      final currentUserId = decodedToken?['id'] ?? '';

      if (currentUserId.isEmpty) {
        if (mounted) {
          showTopSnackBar(
            context: context,
            message: 'Invalid token. Please login again.',
            backgroundColor: AppColors.error,
          );
          setState(() => _isConnecting = false);
        }
        return;
      }

      if (!_socketService.connected) {
        await _socketService.connect(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: '',
            otherUserId: astrologer.id,
            otherUserName: astrologer.name,
            otherUserPhoto: astrologer.profilePhoto,
            currentUserId: currentUserId,
            accessToken: accessToken,
            refreshToken: refreshToken,
            isOnline: astrologer.isOnline,
          ),
        ),
      ).then((_) {
        _loadLockStatus();
      });
    } catch (e) {
      debugPrint('Error opening chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  void _startAdAutoSlide() {
    // Auto change ad every 2 minutes
    _adTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_adPageController.hasClients) {
        _currentAdIndex = (_currentAdIndex + 1) % _adImages.length;
        _adPageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    _scrollAnimationController.dispose();
    _buttonPulseController.dispose();
    _buttonShineController.dispose();
    _pulseController.dispose();
    _adPageController.dispose();
    _adTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlay();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.primaryBlack,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          StarFieldBackground(),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildGreeting(),
                  const SizedBox(height: 24),
                  _buildOnlineChatBox(),
                  const SizedBox(height: 24),
                  _buildFeaturesSection(),
                  const SizedBox(height: 24),
                  _buildServicesBox(),
                  const SizedBox(height: 24),
                  _buildAdBanner(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isConnecting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.cosmicPurple),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GlassIconButton(
              icon: Icons.menu_rounded,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 16),
            _buildAppLogo(),
          ],
        ),
        NotificationButton(
          notificationCount: 3,
          onTap: () => Navigator.pushNamed(context, '/notification_screen'),
        ),
      ],
    );
  }

  Widget _buildAppLogo() {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.cosmicPrimaryGradient.createShader(bounds),
          child: RichText(
            text: const TextSpan(
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
        Icon(Icons.auto_awesome, size: 16, color: AppColors.cosmicPurple),
      ],
    );
  }

  Widget _buildGreeting() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        String displayName = 'User';

        if (state is ProfileLoadedState) {
          displayName = state.user.name;
        } else if (!_isLoadingProfile && _userName != null) {
          displayName = _userName!;
        }

        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.purple300, AppColors.pink300, AppColors.red300],
          ).createShader(bounds),
          child: Text(
            'Hi, ${displayName.split(' ').first}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildOnlineChatBox() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isLoading = state is ActiveUsersLoading;
        final astrologers = state is ActiveUsersLoaded
            ? state.astrologers.where((a) => a.isOnline).toList()
            : <ActiveAstrologerModel>[];

        return AnimatedBuilder(
          animation: _borderAnimation,
          builder: (context, child) {
            return GestureDetector(
              onTap: () => _handleChatNavigation(),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cosmicPurple.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppColors.cosmicPink.withOpacity(0.1),
                      blurRadius: 30,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: AnimatedBorderPainter(
                    animationValue: _borderAnimation.value,
                    color: AppColors.cosmicPink,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.cosmicPurple.withOpacity(0.15),
                          AppColors.cosmicPink.withOpacity(0.1),
                          AppColors.cosmicRed.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Online status - simple and clean
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.greenAccent.withOpacity(
                                          0.6,
                                        ),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Online Astrologers',
                                  style: TextStyle(
                                    color: AppColors.textGray300,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Start Chat with animated button
                            AnimatedBuilder(
                              animation: Listenable.merge([
                                _buttonPulseAnimation,
                                _buttonShineAnimation,
                              ]),
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _buttonPulseAnimation.value,
                                  child: GestureDetector(
                                    onTapDown: (_) {
                                      HapticFeedback.mediumImpact();
                                    },
                                    onTap: () => _handleChatNavigation(),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFE44949),
                                            Color(0xFFF97316),
                                            Color(0xFFFB923C),
                                            Color(0xFFFBBF24),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(
                                              0xFFF97316,
                                            ).withOpacity(0.6),
                                            blurRadius: 20,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 6),
                                          ),
                                          BoxShadow(
                                            color: Color(
                                              0xFFE44949,
                                            ).withOpacity(0.4),
                                            blurRadius: 30,
                                            spreadRadius: 0,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          // Animated shine effect
                                          Positioned.fill(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Transform.translate(
                                                offset: Offset(
                                                  _buttonShineAnimation.value *
                                                      300,
                                                  0,
                                                ),
                                                child: Container(
                                                  width: 50,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.transparent,
                                                        Colors.white
                                                            .withOpacity(0.3),
                                                        Colors.transparent,
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Button content
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                // Animated chat icon
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.chat_bubble_rounded,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                // Text with pulsing indicator
                                                Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Start Live Chat with Jyotish',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        letterSpacing: 0.5,
                                                        shadows: [
                                                          Shadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            blurRadius: 4,
                                                            offset: Offset(
                                                              0,
                                                              2,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 1),
                                                    // Pulsing "Available Now" indicator
                                                    AnimatedBuilder(
                                                      animation:
                                                          _pulseController,
                                                      builder: (context, child) {
                                                        return Opacity(
                                                          opacity:
                                                              0.7 +
                                                              (_pulseController
                                                                      .value *
                                                                  0.3),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Container(
                                                                width: 5,
                                                                height: 5,
                                                                decoration: BoxDecoration(
                                                                  color: Color(
                                                                    0xFF10B981,
                                                                  ),
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Color(
                                                                        0xFF10B981,
                                                                      ).withOpacity(0.8),
                                                                      blurRadius:
                                                                          6,
                                                                      spreadRadius:
                                                                          1.5,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 3,
                                                              ),
                                                              Text(
                                                                'Available Now',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  letterSpacing:
                                                                      0.3,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: 10),
                                                // Animated arrow
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // Astrologers list
                            if (isLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    color: AppColors.cosmicPurple,
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                height: 90,
                                child: astrologers.isEmpty
                                    ? _buildDefaultAstrologersList()
                                    : _buildAstrologersList(astrologers),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDefaultAstrologersList() {
    // Show 4 default avatar images when no astrologers are online - using different images
    final List<String> defaultAvatarUrls = [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=faces',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop&crop=faces',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=faces',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop&crop=faces',
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        return _buildDefaultAstrologerCard(defaultAvatarUrls[index], index);
      },
    );
  }

  Widget _buildDefaultAstrologerCard(String imageUrl, int index) {
    // Generate a default name for each placeholder
    final List<String> defaultNames = [
      'Astrologer',
      'Expert',
      'Guide',
      'Master',
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cosmicPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProfileImageWithFallback(
            imageUrl: imageUrl,
            defaultUrl: imageUrl,
            isOnline: false, // Show as offline for placeholders
            name: defaultNames[index % defaultNames.length],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            height: 14,
            child: Text(
              defaultNames[index % defaultNames.length],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textGray300,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAstrologersList(List<ActiveAstrologerModel> astrologers) {
    if (astrologers.length <= 4) {
      // Static list if 4 or fewer
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: astrologers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildAstrologerCard(astrologers[index]);
        },
      );
    } else {
      // Animated scrolling list if more than 4
      return AnimatedBuilder(
        animation: _scrollAnimationController,
        builder: (context, child) {
          final itemWidth = 88.0; // card width + spacing
          final totalWidth = astrologers.length * itemWidth;
          final screenWidth = MediaQuery.of(context).size.width - 40;
          final scrollableWidth = totalWidth - screenWidth;

          // Use modulo to create seamless loop
          final scrollOffset =
              (_scrollAnimationController.value * scrollableWidth) % totalWidth;

          return ClipRect(
            child: Transform.translate(
              offset: Offset(-scrollOffset, 0),
              child: Row(
                children: [
                  // First set of astrologers
                  ...astrologers.map(
                    (astrologer) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildAstrologerCard(astrologer),
                    ),
                  ),
                  // Duplicate set for seamless loop
                  ...astrologers.map(
                    (astrologer) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildAstrologerCard(astrologer),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildAstrologerCard(ActiveAstrologerModel astrologer) {
    // Default avatar URLs - different images for variety
    final List<String> defaultAvatarUrls = [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=faces',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop&crop=faces',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=faces',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop&crop=faces',
    ];

    // Use a hash of the name to consistently pick an avatar for the same person
    final nameHash = astrologer.name.hashCode;
    final defaultAvatarUrl =
        defaultAvatarUrls[nameHash.abs() % defaultAvatarUrls.length];

    String imageUrl;

    if (astrologer.profilePhoto.isEmpty ||
        astrologer.profilePhoto == 'null' ||
        astrologer.profilePhoto.trim().isEmpty) {
      imageUrl = defaultAvatarUrl;
    } else if (astrologer.profilePhoto.startsWith('http')) {
      imageUrl = astrologer.profilePhoto;
    } else {
      // Try to construct URL, but use default if it seems invalid
      final constructedUrl =
          '${ApiEndpoints.socketUrl}${astrologer.profilePhoto}';
      if (astrologer.profilePhoto.startsWith('/')) {
        imageUrl = constructedUrl;
      } else {
        imageUrl = defaultAvatarUrl;
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cosmicPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProfileImageWithFallback(
            imageUrl: imageUrl,
            defaultUrl: defaultAvatarUrl,
            isOnline: astrologer.isOnline,
            name: astrologer.name,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            height: 14,
            child: Text(
              astrologer.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textGray300,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageWithFallback({
    required String imageUrl,
    required String defaultUrl,
    required bool isOnline,
    required String name,
  }) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(28 * 0.08),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isOnline
                ? LinearGradient(colors: [Colors.green, Colors.greenAccent])
                : LinearGradient(colors: [Colors.grey, Colors.grey.shade600]),
          ),
          child: Container(
            padding: EdgeInsets.all(28 * 0.08),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.backgroundDark,
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.cardMedium,
              child: ClipOval(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: 56,
                  height: 56,
                  errorBuilder: (context, error, stackTrace) {
                    // If original image fails, try default avatar
                    if (imageUrl != defaultUrl) {
                      return Image.network(
                        defaultUrl,
                        fit: BoxFit.cover,
                        width: 56,
                        height: 56,
                        errorBuilder: (context, error, stackTrace) {
                          // If default also fails, show initial
                          return Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.cosmicPurple,
                                  AppColors.cosmicPink,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      // If default fails, show initial
                      return Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.cosmicPurple,
                              AppColors.cosmicPink,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardMedium,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: AppColors.cosmicPink,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 28 * 0.1,
            right: 28 * 0.1,
            child: Container(
              width: 28 * 0.5,
              height: 28 * 0.5,
              decoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.5),
                    blurRadius: 28 * 0.4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturesSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildFeatureItem(
          icon: Icons.verified_user_rounded,
          text: 'Your Trustable',
        ),
        _buildFeatureItem(icon: Icons.public_rounded, text: 'Over World Wide'),
        _buildFeatureItem(
          icon: Icons.person_rounded,
          text: 'Get Personal Astrologer',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.cosmicPink, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textGray300,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cosmicPurple.withOpacity(0.2),
                AppColors.cosmicPink.withOpacity(0.15),
                AppColors.cosmicRed.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cosmicPurple.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with View All button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        AppColors.purple300,
                        AppColors.pink300,
                        AppColors.red300,
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'Our Services',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeDashboardScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.cosmicPrimaryGradient,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cosmicPurple.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Services grid - 4 services matching home_screen_client
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildServiceItem(
                    icon: Icons.chat_bubble_rounded,
                    name: 'Real-Time\nChat',
                    gradient: LinearGradient(
                      colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
                    ),
                    onTap: () => _handleChatNavigation(),
                  ),
                  _buildServiceItem(
                    icon: Icons.calendar_today_rounded,
                    name: 'Daily\nHoroscope',
                    gradient: LinearGradient(
                      colors: [AppColors.cosmicPink, AppColors.cosmicRed],
                    ),
                    onTap: () =>
                        Navigator.pushNamed(context, '/horoscope_screen'),
                  ),
                  _buildServiceItem(
                    icon: Icons.people_rounded,
                    name: 'Consultations',
                    gradient: LinearGradient(
                      colors: [AppColors.cosmicRed, AppColors.cosmicPurple],
                    ),
                    onTap: () => _handleChatNavigation(),
                  ),
                  _buildServiceItem(
                    icon: Icons.stars_rounded,
                    name: 'Birth\nChart',
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, AppColors.cosmicPurple],
                    ),
                    onTap: () =>
                        Navigator.pushNamed(context, '/birth_chart_screen'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.cosmicPink.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.cosmicPurple.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // PageView for multiple ads
            PageView.builder(
              controller: _adPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentAdIndex = index;
                });
              },
              itemCount: _adImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Handle ad banner tap
                  },
                  child: Image.network(
                    _adImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.cosmicPurple.withOpacity(0.4),
                              AppColors.cosmicPink.withOpacity(0.3),
                              AppColors.cosmicRed.withOpacity(0.25),
                            ],
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.cosmicPurple.withOpacity(0.2),
                              AppColors.cosmicPink.withOpacity(0.15),
                            ],
                          ),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.cosmicPink,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            // Subtle overlay to maintain theme consistency
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.cosmicPurple.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            // Page indicators
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _adImages.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentAdIndex == index
                          ? AppColors.cosmicPink
                          : AppColors.cosmicPink.withOpacity(0.3),
                      boxShadow: _currentAdIndex == index
                          ? [
                              BoxShadow(
                                color: AppColors.cosmicPink.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleChatNavigation() async {
    final balance = await _coinService.getBalance();

    if (!mounted) return;

    if (balance > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatOptionsScreen()),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage()));
    }
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String name,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textGray300,
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.primaryBlack,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBlack,
              AppColors.cosmicPurple.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(),
              const Divider(color: Colors.white24),
              Expanded(child: _buildDrawerItems()),
              const Divider(color: Colors.white24),
              _buildDrawerLogout(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        String displayName = 'User';
        String displayEmail = 'user@example.com';

        if (state is ProfileLoadedState) {
          displayName = state.user.name;
          displayEmail = state.user.email;
        }

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.cosmicPrimaryGradient,
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBlack,
                  ),
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.cardMedium,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.textSecondary,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayEmail,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItems() {
    final items = [
      {
        'icon': Icons.home_rounded,
        'title': 'Home',
        'selected': true,
        'route': null,
      },
      {
        'icon': Icons.person_rounded,
        'title': 'Profile',
        'route': '/user_profile_screen',
      },
      {
        'icon': Icons.history_rounded,
        'title': 'History',
        'route': '/history_screen_client',
      },
      {
        'icon': Icons.settings_rounded,
        'title': 'Settings',
        'route': '/settings_screen',
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'route': '/help_support_screen',
      },
      {
        'icon': Icons.info_outline_rounded,
        'title': 'About Us',
        'route': '/about_us_screen',
      },
      {
        'icon': Icons.privacy_tip_outlined,
        'title': 'Privacy Policy',
        'route': '/privacy_policy_screen',
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
              Navigator.pushNamed(context, item['route'] as String);
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
      padding: const EdgeInsets.all(16),
      child: DrawerItem(
        icon: Icons.logout_rounded,
        title: 'Logout',
        isDestructive: true,
        onTap: () {
          Navigator.pushReplacementNamed(context, '/login_screen');
        },
      ),
    );
  }
}

/// Custom painter for animated border - single smooth glow rotating 360 degrees
class AnimatedBorderPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  AnimatedBorderPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r = 20.0;
    final w = size.width;
    final h = size.height;

    // Draw subtle base border
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.cosmicPurple.withOpacity(0.1);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(r)),
      basePaint,
    );

    // Calculate perimeter
    final perimeter = 2 * (w - 2 * r) + 2 * (h - 2 * r) + 2 * pi * r;

    // 2cm line length (~56 pixels)
    const lineLength = 56.0;
    final startPos = animationValue * perimeter;

    // Get points along the line
    final points = <Offset>[];
    for (double d = 0; d <= lineLength; d += 2) {
      points.add(
        _getPointOnBorder((startPos + d) % perimeter, w, h, r, perimeter),
      );
    }

    if (points.length < 2) return;

    // Draw soft glow behind line
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..shader = LinearGradient(
        colors: [
          AppColors.cosmicPink.withOpacity(0.0),
          AppColors.cosmicPink.withOpacity(0.25),
          AppColors.cosmicPink.withOpacity(0.25),
          AppColors.cosmicPink.withOpacity(0.0),
        ],
      ).createShader(Rect.fromPoints(points.first, points.last));

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, glowPaint);

    // Draw main line
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          AppColors.cosmicPink.withOpacity(0.0),
          AppColors.cosmicPink.withOpacity(0.7),
          AppColors.cosmicPink.withOpacity(0.7),
          AppColors.cosmicPink.withOpacity(0.0),
        ],
      ).createShader(Rect.fromPoints(points.first, points.last));

    canvas.drawPath(path, linePaint);
  }

  Offset _getPointOnBorder(
    double pos,
    double w,
    double h,
    double r,
    double perimeter,
  ) {
    // Normalize position
    pos = pos % perimeter;

    final topEdge = w - 2 * r;
    final rightEdge = h - 2 * r;
    final bottomEdge = w - 2 * r;
    final leftEdge = h - 2 * r;
    final cornerArc = pi * r / 2;

    double accumulated = 0;

    // Top edge (left to right)
    if (pos < (accumulated + topEdge)) {
      return Offset(r + (pos - accumulated), 0);
    }
    accumulated += topEdge;

    // Top-right corner
    if (pos < (accumulated + cornerArc)) {
      final angle = -pi / 2 + (pos - accumulated) / r;
      return Offset(w - r + r * cos(angle), r + r * sin(angle));
    }
    accumulated += cornerArc;

    // Right edge (top to bottom)
    if (pos < (accumulated + rightEdge)) {
      return Offset(w, r + (pos - accumulated));
    }
    accumulated += rightEdge;

    // Bottom-right corner
    if (pos < (accumulated + cornerArc)) {
      final angle = (pos - accumulated) / r;
      return Offset(w - r + r * cos(angle), h - r + r * sin(angle));
    }
    accumulated += cornerArc;

    // Bottom edge (right to left)
    if (pos < (accumulated + bottomEdge)) {
      return Offset(w - r - (pos - accumulated), h);
    }
    accumulated += bottomEdge;

    // Bottom-left corner
    if (pos < (accumulated + cornerArc)) {
      final angle = pi / 2 + (pos - accumulated) / r;
      return Offset(r + r * cos(angle), h - r + r * sin(angle));
    }
    accumulated += cornerArc;

    // Left edge (bottom to top)
    if (pos < (accumulated + leftEdge)) {
      return Offset(0, h - r - (pos - accumulated));
    }
    accumulated += leftEdge;

    // Top-left corner
    final angle = pi + (pos - accumulated) / r;
    return Offset(r + r * cos(angle), r + r * sin(angle));
  }

  @override
  bool shouldRepaint(covariant AnimatedBorderPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
