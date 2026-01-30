import 'package:equatable/equatable.dart';

abstract class BookingsAppointmentsEvent extends Equatable {
  const BookingsAppointmentsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch user's bookings
class FetchBookingsEvent extends BookingsAppointmentsEvent {
  final int page;
  final int limit;

  const FetchBookingsEvent({
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [page, limit];
}

/// Event to fetch user's appointments
class FetchAppointmentsEvent extends BookingsAppointmentsEvent {
  final int page;
  final int limit;

  const FetchAppointmentsEvent({
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [page, limit];
}

/// Event to refresh both bookings and appointments
class RefreshAllEvent extends BookingsAppointmentsEvent {
  const RefreshAllEvent();
}
