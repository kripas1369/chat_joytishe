// import 'dart:io';
// import 'package:chat_jyotishi/constants/constant.dart';
// import 'package:chat_jyotishi/features/profile/bloc/profile_bloc.dart';
// import 'package:chat_jyotishi/features/profile/bloc/profile_events.dart';
// import 'package:chat_jyotishi/features/profile/bloc/profile_states.dart';
// import 'package:chat_jyotishi/features/profile/repository/profile_repository.dart';
// import 'package:chat_jyotishi/features/profile/service/profile_service.dart';
// import 'package:chat_jyotishi/features/profile/widgets/profile_widgets.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:image_picker/image_picker.dart';
//
// import '../../app_widgets/show_top_snackBar.dart';
//
// class AstrologerProfileScreen extends StatelessWidget {
//   const AstrologerProfileScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (context) =>
//           ProfileBloc(profileRepository: ProfileRepository(ProfileService())),
//       child: const AstrologerProfileScreenContent(),
//     );
//   }
// }
//
// class AstrologerProfileScreenContent extends StatefulWidget {
//   const AstrologerProfileScreenContent({super.key});
//
//   @override
//   State<AstrologerProfileScreenContent> createState() =>
//       _AstrologerProfileScreenContentState();
// }
//
// class _AstrologerProfileScreenContentState
//     extends State<AstrologerProfileScreenContent>
//     with TickerProviderStateMixin {
//   File? profileImage;
//   final ImagePicker picker = ImagePicker();
//
//   // Common
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController addressController = TextEditingController();
//
//   // Astrologer specific
//   final TextEditingController experienceController = TextEditingController();
//   final TextEditingController expertiseController = TextEditingController();
//   final TextEditingController languagesController = TextEditingController();
//   final TextEditingController bioController = TextEditingController();
//   final TextEditingController priceController = TextEditingController();
//
//   String? selectedGender;
//   bool isAvailable = true;
//
//   late AnimationController _fadeController;
//   late AnimationController _pulseController;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _pulseAnimation;
//   late ProfileBloc _profileBloc; // Will be initialized in initState
//
//   @override
//   void initState() {
//     super.initState();
//
//     _profileBloc = context.read<ProfileBloc>();
//
//     // Initialize animations
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeOut,
//     );
//
//     _pulseController = AnimationController(
//       duration: const Duration(milliseconds: 2000),
//       vsync: this,
//     )
//       ..repeat(reverse: true);
//
//     _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//
//     _fadeController.forward();
//   }
//
//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _pulseController.dispose();
//     nameController.dispose();
//     emailController.dispose();
//     phoneController.dispose();
//     addressController.dispose();
//     experienceController.dispose();
//     expertiseController.dispose();
//     languagesController.dispose();
//     bioController.dispose();
//     priceController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     SystemChrome.setSystemUIOverlayStyle(
//       const SystemUiOverlayStyle(
//         statusBarColor: Colors.transparent,
//         statusBarIconBrightness: Brightness.light,
//       ),
//     );
//     //
//     // return BlocConsumer<ProfileBloc, ProfileState>(
//     //   listener: (context, state) {
//     //     if (state is AstrologerProfileLoadedState) {
//     //       _populateFields(state);
//     //     } else if (state is AstrologerProfileSavedState) {
//     //       showTopSnackBar(
//     //         context: context,
//     //         message: 'Profile saved successfully!',
//     //         backgroundColor: AppColors.success,
//     //         icon: Icons.check_circle,
//     //       );
//     //     } else if (state is ProfileErrorState) {
//     //       showTopSnackBar(
//     //         context: context,
//     //         message: state.message,
//     //         backgroundColor: AppColors.error,
//     //         icon: Icons.error,
//     //       );
//     //     }
//     //   },
//     //   builder: (context, state) {
//     return Scaffold(
//       backgroundColor: AppColors.backgroundDark,
//       body: Stack(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               gradient: AppColors.backgroundGradient,
//             ),
//           ),
//           Positioned(
//             top: -100,
//             left: -50,
//             right: -50,
//             child: AnimatedBuilder(
//               animation: _pulseAnimation,
//               builder: (context, child) {
//                 return Container(
//                   height: 350,
//                   decoration: BoxDecoration(
//                     gradient: RadialGradient(
//                       colors: [
//                         AppColors.primaryPurple.withOpacity(
//                           0.15 * _pulseAnimation.value,
//                         ),
//                         Colors.transparent,
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           SafeArea(
//             child: FadeTransition(
//               opacity: _fadeAnimation,
//               child: Column(
//                 children: [
//                   ProfileHeader(
//                     onBack: () =>
//                         Navigator.pushReplacementNamed(
//                           context,
//                           '/home_screen_astrologer',
//                         ),
//                     onSettings: () {
//                       Navigator.of(
//                         context,
//                       ).pushNamed('/change_password_screen');
//                     },
//                   ),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       physics: const BouncingScrollPhysics(),
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       child: Column(
//                         children: [
//                           const SizedBox(height: 8),
//                           ProfileAvatar(
//                             profileImage: profileImage,
//                             pulseAnimation: _pulseAnimation,
//                             displayName: nameController.text.isEmpty
//                                 ? 'Astrologer Name'
//                                 : nameController.text,
//                             displayEmail: emailController.text.isEmpty
//                                 ? 'Astrologer email'
//                                 : emailController.text,
//                             onTap: () => _showImagePicker(),
//                             localImage: null,
//                             networkImage: '',
//                           ),
//                           const SizedBox(height: 24),
//                           _buildPersonalInfoSection(),
//                           const SizedBox(height: 24),
//                           _buildProfessionalSection(),
//                           const SizedBox(height: 24),
//                           _buildAboutSection(),
//                           const SizedBox(height: 24),
//                           _buildConsultationSection(),
//                           const SizedBox(height: 24),
//                           _buildContactSection(),
//                           const SizedBox(height: 24),
//                           GenderSelector(
//                             selectedGender: selectedGender,
//                             onGenderChanged: (value) {
//                               setState(() => selectedGender = value);
//                             },
//                             options: const ['male', 'female'],
//                           ),
//                           const SizedBox(height: 32),
//                           ProfileSaveButton(
//                             isLoading: state is ProfileLoadingState,
//                             onTap: _saveProfile,
//                           ),
//                           const SizedBox(height: 40),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   ,
//
//   );
// }
//
// Widget _buildPersonalInfoSection() =>
//     ProfileSection(
//       title: 'Personal Information',
//       icon: Icons.person_rounded,
//       children: [
//         AppTextField(
//           controller: nameController,
//           label: 'Full Name',
//           hint: 'Enter your name',
//           icon: Icons.badge_rounded,
//           textCapitalization: TextCapitalization.words,
//           onChanged: (_) => setState(() {}),
//         ),
//       ],
//     );
//
// Widget _buildProfessionalSection() =>
//     ProfileSection(
//       title: 'Professional Details',
//       icon: Icons.workspace_premium_rounded,
//       subtitle: 'Visible to clients',
//       children: [
//         AppTextField(
//           controller: experienceController,
//           label: 'Experience (Years)',
//           hint: 'e.g. 10',
//           icon: Icons.timeline_rounded,
//           keyboardType: TextInputType.number,
//           onChanged: (_) => setState(() {}),
//         ),
//         const SizedBox(height: 16),
//         AppTextField(
//           controller: expertiseController,
//           label: 'Expertise',
//           hint: 'Vedic, Tarot, Numerology',
//           icon: Icons.auto_awesome_rounded,
//           onChanged: (_) => setState(() {}),
//         ),
//         const SizedBox(height: 16),
//         AppTextField(
//           controller: languagesController,
//           label: 'Languages',
//           hint: 'Nepali, Hindi, English',
//           icon: Icons.language_rounded,
//           onChanged: (_) => setState(() {}),
//         ),
//       ],
//     );
//
// Widget _buildAboutSection() =>
//     ProfileSection(
//       title: 'About You',
//       icon: Icons.info_rounded,
//       children: [
//         AppTextField(
//           controller: bioController,
//           label: 'Bio',
//           hint: 'Describe your experience',
//           icon: Icons.edit_note_rounded,
//           maxLines: 3,
//           onChanged: (_) => setState(() {}),
//         ),
//       ],
//     );
//
// Widget _buildConsultationSection() =>
//     ProfileSection(
//       title: 'Consultation Details',
//       icon: Icons.call_rounded,
//       children: [
//         AppTextField(
//           controller: priceController,
//           label: 'Price per minute',
//           hint: 'e.g. 20',
//           icon: Icons.currency_rupee_rounded,
//           keyboardType: TextInputType.number,
//           onChanged: (_) => setState(() {}),
//         ),
//       ],
//     );
//
// Widget _buildContactSection() =>
//     ProfileSection(
//       title: 'Contact Information',
//       icon: Icons.contact_mail_rounded,
//       children: [
//         AppTextField(
//           controller: emailController,
//           label: 'Email',
//           hint: 'astro@email.com',
//           icon: Icons.email_rounded,
//           keyboardType: TextInputType.emailAddress,
//           onChanged: (_) => setState(() {}),
//         ),
//         const SizedBox(height: 16),
//         AppTextField(
//           controller: phoneController,
//           label: 'Phone',
//           hint: '+977 98XXXXXXXX',
//           icon: Icons.phone_rounded,
//           keyboardType: TextInputType.phone,
//           onChanged: (_) => setState(() {}),
//         ),
//         const SizedBox(height: 16),
//         AppTextField(
//           controller: addressController,
//           label: 'Address',
//           hint: 'City, Country',
//           icon: Icons.home_rounded,
//           maxLines: 2,
//           onChanged: (_) => setState(() {}),
//         ),
//       ],
//     );
//
// void _showImagePicker() {
//   ImageSourceSheet.show(
//     context: context,
//     onCameraTap: () => _pickImage(ImageSource.camera),
//     onGalleryTap: () => _pickImage(ImageSource.gallery),
//     onRemoveTap: profileImage != null
//         ? () => setState(() => profileImage = null)
//         : null,
//   );
// }
//
// Future<void> _pickImage(ImageSource source) async {
//   final XFile? image = await picker.pickImage(
//     source: source,
//     imageQuality: 80,
//   );
//
//   if (image != null) {
//     setState(() {
//       profileImage = File(image.path);
//     });
//   }
// }
//
// void _populateFields(AstrologerProfileLoadedState state) {
//   nameController.text = state.profile.name ?? '';
//   emailController.text = state.profile.email ?? '';
//   phoneController.text = state.profile.phone ?? '';
//   addressController.text = state.profile.address ?? '';
//   experienceController.text = state.profile.experienceYears?.toString() ?? '';
//   expertiseController.text = state.profile.expertise ?? '';
//   languagesController.text = state.profile.languages ?? '';
//   bioController.text = state.profile.bio ?? '';
//   priceController.text = state.profile.pricePerMinute?.toString() ?? '';
//   selectedGender = state.profile.gender;
//   isAvailable = state.profile.isAvailable ?? true;
//
//   if (state.profile.profileImagePath != null) {
//     profileImage = File(state.profile.profileImagePath!);
//   }
//
//   setState(() {});
// }
//
// void _saveProfile() {
//   // Use the bloc instance directly
//   // _profileBloc.add(
//   //   SaveAstrologerProfile(
//   //     name: nameController.text,
//   //     email: emailController.text,
//   //     phone: phoneController.text,
//   //     address: addressController.text,
//   //     experienceYears: int.tryParse(experienceController.text),
//   //     expertise: expertiseController.text,
//   //     languages: languagesController.text,
//   //     bio: bioController.text,
//   //     pricePerMinute: double.tryParse(priceController.text),
//   //     gender: selectedGender,
//   //     isAvailable: isAvailable,
//   //     profileImage: profileImage,
//   //   ),
//   // );
// }}
