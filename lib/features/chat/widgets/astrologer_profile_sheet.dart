import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_endpoints.dart';
import '../../../constants/constant.dart';
import '../models/astrologer_profile_model.dart';
import '../service/chat_service.dart';

/// Shows a bottom sheet with astrologer profile details
Future<void> showAstrologerProfileSheet({
  required BuildContext context,
  required String astrologerId,
  required String astrologerName,
  String? astrologerPhoto,
  bool isOnline = false,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AstrologerProfileSheet(
      astrologerId: astrologerId,
      astrologerName: astrologerName,
      astrologerPhoto: astrologerPhoto,
      isOnline: isOnline,
    ),
  );
}

class AstrologerProfileSheet extends StatefulWidget {
  final String astrologerId;
  final String astrologerName;
  final String? astrologerPhoto;
  final bool isOnline;

  const AstrologerProfileSheet({
    super.key,
    required this.astrologerId,
    required this.astrologerName,
    this.astrologerPhoto,
    this.isOnline = false,
  });

  @override
  State<AstrologerProfileSheet> createState() => _AstrologerProfileSheetState();
}

class _AstrologerProfileSheetState extends State<AstrologerProfileSheet> {
  AstrologerProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Initialize chat service with Dio
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final refreshToken = prefs.getString('refreshToken');

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (accessToken != null && refreshToken != null)
              'cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
          },
        ),
      );

      ChatService().initialize(dio);
      final profile = await ChatService().getAstrologerProfile(widget.astrologerId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          // Create basic profile from available data
          _profile = AstrologerProfile.fromBasicData(
            id: widget.astrologerId,
            name: widget.astrologerName,
            profilePhoto: widget.astrologerPhoto,
            isOnline: widget.isOnline,
          );
        });
      }
    }
  }

  String _getImageUrl(String? photo) {
    if (photo == null || photo.isEmpty) return '';
    if (photo.startsWith('http')) return photo;
    return '${ApiEndpoints.socketUrl}$photo';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.cardDark,
            AppColors.backgroundDark,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppColors.primaryPurple.withAlpha(51),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Content
          Flexible(
            child: _isLoading
                ? _buildLoading()
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: _buildProfileContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primaryPurple),
          const SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final profile = _profile;
    if (profile == null) return const SizedBox.shrink();

    final imageUrl = _getImageUrl(profile.profilePhoto ?? widget.astrologerPhoto);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile header with image
        _buildProfileHeader(profile, imageUrl),
        const SizedBox(height: 20),

        // Online status and type badge
        _buildStatusRow(profile),
        const SizedBox(height: 20),

        // Stats row
        _buildStatsRow(profile),
        const SizedBox(height: 20),

        // Info cards
        if (profile.bio != null && profile.bio!.isNotEmpty)
          _buildInfoCard(
            icon: Icons.person_outline,
            title: 'About',
            content: profile.bio!,
          ),

        if (profile.specialization != null && profile.specialization!.isNotEmpty)
          _buildInfoCard(
            icon: Icons.auto_awesome,
            title: 'Specialization',
            content: profile.specialization!,
          ),

        if (profile.expertise.isNotEmpty)
          _buildExpertiseCard(profile.expertise),

        if (profile.languages != null && profile.languages!.isNotEmpty)
          _buildInfoCard(
            icon: Icons.language,
            title: 'Languages',
            content: profile.languages!,
          ),

        if (profile.experience > 0)
          _buildInfoCard(
            icon: Icons.work_history_outlined,
            title: 'Experience',
            content: '${profile.experience} years',
          ),

        // Chat cost info
        _buildChatCostCard(profile),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProfileHeader(AstrologerProfile profile, String imageUrl) {
    return Column(
      children: [
        // Profile image with online indicator
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withAlpha(77),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildInitialsAvatar(profile.name),
                      )
                    : _buildInitialsAvatar(profile.name),
              ),
            ),
            // Online indicator
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: (profile.isOnline || widget.isOnline)
                      ? Colors.green
                      : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardDark, width: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          profile.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Type badge
        Text(
          profile.typeDisplayName,
          style: TextStyle(
            color: gold,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsAvatar(String name) {
    return Container(
      color: AppColors.cardMedium,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusRow(AstrologerProfile profile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatusChip(
          icon: Icons.circle,
          label: (profile.isOnline || widget.isOnline) ? 'Online' : 'Offline',
          color: (profile.isOnline || widget.isOnline) ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 12),
        if (profile.rating > 0)
          _buildStatusChip(
            icon: Icons.star_rounded,
            label: profile.rating.toStringAsFixed(1),
            color: Colors.amber,
          ),
      ],
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AstrologerProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple.withAlpha(26),
            AppColors.deepPurple.withAlpha(13),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryPurple.withAlpha(51),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            value: profile.totalConsultations.toString(),
            label: 'Consultations',
            icon: Icons.chat_bubble_outline,
          ),
          _buildStatDivider(),
          _buildStatItem(
            value: profile.totalReviews.toString(),
            label: 'Reviews',
            icon: Icons.rate_review_outlined,
          ),
          _buildStatDivider(),
          _buildStatItem(
            value: '${profile.experience}+',
            label: 'Years Exp.',
            icon: Icons.workspace_premium_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryPurple, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white12,
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardMedium.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryPurple, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertiseCard(List<String> expertise) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardMedium.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, color: AppColors.primaryPurple, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Expertise',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: expertise.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple.withAlpha(51),
                      AppColors.deepPurple.withAlpha(26),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryPurple.withAlpha(77),
                  ),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCostCard(AstrologerProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gold.withAlpha(26),
            gold.withAlpha(13),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold.withAlpha(77)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: gold.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.monetization_on_rounded,
              color: gold,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat Cost',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.chatCostDescription,
                  style: TextStyle(
                    color: gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
