import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';
import 'scenery.dart';

/// A rainy day seen from a cosy window: drops sliding down the glass and
/// gathering on the frame, fog you can wipe away, lightning in the distance
/// and a steaming cup of chai.
class RainyPage extends StatefulWidget {
  const RainyPage({super.key});

  @override
  State<RainyPage> createState() => _RainyPageState();
}

class _RainyPageState extends State<RainyPage> with TickerProviderStateMixin {
  final _cupKey = GlobalKey();
  final _railKey = GlobalKey();
  final _mullionKey = GlobalKey();
  final _random = Random();

  /// Where the fog has been wiped, and when.
  final _wipes = <(Offset, double)>[];
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(days: 1),
  )..forward();
  late final _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  Timer? _lightning;

  double get _now => _clock.lastElapsedDuration?.inMilliseconds.toDouble() ?? 0;

  @override
  void initState() {
    super.initState();
    _scheduleLightning();
  }

  void _scheduleLightning() {
    _lightning = Timer(Duration(seconds: 5 + _random.nextInt(6)), () {
      if (!mounted) return;
      _flash.forward(from: 0);
      _scheduleLightning();
    });
  }

  @override
  void dispose() {
    _lightning?.cancel();
    _clock.dispose();
    _flash.dispose();
    super.dispose();
  }

  void _wipe(Offset position) {
    _wipes.add((position, _now));
    // Old wipes have fogged over again
    _wipes.removeWhere((w) => _now - w.$2 > 14000);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final window = Rect.fromLTWH(
      22,
      padding.top + 64,
      size.width - 44,
      size.height * 0.56,
    );
    final glass = window.deflate(14);

    return ThemeScaffold(
      child: ColoredBox(
        color: const Color(0xFF2B2420),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // A warm, dim room
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0.9),
                  radius: 1.2,
                  colors: [
                    Color(0xFF5A4636),
                    Color(0xFF2B2420),
                    Color(0xFF1A1512),
                  ],
                ),
              ),
            ),

            // The view outside
            Positioned.fromRect(
              rect: glass,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF3D4B5C),
                            Color(0xFF5E6E80),
                            Color(0xFF8595A6),
                          ],
                        ),
                      ),
                    ),
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: const Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: CitySkylinePainter(
                              far: Color(0xFF4A5868),
                              near: Color(0xFF2E3A48),
                              window: Color(0xFFFFD180),
                              seed: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Rain outside, with splashes on the street
                    ParticleEffects(
                      config: ParticleConfig.rain.copyWith(
                        particleCount: 140,
                        particleColor: const Color(0xFFCFE0F0),
                        splash: const ParticleSplash(
                          count: 3,
                          size: 1.6,
                          color: Color(0xFFE3EEF8),
                        ),
                        depthEffect: 0.8,
                        wind: 0.12,
                      ),
                    ),
                    // Lightning somewhere behind the city
                    AnimatedBuilder(
                      animation: _flash,
                      builder: (context, _) {
                        final t = _flash.value;
                        // Two quick flickers
                        final flicker = t < 0.15
                            ? t / 0.15
                            : t < 0.3
                            ? 1 - (t - 0.15) / 0.15 * 0.8
                            : t < 0.4
                            ? 0.2 + (t - 0.3) / 0.1 * 0.6
                            : (1 - t) / 0.6 * 0.8;
                        return ColoredBox(
                          color: Colors.white.withValues(
                            alpha: _flash.isAnimating ? flicker * 0.5 : 0,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Beads of water stuck to the glass
            Positioned.fromRect(
              rect: glass,
              child: const ParticleEffects(
                config: ParticleConfig(
                  particleTypes: [ParticleType.circle, ParticleType.raindrop],
                  direction: ParticleDirection.none,
                  particleCount: 90,
                  minSize: 2,
                  maxSize: 7,
                  particleColor: Color(0xFFE8F1FA),
                  minOpacity: 0.25,
                  maxOpacity: 0.6,
                  velocityMultiplier: 0.1,
                  driftAmplitude: 0.6,
                  seed: 15,
                ),
              ),
            ),
            // Drops sliding down the glass, gathering on the frame
            Positioned.fromRect(
              rect: glass,
              child: ParticleEffects(
                colliders: [_mullionKey, _railKey],
                collision: const ParticleCollision(
                  settleDuration: Duration(seconds: 9),
                  maxSettled: 60,
                ),
                config: const ParticleConfig(
                  particleType: ParticleType.raindrop,
                  particleCount: 24,
                  minSize: 5,
                  maxSize: 10,
                  particleColor: Color(0xFFEAF3FB),
                  minOpacity: 0.55,
                  maxOpacity: 0.85,
                  enableOpacityAnimation: false,
                  velocityMultiplier: 0.35,
                  animationDuration: Duration(seconds: 14),
                  driftAmplitude: 4,
                  trail: ParticleTrail(
                    length: 10,
                    spacing: Duration(milliseconds: 90),
                    endScale: 0.35,
                    endOpacity: 0,
                  ),
                  seed: 4,
                ),
              ),
            ),

            // Fog on the glass, wiped away by your finger
            Positioned.fromRect(
              rect: glass,
              child: GestureDetector(
                onPanStart: (d) => _wipe(d.localPosition),
                onPanUpdate: (d) => _wipe(d.localPosition),
                child: CustomPaint(
                  painter: _FogPainter(_clock, _wipes),
                  child: const SizedBox.expand(),
                ),
              ),
            ),

            // Window frame, with the cross bar and bottom rail as colliders
            Positioned.fromRect(
              rect: window,
              child: const IgnorePointer(
                child: CustomPaint(painter: _WindowFramePainter()),
              ),
            ),
            Positioned(
              left: glass.left,
              right: size.width - glass.right,
              top: glass.center.dy - 5,
              height: 10,
              child: SizedBox(key: _mullionKey),
            ),
            Positioned(
              left: glass.left,
              right: size.width - glass.right,
              top: glass.bottom - 2,
              height: 16,
              child: SizedBox(key: _railKey),
            ),

            // Windowsill with a cup of chai
            Positioned(
              left: 0,
              right: 0,
              top: window.bottom,
              height: 40,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF8D6E4C), Color(0xFF5D4632)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x88000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 44,
              top: window.bottom - 50,
              child: SizedBox(
                width: 64,
                height: 58,
                child: Stack(
                  children: [
                    const CustomPaint(
                      size: Size(64, 58),
                      painter: _ChaiPainter(),
                    ),
                    Positioned(
                      left: 14,
                      top: 4,
                      child: SizedBox(key: _cupKey, width: 30, height: 4),
                    ),
                  ],
                ),
              ),
            ),
            // Steam rising from the chai
            IgnorePointer(
              child: ParticleEffects(
                config: ParticleConfig(
                  particleCount: 0,
                  minSize: 14,
                  maxSize: 26,
                  particleColor: Colors.white,
                  enableBlur: true,
                  blurSigma: 6,
                  minOpacity: 0,
                  maxOpacity: 0.35,
                  enableOpacityAnimation: false,
                  lifecycle: ParticleLifecycle.growAndFade,
                  emitters: [
                    ParticleEmitter(
                      followKey: _cupKey,
                      rate: 5,
                      spread: pi / 6,
                      minSpeed: 12,
                      maxSpeed: 28,
                      gravity: -12,
                      drag: 0.3,
                      lifespan: const Duration(milliseconds: 3200),
                    ),
                  ],
                ),
              ),
            ),

            // Title
            Positioned(
              left: 24,
              right: 24,
              top: window.bottom + 56,
              child: Column(
                children: [
                  const Text(
                    'Rainy Day',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF5E6D3),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Perfect weather for a cup of chai ☕',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFFF5E6D3).withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Wipe the foggy glass with your finger',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFF5E6D3).withValues(alpha: 0.6),
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

/// Condensation on the glass, with clear streaks where it was wiped. Wiped
/// areas slowly fog up again.
class _FogPainter extends CustomPainter {
  _FogPainter(this.clock, this.wipes) : super(repaint: clock);

  final AnimationController clock;
  final List<(Offset, double)> wipes;

  @override
  void paint(Canvas canvas, Size size) {
    final now = clock.lastElapsedDuration?.inMilliseconds.toDouble() ?? 0;
    final bounds = Offset.zero & size;
    canvas.saveLayer(bounds, Paint());
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.3),
          ],
        ).createShader(bounds),
    );
    for (final (point, time) in wipes) {
      final age = (now - time) / 14000;
      if (age >= 1) continue;
      canvas.drawCircle(
        point,
        26,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..color = Colors.black.withValues(alpha: (1 - age) * 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FogPainter oldDelegate) => false;
}

class _WindowFramePainter extends CustomPainter {
  const _WindowFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Offset.zero & size;
    final glass = outer.deflate(14);
    final wood = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6D4C35), Color(0xFF9C7355), Color(0xFF6D4C35)],
      ).createShader(outer);
    final frame = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(RRect.fromRectAndRadius(outer, const Radius.circular(6)))
      ..addRect(glass);
    canvas.drawPath(frame, wood);
    // Cross bars dividing four panes
    canvas
      ..drawRect(
        Rect.fromCenter(center: glass.center, width: 10, height: glass.height),
        wood,
      )
      ..drawRect(
        Rect.fromCenter(center: glass.center, width: glass.width, height: 10),
        wood,
      );
    // Inner shadow along the glass edge
    canvas.drawRect(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.black.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_WindowFramePainter oldDelegate) => false;
}

/// A cup of milky chai on a saucer.
class _ChaiPainter extends CustomPainter {
  const _ChaiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cup = Rect.fromLTWH(10, 4, 38, 40);
    canvas
      ..drawOval(
        const Rect.fromLTWH(2, 40, 56, 12),
        Paint()..color = const Color(0xFFE8E0D8),
      )
      ..drawPath(
        Path()
          ..moveTo(cup.left, cup.top + 4)
          ..lineTo(cup.right, cup.top + 4)
          ..quadraticBezierTo(cup.right, cup.bottom, cup.center.dx, cup.bottom)
          ..quadraticBezierTo(cup.left, cup.bottom, cup.left, cup.top + 4)
          ..close(),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFD7CFC7), Color(0xFFFFFFFF), Color(0xFFCFC6BD)],
          ).createShader(cup),
      )
      ..drawOval(
        Rect.fromLTWH(cup.left, cup.top, cup.width, 9),
        Paint()..color = const Color(0xFFC18E5C),
      )
      ..drawArc(
        const Rect.fromLTWH(42, 14, 16, 16),
        -pi / 2,
        pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0xFFE8E0D8),
      );
  }

  @override
  bool shouldRepaint(_ChaiPainter oldDelegate) => false;
}
