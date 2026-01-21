import 'package:chat_jyotishi/features/chat/models/chat_model.dart';
import 'package:chat_jyotishi/features/profile/bloc/profile_events.dart';
import 'package:chat_jyotishi/features/profile/bloc/profile_states.dart';
import 'package:chat_jyotishi/features/profile/repository/profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;

  ProfileBloc({required this.profileRepository})
    : super(ProfileInitialState()) {
    on<LoadCurrentUserProfileEvent>(_onLoadCurrentUserProfile);
    on<CompleteProfileSetupEvent>(_onCompleteProfileSetup);
    on<UpdateUserProfileEvent>(_onUpdateUserProfile);
    on<UpdateBirthDetailsEvent>(_onUpdateBirthDetails);
    on<UploadProfilePhotoEvent>(_onUploadProfilePhoto);
    on<RemoveProfilePhotoEvent>(_onRemoveProfilePhoto);
    on<RefreshUserProfileEvent>(_onRefreshUserProfile);
  }

  Future<void> _onLoadCurrentUserProfile(
    LoadCurrentUserProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoadingState());

    try {
      final user = await profileRepository.getCurrentUserProfile();
      emit(ProfileLoadedState(user));
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }

  Future<void> _onCompleteProfileSetup(
    CompleteProfileSetupEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoadingState());

    try {
      String? profilePhotoUrl;

      if (event.profilePhoto != null) {
        emit(
          const ProfileOperationInProgressState('Uploading profile photo...'),
        );

        try {
          profilePhotoUrl = await profileRepository.uploadProfilePhoto(
            event.profilePhoto!,
          );
        } catch (e) {
          debugPrint('Profile photo upload failed: $e');
        }
      }

      final profileData = await profileRepository.completeProfileSetup(
        name: event.name,
        email: event.email,
        dateOfBirth: event.dateOfBirth,
        timeOfBirth: event.timeOfBirth,
        placeOfBirth: event.placeOfBirth,
        currentAddress: event.currentAddress,
        permanentAddress: event.permanentAddress,
        zoadicSign: event.zoadicSign,
        gender: event.gender,
      );

      // 3. Create a copy of the profile with the photo URL if we have it
      final mergedProfile = profileData.copyWith(profilePhoto: profilePhotoUrl);

      emit(
        ProfileSetupSuccessState(
          mergedProfile,
          profilePhotoUrl != null
              ? 'Profile setup completed with photo'
              : 'Profile setup completed successfully',
        ),
      );
    } catch (e) {
      emit(ProfileErrorState('Profile setup failed: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoadingState());

    try {
      final user = await profileRepository.updateUserProfile(
        name: event.name,
        email: event.email,
      );
      emit(ProfileUpdatedState(user));
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }

  Future<void> _onUpdateBirthDetails(
    UpdateBirthDetailsEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoadingState());

    try {
      final birthDetails = await profileRepository.updateBirthDetails(
        dateOfBirth: event.dateOfBirth,
        timeOfBirth: event.timeOfBirth,
        placeOfBirth: event.placeOfBirth,
        currentAddress: event.currentAddress,
        permanentAddress: event.permanentAddress,
        zoadicSign: event.zoadicSign,
        gender: event.gender,
      );
      emit(BirthDetailsUpdatedState(birthDetails));
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }

  Future<void> _onUploadProfilePhoto(
    UploadProfilePhotoEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileOperationInProgressState('Uploading photo...'));

    try {
      final photoUrl = await profileRepository.uploadProfilePhoto(event.photo);
      emit(ProfilePhotoUploadedState(photoUrl));
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }

  Future<void> _onRemoveProfilePhoto(
    RemoveProfilePhotoEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileOperationInProgressState('Removing photo...'));

    try {
      await profileRepository.removeProfilePhoto();
      emit(ProfilePhotoRemovedState());
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }

  Future<void> _onRefreshUserProfile(
    RefreshUserProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      final user = await profileRepository.getCurrentUserProfile();
      emit(ProfileLoadedState(user));
    } catch (e) {
      emit(ProfileErrorState(e.toString()));
    }
  }
}
