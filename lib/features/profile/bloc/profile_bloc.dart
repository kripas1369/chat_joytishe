import 'package:chat_jyotishi/features/profile/bloc/profile_events.dart';
import 'package:chat_jyotishi/features/profile/bloc/profile_states.dart';
import 'package:chat_jyotishi/features/profile/repository/profile_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileInitialState()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<SaveUserProfile>(_onSaveUserProfile);
    on<LoadAstrologerProfile>(_onLoadAstrologerProfile);
    on<SaveAstrologerProfile>(_onSaveAstrologerProfile);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoadingState());
    try {
      final profile = await repository.getUserProfile();
      emit(UserProfileLoadedState(profile));
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }

  Future<void> _onSaveUserProfile(
    SaveUserProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoadingState());
    try {
      await repository.updateUserProfile(
        name: event.name,
        email: event.email,
        phone: event.phone,
        address: event.address,
        dateOfBirth: event.dateOfBirth,
        timeOfBirth: event.timeOfBirth,
        placeOfBirth: event.placeOfBirth,
        zodiacSign: event.zodiacSign,
        gender: event.gender,
        profileImage: event.profileImage,
      );
      emit(UserProfileSavedState());
      // Reload the profile
      add(LoadUserProfile());
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }

  Future<void> _onLoadAstrologerProfile(
    LoadAstrologerProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoadingState());
    try {
      final profile = await repository.getAstrologerProfile();
      emit(AstrologerProfileLoadedState(profile));
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }

  Future<void> _onSaveAstrologerProfile(
    SaveAstrologerProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoadingState());
    try {
      await repository.updateAstrologerProfile(
        name: event.name,
        email: event.email,
        phone: event.phone,
        address: event.address,
        experienceYears: event.experienceYears,
        expertise: event.expertise,
        languages: event.languages,
        bio: event.bio,
        pricePerMinute: event.pricePerMinute,
        gender: event.gender,
        isAvailable: event.isAvailable,
        profileImage: event.profileImage,
      );
      emit(AstrologerProfileSavedState());
      // Reload the profile
      add(LoadAstrologerProfile());
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }
}
