import 'package:chat_jyotishi/features/profile/models/astrologer_profile_model.dart';
import 'package:chat_jyotishi/features/profile/models/user_profile_model.dart';
import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitialState extends ProfileState {}

class ProfileLoadingState extends ProfileState {}

class UserProfileLoadedState extends ProfileState {
  final UserProfileModel profile;

  const UserProfileLoadedState(this.profile);

  @override
  List<Object?> get props => [profile];
}

class UserProfileSavedState extends ProfileState {}

class AstrologerProfileLoadedState extends ProfileState {
  final AstrologerProfileModel profile;

  const AstrologerProfileLoadedState(this.profile);

  @override
  List<Object?> get props => [profile];
}

class AstrologerProfileSavedState extends ProfileState {}

class ProfileErrorState extends ProfileState {
  final String message;

  const ProfileErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
