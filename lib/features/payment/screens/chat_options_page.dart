import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/payment/screens/broadcast_page.dart';
import 'package:chat_jyotishi/features/payment/screens/jyotish_list_screen.dart';
import 'package:chat_jyotishi/features/payment/services/coin_service.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_bloc.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_events.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_states.dart';
import 'package:chat_jyotishi/features/chat/models/active_user_model.dart';
import 'package:chat_jyotishi/features/chat/repository/chat_repository.dart';
import 'package:chat_jyotishi/features/chat/service/chat_service.dart';
import 'package:chat_jyotishi/features/chat/screens/broadcast_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';

class ChatOptionsScreen extends StatefulWidget {
  const ChatOptionsScreen({super.key});

  @override
  State<ChatOptionsScreen> createState() => _ChatOptionsScreenState();
}

class _ChatOptionsScreenState extends State<ChatOptionsScreen> {
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
    if (_coinBalance >= 100) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BroadcastChatScreen()),
        );
      }
    } else {
      _showInsufficientCoinsDialog(100);
    }
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
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cosmicRed, AppColors.cosmicPink],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppColors.purple300,
                  AppColors.pink300,
                  AppColors.red300,
                ],
              ).createShader(bounds),
              child: Text(
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
          style: TextStyle(color: AppColors.textGray300, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
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
              child: Text(
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

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlay();

    // Provide ChatBloc if not already available
    return BlocProvider(
      create: (context) =>
          ChatBloc(chatRepository: ChatRepository(ChatService()))
            ..add(FetchActiveUsersEvent()),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Stack(
          children: [
            // Star field background
            StarFieldBackground(),
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
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    _buildHeader(),
                    SizedBox(height: 24),
                    // _buildBalanceCard(),
                    SizedBox(height: 20),
                    _buildOptionCard(
                      icon: Icons.chat_bubble_rounded,
                      title: 'Start instant chat with astrologer',
                      subtitle:
                          'Astrologer any where from the world can accept',
                      coinCost: 100,
                      gradient: LinearGradient(
                        colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
                      ),
                      onTap: _handleSingleChat,
                    ),
                    SizedBox(height: 16),
                    _buildExpertListCard(),
                    SizedBox(height: 16),
                    _buildKundaliReviewCard(),
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
        SizedBox(width: 16),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.purple300, AppColors.pink300, AppColors.red300],
          ).createShader(bounds),
          child: Text(
            'Chat Options',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Spacer(),
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
          ],
        ),
      ],
    );
  }

  // Widget _buildBalanceCard() {
  //   return ClipRRect(
  //     borderRadius: BorderRadius.circular(20),
  //     child: BackdropFilter(
  //       filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
  //       child: Container(
  //         padding: EdgeInsets.all(20),
  //         decoration: BoxDecoration(
  //           gradient: LinearGradient(
  //             begin: Alignment.topLeft,
  //             end: Alignment.bottomRight,
  //             colors: [
  //               AppColors.cosmicPurple.withOpacity(0.2),
  //               AppColors.cosmicPink.withOpacity(0.15),
  //               AppColors.cosmicRed.withOpacity(0.1),
  //             ],
  //           ),
  //           borderRadius: BorderRadius.circular(20),
  //           border: Border.all(
  //             color: AppColors.cosmicPurple.withOpacity(0.3),
  //             width: 1,
  //           ),
  //           boxShadow: [
  //             BoxShadow(
  //               color: AppColors.cosmicPurple.withOpacity(0.2),
  //               blurRadius: 20,
  //               spreadRadius: 2,
  //             ),
  //           ],
  //         ),
  //         child: Row(
  //           children: [
  //             Container(
  //               padding: EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 gradient: AppColors.cosmicPrimaryGradient,
  //                 borderRadius: BorderRadius.circular(12),
  //                 boxShadow: [
  //                   BoxShadow(
  //                     color: AppColors.cosmicPurple.withOpacity(0.4),
  //                     blurRadius: 12,
  //                     spreadRadius: 2,
  //                   ),
  //                 ],
  //               ),
  //               child: Icon(
  //                 Icons.monetization_on_rounded,
  //                 color: Colors.white,
  //                 size: 32,
  //               ),
  //             ),
  //             SizedBox(width: 16),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   'Your Balance',
  //                   style: TextStyle(
  //                     color: AppColors.textGray300,
  //                     fontSize: 14,
  //                   ),
  //                 ),
  //                 SizedBox(height: 4),
  //                 Row(
  //                   children: [
  //                     Icon(Icons.monetization_on, color: gold, size: 24),
  //                     SizedBox(width: 4),
  //                     Text(
  //                       '$_coinBalance',
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 28,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                     SizedBox(width: 4),
  //                     Text(
  //                       'coins',
  //                       style: TextStyle(
  //                         color: AppColors.textGray400,
  //                         fontSize: 16,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //             Spacer(),
  //             GestureDetector(
  //               onTap: () => Navigator.pushNamed(context, '/payment_page'),
  //               child: Container(
  //                 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //                 decoration: BoxDecoration(
  //                   gradient: AppColors.cosmicPrimaryGradient,
  //                   borderRadius: BorderRadius.circular(12),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: AppColors.cosmicPurple.withOpacity(0.4),
  //                       blurRadius: 12,
  //                       spreadRadius: 2,
  //                     ),
  //                   ],
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Icon(Icons.add, color: Colors.white, size: 18),
  //                     SizedBox(width: 4),
  //                     Text(
  //                       'Add',
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int coinCost,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    final hasEnoughCoins = _coinBalance >= coinCost;
    final cardGradient = gradient;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardGradient.colors.first.withOpacity(0.2),
                  cardGradient.colors.last.withOpacity(0.15),
                  Colors.black.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: cardGradient.colors.first.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: cardGradient.colors.first.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: cardGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: cardGradient.colors.first.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 3,
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
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.textGray300,
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
                                color: AppColors.cosmicRed.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.cosmicRed.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Insufficient',
                                style: TextStyle(
                                  color: AppColors.cosmicRed,
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
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: cardGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpertListCard() {
    final cardGradient = LinearGradient(
      colors: [AppColors.cosmicPink, AppColors.cosmicRed],
    );
    final hasEnoughCoins = _coinBalance >= 200;

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        List<ActiveAstrologerModel> astrologers = [];
        if (state is ActiveUsersLoaded) {
          astrologers = state.astrologers.take(4).toList();
        }

        return GestureDetector(
          onTap: () {
            if (hasEnoughCoins) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JyotishListScreen()),
              );
            } else {
              _showInsufficientCoinsDialog(200);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardGradient.colors.first.withOpacity(0.2),
                      cardGradient.colors.last.withOpacity(0.15),
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cardGradient.colors.first.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cardGradient.colors.first.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: cardGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: cardGradient.colors.first.withOpacity(
                                  0.5,
                                ),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.people_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select jyothis from our expert list',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Choose from our expert astrologers',
                                style: TextStyle(
                                  color: AppColors.textGray300,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.monetization_on,
                                    color: gold,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '200 coins',
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
                                        color: AppColors.cosmicRed.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.cosmicRed
                                              .withOpacity(0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'Insufficient',
                                        style: TextStyle(
                                          color: AppColors.cosmicRed,
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
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: cardGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    if (astrologers.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Row(
                        children: astrologers.map((astrologer) {
                          return Container(
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.cosmicPink.withOpacity(0.6),
                                  AppColors.cosmicRed.withOpacity(0.6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cosmicPink.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.cosmicPurple
                                  .withOpacity(0.3),
                              backgroundImage:
                                  astrologer.profilePhoto.isNotEmpty
                                  ? NetworkImage(astrologer.profilePhoto)
                                  : null,
                              child: astrologer.profilePhoto.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKundaliReviewCard() {
    final cardGradient = LinearGradient(
      colors: [AppColors.cosmicPurple, AppColors.cosmicRed],
    );
    final hasEnoughCoins =
        _coinBalance >= 300; // Assuming 300 coins for kundali review

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        List<ActiveAstrologerModel> astrologers = [];
        if (state is ActiveUsersLoaded) {
          astrologers = state.astrologers.take(4).toList();
        }

        return GestureDetector(
          onTap: () {
            if (hasEnoughCoins) {
              // Handle kundali review navigation
            } else {
              _showInsufficientCoinsDialog(300);
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardGradient.colors.first.withOpacity(0.2),
                      cardGradient.colors.last.withOpacity(0.15),
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cardGradient.colors.first.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cardGradient.colors.first.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: cardGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: cardGradient.colors.first.withOpacity(
                                  0.5,
                                ),
                                blurRadius: 15,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.stars_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Do you want to get full kundali review with our expert astrologer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'This will take time to response your, may be response time max 1 days',
                                style: TextStyle(
                                  color: AppColors.textGray300,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.monetization_on,
                                    color: gold,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '300 coins',
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
                                        color: AppColors.cosmicRed.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.cosmicRed
                                              .withOpacity(0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'Insufficient',
                                        style: TextStyle(
                                          color: AppColors.cosmicRed,
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
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: cardGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    if (astrologers.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Row(
                        children: astrologers.map((astrologer) {
                          return Container(
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.cosmicPink.withOpacity(0.6),
                                  AppColors.cosmicRed.withOpacity(0.6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cosmicPink.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.cosmicPurple
                                  .withOpacity(0.3),
                              backgroundImage:
                                  astrologer.profilePhoto.isNotEmpty
                                  ? NetworkImage(astrologer.profilePhoto)
                                  : null,
                              child: astrologer.profilePhoto.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
