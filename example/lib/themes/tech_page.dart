import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// An original tech-armour theme: a holographic HUD with a scanning line,
/// a network that follows your finger, circuit particles and repulsor
/// blasts.
class TechPage extends StatefulWidget {
  const TechPage({super.key});

  @override
  State<TechPage> createState() => _TechPageState();
}

class _TechPageState extends State<TechPage> with TickerProviderStateMixin {
  final _blasts = ParticleController();
  final _leftKey = GlobalKey();
  final _rightKey = GlobalKey();
  int _power = 98;

  late final _hud = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _hud.dispose();
    _blasts.dispose();
    super.dispose();
  }

  void _fire(GlobalKey key, double angle) {
    _blasts.burstFromKey(
      key,
      count: 60,
      angle: angle,
      spread: pi / 7,
      minSpeed: 500,
      maxSpeed: 1100,
      gravity: 0,
      drag: 1.2,
      lifespan: const Duration(milliseconds: 900),
    );
    setState(() => _power = max(12, _power - 7));
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return ThemeScaffold(
      child: ColoredBox(
        color: const Color(0xFF020A14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [Color(0xFF06243A), Color(0xFF020A14)],
                ),
              ),
            ),
            CustomPaint(painter: _GridPainter(_hud)),
            // Circuit bits drifting up
            const ParticleEffects(
              config: ParticleConfig(
                particleTypes: [ParticleType.square, ParticleType.diamond],
                direction: ParticleDirection.bottomToTop,
                particleCount: 40,
                minSize: 2,
                maxSize: 5,
                particleColor: Color(0xFF18FFFF),
                enableGlow: true,
                glowRadius: 2,
                minOpacity: 0.2,
                maxOpacity: 0.7,
                velocityMultiplier: 0.3,
                driftAmplitude: 0,
                edgeFade: 0.2,
                blendMode: BlendMode.plus,
                seed: 12,
              ),
            ),
            // A network that follows your finger
            const ParticleEffects(
              interaction: ParticleInteraction.attract,
              config: ParticleConfig(
                direction: ParticleDirection.none,
                particleCount: 45,
                minSize: 2,
                maxSize: 4,
                particleColor: Color(0xFF80D8FF),
                enableGlow: true,
                glowRadius: 2,
                velocityMultiplier: 0.3,
                driftAmplitude: 35,
                enableOpacityAnimation: false,
                connections: ParticleConnections(
                  maxDistance: 100,
                  color: Color(0xFF40C4FF),
                  maxOpacity: 0.45,
                ),
                seed: 9,
              ),
            ),
            // The HUD reticle
            Positioned(
              left: 0,
              right: 0,
              top: padding.top + 200,
              child: IgnorePointer(
                child: Center(
                  child: CustomPaint(
                    size: const Size(250, 250),
                    painter: _ReticlePainter(_hud),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: ParticleEffects(
                controller: _blasts,
                config: const ParticleConfig(
                  particleCount: 0,
                  particleTypes: [ParticleType.streak, ParticleType.circle],
                  minSize: 6,
                  maxSize: 20,
                  gradientColors: [
                    Color(0xFF18FFFF),
                    Color(0xFF80D8FF),
                    Colors.white,
                  ],
                  enableGlow: true,
                  glowRadius: 4,
                  blendMode: BlendMode.plus,
                  trail: ParticleTrail(length: 4),
                  lifecycle: ParticleLifecycle.shrink,
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: padding.top + 70,
              child: IgnorePointer(
                child: Column(
                  children: [
                    const Eyebrow(
                      '✦  SYSTEMS ONLINE  ✦',
                      color: Color(0xFF80D8FF),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'TECH SUIT',
                      style: TextStyle(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: Color(0xFFE0F7FA),
                        shadows: [
                          Shadow(color: Color(0xFF18FFFF), blurRadius: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'POWER $_power%  ·  SHIELDS OK  ·  TARGET LOCK',
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: Color(0xFF80D8FF),
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: padding.bottom + 40,
              child: Column(
                children: [
                  // Buttons share the width, so they fit narrow screens
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: _RepulsorButton(
                              key: _leftKey,
                              label: 'L-BLAST',
                              onPressed: () => _fire(_leftKey, -pi / 3),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: _RepulsorButton(
                              label: 'RECHARGE',
                              onPressed: () => setState(() => _power = 98),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: _RepulsorButton(
                              key: _rightKey,
                              label: 'R-BLAST',
                              onPressed: () => _fire(_rightKey, -2 * pi / 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fire the repulsors · touch the screen to link the network',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepulsorButton extends StatelessWidget {
  const _RepulsorButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF18FFFF),
        side: const BorderSide(color: Color(0xFF18FFFF), width: 1.5),
        backgroundColor: const Color(0xFF18FFFF).withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      onPressed: onPressed,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2),
        ),
      ),
    );
  }
}

/// A holographic grid with a scanning line sweeping down.
class _GridPainter extends CustomPainter {
  _GridPainter(this.time) : super(repaint: time);

  final Animation<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..strokeWidth = 1
      ..color = const Color(0xFF18FFFF).withValues(alpha: 0.06);
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final y = size.height * time.value;
    final scan = Rect.fromLTWH(0, y - 40, size.width, 40);
    canvas.drawRect(
      scan,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF18FFFF).withValues(alpha: 0),
            const Color(0xFF18FFFF).withValues(alpha: 0.16),
          ],
        ).createShader(scan),
    );
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..strokeWidth = 1.5
        ..color = const Color(0xFF18FFFF).withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}

/// Rotating HUD rings with tick marks and a pulsing center.
class _ReticlePainter extends CustomPainter {
  _ReticlePainter(this.time) : super(repaint: time);

  final Animation<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final t = time.value * 2 * pi;
    final cyan = const Color(0xFF18FFFF);
    Paint stroke(double width, double alpha) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = cyan.withValues(alpha: alpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

    // Arcs turning in opposite directions
    for (final (radius, speed, sweep, width) in [
      (118.0, 0.5, 1.4, 3.0),
      (100.0, -0.8, 2.2, 1.5),
      (82.0, 1.2, 0.9, 4.0),
    ]) {
      for (int i = 0; i < 3; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          t * speed + i * 2 * pi / 3,
          sweep,
          false,
          stroke(width, 0.7),
        );
      }
    }
    // Tick marks
    for (int i = 0; i < 60; i++) {
      final angle = i * 2 * pi / 60 - t * 0.2;
      final inner = i % 5 == 0 ? 56.0 : 62.0;
      canvas.drawLine(
        center + Offset(cos(angle), sin(angle)) * inner,
        center + Offset(cos(angle), sin(angle)) * 68,
        stroke(1, 0.5),
      );
    }
    // Pulsing core
    final pulse = 0.8 + 0.2 * sin(t * 2);
    canvas
      ..drawCircle(
        center,
        34 * pulse,
        Paint()
          ..color = cyan.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      )
      ..drawCircle(center, 18, stroke(2, 0.9))
      ..drawCircle(center, 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ReticlePainter oldDelegate) => false;
}
