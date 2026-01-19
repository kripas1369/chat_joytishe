import 'package:flutter/material.dart';
import '../../../constants/api_endpoints.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/glass_icon_button.dart';
import '../../app_widgets/star_field_background.dart';
import '../models/astrologer_chat_models.dart';
import '../service/astrologer_chat_service.dart';

/// Client Profile Screen for Astrologers
/// Shows complete birth details and information needed for consultation
class ClientProfileScreen extends StatefulWidget {
  final String clientId;

  const ClientProfileScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final AstrologerChatService _chatService = AstrologerChatService();

  ClientProfileModel? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _chatService.initialize();
      final profile = await _chatService.getClientProfile(widget.clientId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading client profile: $e');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not provided';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatMonthYear(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getZodiacEmoji(String? sign) {
    if (sign == null) return '';

    final zodiacEmojis = {
      'aries': '♈',
      'taurus': '♉',
      'gemini': '♊',
      'cancer': '♋',
      'leo': '♌',
      'virgo': '♍',
      'libra': '♎',
      'scorpio': '♏',
      'sagittarius': '♐',
      'capricorn': '♑',
      'aquarius': '♒',
      'pisces': '♓',
    };

    return zodiacEmojis[sign.toLowerCase()] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StarFieldBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GlassIconButton(
            onTap: () => Navigator.pop(context),
            icon: Icons.arrow_back,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Client Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GlassIconButton(
            onTap: _loadProfile,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryPurple,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.withAlpha(150),
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProfile,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_profile == null) {
      return Center(
        child: Text(
          'Profile not found',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildBirthDetailsCard(),
          const SizedBox(height: 16),
          if (_profile!.zodiacSign != null) ...[
            _buildZodiacCard(),
            const SizedBox(height: 16),
          ],
          if (_profile!.addresses != null && _profile!.addresses!.isNotEmpty)
            _buildAddressCard(),
          const SizedBox(height: 16),
          _buildContactCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final imageUrl = _profile!.profilePhoto != null
        ? (_profile!.profilePhoto!.startsWith('http')
            ? _profile!.profilePhoto!
            : '${ApiEndpoints.socketUrl}${_profile!.profilePhoto}')
        : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withAlpha(50),
            AppColors.deepPurple.withAlpha(30),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryPurple.withAlpha(75),
        ),
      ),
      child: Column(
        children: [
          // Profile Image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryPurple,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withAlpha(75),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildDefaultAvatar(_profile!.name),
                    )
                  : _buildDefaultAvatar(_profile!.name),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _profile!.name ?? 'Unknown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Gender
          if (_profile!.gender != null) ...[
            const SizedBox(height: 4),
            Text(
              _profile!.gender!,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],

          // Member since
          if (_profile!.createdAt != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Member since ${_formatMonthYear(_profile!.createdAt!)}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String? name) {
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : '?';
    return Container(
      color: AppColors.primaryPurple.withAlpha(75),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBirthDetailsCard() {
    return _buildInfoCard(
      title: 'Birth Details',
      icon: Icons.cake_outlined,
      color: Colors.orange,
      children: [
        _buildInfoRow(
          icon: Icons.calendar_today,
          label: 'Birth Date',
          value: _formatDate(_profile!.birthDate),
        ),
        _buildInfoRow(
          icon: Icons.access_time,
          label: 'Birth Time',
          value: _profile!.birthTime ?? 'Not provided',
        ),
        _buildInfoRow(
          icon: Icons.location_on_outlined,
          label: 'Birth Place',
          value: _profile!.birthPlace ?? 'Not provided',
        ),
      ],
    );
  }

  Widget _buildZodiacCard() {
    final emoji = _getZodiacEmoji(_profile!.zodiacSign);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withAlpha(75),
            Colors.indigo.withAlpha(50),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withAlpha(100),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Text(
              emoji,
              style: TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zodiac Sign',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _profile!.zodiacSign!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.auto_awesome,
            color: Colors.amber.withAlpha(200),
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    final addresses = _profile!.addresses!;
    final defaultAddress = addresses.firstWhere(
      (a) => a.isDefault == true,
      orElse: () => addresses.first,
    );

    return _buildInfoCard(
      title: 'Address',
      icon: Icons.home_outlined,
      color: Colors.blue,
      children: [
        if (defaultAddress.street != null)
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Street',
            value: defaultAddress.street!,
          ),
        if (defaultAddress.city != null)
          _buildInfoRow(
            icon: Icons.location_city,
            label: 'City',
            value: defaultAddress.city!,
          ),
        if (defaultAddress.state != null)
          _buildInfoRow(
            icon: Icons.map,
            label: 'State',
            value: defaultAddress.state!,
          ),
        if (defaultAddress.country != null)
          _buildInfoRow(
            icon: Icons.public,
            label: 'Country',
            value: defaultAddress.country!,
          ),
        if (defaultAddress.postalCode != null)
          _buildInfoRow(
            icon: Icons.markunread_mailbox_outlined,
            label: 'Postal Code',
            value: defaultAddress.postalCode!,
          ),
      ],
    );
  }

  Widget _buildContactCard() {
    return _buildInfoCard(
      title: 'Contact Information',
      icon: Icons.contact_phone_outlined,
      color: Colors.green,
      children: [
        if (_profile!.email != null)
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _profile!.email!,
          ),
        if (_profile!.phone != null)
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: _profile!.phone!,
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(40),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white54, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
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
