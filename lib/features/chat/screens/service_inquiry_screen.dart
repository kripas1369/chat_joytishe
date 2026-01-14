import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/chat/service/chat_lock_service.dart';
import 'package:flutter/material.dart';

/// Service Inquiry Screen
/// Shown when Jyotish takes too long to respond
/// Allows user to send inquiry to customer support
class ServiceInquiryScreen extends StatefulWidget {
  final String jyotishName;
  final String jyotishId;

  const ServiceInquiryScreen({
    super.key,
    required this.jyotishName,
    required this.jyotishId,
  });

  @override
  State<ServiceInquiryScreen> createState() => _ServiceInquiryScreenState();
}

class _ServiceInquiryScreenState extends State<ServiceInquiryScreen> {
  final TextEditingController _inquiryController = TextEditingController();
  final ChatLockService _chatLockService = ChatLockService();
  bool _isSending = false;
  bool _inquirySent = false;

  @override
  void dispose() {
    _inquiryController.dispose();
    super.dispose();
  }

  Future<void> _sendInquiry() async {
    final inquiry = _inquiryController.text.trim();
    if (inquiry.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your inquiry'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // TODO: Send inquiry to backend customer support
      // For now, just simulate a delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isSending = false;
          _inquirySent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send inquiry. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelAndUnlock() async {
    // Unlock chats and go back
    await _chatLockService.unlockChats();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StarFieldBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient.withOpacity(0.9),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _inquirySent ? _buildSuccessView() : _buildInquiryForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Header
        Row(
          children: [
            GlassIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 16),
            Text(
              'Service Inquiry',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Warning Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withOpacity(0.2),
                Colors.deepOrange.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Icon(Icons.access_time_rounded, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                'Delayed Response',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.jyotishName} has not responded yet.\nYou can send an inquiry to our support team.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Inquiry Text Field
        Text(
          'Your Inquiry',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TextField(
            controller: _inquiryController,
            maxLines: 5,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Describe your issue or concern...',
              hintStyle: TextStyle(color: Colors.white38),
              contentPadding: const EdgeInsets.all(16),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Send Inquiry Button
        GestureDetector(
          onTap: _isSending ? null : _sendInquiry,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _isSending
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Send Inquiry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Cancel and continue waiting button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Center(
              child: Text(
                'Continue Waiting',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),

        // Cancel chat option
        Center(
          child: TextButton(
            onPressed: _cancelAndUnlock,
            child: Text(
              'Cancel Chat & Try Another Jyotish',
              style: TextStyle(color: Colors.red.shade300, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.2),
                Colors.green.withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 64,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Inquiry Sent!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Our support team will review your inquiry\nand get back to you soon.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Continue Waiting',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _cancelAndUnlock,
          child: Text(
            'Cancel & Try Another Jyotish',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
