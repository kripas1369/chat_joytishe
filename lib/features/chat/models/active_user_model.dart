class ActiveUser {
  final bool success;
  final List<ActiveAstrologerModel> astrologers;

  ActiveUser({required this.success, required this.astrologers});

  factory ActiveUser.fromJson(Map<String, dynamic> json) {
    return ActiveUser(
      success: json['success'] ?? false,
      astrologers: json['success'] == true && json['data'] != null
          ? (json['data'] as List)
                .map((e) => ActiveAstrologerModel.fromJson(e))
                .toList()
          : [],
    );
  }
}

class ActiveAstrologerModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profilePhoto;
  final String role;
  final bool isOnline;

  ActiveAstrologerModel({
    required this.isOnline,
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profilePhoto,
    required this.role,
  });

  factory ActiveAstrologerModel.fromJson(Map<String, dynamic> json) {
    return ActiveAstrologerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      profilePhoto: json['profilePhoto'] ?? '',
      role: json['role'] ?? '',
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profilePhoto': profilePhoto,
      'role': role,
      'isOnline': isOnline,
    };
  }
}
