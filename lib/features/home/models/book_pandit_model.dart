class BookingModel {
  final String id;
  final String clientId;
  final String type;
  final String category;
  final DateTime bookingDate;
  final String status;
  final DateTime createdAt;
  final String location;

  BookingModel({
    required this.id,
    required this.clientId,
    required this.type,
    required this.category,
    required this.bookingDate,
    required this.status,
    required this.createdAt,
    required this.location,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      clientId: json['clientId'],
      type: json['type'],
      category: json['category'],
      bookingDate: DateTime.parse(json['bookingDate']).toLocal(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']).toLocal(),
      location: json['location'] ?? '',
    );
  }
}
