/// Appointment Model based on API response from appointments/my
class AppointmentResponseModel {
  final bool success;
  final List<Appointment> appointments;

  AppointmentResponseModel({
    required this.success,
    required this.appointments,
  });

  factory AppointmentResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    final appointmentsList = data['appointments'] as List<dynamic>? ?? [];

    return AppointmentResponseModel(
      success: json['success'] ?? false,
      appointments: appointmentsList.map((e) => Appointment.fromJson(e)).toList(),
    );
  }
}

class Appointment {
  final String id;
  final String clientId;
  final String astrologerId;
  final DateTime scheduledAt;
  final int duration; // in minutes
  final String status; // PENDING, CONFIRMED, COMPLETED, CANCELLED
  final int amount; // in paisa
  final String? notes;
  final int? rating;
  final String? review;
  final String? cancellationNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AppointmentClient? client;
  final AppointmentAstrologer? astrologer;

  Appointment({
    required this.id,
    required this.clientId,
    required this.astrologerId,
    required this.scheduledAt,
    required this.duration,
    required this.status,
    required this.amount,
    this.notes,
    this.rating,
    this.review,
    this.cancellationNote,
    required this.createdAt,
    required this.updatedAt,
    this.client,
    this.astrologer,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      astrologerId: json['astrologerId'] ?? '',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : DateTime.now(),
      duration: json['duration'] ?? 30,
      status: json['status'] ?? 'PENDING',
      amount: json['amount'] ?? 0,
      notes: json['notes'],
      rating: json['rating'],
      review: json['review'],
      cancellationNote: json['cancellationNote'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      client: json['client'] != null
          ? AppointmentClient.fromJson(json['client'])
          : null,
      astrologer: json['astrologer'] != null
          ? AppointmentAstrologer.fromJson(json['astrologer'])
          : null,
    );
  }

  /// Returns the appointment status enum
  AppointmentStatus get appointmentStatus {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
      case 'APPROVED':
        return AppointmentStatus.approved;
      case 'IN_PROGRESS':
      case 'INPROGRESS':
        return AppointmentStatus.inProgress;
      case 'COMPLETED':
        return AppointmentStatus.completed;
      case 'CANCELLED':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.pending;
    }
  }

  /// Returns duration as display string
  String get durationDisplay => '$duration minutes';

  /// Returns amount in rupees
  double get amountInRupees => amount / 100;

  /// Returns formatted amount
  String get formattedAmount => '₹${amountInRupees.toStringAsFixed(0)}';

  /// Check if cancelled
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  /// Get astrologer name
  String get astrologerName => astrologer?.name ?? 'Unknown';
}

class AppointmentClient {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? profilePhoto;

  AppointmentClient({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.profilePhoto,
  });

  factory AppointmentClient.fromJson(Map<String, dynamic> json) {
    return AppointmentClient(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      profilePhoto: json['profilePhoto'],
    );
  }
}

class AppointmentAstrologer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? profilePhoto;

  AppointmentAstrologer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.profilePhoto,
  });

  factory AppointmentAstrologer.fromJson(Map<String, dynamic> json) {
    return AppointmentAstrologer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      profilePhoto: json['profilePhoto'],
    );
  }
}

enum AppointmentStatus { pending, approved, inProgress, completed, cancelled }
