import 'package:chat_jyotishi/features/app_widgets/show_top_snackBar.dart';
import 'package:chat_jyotishi/features/auth/widgets/input_field.dart';
import 'package:chat_jyotishi/features/auth/widgets/method_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/constant.dart';
import '../../app_widgets/app_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_events.dart';
import '../bloc/auth_states.dart';
import '../screens/otp_screen.dart';

class LoginCard extends StatefulWidget {
  final bool usePassword;
  final VoidCallback onToggle;
  final bool passwordVisibility;
  final VoidCallback onPasswordToggle;

  const LoginCard({
    super.key,
    required this.usePassword,
    required this.onToggle,
    required this.passwordVisibility,
    required this.onPasswordToggle,
  });

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoadingState) {
          if (!isLoading) {
            isLoading = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) =>
                  Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryPurple,
                    ),
                  ),
            );
          }
        } else {
          if (isLoading) {
            isLoading = false;
            Navigator.of(context).pop();
          }
        }

        if (state is AuthOtpLoadedState) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OtpScreen(
                    phoneNumber: state.phoneNumber,
                    sessionId: state.otpResponse.sessionId,
                  ),
            ),
          );
        }

        if (state is AuthErrorState) {
          showTopSnackBar(
            context: context,
            message: state.message,
            backgroundColor: AppColors.error,
          );
        }
      },
      builder: (context, state) {
        return Container(
          width: 380,
          padding: EdgeInsets.fromLTRB(26, 30, 26, 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                // Color(0xFFDC2626).withOpacity(0.5),
                AppColors.primaryPurple.withOpacity(0.15),
                AppColors.deepPurple.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.75),
                blurRadius: 35,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Choose your method of entry',
                style: TextStyle(color: Colors.white54),
              ),
              SizedBox(height: 22),

              MethodToggle(active: widget.usePassword, onTap: widget.onToggle),

              SizedBox(height: 24),

              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: widget.usePassword
                    ? Column(
                  key: ValueKey('password_mode'),
                  children: [
                    InputField(
                      controller: emailController,
                      label: 'Phone / Email',
                      hint: 'stars@gmail.com',
                    ),
                    SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        InputField(
                          controller: passwordController,
                          label: 'Password',
                          hint: '*********',
                          obscure: widget.passwordVisibility,
                        ),
                        Positioned(
                          right: 8,
                          bottom: 4,
                          child: IconButton(
                            icon: Icon(
                              widget.passwordVisibility
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: widget.onPasswordToggle,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () {},
                          child: Text(
                            'Forget password ?',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                    : Column(
                  key: ValueKey('otp_mode'),
                  children: [
                    InputField(
                      controller: phoneController,
                      label: 'Phone or Email',
                      hint: '+977 555 123 4567',
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              AppButton(
                title: widget.usePassword ? 'LOGIN' : 'SEND OTP',
                gradient: AppColors.primaryGradient,
                isLoading: state is AuthLoadingState,
                icon: Icons.auto_awesome,
                onTap: () {
                  if (widget.usePassword) {
                    final identifier = emailController.text.trim();
                    final password = passwordController.text.trim();

                    if (identifier.isEmpty || password.isEmpty) {
                      showTopSnackBar(
                        context: context,
                        message: ' All fields are required',
                        icon: Icons.dangerous,
                        backgroundColor: AppColors.error,
                      );
                      return;
                    }
                  } else {
                    final phone = phoneController.text.trim();

                    if (phone.isEmpty) {
                      showTopSnackBar(
                        context: context,
                        message: ' Phone Number or Email is required',
                        icon: Icons.dangerous,
                        backgroundColor: AppColors.error,
                      );
                      return;
                    }

                    context.read<AuthBloc>().add(
                      SendOtpEvent(phoneNumber: phone.toString()),
                    );
                  }
                },
              ),

              SizedBox(height: 22),
              InkWell(
                onTap: () =>
                    Navigator.pushReplacementNamed(
                      context,
                      '/login_screen_astrologer',
                    ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '  Are you an Astrologer ?',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: ' CLICK-HERE',
                        style: TextStyle(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
