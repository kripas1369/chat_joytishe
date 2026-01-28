import 'dart:async';
import 'dart:math';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:flutter/material.dart';

class BroadcastLoadingScreen extends StatefulWidget {
  final String message;
  final VoidCallback? onComplete;

  const BroadcastLoadingScreen({
    super.key,
    this.message = 'Broadcasting your query...',
    this.onComplete,
  });

  @override
  State<BroadcastLoadingScreen> createState() => _BroadcastLoadingScreenState();
}

class _BroadcastLoadingScreenState extends State<BroadcastLoadingScreen>
    with TickerProviderStateMixin {
  late List<AstrologerNode> _astrologers;
  final List<int> _connected = [];
  final Map<int, AnimationController> _lineAnimations = {};

  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _rippleController;

  Timer? _replayTimer;

  // Configurable particle radius (0.0 to 1.0, where 1.0 is half the screen width)
  final double particleRadiusRatio = 0.35;

  @override
  void initState() {
    super.initState();

    _astrologers = _generateRandomAstrologers();

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat();

    _rippleController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();

    // Start broadcasting to all astrologers immediately
    _startBroadcast();
  }

  List<AstrologerNode> _generateRandomAstrologers() {
    final random = Random();
    final avatars = [
      '🧙',
      '👳',
      '🧔',
      '🧘',
      '👨‍🦳',
      '🧓',
      '👴',
      '🧙‍♀️',
      '👩‍🦳',
      '🧑‍🦰',
      '👨‍🦱',
      '🧑‍🦲',
    ];
    final specialties = [
      'Vedic',
      'Numerology',
      'Palmistry',
      'Spiritual',
      'Horoscope',
      'Tarot',
      'Astrology',
      'Vastu',
      'Gemology',
      'Kundli',
      'Feng Shui',
      'Reiki',
    ];

    final astrologers = <AstrologerNode>[];
    final positions = <Offset>[];

    // Create 7 astrologers with random positions
    final count = 7; // 7 astrologers
    final minDistance = 0.15; // Minimum distance between astrologers
    final minDistanceFromCenter = 0.28; // Minimum distance from center
    final maxAttempts = 100; // Maximum attempts to find valid position

    for (int i = 0; i < count; i++) {
      double x = 0.5;
      double y = 0.5;
      bool validPosition = false;
      int attempts = 0;

      while (!validPosition && attempts < maxAttempts) {
        attempts++;
        x = 0.15 + random.nextDouble() * 0.7; // Between 0.15 and 0.85
        y = 0.15 + random.nextDouble() * 0.7; // Between 0.15 and 0.85

        // Check distance from center (0.5, 0.5)
        final distanceFromCenter = sqrt(pow(x - 0.5, 2) + pow(y - 0.5, 2));

        // Ensure not too close to center
        if (distanceFromCenter < minDistanceFromCenter) {
          continue;
        }

        // Check distance from all existing positions
        bool tooClose = false;
        for (final pos in positions) {
          final distance = sqrt(pow(x - pos.dx, 2) + pow(y - pos.dy, 2));
          if (distance < minDistance) {
            tooClose = true;
            break;
          }
        }

        if (!tooClose) {
          validPosition = true;
        }
      }

      // If we couldn't find a valid position after max attempts, use the last generated position
      final position = Offset(x, y);
      positions.add(position);

      astrologers.add(
        AstrologerNode(
          'Astrologer ${i + 1}',
          avatars[random.nextInt(avatars.length)],
          specialties[random.nextInt(specialties.length)],
          position,
        ),
      );
    }

    return astrologers;
  }

  void _startBroadcast() {
    // Connect to all astrologers at once
    _connectToAllAstrologers();

    // Replay every 10 seconds
    _replayTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _connectToAllAstrologers();
    });
  }

  void _connectToAllAstrologers() {
    setState(() {
      _connected.clear();

      // Dispose old controllers
      _lineAnimations.forEach((_, controller) => controller.dispose());
      _lineAnimations.clear();

      // Create new connections for all astrologers
      for (int i = 0; i < _astrologers.length; i++) {
        _connected.add(i);

        final lineController = AnimationController(
          vsync: this,
          duration: Duration(seconds: 10), // 10 seconds connection time
        );

        _lineAnimations[i] = lineController;

        // Start animation
        lineController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _rippleController.dispose();
    _lineAnimations.forEach((_, controller) => controller.dispose());
    _replayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final broadcastHeight = size.height * 0.7; // 70% for broadcast animation

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E27), Color(0xFF1A1A3E), Color(0xFF2E1A47)],
          ),
        ),
        child: Column(
          children: [
            // Top 70% - Broadcast Animation Area
            SizedBox(
              height: broadcastHeight,
              child: Stack(
                children: [
                  // Background grid pattern
                  CustomPaint(
                    size: Size(size.width, broadcastHeight),
                    painter: GridPainter(),
                  ),

                  // 7 Particles within circular radius
                  ...List.generate(
                    7,
                    (index) => _buildParticle(index, broadcastHeight),
                  ),

                  // Connection lines
                  CustomPaint(
                    size: Size(size.width, broadcastHeight),
                    painter: NetworkPainter(
                      astrologers: _astrologers,
                      connected: _connected,
                      lineAnimations: _lineAnimations,
                      pulse: _pulseController.value,
                      containerHeight: broadcastHeight,
                    ),
                  ),

                  // Astrologer nodes
                  ..._buildAstrologers(size.width, broadcastHeight),

                  // Center node with Earth
                  _centerNode(broadcastHeight),

                  // Top header
                  _topHeader(),
                ],
              ),
            ),

            Expanded(child: _bottomTextArea()),
          ],
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Positioned(
      top: 50,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            'GLOBAL BROADCAST',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: 4),
          Container(
            height: 2,
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFF667EEA),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerNode(double containerHeight) {
    return Positioned(
      left: 0,
      right: 0,
      top: (containerHeight - 100) / 2,
      // Center the 100px node vertically in the broadcast area
      child: Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Multiple ripple effects
              AnimatedBuilder(
                animation: _rippleController,
                builder: (_, __) => Container(
                  width: 120 + (_rippleController.value * 100),
                  height: 120 + (_rippleController.value * 100),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFF667EEA).withOpacity(
                        (1 - _rippleController.value).clamp(0.0, 1.0) * 0.5,
                      ),
                      width: 2,
                    ),
                  ),
                ),
              ),

              // Second ripple with offset
              AnimatedBuilder(
                animation: _rippleController,
                builder: (_, __) {
                  final offset = (_rippleController.value + 0.5) % 1.0;
                  return Container(
                    width: 120 + (offset * 100),
                    height: 120 + (offset * 100),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(
                          0xFF667EEA,
                        ).withOpacity((1 - offset).clamp(0.0, 1.0) * 0.5),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),

              // Main node with glow and Earth icon (NO rotation - still)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF667EEA),
                        Color(0xFF764BA2),
                        Color(0xFF4A148C),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF667EEA).withOpacity(0.6),
                        blurRadius: 30 + (_pulseController.value * 10),
                        spreadRadius: 5 + (_pulseController.value * 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text('🌍', style: TextStyle(fontSize: 50)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAstrologers(double screenWidth, double containerHeight) {
    return _astrologers.asMap().entries.map((e) {
      final index = e.key;
      final astrologer = e.value;
      final connected = _connected.contains(index);
      final isConnecting = _lineAnimations[index]?.isAnimating ?? false;

      return Positioned(
        left: screenWidth * astrologer.position.dx - 30,
        top: containerHeight * astrologer.position.dy - 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isConnecting
                      ? [Color(0xFFE53935), Color(0xFFFF8C00)]
                      : [Color(0xFF2A2A4C), Color(0xFF1A1A3E)],
                ),
                border: Border.all(
                  color: isConnecting ? Color(0xFFFFD700) : Color(0xFF4A4A6A),
                  width: isConnecting ? 3 : 2,
                ),
                boxShadow: isConnecting
                    ? [
                        BoxShadow(
                          color: Color(0xFFFFD700).withOpacity(0.7),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
              ),
              child: Center(
                child: Text(astrologer.avatar, style: TextStyle(fontSize: 28)),
              ),
            ),
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isConnecting
                    ? Color(0xFFFFD700).withOpacity(0.2)
                    : Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isConnecting
                      ? Color(0xFFFFD700).withOpacity(0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                astrologer.specialty,
                style: TextStyle(
                  color: isConnecting ? Color(0xFFFFD700) : Colors.white60,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildParticle(int index, double containerHeight) {
    final rand = Random(index + 100); // Different seed for better randomness

    // Generate random angle and distance within the circular radius
    final angle = rand.nextDouble() * 2 * pi;
    final distance = rand.nextDouble() * particleRadiusRatio;

    // Convert polar coordinates to cartesian
    final dx = 0.5 + (distance * cos(angle));
    final dy = 0.5 + (distance * sin(angle));

    final delay = rand.nextDouble();
    final size = 2.0 + rand.nextDouble() * 3;

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, _) {
        final v = (_rotationController.value + delay) % 1.0;
        final opacity = (0.1 + sin(v * pi * 2) * 0.2).clamp(0.0, 1.0);

        return Positioned(
          left: MediaQuery.of(context).size.width * dx,
          top: containerHeight * dy,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Color(0xFF667EEA),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF667EEA).withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bottomTextArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Opacity(
              opacity: (0.5 + _pulseController.value * 0.5).clamp(0.0, 1.0),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Connecting to Astrologers...',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            'Please be Patient',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class AstrologerNode {
  final String name;
  final String avatar;
  final String specialty;
  final Offset position;

  AstrologerNode(this.name, this.avatar, this.specialty, this.position);
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw vertical lines
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NetworkPainter extends CustomPainter {
  final List<AstrologerNode> astrologers;
  final List<int> connected;
  final Map<int, AnimationController> lineAnimations;
  final double pulse;
  final double containerHeight;

  NetworkPainter({
    required this.astrologers,
    required this.connected,
    required this.lineAnimations,
    required this.pulse,
    required this.containerHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, containerHeight * 0.5);

    for (final i in connected) {
      final astrologer = astrologers[i];
      final astroPoint = Offset(
        size.width * astrologer.position.dx,
        containerHeight * astrologer.position.dy,
      );

      final lineProgress = lineAnimations[i]?.value ?? 0.0;
      final isAnimating = lineAnimations[i]?.isAnimating ?? false;

      final currentEnd = Offset.lerp(center, astroPoint, lineProgress)!;

      // Draw glow effect for animating line
      if (isAnimating || lineProgress >= 1.0) {
        final glowPaint = Paint()
          ..color = Color(0xFFFFD700).withOpacity(0.3)
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawLine(center, currentEnd, glowPaint);
      }

      // Main thin line
      final linePaint = Paint()
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = Color(0xFFFFD700).withOpacity(0.7);

      canvas.drawLine(center, currentEnd, linePaint);

      // Draw connection dot at the end of animating line
      if (isAnimating && lineProgress > 0.05) {
        // Outer glow
        final outerGlowPaint = Paint()
          ..color = Color(0xFFFFD700).withOpacity(0.6)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawCircle(currentEnd, 8, outerGlowPaint);

        // Main dot
        final dotPaint = Paint()
          ..color = Color(0xFFFFD700)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(currentEnd, 5, dotPaint);

        // Inner bright dot
        final brightDotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawCircle(currentEnd, 2.5, brightDotPaint);
      }

      // Draw pulsing particles at completed connections
      if (lineProgress >= 1.0) {
        _drawPulsingParticle(canvas, astroPoint, pulse);
      }
    }
  }

  void _drawPulsingParticle(Canvas canvas, Offset position, double pulse) {
    final size = 4 + (pulse * 3);

    final particlePaint = Paint()
      ..color = Color(0xFFFFD700).withOpacity(0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(position, size, particlePaint);
  }

  @override
  bool shouldRepaint(covariant NetworkPainter old) => true;
}
