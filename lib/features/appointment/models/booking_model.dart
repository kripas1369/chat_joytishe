/// Booking Model based on API response from jyotish-bookings/my
class BookingResponseModel {
  final bool success;
  final List<Booking> bookings;

  BookingResponseModel({required this.success, required this.bookings});

  factory BookingResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final bookingsList = data['bookings'] as List<dynamic>? ?? [];

    return BookingResponseModel(
      success: json['success'] ?? false,
      bookings: bookingsList.map((e) => Booking.fromJson(e)).toList(),
    );
  }
}

class Booking {
  final String id;
  final String clientId;
  final String type; // KATHA_VACHAK, VAASTU, PANDIT
  final String? preferredAstrologerId;
  final String category;
  final DateTime bookingDate;
  final String details;
  final String location;
  final String status; // PENDING, APPROVED, REJECTED
  final String? adminNotes;
  final DateTime? decidedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PreferredAstrologer? preferredAstrologer;

  Booking({
    required this.id,
    required this.clientId,
    required this.type,
    this.preferredAstrologerId,
    required this.category,
    required this.bookingDate,
    required this.details,
    required this.location,
    required this.status,
    this.adminNotes,
    this.decidedAt,
    required this.createdAt,
    required this.updatedAt,
    this.preferredAstrologer,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      type: json['type'] ?? '',
      preferredAstrologerId: json['preferredAstrologerId'],
      category: json['category'] ?? '',
      bookingDate: json['bookingDate'] != null
          ? DateTime.parse(json['bookingDate'])
          : DateTime.now(),
      details: json['details'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? 'PENDING',
      adminNotes: json['adminNotes'] ?? '',
      decidedAt: json['decidedAt'] != null
          ? DateTime.parse(json['decidedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      preferredAstrologer: json['preferredAstrologer'] != null
          ? PreferredAstrologer.fromJson(json['preferredAstrologer'])
          : null,
    );
  }

  /// Returns display-friendly booking type
  String get displayType {
    switch (type) {
      case 'KATHA_VACHAK':
        return 'Katha Vachak';
      case 'VAASTU':
        return 'Vaastu Sastri';
      case 'PANDIT':
        return 'Pandit Ji';
      default:
        return type;
    }
  }

  /// Returns the booking status enum
  BookingStatus get bookingStatus {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return BookingStatus.approved;
      case 'REJECTED':
        return BookingStatus.rejected;
      default:
        return BookingStatus.pending;
    }
  }
}

class PreferredAstrologer {
  final String id;
  final String name;
  final String category;
  final List<String> specialization;
  final String? profilePhoto;

  PreferredAstrologer({
    required this.id,
    required this.name,
    required this.category,
    required this.specialization,
    this.profilePhoto,
  });

  factory PreferredAstrologer.fromJson(Map<String, dynamic> json) {
    return PreferredAstrologer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      specialization: List<String>.from(json['specialization'] ?? []),
      profilePhoto: json['profilePhoto'],
    );
  }
}

enum BookingStatus { pending, approved, rejected }
