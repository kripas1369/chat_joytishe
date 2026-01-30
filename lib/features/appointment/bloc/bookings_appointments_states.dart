import 'package:equatable/equatable.dart';
import '../models/appointment_model.dart';
import '../models/booking_model.dart';

abstract class BookingsAppointmentsState extends Equatable {
  const BookingsAppointmentsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BookingsAppointmentsInitialState extends BookingsAppointmentsState {
  const BookingsAppointmentsInitialState();
}

/// Loading state for bookings
class BookingsLoadingState extends BookingsAppointmentsState {
  const BookingsLoadingState();
}

/// Loading state for appointments
class AppointmentsLoadingState extends BookingsAppointmentsState {
  const AppointmentsLoadingState();
}

/// Bookings loaded successfully
class BookingsLoadedState extends BookingsAppointmentsState {
  final List<Booking> bookings;

  const BookingsLoadedState(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

/// Appointments loaded successfully
class AppointmentsLoadedState extends BookingsAppointmentsState {
  final List<Appointment> appointments;

  const AppointmentsLoadedState(this.appointments);

  @override
  List<Object?> get props => [appointments];
}

/// Combined state when both are loaded (useful for initial load)
class BookingsAppointmentsLoadedState extends BookingsAppointmentsState {
  final List<Booking> bookings;
  final List<Appointment> appointments;

  const BookingsAppointmentsLoadedState({
    required this.bookings,
    required this.appointments,
  });

  @override
  List<Object?> get props => [bookings, appointments];
}

/// Error state for bookings
class BookingsErrorState extends BookingsAppointmentsState {
  final String message;

  const BookingsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

/// Error state for appointments
class AppointmentsErrorState extends BookingsAppointmentsState {
  final String message;

  const AppointmentsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
