import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// An original cosmic superhero theme: a nebula at warp speed, a pulsing
/// energy core, a power blast with a shockwave, and runes to connect.
class CosmicPage extends StatefulWidget {
  const CosmicPage({super.key});

  @override
  State<CosmicPage> createState() => _CosmicPageState();
}

class _CosmicPageState extends State<CosmicPage> with TickerProviderStateMixin {
  final _coreKey = GlobalKey();
  final _blast = ParticleController();
  final _random = Random();

  late final _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();
  late final _shockwave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void dispose() {
    _orbit.dispose();
    _shockwave.dispose();
    _blast.dispose();
    super.dispose();
  }

  void _powerBlast() {
    _shockwave.forward(from: 0);
    _blast.burstFromKey(
      _coreKey,
      count: 140,
      minSpeed: 200,
      maxSpeed: 900,
      gravity: 0,
      drag: 1.4,
      lifespan: const Duration(milliseconds: 1600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return ThemeScaffold(
      child: AnimatedBuilder(
        animation: _shockwave,
        builder: (context, child) {
          // The screen shakes as the blast goes off
          final shake = _shockwave.isAnimating
              ? (1 - _shockwave.value) * 10
              : 0.0;
          return Transform.translate(
            offset: Offset(
              (_random.nextDouble() - 0.5) * shake,
              (_random.nextDouble() - 0.5) * shake,
            ),
            child: child,
          );
        },
        child: ColoredBox(
          color: const Color(0xFF05010F),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _NebulaPainter()),
              // Stars streaming past at warp speed
              ParticleEffects(
                config: ParticleConfig.starfield.copyWith(
                  particleType: ParticleType.streak,
                  particleCount: 120,
                  minSize: 4,
                  maxSize: 14,
                  particleColor: const Color(0xFFE1D5FF),
                  velocityMultiplier: 0.8,
                ),
              ),
              // Runes that connect as you touch them
              Positioned.fill(
                top: padding.top + 380,
                child: ParticleEffects(
                  interaction: ParticleInteraction.attract,
                  config: ParticleConfig.network.copyWith(
                    particleTypes: const [
                      ParticleType.diamond,
                      ParticleType.sparkle,
                    ],
                    particleCount: 30,
                    minSize: 4,
                    maxSize: 8,
                    particleColor: const Color(0xFF80DEEA),
                    enableGlow: true,
                    glowRadius: 2,
                    connections: const ParticleConnections(
                      maxDistance: 90,
                      color: Color(0xFF80DEEA),
                      maxOpacity: 0.55,
                    ),
                    seed: 5,
                  ),
                ),
              ),
              // The energy core, with orbiting rings and energy pouring out
              Positioned(
                left: 0,
                right: 0,
                top: padding.top + 190,
                child: Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(220, 220),
                          painter: _CorePainter(_orbit, _shockwave),
                        ),
                        SizedBox(key: _coreKey, width: 40, height: 40),
                      ],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: ParticleEffects(
                  config: ParticleConfig(
                    particleCount: 0,
                    particleTypes: const [
                      ParticleType.sparkle,
                      ParticleType.circle,
                    ],
                    minSize: 2,
                    maxSize: 6,
                    gradientColors: const [
                      Color(0xFFB388FF),
                      Color(0xFF80DEEA),
                      Colors.white,
                    ],
                    enableGlow: true,
                    glowRadius: 3,
                    blendMode: BlendMode.plus,
                    lifecycle: ParticleLifecycle.shrink,
                    emitters: [
                      ParticleEmitter(
                        followKey: _coreKey,
                        rate: 40,
                        spread: 2 * pi,
                        minSpeed: 30,
                        maxSpeed: 110,
                        drag: 0.8,
                        lifespan: const Duration(milliseconds: 1400),
                      ),
                    ],
                  ),
                ),
              ),
              IgnorePointer(
                child: ParticleEffects(
                  controller: _blast,
                  config: const ParticleConfig(
                    particleCount: 0,
                    particleTypes: [ParticleType.streak, ParticleType.sparkle],
                    minSize: 4,
                    maxSize: 16,
                    gradientColors: [
                      Color(0xFFE040FB),
                      Color(0xFF18FFFF),
                      Colors.white,
                    ],
                    enableGlow: true,
                    glowRadius: 3,
                    blendMode: BlendMode.plus,
                    trail: ParticleTrail(length: 5),
                    lifecycle: ParticleLifecycle.shrink,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: padding.top + 70,
                child: const IgnorePointer(
                  child: Column(
                    children: [
                      Eyebrow(
                        '✦  GUARDIAN OF THE STARS  ✦',
                        color: Color(0xFFB388FF),
                      ),
                      SizedBox(height: 8),
                      GradientText(
                        'COSMIC FORCE',
                        gradient: LinearGradient(
                          colors: [Color(0xFFE040FB), Color(0xFF18FFFF)],
                        ),
                        glow: Color(0xAAE040FB),
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
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
                    FestiveButton(
                      label: '💥  Power blast',
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE040FB),
                          Color(0xFF7C4DFF),
                          Color(0xFF18FFFF),
                        ],
                      ),
                      glow: const Color(0xFFE040FB),
                      textColor: Colors.white,
                      onPressed: _powerBlast,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Touch the runes to connect them',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NebulaPainter extends CustomPainter {
  const _NebulaPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(21);
    const colors = [
      Color(0xFF7C4DFF),
      Color(0xFFE040FB),
      Color(0xFF00B8D4),
      Color(0xFF304FFE),
    ];
    for (int i = 0; i < 10; i++) {
      final r = 90 + random.nextDouble() * 140;
      canvas.drawCircle(
        Offset(
          size.width * random.nextDouble(),
          size.height * random.nextDouble(),
        ),
        r,
        Paint()
          ..color = colors[i % colors.length].withValues(alpha: 0.18)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6),
      );
    }
    for (int i = 0; i < 160; i++) {
      canvas.drawCircle(
        Offset(
          size.width * random.nextDouble(),
          size.height * random.nextDouble(),
        ),
        random.nextDouble() * 1.2,
        Paint()
          ..color = Colors.white.withValues(
            alpha: 0.3 + random.nextDouble() * 0.5,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_NebulaPainter oldDelegate) => false;
}

/// A glowing orb with tilted rings orbiting it, and a shockwave on blasts.
class _CorePainter extends CustomPainter {
  _CorePainter(this.orbit, this.shockwave)
    : super(repaint: Listenable.merge([orbit, shockwave]));

  final Animation<double> orbit;
  final AnimationController shockwave;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final t = orbit.value * 2 * pi;
    final pulse = 1 + sin(t * 3) * 0.06;

    canvas.drawCircle(
      center,
      70 * pulse,
      Paint()
        ..color = const Color(0xFFB388FF).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
    // Orbiting rings
    for (int i = 0; i < 3; i++) {
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(t * (i.isEven ? 1 : -1) * (0.6 + i * 0.3) + i)
        ..scale(1, 0.35);
      canvas.drawCircle(
        Offset.zero,
        70 + i * 18.0,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF80DEEA).withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
      );
      canvas.restore();
    }
    // The core
    canvas.drawCircle(
      center,
      34 * pulse,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Color(0xFFE1BEE7), Color(0xFF7C4DFF)],
        ).createShader(Rect.fromCircle(center: center, radius: 34)),
    );
    // Shockwave
    if (shockwave.isAnimating) {
      final s = shockwave.value;
      canvas.drawCircle(
        center,
        40 + s * 500,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14 * (1 - s)
          ..color = const Color(0xFF18FFFF).withValues(alpha: 1 - s)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(_CorePainter oldDelegate) => false;
}
