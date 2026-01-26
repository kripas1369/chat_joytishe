import 'package:flutter/material.dart';
import 'dart:math' as math;

class VedicAstrologyApp extends StatelessWidget {
  const VedicAstrologyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vedic Astrology',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.purple, fontFamily: 'Roboto'),
      home: const AstrologyHomePage(),
    );
  }
}

class AstrologyHomePage extends StatefulWidget {
  const AstrologyHomePage({Key? key}) : super(key: key);

  @override
  State<AstrologyHomePage> createState() => _AstrologyHomePageState();
}

class _AstrologyHomePageState extends State<AstrologyHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A148C), Color(0xFF3949AB), Color(0xFF6A1B9A)],
          ),
        ),
        child: Stack(
          children: [
            // Starfield Background
            ...List.generate(50, (index) => _buildStar(index)),

            // Main Content
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.purple[200],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Your spiritual companion',
                            style: TextStyle(
                              color: Colors.purple[200],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),

                      // Main Content Row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 800) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: _buildLeftContent()),
                                SizedBox(width: 40),
                                Expanded(child: _buildZodiacWheel()),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildLeftContent(),
                                SizedBox(height: 40),
                                _buildZodiacWheel(),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStar(int index) {
    final random = math.Random(index);
    return Positioned(
      left: random.nextDouble() * 1000,
      top: random.nextDouble() * 1000,
      child: TweenAnimationBuilder(
        duration: Duration(seconds: 2 + random.nextInt(2)),
        tween: Tween<double>(begin: 0.2, end: 1.0),
        builder: (context, double value, child) {
          return Opacity(
            opacity: value,
            child: Container(
              width: 2 + random.nextDouble() * 2,
              height: 2 + random.nextDouble() * 2,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          );
        },
        onEnd: () {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildLeftContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Heading
        Text(
          'वैदिक ज्योतिषद्वारा आफ्नो भविष्य चिनौं!',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.amber[600],
            height: 1.3,
          ),
        ),
        SizedBox(height: 20),

        // Subtitle
        Text(
          'जन्मकुण्डली, ग्रह-नक्षत्र र वैदिक शास्त्रमा आधारित सटीक ज्योतिष परामर्श।',
          style: TextStyle(
            fontSize: 16,
            color: Colors.purple[200],
            height: 1.5,
          ),
        ),
        SizedBox(height: 30),

        // Feature Cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildFeatureCard(
              'Instant Guidance',
              'Verified Jyotish संग real-time chat मा तुरुन्त उत्तर पाउनुहोस्।',
            ),
            _buildFeatureCard(
              'Personalized Insights',
              'जन्म विवरण अनुसार kundali review, match, र future predictions!',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String description) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.amber[300],
            ),
          ),
          SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.purple[200],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZodiacWheel() {
    return Center(
      child: Container(
        width: 350,
        height: 350,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotating Zodiac Wheel
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: child,
                );
              },
              child: CustomPaint(
                size: Size(350, 350),
                painter: ZodiacWheelPainter(),
              ),
            ),

            // Zodiac Signs
            ...List.generate(12, (index) {
              final signs = [
                '♈',
                '♉',
                '♊',
                '♋',
                '♌',
                '♍',
                '♎',
                '♏',
                '♐',
                '♑',
                '♒',
                '♓',
              ];
              final angle = (index * 30) * math.pi / 180;
              final radius = 140.0;
              final x = radius * math.cos(angle);
              final y = radius * math.sin(angle);

              return Transform.translate(
                offset: Offset(x, y),
                child: Text(
                  signs[index],
                  style: TextStyle(fontSize: 28, color: Colors.amber[300]),
                ),
              );
            }),

            // Center Yin-Yang
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(0xFF4A148C),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber[700]!, width: 2),
              ),
              child: CustomPaint(painter: YinYangPainter()),
            ),

            // Decorative Stars
            Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.star, color: Colors.amber[300], size: 24),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Icon(Icons.star, color: Colors.purple[300], size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class ZodiacWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Outer circle
    paint.color = Color(0xFF4A148C).withOpacity(0.5);
    canvas.drawCircle(center, 170, paint);

    // Inner circle
    paint.color = Color(0xFFD4AF37).withOpacity(0.6);
    paint.strokeWidth = 1;
    canvas.drawCircle(center, 130, paint);

    // Zodiac divisions
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final x1 = center.dx + 130 * math.cos(angle);
      final y1 = center.dy + 130 * math.sin(angle);
      final x2 = center.dx + 170 * math.cos(angle);
      final y2 = center.dy + 170 * math.sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class YinYangPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    // White half
    paint.color = Colors.white70;
    final path = Path();
    path.moveTo(center.dx, 0);
    path.arcTo(
      Rect.fromCircle(
        center: Offset(center.dx, size.height * 0.25),
        radius: size.height * 0.25,
      ),
      -math.pi / 2,
      math.pi,
      false,
    );
    path.arcTo(
      Rect.fromCircle(
        center: Offset(center.dx, size.height * 0.75),
        radius: size.height * 0.25,
      ),
      math.pi / 2,
      -math.pi,
      false,
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: size.width / 2),
      math.pi / 2,
      math.pi,
      false,
    );
    canvas.drawPath(path, paint);

    // Small circles
    paint.color = Color(0xFF4A148C);
    canvas.drawCircle(Offset(center.dx, size.height * 0.25), 5, paint);

    paint.color = Colors.white70;
    canvas.drawCircle(Offset(center.dx, size.height * 0.75), 5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
