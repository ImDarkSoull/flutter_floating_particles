import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// An original sorcerer theme: draw a spell with your finger and it
/// erupts when you let go; runes orbit a portal you can open.
class ArcanePage extends StatefulWidget {
  const ArcanePage({super.key});

  @override
  State<ArcanePage> createState() => _ArcanePageState();
}

class _ArcanePageState extends State<ArcanePage> with TickerProviderStateMixin {
  final _sparks = ParticleController();
  final _portal = ParticleController();
  final _portalKey = GlobalKey();

  /// The spell being drawn, and when each point was added.
  final _spell = <(Offset, double)>[];
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(days: 1),
  )..forward();
  late final _runes = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();
  late final _opening = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  double get _now => _clock.lastElapsedDuration?.inMilliseconds.toDouble() ?? 0;

  @override
  void dispose() {
    _clock.dispose();
    _runes.dispose();
    _opening.dispose();
    _sparks.dispose();
    _portal.dispose();
    super.dispose();
  }

  void _draw(Offset point) {
    _spell.add((point, _now));
    _sparks.burst(
      position: point,
      count: 3,
      minSpeed: 10,
      maxSpeed: 60,
      gravity: -20,
      drag: 1.5,
      lifespan: const Duration(milliseconds: 900),
    );
  }

  /// The spell erupts along its whole path.
  void _cast() {
    for (int i = 0; i < _spell.length; i += 4) {
      _sparks.burst(
        position: _spell[i].$1,
        count: 6,
        minSpeed: 60,
        maxSpeed: 260,
        gravity: -30,
        drag: 1.4,
        lifespan: const Duration(milliseconds: 1400),
      );
    }
  }

  void _openPortal() {
    _opening.forward(from: 0);
    _portal.burstFromKey(
      _portalKey,
      count: 120,
      minSpeed: 150,
      maxSpeed: 600,
      gravity: 0,
      drag: 1.3,
      lifespan: const Duration(milliseconds: 1800),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return ThemeScaffold(
      child: ColoredBox(
        color: const Color(0xFF0B0418),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.0,
                  colors: [Color(0xFF2A0E4A), Color(0xFF0B0418)],
                ),
              ),
            ),
            // Mystic motes
            const ParticleEffects(
              config: ParticleConfig(
                particleTypes: [ParticleType.sparkle, ParticleType.circle],
                direction: ParticleDirection.bottomToTop,
                particleCount: 40,
                minSize: 2,
                maxSize: 6,
                gradientColors: [
                  Color(0xFFE1BEE7),
                  Color(0xFFFFD54F),
                  Color(0xFF80DEEA),
                ],
                enableGlow: true,
                glowRadius: 2,
                minOpacity: 0.1,
                velocityMultiplier: 0.25,
                driftAmplitude: 30,
                blendMode: BlendMode.plus,
                seed: 17,
              ),
            ),
            // Runes orbiting the portal
            Positioned(
              left: 0,
              right: 0,
              top: padding.top + 220,
              child: Center(
                child: GestureDetector(
                  onTap: _openPortal,
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(260, 260),
                          painter: _RunesPainter(_runes, _opening),
                        ),
                        SizedBox(key: _portalKey, width: 40, height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // The glowing line of the spell being drawn
            IgnorePointer(
              child: CustomPaint(painter: _SpellPainter(_clock, _spell)),
            ),
            // Drawing surface over everything but the portal and title
            Positioned.fill(
              top: padding.top + 490,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) => _draw(d.globalPosition),
                onPanUpdate: (d) => _draw(d.globalPosition),
                onPanEnd: (_) => _cast(),
              ),
            ),
            IgnorePointer(
              child: ParticleEffects(
                controller: _sparks,
                config: const ParticleConfig(
                  particleCount: 0,
                  particleTypes: [
                    ParticleType.sparkle,
                    ParticleType.star,
                    ParticleType.circle,
                  ],
                  minSize: 3,
                  maxSize: 9,
                  gradientColors: [
                    Color(0xFFFFD54F),
                    Color(0xFFFFF8E1),
                    Color(0xFFFFAB40),
                  ],
                  enableGlow: true,
                  glowRadius: 3,
                  enableRotation: true,
                  blendMode: BlendMode.plus,
                  lifecycle: ParticleLifecycle.shrink,
                ),
              ),
            ),
            IgnorePointer(
              child: ParticleEffects(
                controller: _portal,
                config: const ParticleConfig(
                  particleCount: 0,
                  particleTypes: [ParticleType.sparkle, ParticleType.streak],
                  minSize: 4,
                  maxSize: 14,
                  gradientColors: [
                    Color(0xFFE040FB),
                    Color(0xFF7C4DFF),
                    Color(0xFFFFD54F),
                  ],
                  enableGlow: true,
                  glowRadius: 3,
                  blendMode: BlendMode.plus,
                  trail: ParticleTrail(length: 4),
                  lifecycle: ParticleLifecycle.shrink,
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: padding.top + 80,
              child: const IgnorePointer(
                child: Column(
                  children: [
                    Eyebrow(
                      '✦  MASTER OF THE MYSTIC ARTS  ✦',
                      color: Color(0xFFE1BEE7),
                    ),
                    SizedBox(height: 8),
                    GradientText(
                      'ARCANE',
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFE040FB)],
                      ),
                      glow: Color(0xAAE040FB),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: padding.bottom + 40,
              child: IgnorePointer(
                child: Text(
                  'Tap the portal to open it\nDraw a spell below and let go to cast it',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The spell's line, fading over a couple of seconds.
class _SpellPainter extends CustomPainter {
  _SpellPainter(this.clock, this.points) : super(repaint: clock);

  final AnimationController clock;
  final List<(Offset, double)> points;

  @override
  void paint(Canvas canvas, Size size) {
    final now = clock.lastElapsedDuration?.inMilliseconds.toDouble() ?? 0;
    points.removeWhere((p) => now - p.$2 > 2200);
    for (int i = 1; i < points.length; i++) {
      final (a, ta) = points[i - 1];
      final (b, _) = points[i];
      if ((b - a).distance > 60) continue; // a new stroke
      final fade = (1 - (now - ta) / 2200).clamp(0.0, 1.0);
      for (final (width, blur, color) in [
        (12.0, 10.0, const Color(0xFFFFAB40)),
        (3.0, 0.0, const Color(0xFFFFF8E1)),
      ]) {
        final paint = Paint()
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: fade);
        if (blur > 0) {
          paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
        }
        canvas.drawLine(a, b, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SpellPainter oldDelegate) => false;
}

/// Rune circles turning around a portal.
class _RunesPainter extends CustomPainter {
  _RunesPainter(this.turn, this.opening)
    : super(repaint: Listenable.merge([turn, opening]));

  final Animation<double> turn;
  final AnimationController opening;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final t = turn.value * 2 * pi;
    final open = opening.isAnimating ? sin(opening.value * pi) : 0.0;
    const gold = Color(0xFFFFD54F);

    // The portal
    canvas.drawCircle(
      center,
      44 + open * 30,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            const Color(0xFFE040FB).withValues(alpha: 0.6),
            const Color(0xFF7C4DFF).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 74)),
    );

    for (final (radius, speed, count) in [(118.0, 1.0, 16), (90.0, -1.6, 10)]) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = gold.withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
      );
      canvas.drawCircle(
        center,
        radius - 12,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = gold.withValues(alpha: 0.4),
      );
      // Rune glyphs between the rings
      for (int i = 0; i < count; i++) {
        final angle = t * speed * 0.3 + i * 2 * pi / count;
        final at = center + Offset(cos(angle), sin(angle)) * (radius - 6);
        canvas
          ..save()
          ..translate(at.dx, at.dy)
          ..rotate(angle + pi / 2);
        final glyph = Path();
        switch (i % 4) {
          case 0:
            glyph
              ..moveTo(-4, 4)
              ..lineTo(0, -4)
              ..lineTo(4, 4);
          case 1:
            glyph
              ..moveTo(0, -4)
              ..lineTo(0, 4)
              ..moveTo(-3, -1)
              ..lineTo(3, 1);
          case 2:
            glyph.addOval(Rect.fromCircle(center: Offset.zero, radius: 3));
          default:
            glyph
              ..moveTo(-4, -3)
              ..lineTo(4, -3)
              ..lineTo(-4, 3)
              ..lineTo(4, 3);
        }
        canvas
          ..drawPath(
            glyph,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = gold,
          )
          ..restore();
      }
    }
    // A star inscribed in the outer ring
    final star = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + t * 0.2 + i * 4 * pi / 5;
      final p = center + Offset(cos(angle), sin(angle)) * 106;
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      star..close(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = gold.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_RunesPainter oldDelegate) => false;
}
