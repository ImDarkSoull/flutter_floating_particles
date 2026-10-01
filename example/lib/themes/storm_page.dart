import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// A thunderstorm over the fields: rolling clouds, wind-driven rain and
/// lightning that strikes wherever you tap.
class StormPage extends StatefulWidget {
  const StormPage({super.key});

  @override
  State<StormPage> createState() => _StormPageState();
}

class _StormPageState extends State<StormPage> with TickerProviderStateMixin {
  final _sparks = ParticleController();
  final _random = Random();
  Timer? _timer;

  /// The current bolt, from the clouds to where it strikes.
  List<Offset> _bolt = const [];
  late final _strike = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final _clouds = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 70),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _scheduleStrike();
  }

  void _scheduleStrike() {
    _timer = Timer(Duration(milliseconds: 2500 + _random.nextInt(3500)), () {
      if (!mounted) return;
      final size = MediaQuery.sizeOf(context);
      _strikeAt(
        Offset(
          size.width * (0.1 + _random.nextDouble() * 0.8),
          size.height * (0.72 + _random.nextDouble() * 0.1),
        ),
      );
      _scheduleStrike();
    });
  }

  /// Lightning strikes [target]: a jagged bolt, a flash and sparks.
  void _strikeAt(Offset target) {
    final start = Offset(
      target.dx + (_random.nextDouble() - 0.5) * 160,
      MediaQuery.paddingOf(context).top + 40,
    );
    final points = <Offset>[start];
    const segments = 14;
    for (int i = 1; i < segments; i++) {
      final base = Offset.lerp(start, target, i / segments)!;
      points.add(base + Offset((_random.nextDouble() - 0.5) * 50, 0));
    }
    points.add(target);
    setState(() => _bolt = points);
    _strike.forward(from: 0);
    _sparks.burst(
      position: target,
      count: 60,
      angle: -pi / 2,
      spread: pi * 1.2,
      minSpeed: 120,
      maxSpeed: 480,
      gravity: 700,
      drag: 0.8,
      lifespan: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _strike.dispose();
    _clouds.dispose();
    _sparks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ThemeScaffold(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _strikeAt(details.localPosition),
        child: ColoredBox(
          color: const Color(0xFF0D1117),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0B0F17),
                      Color(0xFF1C2533),
                      Color(0xFF2D3A4A),
                      Color(0xFF1B2419),
                    ],
                    stops: [0, 0.4, 0.72, 1],
                  ),
                ),
              ),
              // The whole sky lights up with each strike
              AnimatedBuilder(
                animation: _strike,
                builder: (context, _) {
                  final t = _strike.value;
                  final flash = _strike.isAnimating
                      ? (t < 0.1 ? t / 0.1 : (1 - t)) * 0.45
                      : 0.0;
                  return ColoredBox(
                    color: const Color(0xFFD6E4FF).withValues(alpha: flash),
                  );
                },
              ),
              CustomPaint(painter: _StormCloudsPainter(_clouds)),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 230,
                child: CustomPaint(painter: _FieldsPainter()),
              ),
              // The bolt
              AnimatedBuilder(
                animation: _strike,
                builder: (context, _) => CustomPaint(
                  painter: _BoltPainter(
                    _bolt,
                    _strike.value,
                    _strike.isAnimating,
                  ),
                ),
              ),
              // Driving rain
              IgnorePointer(
                child: ParticleEffects(
                  config: ParticleConfig.rain.copyWith(
                    particleCount: 220,
                    minSize: 14,
                    maxSize: 28,
                    particleColor: const Color(0xFFB8CCE6),
                    velocityMultiplier: 1.9,
                    wind: 0.35,
                    depthEffect: 0.8,
                    splash: const ParticleSplash(count: 3, size: 1.6),
                  ),
                ),
              ),
              IgnorePointer(
                child: ParticleEffects(
                  controller: _sparks,
                  config: const ParticleConfig(
                    particleCount: 0,
                    particleTypes: [ParticleType.sparkle, ParticleType.streak],
                    minSize: 3,
                    maxSize: 9,
                    gradientColors: [
                      Colors.white,
                      Color(0xFFB3D4FF),
                      Color(0xFFFFF59D),
                    ],
                    enableGlow: true,
                    glowRadius: 3,
                    blendMode: BlendMode.plus,
                    lifecycle: ParticleLifecycle.shrink,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: topPadding + 90,
                child: IgnorePointer(
                  child: Column(
                    children: [
                      const Eyebrow(
                        '✦  FEEL THE POWER  ✦',
                        color: Color(0xFFB3D4FF),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Thunderstorm',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Color(0xFF82B1FF), blurRadius: 24),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap anywhere to call down lightning',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoltPainter extends CustomPainter {
  const _BoltPainter(this.points, this.t, this.visible);

  final List<Offset> points;
  final double t;
  final bool visible;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible || points.length < 2) return;
    // Bright at first, then flickering out
    final alpha = t < 0.2
        ? 1.0
        : (t < 0.3 ? 0.3 : (1 - t) * 1.2).clamp(0.0, 1.0);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    // A short branch splitting off
    final fork = points[points.length ~/ 2];
    final branch = Path()
      ..moveTo(fork.dx, fork.dy)
      ..lineTo(fork.dx + 34, fork.dy + 40)
      ..lineTo(fork.dx + 24, fork.dy + 70)
      ..lineTo(fork.dx + 52, fork.dy + 110);
    for (final (width, blur, color) in [
      (14.0, 16.0, const Color(0xFF82B1FF)),
      (5.0, 3.0, const Color(0xFFD6E4FF)),
      (2.0, 0.0, Colors.white),
    ]) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: alpha * color.a);
      if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas
        ..drawPath(path, paint)
        ..drawPath(branch, paint..strokeWidth = width * 0.6);
    }
  }

  @override
  bool shouldRepaint(_BoltPainter oldDelegate) => true;
}

/// Dark, heavy clouds drifting across the top of the sky.
class _StormCloudsPainter extends CustomPainter {
  _StormCloudsPainter(this.time) : super(repaint: time);

  final Animation<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(9);
    for (int layer = 0; layer < 3; layer++) {
      final speed = 0.5 + layer * 0.4;
      final color = Color.lerp(
        const Color(0xFF2A3342),
        const Color(0xFF3F4B5E),
        layer / 2,
      )!;
      for (int i = 0; i < 9; i++) {
        final travel = size.width + 300;
        final x =
            (random.nextDouble() * travel + time.value * travel * speed) %
                travel -
            150;
        final y =
            size.height * (0.02 + layer * 0.07 + random.nextDouble() * 0.08);
        final r = 60 + random.nextDouble() * 70;
        canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..color = color.withValues(alpha: 0.9)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StormCloudsPainter oldDelegate) => false;
}

/// Dark fields with a lone tree on the horizon.
class _FieldsPainter extends CustomPainter {
  const _FieldsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ground = Path()
      ..moveTo(0, h * 0.35)
      ..quadraticBezierTo(w * 0.3, h * 0.2, w * 0.6, h * 0.32)
      ..quadraticBezierTo(w * 0.85, h * 0.42, w, h * 0.3)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E2B1C), Color(0xFF0E150D)],
        ).createShader(Offset.zero & size),
    );
    // A lone tree
    final base = Offset(w * 0.72, h * 0.38);
    final trunk = Paint()
      ..color = const Color(0xFF0B100A)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, base + const Offset(0, -60), trunk);
    for (final (dx, dy) in [(-26.0, -84.0), (22.0, -90.0), (-8.0, -104.0)]) {
      canvas.drawLine(
        base + const Offset(0, -50),
        base + Offset(dx, dy),
        trunk..strokeWidth = 3,
      );
    }
    for (final (dx, dy, r) in [
      (-24.0, -92.0, 22.0),
      (20.0, -96.0, 24.0),
      (-4.0, -112.0, 26.0),
    ]) {
      canvas.drawCircle(
        base + Offset(dx, dy),
        r,
        Paint()..color = const Color(0xFF0B100A),
      );
    }
  }

  @override
  bool shouldRepaint(_FieldsPainter oldDelegate) => false;
}
