import 'package:chat_jyotishi/features/profile/models/profile_model.dart';
import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitialState extends ProfileState {}

class ProfileLoadingState extends ProfileState {}

/// Profile loaded state
class ProfileLoadedState extends ProfileState {
  final ProfileModel user;

  const ProfileLoadedState(this.user);

  @override
  List<Object?> get props => [user];
}

/// Profile setup success state
class ProfileSetupSuccessState extends ProfileState {
  final ProfileModel user;
  final String message;

  const ProfileSetupSuccessState(this.user, this.message);

  @override
  List<Object?> get props => [user, message];
}

/// Profile updated state
class ProfileUpdatedState extends ProfileState {
  final ProfileModel user;

  const ProfileUpdatedState(this.user);

  @override
  List<Object?> get props => [user];
}

/// Birth details updated state
class BirthDetailsUpdatedState extends ProfileState {
  final Map<String, dynamic> birthDetails;

  const BirthDetailsUpdatedState(this.birthDetails);

  @override
  List<Object?> get props => [birthDetails];
}

/// Profile photo uploaded state
class ProfilePhotoUploadedState extends ProfileState {
  final String photoUrl;

  const ProfilePhotoUploadedState(this.photoUrl);

  @override
  List<Object?> get props => [photoUrl];
}

/// Profile photo removed state
class ProfilePhotoRemovedState extends ProfileState {}

/// Profile error state
class ProfileErrorState extends ProfileState {
  final String message;

  const ProfileErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

/// Profile operation in progress state (for photo upload/remove)
class ProfileOperationInProgressState extends ProfileState {
  final String operation;

  const ProfileOperationInProgressState(this.operation);

  @override
  List<Object?> get props => [operation];
}

/// Chatable users loaded state
// class ChatableUsersLoadedState extends ProfileState {
//   final List<ProfileModel> users;
//
//   const ChatableUsersLoadedState(this.users);
//
//   @override
//   List<Object?> get props => [users];
// }
