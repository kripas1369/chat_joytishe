import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProfile extends ProfileEvent {}

class SaveUserProfile extends ProfileEvent {
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? dateOfBirth;
  final String? timeOfBirth;
  final String? placeOfBirth;
  final String? zodiacSign;
  final String? gender;
  final File? profileImage;

  const SaveUserProfile({
    this.name,
    this.email,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.timeOfBirth,
    this.placeOfBirth,
    this.zodiacSign,
    this.gender,
    this.profileImage,
  });

  @override
  List<Object?> get props => [
    name,
    email,
    phone,
    address,
    dateOfBirth,
    timeOfBirth,
    placeOfBirth,
    zodiacSign,
    gender,
    profileImage,
  ];
}

class LoadAstrologerProfile extends ProfileEvent {}

class SaveAstrologerProfile extends ProfileEvent {
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final int? experienceYears;
  final String? expertise;
  final String? languages;
  final String? bio;
  final double? pricePerMinute;
  final String? gender;
  final bool? isAvailable;
  final File? profileImage;

  const SaveAstrologerProfile({
    this.name,
    this.email,
    this.phone,
    this.address,
    this.experienceYears,
    this.expertise,
    this.languages,
    this.bio,
    this.pricePerMinute,
    this.gender,
    this.isAvailable,
    this.profileImage,
  });

  @override
  List<Object?> get props => [
    name,
    email,
    phone,
    address,
    experienceYears,
    expertise,
    languages,
    bio,
    pricePerMinute,
    gender,
    isAvailable,
    profileImage,
  ];
}
