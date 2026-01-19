import 'package:chat_jyotishi/features/app_widgets/show_top_snackBar.dart';
import 'package:chat_jyotishi/features/auth/widgets/input_field.dart';
import 'package:chat_jyotishi/features/home_astrologer/screens/home_screen_astrologer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/constant.dart';
import '../../app_widgets/app_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_events.dart';
import '../bloc/auth_states.dart';

class LoginCardAstrologer extends StatefulWidget {
  final bool passwordVisibility;
  final VoidCallback onPasswordToggle;

  const LoginCardAstrologer({
    super.key,
    required this.passwordVisibility,
    required this.onPasswordToggle,
  });

  @override
  State<LoginCardAstrologer> createState() => _LoginCardAstrologerState();
}

class _LoginCardAstrologerState extends State<LoginCardAstrologer> {
  TextEditingController emailController = TextEditingController(
    text: "sulav@jyotish.com",
  );
  TextEditingController passwordController = TextEditingController(
    text: "Admin@123",
  );
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Handle loading dialog
        if (state is AuthLoadingState) {
          if (!isLoading) {
            isLoading = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Center(
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

        // Show error messages
        if (state is AuthErrorState) {
          showTopSnackBar(
            context: context,
            message: state.message,
            backgroundColor: AppColors.error,
          );
        }

        if (state is AuthAstrologerPasswordLoginSuccessState) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HomeScreenAstrologer()),
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
                'Login using your credentials',
                style: TextStyle(color: Colors.white54),
              ),

              SizedBox(height: 24),

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

              SizedBox(height: 20),

              AppButton(
                title: 'LOGIN',
                isLoading: state is AuthLoadingState,
                icon: Icons.auto_awesome,
                onTap: () {
                  final identifier = emailController.text.trim();
                  final password = passwordController.text.trim();

                  if (identifier.isEmpty || password.isEmpty) {
                    showTopSnackBar(
                      context: context,
                      message: 'All fields are required',
                      icon: Icons.dangerous,
                      backgroundColor: AppColors.error,
                    );
                    return;
                  }

                  // Dispatch password login event
                  context.read<AuthBloc>().add(
                    AstrologerLoginWithPasswordEvent(
                      identifier: identifier,
                      password: password,
                    ),
                  );
                },
              ),

              SizedBox(height: 22),

              InkWell(
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/login_screen'),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '  Are you a Client ?',
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
