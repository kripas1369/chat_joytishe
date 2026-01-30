import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:chat_jyotishi/constants/constant.dart';
import '../bloc/bookings_appointments_bloc.dart';
import '../bloc/bookings_appointments_events.dart';
import '../bloc/bookings_appointments_states.dart';
import '../models/appointment_model.dart';
import '../models/booking_model.dart';
import '../repository/bookings_appointments_repository.dart';
import '../service/bookings_appointments_service.dart';

class BookingsAppointmentsScreen extends StatelessWidget {
  const BookingsAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingsAppointmentsBloc(
        repository: BookingsAppointmentsRepository(
          BookingsAppointmentsService(),
        ),
      )..add(const FetchBookingsEvent()), // Default: fetch bookings first
      child: const BookingsAppointmentsContent(),
    );
  }
}

class BookingsAppointmentsContent extends StatefulWidget {
  const BookingsAppointmentsContent({super.key});

  @override
  State<BookingsAppointmentsContent> createState() =>
      _BookingsAppointmentsContentState();
}

class _BookingsAppointmentsContentState
    extends State<BookingsAppointmentsContent>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Bookings filters
  String bookingTypeFilter = 'All';
  String bookingStatusFilter = 'All';
  String bookingSearchQuery = '';

  // Appointments filters
  String appointmentStatusFilter = 'All';
  String appointmentSearchQuery = '';

  // Data lists (from bloc)
  List<Booking> bookings = [];
  List<Appointment> appointments = [];

  // Track expanded state for each card
  Set<String> expandedBookingIds = {};
  Set<String> expandedAppointmentIds = {};

  final TextEditingController bookingSearchController = TextEditingController();
  final TextEditingController appointmentSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    final bloc = context.read<BookingsAppointmentsBloc>();

    if (_tabController.index == 0) {
      // Bookings tab
      bloc.add(const FetchBookingsEvent());
    } else {
      // Appointments tab
      bloc.add(const FetchAppointmentsEvent());
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _fadeController.dispose();
    bookingSearchController.dispose();
    appointmentSearchController.dispose();
    super.dispose();
  }

  Future<void> _refreshBookings() async {
    context.read<BookingsAppointmentsBloc>().add(const FetchBookingsEvent());
  }

  Future<void> _refreshAppointments() async {
    context.read<BookingsAppointmentsBloc>().add(
      const FetchAppointmentsEvent(),
    );
  }

  void _toggleBookingExpansion(String bookingId) {
    setState(() {
      if (expandedBookingIds.contains(bookingId)) {
        expandedBookingIds.remove(bookingId);
      } else {
        expandedBookingIds.add(bookingId);
      }
    });
  }

  void _toggleAppointmentExpansion(String appointmentId) {
    setState(() {
      if (expandedAppointmentIds.contains(appointmentId)) {
        expandedAppointmentIds.remove(appointmentId);
      } else {
        expandedAppointmentIds.add(appointmentId);
      }
    });
  }

  List<Booking> get filteredBookings {
    return bookings.where((booking) {
      // Type filter
      if (bookingTypeFilter != 'All' &&
          booking.displayType != bookingTypeFilter) {
        return false;
      }

      // Status filter
      if (bookingStatusFilter != 'All') {
        final status = bookingStatusFilter.toLowerCase();
        if (status == 'pending' &&
            booking.bookingStatus != BookingStatus.pending)
          return false;
        if (status == 'approved' &&
            booking.bookingStatus != BookingStatus.approved)
          return false;
        if (status == 'rejected' &&
            booking.bookingStatus != BookingStatus.rejected)
          return false;
      }

      // Search filter
      if (bookingSearchQuery.isNotEmpty) {
        final query = bookingSearchQuery.toLowerCase();
        final matchesCategory = booking.category.toLowerCase().contains(query);
        final matchesDetails = booking.details.toLowerCase().contains(query);
        final matchesLocation = booking.location.toLowerCase().contains(query);
        if (!matchesCategory && !matchesDetails && !matchesLocation)
          return false;
      }

      return true;
    }).toList();
  }

  List<Appointment> get filteredAppointments {
    return appointments.where((appointment) {
      // Status filter
      if (appointmentStatusFilter != 'All') {
        final status = appointmentStatusFilter.toLowerCase().replaceAll(
          ' ',
          '',
        );
        if (status == 'pending' &&
            appointment.appointmentStatus != AppointmentStatus.pending)
          return false;
        if (status == 'approved' &&
            appointment.appointmentStatus != AppointmentStatus.approved)
          return false;
        if (status == 'inprogress' &&
            appointment.appointmentStatus != AppointmentStatus.inProgress)
          return false;
        if (status == 'completed' &&
            appointment.appointmentStatus != AppointmentStatus.completed)
          return false;
        if (status == 'cancelled' &&
            appointment.appointmentStatus != AppointmentStatus.cancelled)
          return false;
      }

      // Search filter
      if (appointmentSearchQuery.isNotEmpty) {
        final query = appointmentSearchQuery.toLowerCase();
        if (!appointment.astrologerName.toLowerCase().contains(query))
          return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: BlocConsumer<BookingsAppointmentsBloc, BookingsAppointmentsState>(
        listener: (context, state) {
          if (state is BookingsLoadedState) {
            setState(() {
              bookings = state.bookings;
            });
          } else if (state is AppointmentsLoadedState) {
            setState(() {
              appointments = state.appointments;
            });
          } else if (state is BookingsAppointmentsLoadedState) {
            setState(() {
              bookings = state.bookings;
              appointments = state.appointments;
            });
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryBlack,
                      Color(0xFF9333EA).withOpacity(0.1),
                      AppColors.primaryBlack,
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildAppBar(),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildBookingsTab(state),
                            _buildAppointmentsTab(state),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9333EA).withOpacity(0.3),
                  Color(0xFFDB2777).withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF9333EA).withOpacity(0.3)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Bookings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Track your bookings and appointments',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9333EA).withOpacity(0.2),
            Color(0xFFDB2777).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF9333EA).withOpacity(0.3)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Bookings'),
          Tab(text: 'Appointments'),
        ],
      ),
    );
  }

  Widget _buildBookingsTab(BookingsAppointmentsState state) {
    final isLoading = state is BookingsLoadingState;
    final hasError = state is BookingsErrorState;

    return Column(
      children: [
        const SizedBox(height: 20),
        _buildBookingsFilters(),
        const SizedBox(height: 16),
        _buildBookingsSearch(),
        const SizedBox(height: 16),
        Expanded(
          child: isLoading
              ? _buildLoadingState()
              : hasError
              ? _buildErrorState(
                  (state as BookingsErrorState).message,
                  () => _refreshBookings(),
                )
              : filteredBookings.isEmpty
              ? _buildEmptyState('No bookings found')
              : _buildBookingsList(),
        ),
      ],
    );
  }

  Widget _buildAppointmentsTab(BookingsAppointmentsState state) {
    final isLoading = state is AppointmentsLoadingState;
    final hasError = state is AppointmentsErrorState;

    return Column(
      children: [
        const SizedBox(height: 20),
        _buildAppointmentsFilters(),
        const SizedBox(height: 16),
        _buildAppointmentsSearch(),
        const SizedBox(height: 16),
        Expanded(
          child: isLoading
              ? _buildLoadingState()
              : hasError
              ? _buildErrorState(
                  (state as AppointmentsErrorState).message,
                  () => _refreshAppointments(),
                )
              : filteredAppointments.isEmpty
              ? _buildEmptyState('No appointments found')
              : _buildAppointmentsList(),
        ),
      ],
    );
  }

  Widget _buildBookingsFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterDropdown(
              label: 'Type',
              value: bookingTypeFilter,
              items: ['All', 'Pandit Ji', 'Vaastu Sastri', 'Katha Vachak'],
              onChanged: (value) {
                setState(() => bookingTypeFilter = value!);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterDropdown(
              label: 'Status',
              value: bookingStatusFilter,
              items: ['All', 'Pending', 'Approved', 'Rejected'],
              onChanged: (value) {
                setState(() => bookingStatusFilter = value!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildFilterDropdown(
        label: 'Status',
        value: appointmentStatusFilter,
        items: [
          'All',
          'Pending',
          'Approved',
          'In Progress',
          'Completed',
          'Cancelled',
        ],
        onChanged: (value) {
          setState(() => appointmentStatusFilter = value!);
        },
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF9333EA).withOpacity(0.2),
            Color(0xFFDB2777).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF9333EA).withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.primaryBlack,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBookingsSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF9333EA).withOpacity(0.2),
              Color(0xFFDB2777).withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF9333EA).withOpacity(0.3)),
        ),
        child: TextField(
          controller: bookingSearchController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by category, details or location...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
            suffixIcon: bookingSearchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    onPressed: () {
                      bookingSearchController.clear();
                      setState(() => bookingSearchQuery = '');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() => bookingSearchQuery = value);
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentsSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF9333EA).withOpacity(0.2),
              Color(0xFFDB2777).withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF9333EA).withOpacity(0.3)),
        ),
        child: TextField(
          controller: appointmentSearchController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search by astrologer name...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
            suffixIcon: appointmentSearchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    onPressed: () {
                      appointmentSearchController.clear();
                      setState(() => appointmentSearchQuery = '');
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() => appointmentSearchQuery = value);
          },
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    return RefreshIndicator(
      onRefresh: _refreshBookings,
      color: Color(0xFF9333EA),
      backgroundColor: AppColors.primaryBlack,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filteredBookings.length,
        itemBuilder: (context, index) {
          final booking = filteredBookings[index];
          return _buildBookingCard(booking, index + 1);
        },
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return RefreshIndicator(
      onRefresh: _refreshAppointments,
      color: Color(0xFF9333EA),
      backgroundColor: AppColors.primaryBlack,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filteredAppointments.length,
        itemBuilder: (context, index) {
          final appointment = filteredAppointments[index];
          return _buildAppointmentCard(appointment, index + 1);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, int serialNumber) {
    final bookingId = booking.id ?? 'booking_$serialNumber';
    final isExpanded = expandedBookingIds.contains(bookingId);

    return GestureDetector(
      onTap: () => _toggleBookingExpansion(bookingId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.cosmicPink.withOpacity(0.2),
              Colors.deepPurple.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with S.N, Type and Status (Always visible)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$serialNumber',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF9333EA).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFF9333EA).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.category,
                                  color: Color(0xFF9333EA),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  booking.displayType,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildStatusBadge(booking.bookingStatus),
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Expandable content
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Booking Type
                        _buildInfoRow(
                          icon: Icons.category,
                          label: 'Type',
                          value: booking.displayType,
                          iconColor: Color(0xFF9333EA),
                        ),
                        const SizedBox(height: 12),

                        // Category
                        _buildInfoRow(
                          icon: Icons.bookmark,
                          label: 'Category',
                          value: booking.category,
                          iconColor: Color(0xFFDB2777),
                        ),
                        const SizedBox(height: 12),

                        // Date
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: DateFormat(
                            'MMM dd, yyyy',
                          ).format(booking.bookingDate),
                          iconColor: Color(0xFFE44949),
                        ),
                        const SizedBox(height: 12),

                        // Details
                        if (booking.details.isNotEmpty) ...[
                          _buildInfoRow(
                            icon: Icons.notes,
                            label: 'Remark',
                            value: booking.details,
                            iconColor: Color(0xFFF97316),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Preferred Astrologer
                        if (booking.preferredAstrologer != null) ...[
                          _buildInfoRow(
                            icon: Icons.person,
                            label: 'Preferred',
                            value: booking.preferredAstrologer!.name,
                            iconColor: Color(0xFF3B82F6),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Admin Note
                        if (booking.adminNotes != null &&
                            booking.adminNotes!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF3B82F6).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFF3B82F6).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  color: Color(0xFF60A5FA),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Admin Note',
                                        style: TextStyle(
                                          color: Color(0xFF60A5FA),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        booking.adminNotes!,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Submitted Date
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.white.withOpacity(0.5),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Submitted: ${DateFormat('MMM dd, yyyy - hh:mm a').format(booking.createdAt)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, int serialNumber) {
    final appointmentId = appointment.id ?? 'appointment_$serialNumber';
    final isExpanded = expandedAppointmentIds.contains(appointmentId);

    return GestureDetector(
      onTap: () => _toggleAppointmentExpansion(appointmentId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.cosmicPink.withOpacity(0.2),
              Colors.deepPurple.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          // border: Border.all(color: Color(0xFF9333EA).withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with S.N, Astrologer and Status (Always visible)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF9333EA),
                                    Color(0xFFDB2777),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$serialNumber',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF9333EA).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Color(0xFF9333EA).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Color(0xFF9333EA),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        appointment.astrologerName,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _buildAppointmentStatusBadge(
                            appointment.appointmentStatus,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Expandable content
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Astrologer Name
                        _buildInfoRow(
                          icon: Icons.person,
                          label: 'Astrologer',
                          value: appointment.astrologerName,
                          iconColor: Color(0xFF9333EA),
                        ),
                        const SizedBox(height: 12),

                        // Scheduled Date
                        _buildInfoRow(
                          icon: Icons.calendar_month,
                          label: 'Scheduled',
                          value: DateFormat(
                            'MMM dd, yyyy - hh:mm a',
                          ).format(appointment.scheduledAt),
                          iconColor: Color(0xFFDB2777),
                        ),
                        const SizedBox(height: 12),

                        // Duration and Amount row
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoRow(
                                icon: Icons.timer,
                                label: 'Duration',
                                value: appointment.durationDisplay,
                                iconColor: Color(0xFFE44949),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoRow(
                                icon: Icons.currency_rupee,
                                label: 'Amount',
                                value: appointment.formattedAmount,
                                iconColor: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Notes
                        if (appointment.notes != null &&
                            appointment.notes!.isNotEmpty) ...[
                          _buildInfoRow(
                            icon: Icons.note,
                            label: 'Notes',
                            value: appointment.notes!,
                            iconColor: Color(0xFFF97316),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Cancellation Note
                        if (appointment.isCancelled &&
                            appointment.cancellationNote != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFE44949).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFFE44949).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cancel,
                                  color: Color(0xFFE44949),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    appointment.cancellationNote!,
                                    style: TextStyle(
                                      color: Color(0xFFE44949),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Requested Date
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.white.withOpacity(0.5),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Requested: ${DateFormat('MMM dd, yyyy - hh:mm a').format(appointment.createdAt)}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BookingStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case BookingStatus.pending:
        color = Color(0xFFFB923C);
        text = 'Pending';
        icon = Icons.pending;
        break;
      case BookingStatus.approved:
        color = Color(0xFF10B981);
        text = 'Approved';
        icon = Icons.check_circle;
        break;
      case BookingStatus.rejected:
        color = Color(0xFFE44949);
        text = 'Rejected';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentStatusBadge(AppointmentStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case AppointmentStatus.pending:
        color = Color(0xFFFB923C);
        text = 'Pending';
        icon = Icons.pending;
        break;
      case AppointmentStatus.approved:
        color = Color(0xFF10B981);
        text = 'Approved';
        icon = Icons.check_circle;
        break;
      case AppointmentStatus.inProgress:
        color = Color(0xFF3B82F6);
        text = 'In Progress';
        icon = Icons.timelapse;
        break;
      case AppointmentStatus.completed:
        color = Color(0xFF10B981);
        text = 'Completed';
        icon = Icons.done_all;
        break;
      case AppointmentStatus.cancelled:
        color = Color(0xFFE44949);
        text = 'Cancelled';
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9333EA).withOpacity(0.3),
              Color(0xFFDB2777).withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF9333EA).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9333EA)),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE44949).withOpacity(0.2),
                    Color(0xFFE44949).withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFE44949),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9333EA).withOpacity(0.2),
                  Color(0xFFDB2777).withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
