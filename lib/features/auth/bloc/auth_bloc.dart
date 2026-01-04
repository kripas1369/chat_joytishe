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
        print(e);
        print(e);
        print(e);
        print(e);
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
        print(e);
        print(e);
        print(e);
        print(e);

        emit(AuthErrorState(message: e.toString()));
      }
    });
  }
}
