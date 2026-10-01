import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';
import 'scenery.dart';

/// A sunny beach: dust motes in the sunlight, rolling waves with foam,
/// bubbles in the sea, seagulls, and sand that sprays where you tap.
class BeachPage extends StatefulWidget {
  const BeachPage({super.key});

  @override
  State<BeachPage> createState() => _BeachPageState();
}

class _BeachPageState extends State<BeachPage> with TickerProviderStateMixin {
  final _foam = ParticleController();
  final _sand = ParticleController();
  final _random = Random();
  late final Timer _waves;

  late final _swell = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void initState() {
    super.initState();
    // Foam sprays up as each wave breaks on the shore
    _waves = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      final size = MediaQuery.sizeOf(context);
      final x = size.width * _random.nextDouble();
      _foam.burst(
        position: Offset(x, _shoreY(size, x)),
        count: 18,
        angle: -pi / 2,
        spread: pi / 2,
        minSpeed: 60,
        maxSpeed: 200,
        gravity: 420,
        drag: 0.6,
        lifespan: const Duration(milliseconds: 1100),
      );
    });
  }

  double _shoreY(Size size, double x) =>
      size.height * 0.7 +
      sin(x / size.width * 2 * pi * 1.5 + _swell.value * 2 * pi) * 8;

  @override
  void dispose() {
    _waves.cancel();
    _swell.dispose();
    _foam.dispose();
    _sand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final horizon = size.height * 0.46;

    return ThemeScaffold(
      dark: false,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          // Only the sand sprays
          final position = details.localPosition;
          if (position.dy < _shoreY(size, position.dx)) return;
          _sand.burst(
            position: details.localPosition,
            count: 40,
            angle: -pi / 2,
            spread: pi / 1.4,
            minSpeed: 100,
            maxSpeed: 360,
            gravity: 900,
            drag: 0.4,
            lifespan: const Duration(milliseconds: 1000),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Sky
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF3FA9F5),
                    Color(0xFF8FD3FF),
                    Color(0xFFFFF3D6),
                  ],
                  stops: [0, 0.3, 0.46],
                ),
              ),
            ),
            // Sun
            Positioned(
              top: padding.top + 40,
              right: 30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFFDE7), Color(0xFFFFE082)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
                      blurRadius: 80,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
            // Seagulls
            ParticleEffects(
              config: ParticleConfig(
                particleType: ParticleType.path,
                customPath: birdPath,
                direction: ParticleDirection.leftToRight,
                particleCoverage: ParticleCoverage.full,
                particleCount: 5,
                minSize: 12,
                maxSize: 20,
                particleColor: const Color(0xFF455A64),
                velocityMultiplier: 0.3,
                animationDuration: const Duration(seconds: 22),
                enableOpacityAnimation: false,
                maxOpacity: 0.8,
                driftAmplitude: 20,
                seed: 6,
              ),
            ),
            // The sea
            Positioned(
              left: 0,
              right: 0,
              top: horizon,
              bottom: 0,
              child: CustomPaint(painter: _SeaPainter(_swell)),
            ),
            // Bubbles and glints in the water
            Positioned(
              left: 0,
              right: 0,
              top: horizon + 20,
              height: size.height * 0.22,
              child: const ParticleEffects(
                config: ParticleConfig(
                  particleTypes: [ParticleType.ring, ParticleType.sparkle],
                  direction: ParticleDirection.bottomToTop,
                  particleCoverage: ParticleCoverage.semiFull,
                  particleCount: 26,
                  minSize: 3,
                  maxSize: 8,
                  particleColor: Colors.white,
                  minOpacity: 0.3,
                  maxOpacity: 0.8,
                  velocityMultiplier: 0.3,
                  driftAmplitude: 8,
                  seed: 10,
                ),
              ),
            ),
            // Sand, with a wet edge where the waves reach
            AnimatedBuilder(
              animation: _swell,
              builder: (context, _) => CustomPaint(
                painter: _SandPainter(_swell.value, horizon: horizon),
              ),
            ),
            const Positioned(
              left: -20,
              bottom: 120,
              child: IgnorePointer(
                child: CustomPaint(
                  size: Size(170, 300),
                  painter: _PalmPainter(),
                ),
              ),
            ),
            // Warm dust in the sunlight
            const IgnorePointer(
              child: ParticleEffects(
                config: ParticleConfig(
                  particleTypes: [ParticleType.circle, ParticleType.sparkle],
                  direction: ParticleDirection.none,
                  particleCount: 40,
                  minSize: 1.5,
                  maxSize: 4,
                  gradientColors: [Color(0xFFFFF8E1), Color(0xFFFFE082)],
                  enableGlow: true,
                  glowRadius: 2,
                  minOpacity: 0,
                  maxOpacity: 0.7,
                  velocityMultiplier: 0.2,
                  driftAmplitude: 30,
                  blendMode: BlendMode.plus,
                  seed: 2,
                ),
              ),
            ),
            IgnorePointer(
              child: ParticleEffects(
                controller: _foam,
                config: const ParticleConfig(
                  particleCount: 0,
                  minSize: 2,
                  maxSize: 6,
                  particleColor: Colors.white,
                  enableOpacityAnimation: false,
                  maxOpacity: 0.9,
                ),
              ),
            ),
            IgnorePointer(
              child: ParticleEffects(
                controller: _sand,
                config: const ParticleConfig(
                  particleCount: 0,
                  minSize: 2,
                  maxSize: 4,
                  gradientColors: [
                    Color(0xFFE6C9A0),
                    Color(0xFFD4B07C),
                    Color(0xFFF2DDBB),
                  ],
                  enableOpacityAnimation: false,
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: padding.top + 130,
              child: IgnorePointer(
                child: Column(
                  children: [
                    const Eyebrow(
                      '✦  SUN · SEA · SAND  ✦',
                      color: Color(0xFF01579B),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Summer\nVibes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 58,
                        height: 0.92,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0x6601579B),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tap the sand',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF01579B).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeaPainter extends CustomPainter {
  _SeaPainter(this.swell) : super(repaint: swell);

  final Animation<double> swell;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0277BD), Color(0xFF0097A7), Color(0xFF4DD0E1)],
        ).createShader(Offset.zero & size),
    );
    // Rolling swells, lighter towards the shore
    for (int i = 0; i < 6; i++) {
      final y = h * (0.05 + i * 0.09);
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= w; x += 8) {
        path.lineTo(
          x,
          y +
              sin(x / w * 2 * pi * (2 + i * 0.3) + swell.value * 2 * pi + i) *
                  (2 + i),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 + i * 0.4
          ..color = Colors.white.withValues(alpha: 0.12 + i * 0.05),
      );
    }
    // Sun glitter on the water
    final random = Random(3);
    for (int i = 0; i < 40; i++) {
      final x = w * (0.55 + random.nextDouble() * 0.4);
      final y = h * random.nextDouble() * 0.4;
      final twinkle = 0.5 + 0.5 * sin(swell.value * 2 * pi * 3 + i);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 10, height: 1.5),
        Paint()..color = Colors.white.withValues(alpha: 0.6 * twinkle),
      );
    }
  }

  @override
  bool shouldRepaint(_SeaPainter oldDelegate) => false;
}

