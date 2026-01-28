import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/payment/screens/qr_code_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _coinController = TextEditingController();
  int _selectedCoins = 0;
  int _selectedPackageIndex = -1;

  final List<Map<String, dynamic>> _packages = [
    {'coins': 10, 'price': 1000, 'popular': false},
    {'coins': 25, 'price': 2500, 'popular': true},
    {'coins': 50, 'price': 5000, 'popular': false},
  ];

  void _setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.primaryBlack,
      ),
    );
  }

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  void _selectPackage(int index) {
    setState(() {
      _selectedPackageIndex = index;
      _selectedCoins = _packages[index]['coins'];
      _coinController.text = _selectedCoins.toString();
    });
  }

  void _onCustomAmountChanged(String value) {
    final coins = int.tryParse(value) ?? 0;
    setState(() {
      _selectedCoins = coins;
      _selectedPackageIndex = -1;
    });
  }

  int get _totalAmount => _selectedCoins * 100;

  void _proceedToPayment() {
    if (_selectedCoins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid coin amount'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRCodePage(
          coins: _selectedCoins,
          amount: _totalAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlay();
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Stack(
        children: [
          const StarFieldBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.75),
                  AppColors.cosmicPurple.withOpacity(0.28),
                  AppColors.cosmicPink.withOpacity(0.18),
                  Colors.black.withOpacity(0.92),
                ],
                stops: const [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildTitleSection(),
                    const SizedBox(height: 24),
                    _buildCustomAmountSection(),
                    const SizedBox(height: 20),
                    _buildPackagesSection(),
                    const SizedBox(height: 24),
                    _buildSummaryCard(),
                    const SizedBox(height: 18),
                    _buildPayButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GlassIconButton(
          onTap: () => Navigator.pop(context),
          icon: Icons.arrow_back,
        ),
        const SizedBox(width: 14),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.purple300,
              AppColors.pink300,
              AppColors.red300,
            ],
          ).createShader(bounds),
          child: const Text(
            'Add Coins',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    BorderRadiusGeometry borderRadius = const BorderRadius.all(
      Radius.circular(20),
    ),
    List<Color>? gradientColors,
  }) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors ??
                  [
                    Colors.white.withOpacity(0.10),
                    Colors.white.withOpacity(0.05),
                    Colors.black.withOpacity(0.20),
                  ],
            ),
            borderRadius: borderRadius,
            border: Border.all(
              color: AppColors.cosmicPurple.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cosmicPurple.withOpacity(0.18),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return _glassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(22),
      gradientColors: [
        AppColors.cosmicPurple.withOpacity(0.22),
        AppColors.cosmicPink.withOpacity(0.14),
        Colors.black.withOpacity(0.28),
      ],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.cosmicPrimaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cosmicPurple.withOpacity(0.45),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.monetization_on_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 14),
          ShaderMask(
            shaderCallback: (bounds) => AppColors.cosmicPrimaryGradient
                .createShader(bounds),
            child: const Text(
              'Add Coins for Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '1 Coin = Rs 100',
            style: TextStyle(
              color: gold,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Purchase coins to chat with astrologers',
            style: TextStyle(
              color: AppColors.textGray300,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Custom Amount',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _glassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          borderRadius: BorderRadius.circular(16),
          gradientColors: [
            AppColors.cosmicPurple.withOpacity(0.16),
            AppColors.cosmicPink.withOpacity(0.10),
            Colors.black.withOpacity(0.20),
          ],
          child: Row(
            children: [
              Icon(
                Icons.monetization_on_outlined,
                color: gold,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _coinController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'Enter number of coins',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                  onChanged: _onCustomAmountChanged,
                ),
              ),
              Text(
                'coins',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Or Choose a Package',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Column(
          children: List.generate(_packages.length, (index) {
            return _buildPackageCard(index);
          }),
        ),
      ],
    );
  }

  Widget _buildPackageCard(int index) {
    final package = _packages[index];
    final isSelected = _selectedPackageIndex == index;
    final isPopular = package['popular'] as bool;

    return GestureDetector(
      onTap: () => _selectPackage(index),
      child: _glassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(18),
        gradientColors: isSelected
            ? [
                AppColors.cosmicPurple.withOpacity(0.30),
                AppColors.cosmicPink.withOpacity(0.20),
                Colors.black.withOpacity(0.22),
              ]
            : [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.04),
                Colors.black.withOpacity(0.20),
              ],
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? AppColors.cosmicPurple : Colors.white38,
                  width: 2,
                ),
                color: isSelected ? AppColors.cosmicPurple : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 16),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.monetization_on_rounded,
                color: gold,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${package['coins']} Coins',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.cosmicHeroGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'POPULAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Rs ${package['price']}',
                    style: TextStyle(
                      color: gold,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return _glassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(20),
      gradientColors: [
        Colors.white.withOpacity(0.10),
        AppColors.cosmicPurple.withOpacity(0.10),
        Colors.black.withOpacity(0.22),
      ],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coins to Purchase',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.monetization_on, color: gold, size: 18),
                  SizedBox(width: 4),
                  Text(
                    '$_selectedCoins',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(color: Colors.white12),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Rs $_totalAmount',
                style: TextStyle(
                  color: gold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return GestureDetector(
      onTap: _selectedCoins > 0 ? _proceedToPayment : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _selectedCoins > 0
              ? AppColors.cosmicHeroGradient
              : LinearGradient(
                  colors: [Colors.grey, Colors.grey.shade700],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _selectedCoins > 0
              ? [
                  BoxShadow(
                    color: AppColors.cosmicRed.withOpacity(0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: AppColors.cosmicPurple.withOpacity(0.35),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_rounded, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'Proceed to Pay',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
