import 'package:flutter/material.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/star_field_background.dart';

class HoroscopeScreen extends StatefulWidget {
  const HoroscopeScreen({super.key});

  @override
  State<HoroscopeScreen> createState() => _HoroscopeGridScreenState();
}

class _HoroscopeGridScreenState extends State<HoroscopeScreen> {
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

  int hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StarFieldBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient.withOpacity(0.8),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context),
                SizedBox(height: 16),
                Expanded(child: _zodiacGrid()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8),
          Text(
            'Horoscopes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
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
    bool isHovered = hoveredIndex == index;

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
          border: Border.all(color: Colors.white24),
          boxShadow: isHovered
              ? [BoxShadow(color: gold, blurRadius: 16, spreadRadius: 4)]
              : [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: Offset(0, 3),
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
