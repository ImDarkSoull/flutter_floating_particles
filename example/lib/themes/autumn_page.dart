import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// An autumn forest in golden light: leaves piling up on a bench and the
/// ground, gusts of wind, and mushrooms that puff glowing spores.
class AutumnPage extends StatefulWidget {
  const AutumnPage({super.key});

  @override
  State<AutumnPage> createState() => _AutumnPageState();
}

class _AutumnPageState extends State<AutumnPage> with TickerProviderStateMixin {
  final _benchKey = GlobalKey();
  final _groundKey = GlobalKey();
  final _mushroomKeys = List.generate(3, (_) => GlobalKey());
  final _spores = ParticleController();

  /// A gust shifts every leaf sideways through the parallax offset.
  final _gustOffset = ValueNotifier(Offset.zero);
  late final AnimationController _gust =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      )..addListener(() {
        // Rises quickly, then eases off; the offset keeps what it gained
        final t = Curves.easeOutCubic.transform(_gust.value);
        _gustOffset.value = Offset(_gustStart - t * 420, 0);
      });
  double _gustStart = 0;

  late final _light = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _gust.dispose();
    _light.dispose();
    _gustOffset.dispose();
    _spores.dispose();
    super.dispose();
  }

  void _blow() {
    _gustStart = _gustOffset.value.dx;
    _gust.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final groundTop = size.height * 0.78;

    return ThemeScaffold(
      child: ColoredBox(
        color: const Color(0xFF3E2415),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFC46B),
                    Color(0xFFE08A3C),
                    Color(0xFF8C4A22),
                    Color(0xFF3E2415),
                  ],
                  stops: [0, 0.35, 0.7, 1],
                ),
              ),
            ),
            // Sun rays through the trees
            AnimatedBuilder(
              animation: _light,
              builder: (context, _) =>
                  CustomPaint(painter: _LightRaysPainter(_light.value)),
            ),
            const CustomPaint(painter: _TreesPainter()),
            // The forest floor, which collects leaves
            Positioned(
              key: _groundKey,
              left: 0,
              right: 0,
              top: groundTop,
              bottom: 0,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6B3A1E), Color(0xFF3E2415)],
                  ),
                ),
              ),
            ),
            // A park bench
            Positioned(
              left: size.width * 0.52,
              top: groundTop - 64,
              child: SizedBox(
                width: 150,
                height: 70,
                child: Stack(
                  children: [
                    const CustomPaint(
                      size: Size(150, 70),
                      painter: _BenchPainter(),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 26,
                      height: 8,
                      child: SizedBox(key: _benchKey),
                    ),
                  ],
                ),
              ),
            ),
            // Mushrooms that puff spores
            for (int i = 0; i < 3; i++)
              Positioned(
                left: size.width * (0.08 + i * 0.13),
                top: groundTop - 34 + (i.isOdd ? 8 : 0),
                child: GestureDetector(
                  onTap: () => _spores.burstFromKey(
                    _mushroomKeys[i],
                    count: 30,
                    angle: -pi / 2,
                    spread: pi / 1.5,
                    minSpeed: 30,
                    maxSpeed: 110,
                    gravity: -25,
                    drag: 1.2,
                    lifespan: const Duration(milliseconds: 2400),
                  ),
                  child: CustomPaint(
                    key: _mushroomKeys[i],
                    size: Size(34 - i * 4.0, 36 - i * 4.0),
                    painter: const _MushroomPainter(),
                  ),
                ),
              ),

            // Falling leaves, settling on the bench and the ground
            IgnorePointer(
              child: ParticleEffects(
                parallax: _gustOffset,
                colliders: [_benchKey, _groundKey],
                collision: const ParticleCollision(
                  settleDuration: Duration(seconds: 18),
                  maxSettled: 140,
                ),
                config: ParticleConfig.fallingLeaves.copyWith(
                  particleTypes: const [
                    ParticleType.leaf,
                    ParticleType.leaf,
                    ParticleType.petal,
                  ],
                  particleCount: 55,
                  minSize: 9,
                  maxSize: 18,
                  gradientColors: const [
                    Color(0xFFD84315),
                    Color(0xFFEF6C00),
                    Color(0xFFFFA000),
                    Color(0xFFFFC107),
                    Color(0xFF8D6E63),
                    Color(0xFFC62828),
                  ],
                  wind: 0.2,
                  depthEffect: 0.6,
                  parallaxFactor: 1,
                ),
              ),
            ),
            // Glowing spores
            IgnorePointer(
              child: ParticleEffects(
                controller: _spores,
                config: const ParticleConfig(
                  particleCount: 0,
                  minSize: 2,
                  maxSize: 5,
                  gradientColors: [Color(0xFFFFF59D), Color(0xFFE6EE9C)],
                  enableGlow: true,
                  glowRadius: 3,
                  blendMode: BlendMode.plus,
                  lifecycle: ParticleLifecycle.shrink,
                ),
              ),
            ),
            // Dust drifting in the light
            const IgnorePointer(
              child: ParticleEffects(
                config: ParticleConfig(
                  direction: ParticleDirection.none,
                  particleCount: 30,
                  minSize: 1.5,
                  maxSize: 3,
                  particleColor: Color(0xFFFFF3C4),
                  enableGlow: true,
                  glowRadius: 2,
                  minOpacity: 0,
                  maxOpacity: 0.6,
                  velocityMultiplier: 0.2,
                  driftAmplitude: 25,
                  blendMode: BlendMode.plus,
                  seed: 7,
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: padding.top + 90,
              child: Column(
                children: [
                  const Eyebrow(
                    '✦  THE GOLDEN SEASON  ✦',
                    color: Color(0xFF5D2E12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Autumn\nForest',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 54,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFF3E0),
                      shadows: [
                        Shadow(
                          color: Color(0x885D2E12),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FestiveButton(
                    label: '🍃  Gust of wind',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE0B2), Color(0xFFFFB74D)],
                    ),
                    glow: const Color(0xFFFF9800),
                    textColor: const Color(0xFF5D2E12),
                    onPressed: _blow,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap a mushroom',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFF3E0),
                      shadows: [
                        Shadow(color: Color(0xCC3E2415), blurRadius: 8),
                      ],
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

class _LightRaysPainter extends CustomPainter {
  const _LightRaysPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.8, -40);
    for (int i = 0; i < 6; i++) {
      final angle = pi * 0.55 + i * 0.09 + sin(t * pi + i) * 0.02;
      final end = origin + Offset(cos(angle), sin(angle)) * size.height * 1.3;
      final side = Offset(-sin(angle), cos(angle)) * (18 + i * 6.0);
      canvas.drawPath(
        Path()
          ..moveTo(origin.dx, origin.dy)
          ..lineTo(end.dx + side.dx, end.dy + side.dy)
          ..lineTo(end.dx - side.dx, end.dy - side.dy)
          ..close(),
        Paint()
          ..color = const Color(
            0xFFFFF3C4,
          ).withValues(alpha: 0.08 + 0.04 * sin(t * pi * 2 + i))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
  }

  @override
  bool shouldRepaint(_LightRaysPainter oldDelegate) => oldDelegate.t != t;
}

/// Tree trunks in the misty distance and close by, with leafy autumn
/// canopies built from many small, softly shaded clusters.
class _TreesPainter extends CustomPainter {
  const _TreesPainter();

  static const _foliage = [
    Color(0xFFD84315),
    Color(0xFFEF6C00),
    Color(0xFFFFA000),
    Color(0xFFC62828),
    Color(0xFFFFB300),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(13);
    final w = size.width;
    final h = size.height;
    for (int layer = 0; layer < 2; layer++) {
      final far = layer == 0;
      final trunkColor = far
          ? const Color(0x668C4A22)
          : const Color(0xFF4E2A15);
      for (int i = 0; i < (far ? 7 : 4); i++) {
        final x = w * random.nextDouble();
        final width = far
            ? 10 + random.nextDouble() * 8
            : 20 + random.nextDouble() * 16;
        canvas.drawRect(
          Rect.fromLTWH(x, h * 0.12, width, h * 0.73),
          Paint()..color = trunkColor,
        );
        // Branches reaching into the canopy
        for (final side in [-1.0, 1.0]) {
          canvas.drawLine(
            Offset(x + width / 2, h * 0.3),
            Offset(
              x + width / 2 + side * (30 + random.nextDouble() * 30),
              h * 0.16,
            ),
            Paint()
              ..strokeWidth = width * 0.35
              ..strokeCap = StrokeCap.round
              ..color = trunkColor,
          );
        }
        // Canopy: darker clusters underneath, lighter sunlit ones on top
        final canopy = Offset(x + width / 2, h * 0.14);
        for (int c = 0; c < (far ? 16 : 28); c++) {
          final spread = Offset(
            (random.nextDouble() - 0.5) * (far ? 130 : 170),
            (random.nextDouble() - 0.6) * (far ? 70 : 100),
          );
          final r = (far ? 14 : 18) + random.nextDouble() * (far ? 14 : 20);
          final lit = spread.dy < 0;
          final base = _foliage[random.nextInt(_foliage.length)];
          final color = Color.lerp(
            base,
            lit ? const Color(0xFFFFE082) : const Color(0xFF5D1A08),
            lit ? 0.2 : 0.3,
          )!;
          canvas.drawCircle(
            canopy + spread,
            r,
            Paint()
              ..color = color.withValues(alpha: far ? 0.35 : 0.92)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, far ? 4 : 1.5),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TreesPainter oldDelegate) => false;
}

class _BenchPainter extends CustomPainter {
  const _BenchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wood = Paint()..color = const Color(0xFF6D4C35);
    final iron = Paint()
      ..color = const Color(0xFF263238)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    // Backrest slats, seat and legs
    for (final y in [0.0, 12.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(6, y, size.width - 12, 8),
          const Radius.circular(2),
        ),
        wood,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 30, size.width, 10),
        const Radius.circular(2),
      ),
      wood,
    );
    for (final x in [14.0, size.width - 14]) {
      canvas
        ..drawLine(Offset(x, 0), Offset(x, size.height), iron)
        ..drawLine(Offset(x, 40), Offset(x - 8, size.height), iron);
    }
  }

  @override
  bool shouldRepaint(_BenchPainter oldDelegate) => false;
}

class _MushroomPainter extends CustomPainter {
  const _MushroomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.35, h * 0.45, w * 0.3, h * 0.55),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFF5E6D3),
      )
      ..drawPath(
        Path()
          ..moveTo(0, h * 0.55)
          ..quadraticBezierTo(w / 2, -h * 0.2, w, h * 0.55)
          ..close(),
        Paint()..color = const Color(0xFFC62828),
      );
    for (final (fx, fy, r) in [
      (0.3, 0.3, 0.08),
      (0.62, 0.22, 0.07),
      (0.5, 0.42, 0.05),
    ]) {
      canvas.drawCircle(
        Offset(w * fx, h * fy),
        w * r,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_MushroomPainter oldDelegate) => false;
}