class _SandPainter extends CustomPainter {
  const _SandPainter(this.swell, {required this.horizon});

  final double swell;
  final double horizon;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final shore = size.height * 0.7;
    double edge(double x) =>
        shore + sin(x / w * 2 * pi * 1.5 + swell * 2 * pi) * 8;

    // Foamy wave edge, then wet and dry sand
    final foam = Path()..moveTo(0, edge(0) - 10);
    for (double x = 0; x <= w; x += 6) {
      foam.lineTo(x, edge(x) - 10);
    }
    foam.lineTo(w, edge(w) - 10);
    foam
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      foam,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );

    final sand = Path()..moveTo(0, edge(0));
    for (double x = 0; x <= w; x += 6) {
      sand.lineTo(x, edge(x));
    }
    // Reach the right edge exactly, whatever the screen width
    sand.lineTo(w, edge(w));
    sand
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      sand,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFCBA774),
            Color(0xFFE9D2A8),
            Color(0xFFF3E1BE),
          ],
          stops: const [0, 0.25, 1],
        ).createShader(Rect.fromLTWH(0, shore, w, size.height - shore)),
    );
    // Grains of sand
    final random = Random(8);
    for (int i = 0; i < 260; i++) {
      canvas.drawCircle(
        Offset(
          w * random.nextDouble(),
          shore + 20 + random.nextDouble() * (size.height - shore),
        ),
        0.8,
        Paint()..color = const Color(0xFF8D6E4C).withValues(alpha: 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(_SandPainter oldDelegate) => oldDelegate.swell != swell;
}

class _PalmPainter extends CustomPainter {
  const _PalmPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final base = Offset(size.width * 0.35, size.height);
    final top = Offset(size.width * 0.55, size.height * 0.2);
    // Curved trunk with rings
    final trunk = Path()
      ..moveTo(base.dx - 9, base.dy)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.55,
        top.dx - 5,
        top.dy,
      )
      ..lineTo(top.dx + 5, top.dy)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.55,
        base.dx + 9,
        base.dy,
      )
      ..close();
    canvas.drawPath(trunk, Paint()..color = const Color(0xFF8D6E4C));
    for (double t = 0.1; t < 1; t += 0.08) {
      final y = base.dy + (top.dy - base.dy) * t;
      final x = base.dx + (top.dx - base.dx) * t - sin(t * pi) * 18;
      canvas.drawLine(
        Offset(x - 8, y),
        Offset(x + 8, y - 3),
        Paint()
          ..strokeWidth = 2
          ..color = const Color(0xFF6D4C35),
      );
    }
    // Fronds
    for (final angle in [-2.6, -2.0, -1.3, -0.6, 0.1, 0.6]) {
      final tip = top + Offset(cos(angle), sin(angle) + 0.4) * 90;
      final control = top + Offset(cos(angle), sin(angle) - 0.3) * 60;
      final frond = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(control.dx, control.dy - 12, tip.dx, tip.dy)
        ..quadraticBezierTo(control.dx, control.dy + 10, top.dx, top.dy)
        ..close();
      canvas.drawPath(frond, Paint()..color = const Color(0xFF2E7D32));
    }
    canvas.drawCircle(
      top + const Offset(0, 10),
      7,
      Paint()..color = const Color(0xFF5D4037),
    );
    canvas.drawCircle(
      top + const Offset(10, 8),
      7,
      Paint()..color = const Color(0xFF6D4C41),
    );
  }

  @override
  bool shouldRepaint(_PalmPainter oldDelegate) => false;
}
