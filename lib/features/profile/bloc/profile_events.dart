import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Load current user profile event
class LoadCurrentUserProfileEvent extends ProfileEvent {}

/// Complete profile setup event
class CompleteProfileSetupEvent extends ProfileEvent {
  final String name;
  final String email;
  final String dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
  final String currentAddress;
  final String permanentAddress;
  final String zoadicSign;
  final String gender;

  final File? profilePhoto;

  const CompleteProfileSetupEvent({
    required this.zoadicSign,
    required this.gender,
    required this.name,
    required this.email,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    required this.currentAddress,
    required this.permanentAddress,
    this.profilePhoto,
  });

  @override
  List<Object?> get props => [
    name,
    email,
    dateOfBirth,
    timeOfBirth,
    placeOfBirth,
    currentAddress,
    permanentAddress,
    profilePhoto,
  ];
}

/// Update user profile event (name, email)
class UpdateUserProfileEvent extends ProfileEvent {
  final String? name;
  final String? email;

  const UpdateUserProfileEvent({this.name, this.email});

  @override
  List<Object?> get props => [name, email];
}

/// Update birth details event
class UpdateBirthDetailsEvent extends ProfileEvent {
  final String? dateOfBirth;
  final String? timeOfBirth;
  final String? placeOfBirth;
  final String? currentAddress;
  final String? permanentAddress;
  final String? zoadicSign;
  final String? gender;

  const UpdateBirthDetailsEvent({
    this.zoadicSign,
    this.gender,
    this.dateOfBirth,
    this.timeOfBirth,
    this.placeOfBirth,
    this.currentAddress,
    this.permanentAddress,
  });

  @override
  List<Object?> get props => [
    dateOfBirth,
    timeOfBirth,
    placeOfBirth,
    currentAddress,
    permanentAddress,
  ];
}

/// Upload profile photo event
class UploadProfilePhotoEvent extends ProfileEvent {
  final File photo;

  const UploadProfilePhotoEvent(this.photo);

  @override
  List<Object?> get props => [photo];
}

class RemoveProfilePhotoEvent extends ProfileEvent {}

class RefreshUserProfileEvent extends ProfileEvent {}

// class LoadChatableUsersEvent extends ProfileEvent {}
