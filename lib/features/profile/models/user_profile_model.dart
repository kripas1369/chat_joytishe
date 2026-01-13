class UserProfileModel {
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? dateOfBirth;
  final String? timeOfBirth;
  final String? placeOfBirth;
  final String? zodiacSign;
  final String? gender;
  final String? profileImagePath;

  UserProfileModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.timeOfBirth,
    this.placeOfBirth,
    this.zodiacSign,
    this.gender,
    this.profileImagePath,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      dateOfBirth: json['dateOfBirth'],
      timeOfBirth: json['timeOfBirth'],
      placeOfBirth: json['placeOfBirth'],
      zodiacSign: json['zodiacSign'],
      gender: json['gender'],
      profileImagePath: json['profileImagePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'timeOfBirth': timeOfBirth,
      'placeOfBirth': placeOfBirth,
      'zodiacSign': zodiacSign,
      'gender': gender,
      'profileImagePath': profileImagePath,
    };
  }
}
