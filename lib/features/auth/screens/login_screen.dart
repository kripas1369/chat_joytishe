import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/constant.dart';
import '../bloc/auth_bloc.dart';

import '../repository/auth_repository.dart';
import '../service/auth_service.dart';
import '../widgets/login_card.dart';
import '../../app_widgets/star_field_background.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AuthBloc(authRepository: AuthRepository(AuthService())),
      child: LoginScreenContent(),
    );
  }
}

class LoginScreenContent extends StatefulWidget {
  const LoginScreenContent({super.key});

  @override
  State<LoginScreenContent> createState() => _LoginScreenContentState();
}

class _LoginScreenContentState extends State<LoginScreenContent>
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
        systemNavigationBarColor: AppColors.backgroundDark,
      ),
    );
    return Scaffold(
      body: Stack(
        children: [
          StarFieldBackground(),
          Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          ),

          _loginHeader(),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: LoginCard(
                usePassword: usePassword,
                onToggle: () {
                  setState(() => usePassword = !usePassword);
                },
                glow: glowController,
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
                  colors: [Colors.white, AppColors.lightPurple],
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
              Icon(
                Icons.auto_awesome,
                size: 24,
                color: AppColors.primaryPurple,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'PORTAL FOR CELESTIAL GUIDES',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.4,
              color: Colors.white70,
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
        style: TextStyle(fontSize: 11, color: Colors.white70),
      ),
    );
  }
}
