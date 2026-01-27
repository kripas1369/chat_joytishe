import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/app_button.dart';
import '../../app_widgets/show_top_snackBar.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_events.dart';
import '../bloc/auth_states.dart';
import '../repository/auth_repository.dart';
import '../service/auth_service.dart';
import '../../app_widgets/star_field_background.dart';
import '../../home/screens/welcome_screen.dart';

class OtpScreen extends StatelessWidget {
  final String phoneNumber;
  final String sessionId;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AuthBloc(authRepository: AuthRepository(AuthService())),
      child: OtpScreenContent(phoneNumber: phoneNumber, sessionId: sessionId),
    );
  }
}

class OtpScreenContent extends StatefulWidget {
  final String phoneNumber;
  final String sessionId;

  const OtpScreenContent({
    super.key,
    required this.phoneNumber,
    required this.sessionId,
  });

  @override
  State<OtpScreenContent> createState() => _OtpScreenContentState();
}

class _OtpScreenContentState extends State<OtpScreenContent> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  late AuthBloc _authBloc;
  late String _currentSessionId;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>();
    _currentSessionId = widget.sessionId;
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
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
                  AppColors.cosmicPink.withOpacity(0.2),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),
          _otpHeader(),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthErrorState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (state is AuthOtpVerifiedState) {
                    // Clear OTP fields
                    for (var controller in _controllers) {
                      controller.clear();
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    );
                  } else if (state is AuthOtpLoadedState) {
                    setState(() {
                      _currentSessionId = state.otpResponse.sessionId;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('OTP resent successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return _otpCard(context, state);
                },
              ),
            ),
          ),
          _otpFooter(),
        ],
      ),
    );
  }

  Widget _otpHeader() {
    return Positioned(
      top: 60,
      left: 1,
      right: 1,
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
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: 'Jyotishi',
                        style: TextStyle(
                          fontSize: 32,
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
            'OTP VERIFICATION',
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

  Widget _otpCard(BuildContext context, AuthState state) {
    bool isLoading = state is AuthLoadingState;

    return Container(
      padding: EdgeInsets.all(24),
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
        border: Border.all(
          color: AppColors.cosmicPurple.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cosmicPurple.withOpacity(0.3),
            blurRadius: 40,
            offset: Offset(0, 24),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Enter 6-Digit OTP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Code sent to ${widget.phoneNumber}',
            style: TextStyle(
              color: AppColors.textGray300,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) => _otpBox(index)),
          ),
          SizedBox(height: 30),
          SizedBox(
            child: AppButton(
              title: 'VERIFY',
              isLoading: isLoading,
              icon: Icons.verified,
              gradient: AppColors.cosmicHeroGradient,
              onTap: () {
                String otp = _controllers.map((c) => c.text).join();

                if (otp.length < 6) {
                  showTopSnackBar(
                    context: context,
                    message: 'Please enter a 6-digit OTP',
                    icon: Icons.warning_amber_rounded,
                    backgroundColor: Colors.orange,
                  );
                  return;
                }

                _authBloc.add(
                  VerifyOtpEvent(
                    phoneNumber: widget.phoneNumber,
                    sessionId: _currentSessionId,
                    otp: otp,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 14),
          TextButton(
            onPressed: isLoading
                ? null
                : () {
                    for (var controller in _controllers) {
                      controller.clear();
                    }

                    // Resend OTP
                    _authBloc.add(
                      SendOtpEvent(phoneNumber: widget.phoneNumber),
                    );
                  },
            child: Text(
              'Resend OTP',
              style: TextStyle(
                color: isLoading
                    ? AppColors.textGray400
                    : AppColors.pink400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 44,
      height: 54,
      child: TextField(
        controller: _controllers[index],
        autofocus: index == 0,
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        cursorColor: AppColors.cosmicPurple,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.cosmicPurple.withOpacity(0.2),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.cosmicPurple.withOpacity(0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.cosmicPurple,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).nextFocus();
          }
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }

  Widget _otpFooter() {
    return Positioned(
      bottom: 30,
      left: 1,
      right: 1,
      child: Text(
        'Authentication in progress…',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textGray400,
        ),
      ),
    );
  }
}
