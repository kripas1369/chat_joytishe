import '../models/appointment_model.dart';
import '../models/booking_model.dart';
import '../service/bookings_appointments_service.dart';

class BookingsAppointmentsRepository {
  final BookingsAppointmentsService _service;

  BookingsAppointmentsRepository(this._service);

  /// Fetches user's bookings and returns typed model
  Future<BookingResponseModel> getMyBookings({
    int page = 1,
    int limit = 10,
  }) async {
    final data = await _service.getMyBookings(page: page, limit: limit);
    return BookingResponseModel.fromJson(data);
  }

  /// Fetches user's appointments and returns typed model
  Future<AppointmentResponseModel> getMyAppointments({
    int page = 1,
    int limit = 10,
  }) async {
    final data = await _service.getMyAppointments(page: page, limit: limit);
    return AppointmentResponseModel.fromJson(data);
  }
}
