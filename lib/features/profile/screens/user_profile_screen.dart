import 'dart:io';
import 'package:chat_jyotishi/features/auth/widgets/input_field.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants/constant.dart';
import '../../auth/widgets/star_field_background.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  File? profileImage;
  final ImagePicker picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StarFieldBackground(),
          SafeArea(
            child: Column(
              children: [
                _profileHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _profileCard(),
                        SizedBox(height: 28),
                        _infoCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8),
          Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 30,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white24,
                backgroundImage: profileImage != null
                    ? FileImage(profileImage!)
                    : null,
                child: profileImage == null
                    ? Icon(Icons.person, size: 48, color: Colors.white)
                    : null,
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: InkWell(
                  onTap: () => _showImageSourceSheet(context),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: gold,
                    child: Icon(Icons.edit, size: 16, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Praveen Shrestha',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              _infoRow(icon: Icons.person, label: 'Full Name', value: ''),
              _infoRow(
                icon: Icons.calendar_month,
                label: 'Date of Birth (YYYY/MM/DD)',
                value: '',
              ),
              _infoRow(icon: Icons.place, label: 'Place of Birth', value: ''),

              _infoRow(icon: Icons.email_outlined, label: 'Email', value: ''),

              _infoRow(icon: Icons.phone_outlined, label: 'Phone', value: ''),

              _infoRow(icon: Icons.auto_awesome, label: 'Horoscope', value: ''),

              _infoRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: '',
              ),
            ],
          ),
        ),
        SizedBox(height: 18),
        SizedBox(
          width: 260,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: Colors.black,
              minimumSize: Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'SAVE CHANGES',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [InputField(label: label, prefixIcon: icon)],
            ),
          ),
          // Icon(Icons.edit, color: gold, size: 18),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(color: Colors.white24, height: 1);
  }

  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _sheetItem(
                      Icons.camera_alt,
                      'Camera',
                      ImageSource.camera,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _sheetItem(
                      Icons.photo_library,
                      'Gallery',
                      ImageSource.gallery,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetItem(IconData icon, String title, ImageSource source) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: gold, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
    }
  }
}
