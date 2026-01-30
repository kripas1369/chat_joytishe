import 'dart:io';
import 'dart:ui';
import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/app_night_mode_overlay.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/home/screens/welcome_screen.dart';
import 'package:chat_jyotishi/features/profile/bloc/profile_bloc.dart';
import 'package:chat_jyotishi/features/profile/bloc/profile_events.dart';
import 'package:chat_jyotishi/features/profile/bloc/profile_states.dart';
import 'package:chat_jyotishi/features/profile/repository/profile_repository.dart';
import 'package:chat_jyotishi/features/profile/service/profile_service.dart';
import 'package:chat_jyotishi/features/profile/widgets/profile_widgets.dart';

import 'package:flutter/material.dart' hide TextField;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart'
    hide CalendarDatePicker;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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
  String? networkProfileImage;
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
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
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

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
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
        systemNavigationBarColor: AppColors.primaryBlack,
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
          // Reload profile to get fresh data from server
          _profileBloc.add(LoadCurrentUserProfileEvent());
          Future.delayed(const Duration(milliseconds: 600), () {});
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => WelcomeScreen()),
          );
        } else if (state is BirthDetailsUpdatedState) {
          showTopSnackBar(
            context: context,
            message: 'Profile updated successfully!',
            backgroundColor: AppColors.success,
            icon: Icons.check_circle,
          );
          // Reload profile to get fresh data from server
          _profileBloc.add(LoadCurrentUserProfileEvent());
        } else if (state is ProfilePhotoUploadedState) {
          showTopSnackBar(
            context: context,
            message: 'Photo uploaded successfully!',
            backgroundColor: AppColors.success,
            icon: Icons.check_circle,
          );
          // Reload profile to get updated data
          _profileBloc.add(LoadCurrentUserProfileEvent());
        } else if (state is ProfilePhotoRemovedState) {
          showTopSnackBar(
            context: context,
            message: 'Photo removed successfully!',
            backgroundColor: AppColors.success,
            icon: Icons.check_circle,
          );
          setState(() => profileImage = null);
          _profileBloc.add(LoadCurrentUserProfileEvent());
        } else if (state is ProfileSetupSuccessState) {
          showTopSnackBar(
            context: context,
            message: state.message,
            backgroundColor: AppColors.success,
            icon: Icons.check_circle,
          );
          // Reload profile to get fresh data from server
          _profileBloc.add(LoadCurrentUserProfileEvent());
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
          backgroundColor: AppColors.primaryBlack,
          body: Stack(
            children: [
              // Star field background
              // StarFieldBackground(),
              // Cosmic gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      AppColors.cosmicPurple.withOpacity(0.3),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // buildNightModeOverlay(),
              // Decorative top glow
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
                            AppColors.cosmicPink.withOpacity(
                              0.2 * _pulseAnimation.value,
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
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                ProfileAvatar(
                                  localImage: profileImage,
                                  // File?
                                  networkImage: networkProfileImage,
                                  // String?
                                  pulseAnimation: _pulseAnimation,
                                  displayName: nameController.text.isEmpty
                                      ? 'Your Name'
                                      : nameController.text,
                                  displayEmail: emailController.text.isEmpty
                                      ? 'Add your email'
                                      : emailController.text,
                                  onTap: _showImagePicker,
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
                                const SizedBox(height: 24),
                                _buildFooterInfo(),
                                const SizedBox(height: 40),
                              ],
                            ),
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

  Widget _buildFooterInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Icon(
              Icons.auto_awesome,
              size: 14,
              color: AppColors.cosmicPink.withOpacity(
                0.5 + (_pulseAnimation.value * 0.3),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.purple300.withOpacity(0.7),
              AppColors.pink300.withOpacity(0.7),
            ],
          ).createShader(bounds),
          child: const Text(
            'Your cosmic identity awaits…',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Icon(
              Icons.auto_awesome,
              size: 14,
              color: AppColors.cosmicPink.withOpacity(
                0.5 + (_pulseAnimation.value * 0.3),
              ),
            );
          },
        ),
      ],
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
          hint: 'HH:MM',
          icon: Icons.schedule_rounded,
          readOnly: true,
          onTap: () => _selectTime(context),
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
          readOnly: true,
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
        const SizedBox(height: 16),
        AppTextField(
          controller: permanentAddressController,
          label: 'Permanent-Address',
          hint: 'Your Permanent address',
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
      imageQuality: 100,
    );

    if (image == null) return;

    debugPrint('--- PICKED IMAGE ---');
    debugPrint('XFile path: ${image.path}');
    debugPrint('XFile name: ${image.name}');
    debugPrint('XFile mimeType: ${image.mimeType}');
    debugPrint('XFile length: ${await image.length()} bytes');

    File original = File(image.path);

    debugPrint('Original file extension: ${path.extension(original.path)}');

    File jpegImage = await _convertToJpeg(original);

    debugPrint('--- AFTER JPEG CONVERSION ---');
    debugPrint('JPEG path: ${jpegImage.path}');
    debugPrint('JPEG extension: ${path.extension(jpegImage.path)}');
    debugPrint('JPEG size: ${await jpegImage.length()} bytes');

    setState(() {
      profileImage = jpegImage;
    });

    _profileBloc.add(UploadProfilePhotoEvent(jpegImage));
  }

  Future<File> _convertToJpeg(File file) async {
    final bytes = await file.readAsBytes();

    debugPrint('Converting image...');
    debugPrint('Input bytes length: ${bytes.length}');

    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      debugPrint('❌ Failed to decode image');
      throw Exception('Invalid image');
    }

    debugPrint(
      'Decoded image → width: ${decodedImage.width}, height: ${decodedImage.height}',
    );

    final dir = await getTemporaryDirectory();
    final newPath = path.join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}.JPEG',
    );

    final jpegFile = File(newPath);
    await jpegFile.writeAsBytes(img.encodeJpg(decodedImage, quality: 85));

    debugPrint('JPEG written at: $newPath');

    return jpegFile;
  }

  Future<void> _selectDate(BuildContext context) async {
    int selectedOption = 0;

    await showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.cosmicPurple.withOpacity(0.2),
                      AppColors.cosmicPink.withOpacity(0.15),
                      AppColors.cosmicRed.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.cosmicPurple.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cosmicPurple.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.cosmicHeroGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [AppColors.purple300, AppColors.pink300],
                          ).createShader(bounds),
                          child: const Text(
                            'Select Calendar Type',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedOption = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                gradient: selectedOption == 0
                                    ? AppColors.cosmicHeroGradient
                                    : null,
                                color: selectedOption == 0
                                    ? null
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selectedOption == 0
                                      ? AppColors.cosmicPink
                                      : Colors.white.withOpacity(0.1),
                                  width: selectedOption == 0 ? 1.5 : 1,
                                ),
                                boxShadow: selectedOption == 0
                                    ? [
                                        BoxShadow(
                                          color: AppColors.cosmicPurple
                                              .withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'B.S. (Nepali)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                gradient: selectedOption == 1
                                    ? AppColors.cosmicHeroGradient
                                    : null,
                                color: selectedOption == 1
                                    ? null
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selectedOption == 1
                                      ? AppColors.cosmicPink
                                      : Colors.white.withOpacity(0.1),
                                  width: selectedOption == 1 ? 1.5 : 1,
                                ),
                                boxShadow: selectedOption == 1
                                    ? [
                                        BoxShadow(
                                          color: AppColors.cosmicPurple
                                              .withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.calendar_month,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'A.D. (English)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: AppColors.textGray300,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.cosmicPrimaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cosmicPurple.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                if (selectedOption == 0) {
                                  await _selectNepaliDate(context);
                                } else {
                                  await _selectGregorianDate(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
      barrierColor: Colors.black54,
      builder: (_) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cosmicPurple.withOpacity(0.2),
                    AppColors.cosmicPink.withOpacity(0.15),
                    AppColors.cosmicRed.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.cosmicPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: AppColors.cosmicPink,
                    onPrimary: Colors.white,
                    surface: Colors.transparent,
                    onSurface: Colors.white,
                  ),
                  textTheme: const TextTheme(
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

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.cosmicPink,
              onPrimary: Colors.white,
              surface: AppColors.primaryBlack,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');

      setState(() {
        tobController.text = '$hour:$minute'; // ✅ HH:MM
      });
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
    phoneController.text = user.phoneNumber ?? '';
    horoscopeController.text = user.zodiacSign ?? '';
    currentAddressController.text = state.user.currentAddress ?? '';
    permanentAddressController.text = state.user.currentAddress ?? '';
    selectedGender = user.gender;

    profileImage = null; // ALWAYS reset local file

    if (user.profilePhoto != null && user.profilePhoto!.isNotEmpty) {
      networkProfileImage = user.profilePhoto;
    } else {
      networkProfileImage = null;
    }
    setState(() {});
  }

  void _saveProfile() {
    final currentState = _profileBloc.state;

    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        dobController.text.isEmpty ||
        tobController.text.isEmpty ||
        pobController.text.isEmpty ||
        currentAddressController.text.isEmpty ||
        permanentAddressController.text.isEmpty ||
        selectedGender == null ||
        selectedGender!.isEmpty) {
      showTopSnackBar(
        context: context,
        message: 'Please fill all required fields.',
        backgroundColor: AppColors.error,
        icon: Icons.error,
      );
      return; // Stop if validation fails
    }

    final genderForApi = selectedGender!;

    final isFirstTimeSetup =
        currentState is ProfileLoadedState &&
        !currentState.user.profileCompleted;

    if (isFirstTimeSetup) {
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
          zoadicSign: horoscopeController.text,
          gender: genderForApi,
        ),
      );
      return;
    }

    _profileBloc.add(
      UpdateUserProfileEvent(
        name: nameController.text,
        email: emailController.text,
      ),
    );

    _profileBloc.add(
      UpdateBirthDetailsEvent(
        zoadicSign: horoscopeController.text,
        gender: genderForApi,
        dateOfBirth: dobController.text,
        timeOfBirth: tobController.text,
        placeOfBirth: pobController.text,
        currentAddress: currentAddressController.text,
        permanentAddress: permanentAddressController.text,
      ),
    );
  }
}
