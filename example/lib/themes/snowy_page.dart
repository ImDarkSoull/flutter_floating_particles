import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// A cabin in the snowy mountains at dusk: a blizzard with depth, snow
/// settling on the roof, chimney smoke and footprints where you walk.
class SnowyPage extends StatefulWidget {
  const SnowyPage({super.key});

  @override
  State<SnowyPage> createState() => _SnowyPageState();
}

class _SnowyPageState extends State<SnowyPage> {
  /// Colliders are rectangles, so the sloped roof is a row of steps that
  /// follow its shape.
  final _roofKeys = List.generate(12, (_) => GlobalKey());
  final _chimneyKey = GlobalKey();
  final _puffs = ParticleController();

  /// Footprints left by dragging across the snow.
  final _footprints = ValueNotifier<List<(Offset, double, bool)>>(const []);
  Offset? _lastStep;
  bool _leftFoot = true;

  @override
  void dispose() {
    _puffs.dispose();
    _footprints.dispose();
    super.dispose();
  }

  void _walk(Offset position) {
    final last = _lastStep;
    if (last != null && (position - last).distance < 26) return;
    final direction = last == null
        ? 0.0
        : atan2(position.dy - last.dy, position.dx - last.dx);
    _lastStep = position;
    _leftFoot = !_leftFoot;
    final prints = [..._footprints.value, (position, direction, _leftFoot)];
    _footprints.value = prints.length > 60
        ? prints.sublist(prints.length - 60)
        : prints;
    _puffs.burst(
      position: position,
      count: 6,
      angle: -pi / 2,
      spread: pi,
      minSpeed: 20,
      maxSpeed: 80,
      gravity: 200,
      lifespan: const Duration(milliseconds: 700),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final groundTop = size.height * 0.68;

    return ThemeScaffold(
      child: ColoredBox(
        color: const Color(0xFF1A2440),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF141B33),
                    Color(0xFF2E3B66),
                    Color(0xFF6B6F9E),
                    Color(0xFFB8A9C9),
                  ],
                  stops: [0, 0.35, 0.6, 0.7],
                ),
              ),
            ),
            // Moon
            Positioned(
              top: padding.top + 70,
              left: 40,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF5F3E7),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: size.height * 0.3,
              height: size.height * 0.42,
              child: const CustomPaint(painter: _PeaksPainter()),
            ),
            // Snowy ground where you leave footprints
            Positioned(
              left: 0,
              right: 0,
              top: groundTop,
              bottom: 0,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE3E8F5), Color(0xFFF7F9FF)],
                  ),
                ),
              ),
            ),
            CustomPaint(painter: _FootprintsPainter(_footprints)),
            Positioned(
              left: 0,
              right: 0,
              top: groundTop,
              bottom: 0,
              child: GestureDetector(
                onPanStart: (d) => _walk(d.globalPosition),
                onPanUpdate: (d) => _walk(d.globalPosition),
                onPanEnd: (_) => _lastStep = null,
              ),
            ),
            // Pine trees
            for (final (fx, s) in const [
              (0.06, 1.1),
              (0.16, 0.8),
              (0.86, 1.2),
              (0.95, 0.85),
            ])
              Positioned(
                left: size.width * fx - 30 * s,
                top: groundTop - 110 * s + 8,
                child: IgnorePointer(
                  child: CustomPaint(
                    size: Size(60 * s, 110 * s),
                    painter: const _PinePainter(),
                  ),
                ),
              ),
            // The cabin, with a roof that collects snow
            Positioned(
              left: size.width / 2 - 90,
              top: groundTop - 128,
              child: IgnorePointer(
                child: SizedBox(
                  width: 180,
                  height: 140,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const CustomPaint(
                        size: Size(180, 140),
                        painter: _CabinPainter(),
                      ),
                      for (int i = 0; i < 12; i++)
                        Positioned(
                          left: i * 15.0,
                          // The roof rises from y = 62 at the eaves to 26 at
                          // the ridge in the middle
                          top:
                              62 -
                              36 * (1 - ((i + 0.5) * 15 - 90).abs() / 90) -
                              2,
                          width: 15,
                          height: 8,
                          child: SizedBox(key: _roofKeys[i]),
                        ),
                      Positioned(
                        left: 124,
                        top: -2,
                        child: SizedBox(key: _chimneyKey, width: 16, height: 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Chimney smoke
            IgnorePointer(
              child: ParticleEffects(
                config: ParticleConfig(
                  particleCount: 0,
                  minSize: 16,
                  maxSize: 32,
                  particleColor: const Color(0xFFCFD3E0),
                  enableBlur: true,
                  blurSigma: 7,
                  minOpacity: 0,
                  maxOpacity: 0.45,
                  enableOpacityAnimation: false,
                  lifecycle: ParticleLifecycle.growAndFade,
                  emitters: [
                    ParticleEmitter(
                      followKey: _chimneyKey,
                      rate: 5,
                      spread: pi / 8,
                      minSpeed: 18,
                      maxSpeed: 34,
                      gravity: -8,
                      drag: 0.2,
                      lifespan: const Duration(seconds: 5),
                    ),
                  ],
                ),
              ),
            ),
            // Blizzard, settling on the roof
            IgnorePointer(
              child: ParticleEffects(
                colliders: _roofKeys,
                collision: const ParticleCollision(
                  settleDuration: Duration(seconds: 20),
                  maxSettled: 160,
                ),
                config: ParticleConfig.blizzard.copyWith(
                  particleCount: 170,
                  wind: 0.2,
                ),
              ),
            ),
            IgnorePointer(
              child: ParticleEffects(
                controller: _puffs,
                config: const ParticleConfig(
                  particleCount: 0,
                  minSize: 2,
                  maxSize: 5,
                  particleColor: Colors.white,
                  enableOpacityAnimation: false,
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: padding.top + 120,
              child: IgnorePointer(
                child: Column(
                  children: [
                    const Eyebrow(
                      '✦  WINTER WONDERLAND  ✦',
                      color: Color(0xFFE3E8F5),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Snowy\nMountains',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 50,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Color(0xFF8C9EFF), blurRadius: 24),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Walk through the snow — drag along the ground',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
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

class _FootprintsPainter extends CustomPainter {
  _FootprintsPainter(this.prints) : super(repaint: prints);

  final ValueNotifier<List<(Offset, double, bool)>> prints;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9AA6C4).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (final (position, direction, left) in prints.value) {
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(direction + pi / 2)
        ..translate(left ? -7 : 7, 0)
        ..drawOval(const Rect.fromLTWH(-4, -7, 8, 12), paint)
        ..drawOval(const Rect.fromLTWH(-3, 6, 6, 5), paint)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_FootprintsPainter oldDelegate) => false;
}

class _PeaksPainter extends CustomPainter {
  const _PeaksPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    void range(List<(double, double)> peaks, Color lit, Color shade) {
      for (final (px, py) in peaks) {
        final peak = Offset(w * px, h * py);
        final spread = w * 0.3;
        final ridge = Offset(peak.dx + spread * 0.15, h);
        canvas
          ..drawPath(
            Path()
              ..moveTo(peak.dx, peak.dy)
              ..lineTo(peak.dx - spread, h)
              ..lineTo(ridge.dx, ridge.dy)
              ..close(),
            Paint()..color = lit,
          )
          ..drawPath(
            Path()
              ..moveTo(peak.dx, peak.dy)
              ..lineTo(ridge.dx, ridge.dy)
              ..lineTo(peak.dx + spread, h)
              ..close(),
            Paint()..color = shade,
          );
      }
    }

    range(
      const [(0.15, 0.2), (0.45, 0.02), (0.78, 0.15)],
      const Color(0xFFD9DEF0),
      const Color(0xFF9FA8CC),
    );
    range(
      const [(0.0, 0.45), (0.3, 0.38), (0.62, 0.42), (1.0, 0.36)],
      const Color(0xFFC5CCE6),
      const Color(0xFF8590B8),
    );
  }

  @override
  bool shouldRepaint(_PeaksPainter oldDelegate) => false;
}

class _PinePainter extends CustomPainter {
  const _PinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.44, h * 0.82, w * 0.12, h * 0.18),
      Paint()..color = const Color(0xFF3E2C23),
    );
    for (int i = 0; i < 3; i++) {
      final top = h * (0.02 + i * 0.24);
      final bottom = top + h * 0.4;
      final half = w * (0.26 + i * 0.12);
      final tier = Path()
        ..moveTo(w / 2, top)
        ..lineTo(w / 2 + half, bottom)
        ..lineTo(w / 2 - half, bottom)
        ..close();
      canvas.drawPath(tier, Paint()..color = const Color(0xFF1F3B32));
      // Snow on the branches
      canvas.drawPath(
        Path()
          ..moveTo(w / 2, top)
          ..lineTo(w / 2 + half * 0.5, top + (bottom - top) * 0.5)
          ..lineTo(w / 2, top + (bottom - top) * 0.4)
          ..lineTo(w / 2 - half * 0.5, top + (bottom - top) * 0.5)
          ..close(),
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(_PinePainter oldDelegate) => false;
}

/// A log cabin with warm glowing windows.
class _CabinPainter extends CustomPainter {
  const _CabinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const walls = Rect.fromLTWH(20, 58, 140, 82);
    // Warm light spilling onto the snow
    canvas.drawOval(
      const Rect.fromLTWH(10, 120, 160, 40),
      Paint()
        ..color = const Color(0xFFFFB74D).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawRect(walls, Paint()..color = const Color(0xFF6D4431));
    // Log lines
    for (double y = walls.top + 10; y < walls.bottom; y += 10) {
      canvas.drawLine(
        Offset(walls.left, y),
        Offset(walls.right, y),
        Paint()
          ..strokeWidth = 1.5
          ..color = const Color(0xFF4E2F21),
      );
    }
    // Chimney
    canvas.drawRect(
      const Rect.fromLTWH(124, 0, 16, 40),
      Paint()..color = const Color(0xFF5D4037),
    );
    // Roof
    canvas.drawPath(
      Path()
        ..moveTo(0, 62)
        ..lineTo(90, 26)
        ..lineTo(180, 62)
        ..close(),
      Paint()..color = const Color(0xFF3E2723),
    );
    // Windows and door
    for (final rect in const [
      Rect.fromLTWH(36, 78, 30, 26),
      Rect.fromLTWH(114, 78, 30, 26),
    ]) {
      canvas
        ..drawRect(
          rect.inflate(6),
          Paint()
            ..color = const Color(0xFFFFCA28).withValues(alpha: 0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        )
        ..drawRect(rect, Paint()..color = const Color(0xFFFFD54F))
        ..drawLine(
          rect.topCenter,
          rect.bottomCenter,
          Paint()
            ..color = const Color(0xFF4E2F21)
            ..strokeWidth = 2,
        )
        ..drawLine(
          rect.centerLeft,
          rect.centerRight,
          Paint()
            ..color = const Color(0xFF4E2F21)
            ..strokeWidth = 2,
        );
    }
    canvas.drawRect(
      const Rect.fromLTWH(78, 96, 24, 44),
      Paint()..color = const Color(0xFF3E2723),
    );
  }

  @override
  bool shouldRepaint(_CabinPainter oldDelegate) => false;
}
