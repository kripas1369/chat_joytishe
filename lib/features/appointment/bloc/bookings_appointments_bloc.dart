import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/appointment_model.dart';
import '../models/booking_model.dart';
import '../repository/bookings_appointments_repository.dart';
import 'bookings_appointments_events.dart';
import 'bookings_appointments_states.dart';

class BookingsAppointmentsBloc
    extends Bloc<BookingsAppointmentsEvent, BookingsAppointmentsState> {
  final BookingsAppointmentsRepository repository;

  // Cache the loaded data
  List<Booking> _bookings = [];
  List<Appointment> _appointments = [];

  BookingsAppointmentsBloc({required this.repository})
      : super(const BookingsAppointmentsInitialState()) {
    on<FetchBookingsEvent>(_onFetchBookings);
    on<FetchAppointmentsEvent>(_onFetchAppointments);
    on<RefreshAllEvent>(_onRefreshAll);
  }

  /// Handle fetch bookings event
  Future<void> _onFetchBookings(
    FetchBookingsEvent event,
    Emitter<BookingsAppointmentsState> emit,
  ) async {
    emit(const BookingsLoadingState());

    try {
      final response = await repository.getMyBookings(
        page: event.page,
        limit: event.limit,
      );

      _bookings = response.bookings;
      emit(BookingsLoadedState(_bookings));
    } catch (e) {
      emit(BookingsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Handle fetch appointments event
  Future<void> _onFetchAppointments(
    FetchAppointmentsEvent event,
    Emitter<BookingsAppointmentsState> emit,
  ) async {
    emit(const AppointmentsLoadingState());

    try {
      final response = await repository.getMyAppointments(
        page: event.page,
        limit: event.limit,
      );

      _appointments = response.appointments;
      emit(AppointmentsLoadedState(_appointments));
    } catch (e) {
      emit(AppointmentsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Handle refresh all event - fetches both bookings and appointments
  Future<void> _onRefreshAll(
    RefreshAllEvent event,
    Emitter<BookingsAppointmentsState> emit,
  ) async {
    emit(const BookingsLoadingState());

    try {
      // Fetch both in parallel
      final results = await Future.wait([
        repository.getMyBookings(),
        repository.getMyAppointments(),
      ]);

      final bookingResponse = results[0] as BookingResponseModel;
      final appointmentResponse = results[1] as AppointmentResponseModel;

      _bookings = bookingResponse.bookings;
      _appointments = appointmentResponse.appointments;

      emit(BookingsAppointmentsLoadedState(
        bookings: _bookings,
        appointments: _appointments,
      ));
    } catch (e) {
      emit(BookingsErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Getter for cached bookings
  List<Booking> get bookings => _bookings;

  /// Getter for cached appointments
  List<Appointment> get appointments => _appointments;
}
