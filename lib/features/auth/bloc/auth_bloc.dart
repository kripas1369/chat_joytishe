import 'package:chat_jyotishi/features/auth/repository/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_events.dart';
import 'auth_states.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitialState()) {
    on<SendOtpEvent>((event, emit) async {
      emit(AuthLoadingState());
      try {
        final otpResponse = await authRepository.sendOtp(
          phoneNumber: event.phoneNumber,
        );
        emit(
          AuthOtpLoadedState(
            otpResponse: otpResponse,
            phoneNumber: event.phoneNumber,
          ),
        );
      } catch (e) {
        emit(AuthErrorState(message: e.toString()));
      }
    });

    on<VerifyOtpEvent>((event, emit) async {
      emit(AuthLoadingState());
      try {
        final verifiedOtp = await authRepository.verifyOtp(
          phoneNumber: event.phoneNumber,
          sessionId: event.sessionId,
          otp: event.otp,
        );
        emit(AuthOtpVerifiedState(verifiedOtp: verifiedOtp));
      } catch (e) {
        emit(AuthErrorState(message: e.toString()));
      }
    });

    on<AstrologerLoginWithPasswordEvent>((event, emit) async {
      emit(AuthLoadingState());
      try {
        final loginResponse = await authRepository.astrologerLoginWithPassword(
          identifier: event.identifier,
          password: event.password,
        );

        emit(
          AuthAstrologerPasswordLoginSuccessState(loginResponse: loginResponse),
        );
      } catch (e) {
        emit(AuthErrorState(message: e.toString()));
      }
    });

    on<LogoutUserEvent>((event, emit) async {
      emit(AuthLoadingState());
      try {
        await authRepository.logoutUser();
        emit(const AuthLogoutSuccessState(message: 'User logged out successfully'));
      } catch (e) {
        // Even if API fails, local tokens are cleared in service
        emit(const AuthLogoutSuccessState(message: 'Logged out successfully'));
      }
    });

    // on<LogoutAstrologerEvent>((event, emit) async {
    //   emit(AuthLoadingState());
    //   try {
    //     await authRepository.logoutAstrologer();
    //     emit(const AuthLogoutSuccessState(message: 'Astrologer logged out successfully'));
    //   } catch (e) {
    //     // Even if API fails, local tokens are cleared in service
    //     emit(const AuthLogoutSuccessState(message: 'Logged out successfully'));
    //   }
    // });

    // on<CheckLoginStatusEvent>((event, emit) async {
    //   try {
    //     final isUserLoggedIn = await authRepository.isUserLoggedIn();
    //     final isAstrologerLoggedIn = await authRepository.isAstrologerLoggedIn();
    //
    //     if (isUserLoggedIn) {
    //       emit(const AuthUserLoggedInState(isLoggedIn: true));
    //     } else if (isAstrologerLoggedIn) {
    //       emit(const AuthAstrologerLoggedInState(isLoggedIn: true));
    //     } else {
    //       emit(AuthInitialState());
    //     }
    //   } catch (e) {
    //     emit(AuthErrorState(message: e.toString()));
    //   }
    // });
  }
}