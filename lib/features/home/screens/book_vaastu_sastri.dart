import 'dart:ui';
import 'package:chat_jyotishi/features/app_widgets/app_button.dart';
import 'package:chat_jyotishi/features/home/screens/home_screen_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:chat_jyotishi/features/home/bloc/home_client_bloc.dart';
import 'package:chat_jyotishi/features/home/bloc/home_client_events.dart';
import 'package:chat_jyotishi/features/home/bloc/home_client_states.dart';
import 'package:chat_jyotishi/features/home/repository/home_client_repository.dart';
import 'package:chat_jyotishi/features/home/service/home_client_service.dart';
import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/show_top_snackBar.dart';

class BookVaastuSastriScreen extends StatefulWidget {
  const BookVaastuSastriScreen({super.key});

  @override
  State<BookVaastuSastriScreen> createState() => _BookVaastuSastriScreenState();
}

class _BookVaastuSastriScreenState extends State<BookVaastuSastriScreen>
    with TickerProviderStateMixin {
  String? selectedCategory;
  DateTime? selectedDate;
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  late HomeClientBloc _bloc;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _buttonPulseController;
  late AnimationController _buttonShineController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _buttonPulseAnimation;
  late Animation<double> _buttonShineAnimation;
  late Animation<Offset> _slideAnimation;

  final List<CategoryItem> categories = [
    CategoryItem(
      name: 'Home & Residential Vaastu',
      icon: Icons.home_work_rounded,
      description: 'Vaastu guidance for homes to improve peace, health, and prosperity.',
      colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
    ),
    CategoryItem(
      name: 'Property & Construction Vaastu',
      icon: Icons.apartment_rounded,
      description: 'Vaastu consultation for land selection, construction, and property planning.',
      colors: [Color(0xFFDB2777), Color(0xFFE44949)],
    ),
    CategoryItem(
      name: 'Office & Business Vaastu',
      icon: Icons.business_rounded,
      description: 'Vaastu solutions to enhance business growth, stability, and success.',
      colors: [Color(0xFFE44949), Color(0xFFF97316)],
    ),
    CategoryItem(
      name: 'Vaastu Dasha & Corrections',
      icon: Icons.tune_rounded,
      description: 'Analysis of Vaastu doshas with practical correction remedies.',
      colors: [Color(0xFFF97316), Color(0xFFFB923C)],
    ),
    CategoryItem(
      name: 'Energy & Directional Remedies',
      icon: Icons.explore_rounded,
      description: 'Balancing energies and correcting directional imbalances using Vaastu principles.',
      colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
    ),
    CategoryItem(
      name: 'Online & Special Consultation',
      icon: Icons.video_call_rounded,
      description: 'Personalized Vaastu consultations available online or for special cases.',
      colors: [Color(0xFFDB2777), Color(0xFFE44949)],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _bloc = HomeClientBloc(
      repository: HomeClientRepository(HomeClientService()),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _buttonPulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _buttonPulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _buttonPulseController, curve: Curves.easeInOut),
    );

    _buttonShineController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    _buttonShineAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _buttonShineController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _buttonPulseController.dispose();
    _buttonShineController.dispose();
    detailsController.dispose();
    locationController.dispose();
    _bloc.close();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF9333EA),
              onPrimary: Colors.white,
              surface: AppColors.primaryBlack,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.primaryBlack,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBlack,
              Color(0xFF9333EA).withOpacity(0.15),
              AppColors.primaryBlack,
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF9333EA),
                    Color(0xFFDB2777),
                    Color(0xFFE44949),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFDB2777).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.category,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Category',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choose consultation type',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category.name;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          selectedCategory = category.name;
                        });
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: category.colors,
                          )
                              : LinearGradient(
                            colors: [
                              Color(0xFF9333EA).withOpacity(0.15),
                              Color(0xFFDB2777).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Color(0xFF9333EA).withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: category.colors.first.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ]
                              : [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                      isSelected ? 0.25 : 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    category.icon,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.name,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        category.description,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.circle_outlined,
                                    color: Colors.white.withOpacity(0.3),
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (selectedCategory == null ||
        selectedDate == null ||
        locationController.text.trim().isEmpty) {
      showTopSnackBar(
        context: context,
        message: 'Please select category, date and location',
        backgroundColor: AppColors.error,
        icon: Icons.error,
      );
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
    _bloc.add(
      BookPanditEvent(
        bookingDate: formattedDate,
        category: selectedCategory!,
        type: 'VAASTU',
        location: locationController.text.trim(),
      ),
    );
  }

  void _handleCancel() {
    if (selectedCategory != null ||
        selectedDate != null ||
        detailsController.text.isNotEmpty ||
        locationController.text.trim().isNotEmpty) {
      _showCancelConfirmation();
    } else {
      Navigator.pop(context);
    }
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlack,
                Color(0xFF9333EA).withOpacity(0.15),
                AppColors.primaryBlack,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Color(0xFFF97316).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFF97316).withOpacity(0.3),
                            Color(0xFFFB923C).withOpacity(0.3),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFB923C),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Discard Changes?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your entered information will be lost. Are you sure?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF9333EA).withOpacity(0.3),
                                  Color(0xFFDB2777).withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFE44949),
                                  Color(0xFFF97316),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    selectedCategory = null;
                                    selectedDate = null;
                                    detailsController.clear();
                                    locationController.clear();
                                  });
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Discard',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(dynamic booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlack,
                Color(0xFF10B981).withOpacity(0.15),
                AppColors.primaryBlack,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Color(0xFF10B981).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF10B981).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF10B981).withOpacity(0.3),
                            Color(0xFF34D399).withOpacity(0.3),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF10B981),
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Booking Successful!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your request has been submitted',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF9333EA).withOpacity(0.3),
                            Color(0xFFDB2777).withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFF9333EA).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow('Status', booking.status),
                          Divider(
                            color: Colors.white.withOpacity(0.2),
                            height: 20,
                          ),
                          _buildInfoRow('Category', booking.category),
                          Divider(
                            color: Colors.white.withOpacity(0.2),
                            height: 20,
                          ),
                          _buildInfoRow(
                            'Date',
                            DateFormat('MMM dd, yyyy').format(booking.bookingDate),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF3B82F6).withOpacity(0.3),
                            Color(0xFF2563EB).withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Color(0xFF3B82F6).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF60A5FA),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Admin will review and respond soon',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _buttonPulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonPulseAnimation.value,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF10B981),
                                  Color(0xFF34D399),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF10B981).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Got It!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE44949), Color(0xFFF97316)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.place,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Location',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Where should the Vaastu consultation take place?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF9333EA).withOpacity(0.3),
                Color(0xFFDB2777).withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(0xFF9333EA).withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                controller: locationController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter address or city',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeClientBloc>.value(
      value: _bloc,
      child: BlocConsumer<HomeClientBloc, HomeClientState>(
        listener: (context, state) {
          if (state is HomeClientBookingSuccess) {
            _showSuccessDialog(state.booking);
          } else if (state is HomeClientErrorState) {
            showTopSnackBar(
              context: context,
              message: state.message,
              backgroundColor: AppColors.error,
              icon: Icons.error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is HomeClientLoadingState;

          return Scaffold(
            backgroundColor: AppColors.primaryBlack,
            body: Stack(
              children: [
                // Background
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
                Positioned(
                  top: -100,
                  left: -50,
                  right: -50,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        height: 350,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Color(0xFF9333EA).withOpacity(
                                0.15 * _pulseAnimation.value,
                              ),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _buildAppBar(),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeaderCard(),
                                  const SizedBox(height: 24),
                                  _buildCategorySection(),
                                  const SizedBox(height: 20),
                                  _buildDateSection(),
                                  const SizedBox(height: 20),
                                  _buildLocationSection(),
                                  const SizedBox(height: 20),
                                  _buildDetailsSection(),
                                  const SizedBox(height: 24),
                                  _buildInfoCard(),
                                  const SizedBox(height: 32),
                                  _buildActionButtons(isLoading),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.8),
                    child: Center(
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
                          border: Border.all(
                            color: Color(0xFF9333EA).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 50,
                              height: 50,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF9333EA),
                                ),
                                strokeWidth: 4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Submitting your request...',
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
                  ),
              ],
            ),
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
              border: Border.all(
                color: Color(0xFF9333EA).withOpacity(0.3),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleCancel,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
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
                  'Book Vaastu Sastri',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Schedule your Vaastu consultation',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF9333EA),
            Color(0xFFDB2777),
            Color(0xFFE44949),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFDB2777).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expert Vaastu Consultants',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Verified & experienced Vaastu experts for all needs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    final CategoryItem? selectedItem = selectedCategory != null
        ? categories.firstWhere(
          (cat) => cat.name == selectedCategory,
      orElse: () => categories.first,
    )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFFDB2777)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.category,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Select Category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the type of consultation you need',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _showCategorySelector,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: selectedCategory != null
                    ? selectedItem!.colors
                    : [
                  Color(0xFF9333EA).withOpacity(0.3),
                  Color(0xFFDB2777).withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFF9333EA).withOpacity(0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        selectedCategory != null
                            ? selectedItem?.icon
                            : Icons.category,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCategory ?? 'Select consultation type',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: selectedCategory != null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          if (selectedCategory != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              selectedItem!.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDB2777), Color(0xFFE44949)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Preferred Date',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'When would you like the consultation?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF9333EA).withOpacity(0.3),
                  Color(0xFFDB2777).withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFF9333EA).withOpacity(0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedDate == null
                                ? 'Select Date'
                                : DateFormat(
                              'EEEE, MMM dd, yyyy',
                            ).format(selectedDate!),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: selectedDate == null
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                          if (selectedDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _getRelativeDate(selectedDate!),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);
    final difference = selectedDay.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference > 1 && difference <= 7) return 'In $difference days';
    return '';
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_note,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Additional Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF9333EA).withOpacity(0.3),
                    Color(0xFFDB2777).withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Optional',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Provide specific requirements for your consultation',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF9333EA).withOpacity(0.3),
                Color(0xFFDB2777).withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(0xFF9333EA).withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextField(
                controller: detailsController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                  'E.g., Property type, specific concerns, preferred time...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3B82F6).withOpacity(0.3),
            Color(0xFF2563EB).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF3B82F6).withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF60A5FA),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Important Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your request will be reviewed by our admin team. You\'ll receive confirmation once approved. The Vaastu expert will contact you for further arrangements.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF9333EA).withOpacity(0.3),
                  Color(0xFFDB2777).withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : _handleCancel,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.close,
                        color: isLoading ? Colors.white38 : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cancel',
                        style: TextStyle(
                          color: isLoading ? Colors.white38 : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedBuilder(
            animation: _buttonPulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isLoading ? 1.0 : _buttonPulseAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFE44949),
                        Color(0xFFF97316),
                        Color(0xFFFB923C),
                        Color(0xFFFBBF24),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFF97316).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isLoading ? null : _handleSubmit,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send,
                              color: isLoading ? Colors.white38 : Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Submit Request',
                              style: TextStyle(
                                color: isLoading ? Colors.white38 : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CategoryItem {
  final String name;
  final IconData icon;
  final String description;
  final List<Color> colors;

  CategoryItem({
    required this.name,
    required this.icon,
    required this.description,
    required this.colors,
  });
}