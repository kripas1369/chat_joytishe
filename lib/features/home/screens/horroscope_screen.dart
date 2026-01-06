import 'package:chat_jyotishi/features/app_widgets/app_button.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:flutter/material.dart';
import '../../../constants/constant.dart';

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
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
      onTap: () => _openHoroscopePopup(name, icon),
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

  void _openHoroscopePopup(String zodiacName, String icon) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Center(
          child: HoroscopeDetailPopup(zodiacName: zodiacName, icon: icon),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(animation.value),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
    );
  }
}

class HoroscopeDetailPopup extends StatefulWidget {
  final String zodiacName;
  final String icon;

  const HoroscopeDetailPopup({
    super.key,
    required this.zodiacName,
    required this.icon,
  });

  @override
  State<HoroscopeDetailPopup> createState() => _HoroscopeDetailPopupState();
}

class _HoroscopeDetailPopupState extends State<HoroscopeDetailPopup> {
  DateTime selectedDate = DateTime.now();

  String _getZodiacDate(String name) {
    final dates = {
      'Aries': 'Mar 21 - Apr 19',
      'Taurus': 'Apr 20 - May 20',
      'Gemini': 'May 21 - Jun 20',
      'Cancer': 'Jun 21 - Jul 22',
      'Leo': 'Jul 23 - Aug 22',
      'Virgo': 'Aug 23 - Sep 22',
      'Libra': 'Sep 23 - Oct 22',
      'Scorpio': 'Oct 23 - Nov 21',
      'Sagittarius': 'Nov 22 - Dec 21',
      'Capricorn': 'Dec 22 - Jan 19',
      'Aquarius': 'Jan 20 - Feb 18',
      'Pisces': 'Feb 19 - Mar 20',
    };
    return dates[name] ?? '';
  }

  String _getFormattedDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);

    if (compareDate == today) return 'Today';
    if (compareDate == today.add(Duration(days: 1))) return 'Tomorrow';
    if (compareDate == today.subtract(Duration(days: 1))) return 'Yesterday';
    return '';
  }

  String _getHoroscopeForDate(DateTime date) {
    final horoscopes = [
      "Today is a favorable day for personal growth. Focus on communication and avoid unnecessary conflicts. A surprise opportunity may arise in the evening. Trust your intuition when making important decisions.",
      "Your creative energy is at its peak today. Express yourself freely and don't hold back your ideas. Romantic prospects look promising. Financial matters require careful attention.",
      "A day of reflection and inner peace awaits you. Take time to meditate and connect with your spiritual side. Family relationships strengthen. Avoid making hasty decisions.",
      "Opportunities for advancement present themselves today. Stay alert and be ready to act quickly. Your leadership qualities shine through. Evening brings pleasant social interactions.",
      "Focus on building strong foundations in your personal and professional life. Patience is your greatest asset today. Someone from your past may reach out with important news.",
      "Your analytical skills are heightened. Use them to solve pending problems. Health and wellness should be prioritized. A financial windfall may surprise you.",
      "Balance is the key theme for today. Harmonize work and personal life for best results. Collaborative efforts yield excellent outcomes. Evening favors relaxation and entertainment.",
    ];

    return horoscopes[date.day % horoscopes.length];
  }

  Map<String, String> _getLuckyElements(DateTime date) {
    final colors = [
      'Purple',
      'Blue',
      'Green',
      'Red',
      'Gold',
      'Silver',
      'Orange',
    ];
    final numbers = ['3', '7', '9', '12', '21', '33', '5'];
    final times = [
      '6-8 AM',
      '10-12 PM',
      '2-4 PM',
      '5-7 PM',
      '8-10 PM',
      '3-5 AM',
      '1-3 PM',
    ];

    return {
      'color': colors[date.day % colors.length],
      'number': numbers[date.day % numbers.length],
      'time': times[date.day % times.length],
    };
  }

  void _changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel = _getDayLabel(selectedDate);
    final luckyElements = _getLuckyElements(selectedDate);

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 30,
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryPurple.withOpacity(0.3),
                AppColors.primaryPurple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.icon,
                    style: TextStyle(
                      fontSize: 64,
                      shadows: [
                        Shadow(
                          color: AppColors.primaryPurple.withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16),

                  Text(
                    widget.zodiacName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    _getZodiacDate(widget.zodiacName),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 20),

                  Divider(color: Colors.white.withOpacity(0.2), thickness: 1),

                  SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _changeDate(-1),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurple.withOpacity(0.3),
                                AppColors.primaryPurple.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryPurple.withOpacity(0.4),
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          if (dayLabel.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primaryPurple.withOpacity(0.4),
                                    AppColors.primaryPurple.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryPurple.withOpacity(
                                    0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                dayLabel,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          SizedBox(height: 8),
                          Text(
                            _getFormattedDate(selectedDate),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _changeDate(1),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurple.withOpacity(0.3),
                                AppColors.primaryPurple.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryPurple.withOpacity(0.4),
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  Text(
                    _getHoroscopeForDate(selectedDate),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 15,
                      height: 1.6,
                      letterSpacing: 0.2,
                    ),
                  ),

                  SizedBox(height: 24),

                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPurple.withOpacity(0.2),
                          AppColors.deepPurple.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryPurple.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        _luckyItem(
                          Icons.palette,
                          'Lucky Color',
                          luckyElements['color']!,
                        ),
                        SizedBox(height: 12),
                        _luckyItem(
                          Icons.filter_7,
                          'Lucky Number',
                          luckyElements['number']!,
                        ),
                        SizedBox(height: 12),
                        _luckyItem(
                          Icons.access_time,
                          'Lucky Time',
                          luckyElements['time']!,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 28),

                  AppButton(
                    title: 'Close',
                    onTap: () => Navigator.pop(context),
                    icon: Icons.dangerous,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _luckyItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryPurple.withOpacity(0.3),
                AppColors.primaryPurple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
