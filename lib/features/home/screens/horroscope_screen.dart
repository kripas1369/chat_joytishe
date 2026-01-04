import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:flutter/material.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/star_field_background.dart';

class HoroscopeScreen extends StatefulWidget {
  const HoroscopeScreen({super.key});

  @override
  State<HoroscopeScreen> createState() => _HoroscopeGridScreenState();
}

class _HoroscopeGridScreenState extends State<HoroscopeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final List<Map<String, String>> zodiacList = [
    {'name': 'Aries', 'icon': '♈'},
    {'name': 'Taurus', 'icon': '♉'},
    {'name': 'Gemini', 'icon': '♊'},
    {'name': 'Cancer', 'icon': '♋'},
    {'name': 'Leo', 'icon': '♌'},
    {'name': 'Virgo', 'icon': '♍'},
    {'name': 'Libra', 'icon': '♎'},
    {'name': 'Scorpio', 'icon': '♏'},
    {'name': 'Sagittarius', 'icon': '♐'},
    {'name': 'Capricorn', 'icon': '♑'},
    {'name': 'Aquarius', 'icon': '♒'},
    {'name': 'Pisces', 'icon': '♓'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                SizedBox(height: 16),
                Expanded(child: _zodiacGrid()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(width: 16),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, AppColors.lightPurple],
            ).createShader(bounds),
            child: Text(
              'Horoscope',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zodiacGrid() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: zodiacList.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final zodiac = zodiacList[index];
        return _zodiacCard(index, zodiac['name']!, zodiac['icon']!);
      },
    );
  }

  Widget _zodiacCard(int index, String name, String icon) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryPurple.withOpacity(0.4),
              AppColors.deepPurple.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 26)),
            SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
