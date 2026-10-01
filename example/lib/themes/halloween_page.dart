import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// Halloween night: bats across a full moon, rolling fog, ghosts to catch
/// and jack-o'-lanterns full of candy.
class HalloweenPage extends StatefulWidget {
  const HalloweenPage({super.key});

  @override
  State<HalloweenPage> createState() => _HalloweenPageState();
}

class _HalloweenPageState extends State<HalloweenPage>
    with SingleTickerProviderStateMixin {
  final _candy = ParticleController();
  final _pumpkinKeys = List.generate(3, (_) => GlobalKey());
  int _ghostsCaught = 0;

  late final _flicker = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  static const _spooky = LinearGradient(
    colors: [Color(0xFFFFB74D), Color(0xFFFF6D00), Color(0xFFB388FF)],
  );

  @override
  void dispose() {
    _flicker.dispose();
    _candy.dispose();
    super.dispose();
  }

  void _openPumpkin(int index) {
    _candy.burstFromKey(
      _pumpkinKeys[index],
      count: 50,
      spread: pi / 2,
      minSpeed: 250,
      maxSpeed: 600,
      gravity: 700,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ThemeScaffold(
      child: ColoredBox(
        color: const Color(0xFF0B0616),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF07030F),
                    Color(0xFF1E0B2F),
                    Color(0xFF3B1242),
                    Color(0xFF1A0A12),
                  ],
                ),
              ),
            ),
            // A huge moon
            Positioned(
              top: topPadding + 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 230,
                  height: 230,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.25, -0.3),
                      colors: [
                        Color(0xFFFFF3E0),
                        Color(0xFFFFCC80),
                        Color(0xFFFFA726),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.45),
                        blurRadius: 90,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 0,
              right: 0,
              width: 170,
              height: 170,
              child: CustomPaint(painter: _SpiderWebPainter()),
            ),
            // Bats fluttering across the sky
            ParticleEffects(
              config: ParticleConfig(
                particleType: ParticleType.path,
                customPath: _bat,
                direction: ParticleDirection.leftToRight,
                particleCount: 14,
                minSize: 18,
                maxSize: 40,
                particleColor: const Color(0xFF12071C),
                velocityMultiplier: 0.8,
                animationDuration: const Duration(seconds: 9),
                enableOpacityAnimation: false,
                driftAmplitude: 40,
                depthEffect: 0.6,
                seed: 13,
              ),
            ),
            // Rolling fog
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 320,
              child: ParticleEffects(
                config: ParticleConfig(
                  particleCount: 0,
                  minSize: 60,
                  maxSize: 130,
                  particleColor: Color(0xFFD1C4E9),
                  enableBlur: true,
                  blurSigma: 12,
                  minOpacity: 0.0,
                  maxOpacity: 0.18,
                  enableOpacityAnimation: false,
                  lifecycle: ParticleLifecycle.growAndFade,
                  emitters: [
                    ParticleEmitter(
                      extent: Size(10000, 40),
                      rate: 7,
                      angle: 0,
                      spread: 0.6,
                      minSpeed: 10,
                      maxSpeed: 35,
                      gravity: -4,
                      drag: 0.1,
                      lifespan: Duration(seconds: 7),
                    ),
                  ],
                ),
              ),
            ),

            ListView(
              padding: EdgeInsets.only(top: topPadding + 290),
              children: [
                const Eyebrow(
                  '✦  TRICK OR TREAT?  ✦',
                  color: Color(0xFFFFCC80),
                ),
                const SizedBox(height: 10),
                const GradientText(
                  'Happy\nHalloween',
                  gradient: _spooky,
                  glow: Color(0x88FF6D00),
                  style: TextStyle(
                    fontSize: 58,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    tint: const Color(0xFFB388FF),
                    child: Column(
                      children: [
                        const Text(
                          '👻  Catch the ghosts!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the ghosts floating around to catch them.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Text(
                            'Caught: $_ghostsCaught',
                            key: ValueKey(_ghostsCaught),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFB74D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                const Center(
                  child: Text(
                    'Tap a pumpkin for candy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < 3; i++)
                      GestureDetector(
                        onTap: () => _openPumpkin(i),
                        child: SizedBox(
                          key: _pumpkinKeys[i],
                          width: 90 + i % 2 * 20.0,
                          height: 80 + i % 2 * 18.0,
                          child: CustomPaint(
                            painter: _PumpkinPainter(_flicker, seed: i),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 60),
                const MadeWith(),
              ],
            ),

            // Ghosts wandering over everything, caught with a tap
            ParticleEffects(
              interaction: ParticleInteraction.pop,
              onParticleTap: (_) => setState(() => _ghostsCaught++),
              config: const ParticleConfig(
                particleType: ParticleType.custom,
                customParticle: Text('👻', style: TextStyle(fontSize: 44)),
                direction: ParticleDirection.none,
                particleCount: 6,
                minSize: 36,
                maxSize: 56,
                velocityMultiplier: 0.35,
                driftAmplitude: 70,
                minOpacity: 0.45,
                maxOpacity: 0.95,
                seed: 21,
              ),
            ),
            // Candy
            ParticleEffects(
              controller: _candy,
              config: const ParticleConfig(
                particleCount: 0,
                particleTypes: [
                  ParticleType.circle,
                  ParticleType.star,
                  ParticleType.square,
                ],
                minSize: 6,
                maxSize: 12,
                gradientColors: [
                  Color(0xFFFF6D00),
                  Color(0xFF7C4DFF),
                  Color(0xFF76FF03),
                  Color(0xFFFFEA00),
                  Color(0xFFFF4081),
                ],
                enableRotation: true,
                rotationSpeed: 2,
                enableOpacityAnimation: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A bat silhouette, mirrored from one wing.
final Path _bat = () {
  const wing = [
    (0.08, -0.35),
    (0.13, -0.12),
    (1.0, -0.22),
    (0.78, 0.12),
    (0.52, 0.14),
    (0.26, 0.2),
    (0.08, 0.32),
    (0.0, 0.4),
  ];
  final path = Path()..moveTo(0, -0.15);
  for (final (x, y) in wing) {
    path.lineTo(x, y);
  }
  for (final (x, y) in wing.reversed.skip(1)) {
    path.lineTo(-x, y);
  }
  return path..close();
}();

class _PumpkinPainter extends CustomPainter {
  _PumpkinPainter(this.flicker, {required this.seed}) : super(repaint: flicker);

  final Animation<double> flicker;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Rect.fromLTWH(0, h * 0.15, w, h * 0.85);
    final glow = 0.6 + 0.4 * sin(flicker.value * pi + seed);

    // Glow around the pumpkin
    canvas.drawOval(
      body.inflate(10),
      Paint()
        ..color = const Color(0xFFFF9800).withValues(alpha: 0.25 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    // Ribs
    final ribPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        colors: [Color(0xFFFFA726), Color(0xFFE65100), Color(0xFFBF360C)],
      ).createShader(body);
    for (final (dx, width) in [(0.0, 0.5), (0.5, 0.5), (0.2, 0.6)]) {
      canvas.drawOval(
        Rect.fromLTWH(w * dx, body.top, w * width, body.height),
        ribPaint,
      );
    }
    // Stem
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.45, 0, w * 0.1, h * 0.22),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF33691E),
    );
    // Carved face, glowing from the candle inside
    final face = Paint()
      ..color = Color.lerp(
        const Color(0xFFFFD54F),
        const Color(0xFFFFF8E1),
        glow,
      )!;
    Path triangle(double cx, double cy, double s) => Path()
      ..moveTo(cx, cy - s)
      ..lineTo(cx + s, cy + s * 0.6)
      ..lineTo(cx - s, cy + s * 0.6)
      ..close();
    canvas
      ..drawPath(triangle(w * 0.33, h * 0.45, w * 0.08), face)
      ..drawPath(triangle(w * 0.67, h * 0.45, w * 0.08), face);
    final mouth = Path()..moveTo(w * 0.24, h * 0.66);
    for (int i = 0; i < 6; i++) {
      final x = w * (0.24 + (i + 1) * 0.52 / 6);
      mouth.lineTo(x - w * 0.043, h * (i.isEven ? 0.74 : 0.66));
      mouth.lineTo(x, h * 0.66);
    }
    mouth.quadraticBezierTo(w * 0.5, h * 0.92, w * 0.24, h * 0.66);
    canvas.drawPath(mouth, face);
  }

  @override
  bool shouldRepaint(_PumpkinPainter oldDelegate) => false;
}

class _SpiderWebPainter extends CustomPainter {
  const _SpiderWebPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final corner = Offset(size.width, 0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.35);
    const spokes = 6;
    final radius = size.width;
    final angles = [
      for (int i = 0; i <= spokes; i++) pi / 2 + i * (pi / 2) / spokes,
    ];
    for (final angle in angles) {
      canvas.drawLine(
        corner,
        corner + Offset(cos(angle), sin(angle)) * radius,
        paint,
      );
    }
    for (int ring = 1; ring <= 5; ring++) {
      final r = radius * ring / 5.5;
      final path = Path();
      for (int i = 0; i < angles.length; i++) {
        final point = corner + Offset(cos(angles[i]), sin(angles[i])) * r;
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          // Sagging threads between spokes
          final previous =
              corner + Offset(cos(angles[i - 1]), sin(angles[i - 1])) * r;
          final middle = Offset.lerp(previous, point, 0.5)!;
          final sag = Offset.lerp(middle, corner, 0.08)!;
          path.quadraticBezierTo(sag.dx, sag.dy, point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
    // The spider
    final spider = corner + Offset(-radius * 0.45, radius * 0.5);
    canvas
      ..drawLine(
        Offset(spider.dx, 0),
        spider,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      )
      ..drawCircle(spider, 6, Paint()..color = const Color(0xFF0B0616))
      ..drawCircle(
        spider,
        6,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: 0.4),
      );
  }

  @override
  bool shouldRepaint(_SpiderWebPainter oldDelegate) => false;
}
