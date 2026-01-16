import 'dart:io';
import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/profile/bloc/profile_bloc.dart';
import 'package:chat_jyotishi/features/profile/bloc/profile_events.dart';
import 'package:chat_jyotishi/features/profile/bloc/profile_states.dart';
import 'package:chat_jyotishi/features/profile/repository/profile_repository.dart';
import 'package:chat_jyotishi/features/profile/service/profile_service.dart';
import 'package:chat_jyotishi/features/profile/widgets/profile_widgets.dart';

import 'package:flutter/material.dart' hide TextField;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart'
    hide CalendarDatePicker;

import '../../app_widgets/show_top_snackBar.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProfileBloc(profileRepository: ProfileRepository(ProfileService()))
            ..add(LoadCurrentUserProfileEvent()),
      child: const UserProfileScreenContent(),
    );
  }
}

class UserProfileScreenContent extends StatefulWidget {
  const UserProfileScreenContent({super.key});

  @override
  State<UserProfileScreenContent> createState() =>
      _UserProfileScreenContentState();
}

class _UserProfileScreenContentState extends State<UserProfileScreenContent>
    with TickerProviderStateMixin {
  File? profileImage;
  final ImagePicker picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController tobController = TextEditingController();
  final TextEditingController pobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController horoscopeController = TextEditingController();
  final TextEditingController currentAddressController =
      TextEditingController();
  final TextEditingController permanentAddressController =
      TextEditingController();
  final TextEditingController zoadicSignController = TextEditingController();
  final TextEditingController genderController = TextEditingController();

  String? selectedGender;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();

    _profileBloc = context.read<ProfileBloc>();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    nameController.dispose();
    dobController.dispose();
    tobController.dispose();
    pobController.dispose();
    emailController.dispose();
    phoneController.dispose();
    horoscopeController.dispose();
    currentAddressController.dispose();
    permanentAddressController.dispose();
    zoadicSignController.dispose();
    genderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoadedState) {
          populateFields(state);
        } else if (state is ProfileUpdatedState) {
          showTopSnackBar(
            context: context,
            message: 'Profile updated successfully!',
            backgroundColor: AppColors.success,
            icon: Icons.check_circle,
          );
          populateFields(state);
        } else if (state is BirthDetailsUpdatedState) {
          showTopSnackBar(
            context: context,
            message: 'Birth details updated successfully!',
            backgroundColor: AppColors.success,
            icon: Icons.check_circle,
          );
        } else if (state is ProfilePhotoUploadedState) {
          showTopSnackBar(
            context: context,
            message: 'Photo uploaded successfully!',
            backgroundColor: AppColors.success,
            icon: Icons.check_circle,
          );
          // Reload profile to get updated data
          _profileBloc.add(RefreshUserProfileEvent());
        } else if (state is ProfilePhotoRemovedState) {
          showTopSnackBar(
            context: context,
            message: 'Photo removed successfully!',
            backgroundColor: AppColors.success,
            icon: Icons.check_circle,
          );
          setState(() => profileImage = null);
          _profileBloc.add(RefreshUserProfileEvent());
        } else if (state is ProfileSetupSuccessState) {
          showTopSnackBar(
            context: context,
            message: state.message,
            backgroundColor: AppColors.success,
            icon: Icons.check_circle,
          );
          populateFields(state);
        } else if (state is ProfileErrorState) {
          showTopSnackBar(
            context: context,
            message: state.message,
            backgroundColor: AppColors.error,
            icon: Icons.error,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.backgroundGradient,
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
                            AppColors.primaryPurple.withOpacity(
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
                      ProfileHeader(
                        onBack: () => Navigator.pop(context),
                        onSettings: () {
                          Navigator.of(
                            context,
                          ).pushNamed('/change_password_screen');
                        },
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              ProfileAvatar(
                                profileImage: profileImage,
                                pulseAnimation: _pulseAnimation,
                                displayName: nameController.text.isEmpty
                                    ? 'Your Name'
                                    : nameController.text,
                                displayEmail: emailController.text.isEmpty
                                    ? 'Add your email'
                                    : emailController.text,
                                onTap: () => _showImagePicker(),
                              ),
                              const SizedBox(height: 32),
                              ProfileCompletionCard(
                                filledFields: _calculateFilledFields(),
                                totalFields: 9,
                              ),
                              const SizedBox(height: 24),
                              _buildPersonalInfoSection(),
                              const SizedBox(height: 24),
                              _buildBirthDetailsSection(),
                              const SizedBox(height: 24),
                              _buildContactSection(),
                              const SizedBox(height: 24),
                              GenderSelector(
                                selectedGender: selectedGender,
                                onGenderChanged: (value) {
                                  setState(() => selectedGender = value);
                                },
                              ),
                              const SizedBox(height: 32),
                              ProfileSaveButton(
                                isLoading:
                                    state is ProfileLoadingState ||
                                    state is ProfileOperationInProgressState,
                                onTap: _saveProfile,
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoSection() {
    return ProfileSection(
      title: 'Personal Information',
      icon: Icons.person_rounded,
      children: [
        AppTextField(
          controller: nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          icon: Icons.badge_rounded,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: horoscopeController,
          label: 'Zodiac Sign',
          hint: 'e.g., Aries, Taurus...',
          icon: Icons.auto_awesome,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildBirthDetailsSection() {
    return ProfileSection(
      title: 'Birth Details',
      icon: Icons.cake_rounded,
      subtitle: 'Required for accurate horoscope',
      children: [
        AppTextField(
          controller: dobController,
          label: 'Date of Birth',
          hint: 'YYYY/MM/DD (B.S.)',
          icon: Icons.calendar_month_rounded,
          keyboardType: TextInputType.datetime,
          onTap: () => _selectDate(context),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: tobController,
          label: 'Time of Birth',
          hint: 'HH:mm:ss',
          icon: Icons.schedule_rounded,
          keyboardType: TextInputType.datetime,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: pobController,
          label: 'Place of Birth',
          hint: 'City, Country',
          icon: Icons.place_rounded,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return ProfileSection(
      title: 'Contact Information',
      icon: Icons.contact_mail_rounded,
      children: [
        AppTextField(
          controller: emailController,
          label: 'Email Address',
          hint: 'your@email.com',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: phoneController,
          label: 'Phone Number',
          hint: '+977 98XXXXXXXX',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: currentAddressController,
          label: 'Current-Address',
          hint: 'Your current address',
          icon: Icons.home_rounded,
          maxLines: 2,
          onChanged: (_) => setState(() {}),
        ),
        AppTextField(
          controller: permanentAddressController,
          label: 'Permanent-Address',
          hint: 'Your current address',
          icon: Icons.home_rounded,
          maxLines: 2,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  void _showImagePicker() {
    ImageSourceSheet.show(
      context: context,
      onCameraTap: () => _pickImage(ImageSource.camera),
      onGalleryTap: () => _pickImage(ImageSource.gallery),
      onRemoveTap: profileImage != null
          ? () {
              _profileBloc.add(RemoveProfilePhotoEvent());
            }
          : null,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });

      // Upload the photo
      _profileBloc.add(UploadProfilePhotoEvent(File(image.path)));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    int selectedOption = 0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.backgroundGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryPurple.withOpacity(0.15),
                      AppColors.deepPurple.withOpacity(0.08),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select Calendar Type',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedOption = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: selectedOption == 0
                                    ? AppColors.primaryPurple.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'B.S. (Nepali)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedOption = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: selectedOption == 1
                                    ? AppColors.primaryPurple.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'A.D. (English)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              if (selectedOption == 0) {
                                await _selectNepaliDate(context);
                              } else {
                                await _selectGregorianDate(context);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryPurple.withOpacity(0.3),
                                    AppColors.deepPurple,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
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
          );
        },
      ),
    );
  }

  Future<void> _selectNepaliDate(BuildContext context) async {
    final NepaliDateTime? picked = await showAdaptiveDatePicker(
      context: context,
      initialDate: NepaliDateTime.now(),
      firstDate: NepaliDateTime(2000),
      lastDate: NepaliDateTime.now(),
      dateOrder: DateOrder.mdy,
      initialDatePickerMode: DatePickerMode.day,
    );

    if (picked != null) {
      setState(() {
        dobController.text = NepaliDateFormat('yyyy/MM/dd').format(picked);
      });
    }
  }

  Future<void> _selectGregorianDate(BuildContext context) async {
    DateTime? pickedDate;
    await showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.15),
                    AppColors.deepPurple.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: EdgeInsets.all(16),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: Colors.white,
                    onPrimary: AppColors.primaryPurple,
                    surface: Colors.transparent,
                    onSurface: Colors.white,
                  ),
                  textTheme: TextTheme(
                    bodyLarge: TextStyle(color: Colors.white),
                    bodyMedium: TextStyle(color: Colors.white70),
                    titleMedium: TextStyle(color: Colors.white),
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  onDateChanged: (date) {
                    pickedDate = date;
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    if (pickedDate != null) {
      dobController.text =
          "${pickedDate!.year}/${pickedDate!.month.toString().padLeft(2, '0')}/${pickedDate!.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  int _calculateFilledFields() {
    int count = 0;
    if (nameController.text.isNotEmpty) count++;
    if (dobController.text.isNotEmpty) count++;
    if (tobController.text.isNotEmpty) count++;
    if (pobController.text.isNotEmpty) count++;
    if (emailController.text.isNotEmpty) count++;
    if (phoneController.text.isNotEmpty) count++;
    if (horoscopeController.text.isNotEmpty) count++;
    if (currentAddressController.text.isNotEmpty) count++;
    if (permanentAddressController.text.isNotEmpty) count++;
    if (selectedGender != null) count++;
    return count;
  }

  void populateFields(dynamic state) {
    final user = state.user;

    nameController.text = user.name ?? '';
    emailController.text = user.email ?? '';

    if (user.dateOfBirth != null) {
      dobController.text =
          "${user.dateOfBirth!.year}/${user.dateOfBirth!.month.toString().padLeft(2, '0')}/${user.dateOfBirth!.day.toString().padLeft(2, '0')}";
    } else {
      dobController.clear();
    }

    tobController.text = user.timeOfBirth ?? '';
    pobController.text = user.placeOfBirth ?? '';
    phoneController.text = user.phone ?? '';
    horoscopeController.text = user.zodiacSign ?? '';
    currentAddressController.text = state.user.currentAddress ?? '';
    permanentAddressController.text = state.user.currentAddress ?? '';
    selectedGender = user.gender;

    if (user.profilePhoto != null && user.profilePhoto!.isNotEmpty) {
      profileImage = File(user.profilePhoto!);
    } else {
      profileImage = null;
    }

    setState(() {});
  }

  void _populateFields(ProfileLoadedState state) {
    nameController.text = state.user.name ?? '';
    emailController.text = state.user.email ?? '';

    // Handle date formatting - assuming dateOfBirth is DateTime
    if (state.user.dateOfBirth != null) {
      dobController.text =
          "${state.user.dateOfBirth!.year}/${state.user.dateOfBirth!.month.toString().padLeft(2, '0')}/${state.user.dateOfBirth!.day.toString().padLeft(2, '0')}";
    }

    tobController.text = state.user.timeOfBirth ?? '';
    pobController.text = state.user.placeOfBirth ?? '';

    // These fields might not exist in ProfileModel, adjust based on your model
    phoneController.text = state.user.phoneNumber ?? '';
    horoscopeController.text = state.user.zodiacSign ?? '';
    currentAddressController.text = state.user.currentAddress ?? '';
    permanentAddressController.text = state.user.currentAddress ?? '';
    selectedGender = state.user.gender;

    if (state.user.profilePhoto != null &&
        state.user.profilePhoto!.isNotEmpty) {
      // If profilePhoto is a URL, you might need to handle it differently
      // For now, assuming it's a local path
      profileImage = File(state.user.profilePhoto!);
    }

    setState(() {});
  }

  void _populateFieldsFromUpdated(ProfileUpdatedState state) {
    nameController.text = state.user.name ?? '';
    emailController.text = state.user.email ?? '';
    setState(() {});
  }

  void _populateFieldsFromSetup(ProfileSetupSuccessState state) {
    nameController.text = state.user.name ?? '';
    emailController.text = state.user.email ?? '';

    if (state.user.dateOfBirth != null) {
      dobController.text =
          "${state.user.dateOfBirth!.year}/${state.user.dateOfBirth!.month.toString().padLeft(2, '0')}/${state.user.dateOfBirth!.day.toString().padLeft(2, '0')}";
    }

    tobController.text = state.user.timeOfBirth ?? '';
    pobController.text = state.user.placeOfBirth ?? '';
    phoneController.text = state.user.phoneNumber ?? '';
    horoscopeController.text = state.user.zodiacSign ?? '';
    currentAddressController.text = state.user.currentAddress ?? '';
    permanentAddressController.text = state.user.permanentAddress ?? '';
    selectedGender = state.user.gender;

    if (state.user.profilePhoto != null &&
        state.user.profilePhoto!.isNotEmpty) {
      profileImage = File(state.user.profilePhoto!);
    }

    setState(() {});
  }

  void _saveProfile() {
    // Check if this is initial setup or update
    final currentState = _profileBloc.state;

    if (currentState is ProfileInitialState ||
        currentState is ProfileErrorState) {
      // Complete profile setup
      _profileBloc.add(
        CompleteProfileSetupEvent(
          name: nameController.text,
          email: emailController.text,
          dateOfBirth: dobController.text,
          timeOfBirth: tobController.text,
          placeOfBirth: pobController.text,
          currentAddress: currentAddressController.text,
          permanentAddress: permanentAddressController.text,
          profilePhoto: profileImage,
          zoadicSign: zoadicSignController.text,
          gender: genderController.text,
        ),
      );
    } else {
      // Update existing profile - update basic info
      _profileBloc.add(
        UpdateUserProfileEvent(
          name: nameController.text,
          email: emailController.text,
        ),
      );

      // Update birth details separately
      _profileBloc.add(
        UpdateBirthDetailsEvent(
          zoadicSign: zoadicSignController.text,
          gender: genderController.text,
          dateOfBirth: dobController.text,
          timeOfBirth: tobController.text,
          placeOfBirth: pobController.text,
          currentAddress: currentAddressController.text,
          permanentAddress: permanentAddressController.text,
        ),
      );
    }
  }
}
