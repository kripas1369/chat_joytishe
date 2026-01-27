import 'package:chat_jyotishi/features/auth/widgets/login_card_astrologer.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/constant.dart';
import '../bloc/auth_bloc.dart';

import '../repository/auth_repository.dart';
import '../service/auth_service.dart';

class LoginScreenAstrologer extends StatelessWidget {
  const LoginScreenAstrologer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AuthBloc(authRepository: AuthRepository(AuthService())),
      child: LoginScreenAstrologerContent(),
    );
  }
}

class LoginScreenAstrologerContent extends StatefulWidget {
  const LoginScreenAstrologerContent({super.key});

  @override
  State<LoginScreenAstrologerContent> createState() =>
      _LoginScreenAstrologerContentState();
}

class _LoginScreenAstrologerContentState
    extends State<LoginScreenAstrologerContent>
    with SingleTickerProviderStateMixin {
  bool usePassword = false;
  bool passwordVisibility = false;

  late AnimationController glowController;

  @override
  void initState() {
    super.initState();
    glowController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.primaryBlack,
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Stack(
        children: [
          // Star field background (matching homepage)
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
                  AppColors.cosmicPink.withOpacity(0.2),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),

          _loginHeader(),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: LoginCardAstrologer(
                passwordVisibility: passwordVisibility,
                onPasswordToggle: () {
                  setState(() => passwordVisibility = !passwordVisibility);
                },
              ),
            ),
          ),
          _loginFooter(),
        ],
      ),
    );
  }

  Widget _loginHeader() {
    return Positioned(
      top: 68,
      right: 1,
      left: 1,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    AppColors.purple300,
                    AppColors.pink300,
                    AppColors.red300,
                  ],
                ).createShader(bounds),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Chat',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: 'Jyotishi',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppColors.cosmicPrimaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'ASTROLOGER PORTAL',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              color: AppColors.purple400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginFooter() {
    return Positioned(
      bottom: 30,
      right: 1,
      left: 1,
      child: Text(
        'Protected by celestial encryption.\n© ${DateTime.now().year} ChatJyotish. All rights aligned.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textGray400,
        ),
      ),
    );
  }
}
