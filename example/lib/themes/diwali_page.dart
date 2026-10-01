import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// Diwali, the festival of lights: diyas with flickering flames, floating
/// sky lanterns, a rangoli, a finger sparkler and fireworks.
class DiwaliPage extends StatefulWidget {
  const DiwaliPage({super.key});

  @override
  State<DiwaliPage> createState() => _DiwaliPageState();
}

class _DiwaliPageState extends State<DiwaliPage>
    with SingleTickerProviderStateMixin {
  final _fireworks = ParticleController();
  final _petals = ParticleController();
  final _rangoliKey = GlobalKey();
  final _flameKeys = List.generate(5, (_) => GlobalKey());
  bool _lit = true;

  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  )..repeat();

  static const _gold = LinearGradient(
    colors: [Color(0xFFFFF3C4), Color(0xFFFFC107), Color(0xFFFF8F00)],
  );

  @override
  void dispose() {
    _spin.dispose();
    _fireworks.dispose();
    _petals.dispose();
    super.dispose();
  }

  void _celebrate() {
    staggered(3, const Duration(milliseconds: 450), () => mounted, (_) {
      _fireworks.fireworks(shells: 3, sparks: 90);
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ThemeScaffold(
      child: ColoredBox(
        color: const Color(0xFF12001F),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D0018),
                    Color(0xFF2A0839),
                    Color(0xFF4A0F3A),
                    Color(0xFF6B1E2A),
                  ],
                ),
              ),
            ),
            // Stars
            const ParticleEffects(
              config: ParticleConfig(
                particleTypes: [ParticleType.sparkle, ParticleType.circle],
                direction: ParticleDirection.none,
                particleCount: 60,
                minSize: 1.2,
                maxSize: 4,
                gradientColors: [Colors.white, Color(0xFFFFE0B2)],
                enableGlow: true,
                glowRadius: 2,
                minOpacity: 0.1,
                velocityMultiplier: 0.25,
                driftAmplitude: 2,
                seed: 31,
              ),
            ),
            // Fireworks show
            ParticleEffects(
              controller: _fireworks,
              config: ParticleConfig.fireworks.copyWith(
                gradientColors: const [
                  Color(0xFFFFD740),
                  Color(0xFFFF6E40),
                  Color(0xFFFF4081),
                  Color(0xFFFFFFFF),
                ],
                emitters: const [
                  ParticleEmitter(
                    extent: Size(10000, 0),
                    rate: 0.3,
                    fireworks: true,
                    sparkCount: 80,
                  ),
                ],
              ),
            ),
            // Sky lanterns rising slowly
            const ParticleEffects(
              config: ParticleConfig(
                particleType: ParticleType.custom,
                customParticle: _SkyLantern(),
                enableGlow: true,
                glowRadius: 6,
                direction: ParticleDirection.bottomToTop,
                particleCount: 14,
                minSize: 18,
                maxSize: 38,
                velocityMultiplier: 0.25,
                animationDuration: Duration(seconds: 30),
                enableOpacityAnimation: false,
                maxOpacity: 0.95,
                driftAmplitude: 25,
                depthEffect: 0.8,
                edgeFade: 0.15,
                seed: 4,
              ),
            ),

            ListView(
              padding: EdgeInsets.only(top: topPadding + 80),
              children: [
                const Column(
                  children: [
                    Eyebrow(
                      '✦  THE FESTIVAL OF LIGHTS  ✦',
                      color: Color(0xFFFFCC80),
                    ),
                    SizedBox(height: 12),
                    GradientText(
                      'Happy\nDiwali',
                      gradient: _gold,
                      glow: Color(0x99FF9800),
                      style: TextStyle(
                        fontSize: 64,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'शुभ दीपावली',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFE0B2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                // Rangoli
                Center(
                  child: GestureDetector(
                    onTap: () => _petals.burstFromKey(
                      _rangoliKey,
                      count: 70,
                      minSpeed: 120,
                      maxSpeed: 420,
                      gravity: 250,
                      drag: 1,
                    ),
                    child: SizedBox(
                      key: _rangoliKey,
                      width: 250,
                      height: 250,
                      child: CustomPaint(painter: _RangoliPainter(_spin)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap the rangoli · drag anywhere to light a sparkler',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 36),
                // A row of diyas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < 5; i++)
                      _Diya(flameKey: _flameKeys[i], lit: _lit),
                  ],
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    tint: const Color(0xFFFFE0B2),
                    child: Column(
                      children: [
                        const Text(
                          'May the light of the diyas fill your home with '
                          'joy, prosperity and peace.',
                          textAlign: TextAlign.center,
                          style: TextStyle(height: 1.5, fontSize: 16),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            FestiveButton(
                              label: _lit ? '🪔  Blow out' : '🪔  Light diyas',
                              gradient: _gold,
                              onPressed: () => setState(() => _lit = !_lit),
                            ),
                            FestiveButton(
                              label: '🎆  Fireworks',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF4081), Color(0xFFFF6E40)],
                              ),
                              glow: const Color(0xFFFF4081),
                              textColor: Colors.white,
                              onPressed: _celebrate,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const MadeWith(),
              ],
            ),

            // Flames on the diyas
            ParticleEffects(
              isEnabled: _lit,
              config: ParticleConfig(
                particleCount: 0,
                minSize: 3,
                maxSize: 7,
                gradientColors: const [Color(0xFFFFE082), Color(0xFFFFB300)],
                enableGlow: true,
                glowRadius: 3,
                blendMode: BlendMode.plus,
                lifecycle: ParticleLifecycle.ember,
                emitters: [
                  for (final key in _flameKeys)
                    ParticleEmitter(
                      followKey: key,
                      extent: const Size(6, 4),
                      rate: 14,
                      spread: pi / 5,
                      minSpeed: 15,
                      maxSpeed: 45,
                      gravity: -30,
                      lifespan: const Duration(milliseconds: 900),
                    ),
                ],
              ),
            ),
            // Rangoli petals
            ParticleEffects(
              controller: _petals,
              config: const ParticleConfig(
                particleCount: 0,
                particleTypes: [ParticleType.petal, ParticleType.circle],
                minSize: 5,
                maxSize: 11,
                gradientColors: [
                  Color(0xFFFF4081),
                  Color(0xFFFFC107),
                  Color(0xFF00E5FF),
                  Color(0xFF76FF03),
                  Color(0xFFFF6D00),
                ],
                enableRotation: true,
                enableOpacityAnimation: false,
              ),
            ),
            // A sparkler you draw with your finger
            const ParticleEffects(
              interaction: ParticleInteraction(
                mode: ParticleInteractionMode.none,
                emitOnDrag: 4,
              ),
              config: ParticleConfig(
                particleCount: 0,
                particleTypes: [ParticleType.sparkle, ParticleType.streak],
                minSize: 3,
                maxSize: 9,
                gradientColors: [
                  Color(0xFFFFF8E1),
                  Color(0xFFFFD54F),
                  Color(0xFFFFAB40),
                ],
                enableGlow: true,
                glowRadius: 2,
                enableRotation: true,
                blendMode: BlendMode.plus,
                lifecycle: ParticleLifecycle.shrink,
                trail: ParticleTrail(length: 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A glowing paper sky lantern, used as a custom widget particle.
class _SkyLantern extends StatelessWidget {
  const _SkyLantern();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.7,
        heightFactor: 0.9,
        // No boxShadow: a glow outside the widget's box would be cut off
        // square in the particle image. The config's enableGlow adds one.
        child: const DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(40),
              bottom: Radius.circular(10),
            ),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFFFFF59D), Color(0xFFFFA726), Color(0xFFE65100)],
            ),
          ),
        ),
      ),
    );
  }
}

/// A clay oil lamp with a flame.
class _Diya extends StatelessWidget {
  const _Diya({required this.flameKey, required this.lit});

  final GlobalKey flameKey;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 70,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Glow
          AnimatedOpacity(
            opacity: lit ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFB300).withValues(alpha: 0.55),
                    const Color(0xFFFFB300).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Flame
          Positioned(
            bottom: 24,
            child: AnimatedScale(
              scale: lit ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: flameKey,
                width: 12,
                height: 20,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12),
                    bottom: Radius.circular(6),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.white,
                      Color(0xFFFFD54F),
                      Color(0xFFFF6D00),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Clay bowl
          CustomPaint(size: const Size(58, 28), painter: _DiyaPainter()),
        ],
      ),
    );
  }
}

