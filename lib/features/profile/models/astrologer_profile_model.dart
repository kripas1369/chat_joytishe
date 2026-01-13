class AstrologerProfileModel {
  final String? id;
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
  final String? profileImagePath;

  AstrologerProfileModel({
    this.id,
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
    this.profileImagePath,
  });

  factory AstrologerProfileModel.fromJson(Map<String, dynamic> json) {
    return AstrologerProfileModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      experienceYears: json['experienceYears'],
      expertise: json['expertise'],
      languages: json['languages'],
      bio: json['bio'],
      pricePerMinute: json['pricePerMinute']?.toDouble(),
      gender: json['gender'],
      isAvailable: json['isAvailable'],
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
      'experienceYears': experienceYears,
      'expertise': expertise,
      'languages': languages,
      'bio': bio,
      'pricePerMinute': pricePerMinute,
      'gender': gender,
      'isAvailable': isAvailable,
      'profileImagePath': profileImagePath,
    };
  }
}