class _DiyaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bowl = Path()
      ..moveTo(0, 4)
      ..quadraticBezierTo(w / 2, 12, w, 4)
      ..quadraticBezierTo(w * 0.85, h, w / 2, h)
      ..quadraticBezierTo(w * 0.15, h, 0, 4)
      ..close();
    canvas.drawPath(
      bowl,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD84315), Color(0xFF8D2A0B)],
        ).createShader(Offset.zero & size),
    );
    // Painted dots
    for (int i = 1; i < 6; i++) {
      canvas.drawCircle(
        Offset(w * i / 6, h * 0.55),
        1.8,
        Paint()..color = const Color(0xFFFFD54F),
      );
    }
  }

  @override
  bool shouldRepaint(_DiyaPainter oldDelegate) => false;
}

/// A slowly turning mandala-style rangoli.
class _RangoliPainter extends CustomPainter {
  _RangoliPainter(this.spin) : super(repaint: spin);

  final Animation<double> spin;

  static const _rings = [
    (12, 0.95, Color(0xFFFF4081)),
    (12, 0.78, Color(0xFFFFC107)),
    (8, 0.6, Color(0xFF00BFA5)),
    (8, 0.44, Color(0xFFFF6D00)),
    (6, 0.28, Color(0xFF7C4DFF)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Glow
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = const Color(0xFFFF4081).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );

    for (int r = 0; r < _rings.length; r++) {
      final (petals, extent, color) = _rings[r];
      canvas.save();
      // Alternate rings turn in opposite directions
      canvas.rotate(spin.value * 2 * pi * (r.isEven ? 1 : -1));
      final petalLength = radius * extent;
      final paint = Paint()..color = color;
      for (int i = 0; i < petals; i++) {
        canvas.save();
        canvas.rotate(i * 2 * pi / petals);
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(
              petalLength * 0.3,
              -petalLength * 0.5,
              0,
              -petalLength,
            )
            ..quadraticBezierTo(-petalLength * 0.3, -petalLength * 0.5, 0, 0)
            ..close(),
          paint,
        );
        canvas.drawCircle(
          Offset(0, -petalLength * 0.98),
          3,
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
        canvas.restore();
      }
      canvas.restore();
    }
    canvas.drawCircle(
      Offset.zero,
      radius * 0.12,
      Paint()..color = const Color(0xFFFFEB3B),
    );
    canvas.drawCircle(
      Offset.zero,
      radius * 0.06,
      Paint()..color = const Color(0xFFD50000),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RangoliPainter oldDelegate) => false;
}
