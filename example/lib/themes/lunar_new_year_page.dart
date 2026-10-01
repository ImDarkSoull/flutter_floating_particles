import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// Lunar New Year: swaying red lanterns, a dragon trailing gold, falling
/// coins and red envelopes, firecrackers and fortunes.
class LunarNewYearPage extends StatefulWidget {
  const LunarNewYearPage({super.key});

  @override
  State<LunarNewYearPage> createState() => _LunarNewYearPageState();
}

class _LunarNewYearPageState extends State<LunarNewYearPage>
    with SingleTickerProviderStateMixin {
  final _firecrackers = ParticleController();
  final _fireworks = ParticleController();
  final _coins = ParticleController();
  final _dragonTailKey = GlobalKey();
  final _envelopeKey = GlobalKey();
  final _lanternKeys = List.generate(4, (_) => GlobalKey());
  final _random = Random();
  int? _fortune;

  late final _sway = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  static const _gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF3C4), Color(0xFFFFD54F), Color(0xFFE8A93A)],
  );

  static const _fortunes = [
    'Great fortune and prosperity will find you this year.',
    'A year of good health and happiness awaits your family.',
    'New opportunities will open doors you never expected.',
    'Your hard work will bloom like the spring flowers.',
  ];

  @override
  void dispose() {
    _sway.dispose();
    _firecrackers.dispose();
    _fireworks.dispose();
    _coins.dispose();
    super.dispose();
  }

  void _lightFirecrackers() {
    staggered(10, const Duration(milliseconds: 120), () => mounted, (i) {
      _firecrackers.explode(
        alignment: Alignment(
          _random.nextDouble() * 1.6 - 0.8,
          _random.nextDouble() * 1.2 - 0.2,
        ),
        count: 26,
        speed: 320,
      );
    });
    _fireworks.fireworks(shells: 4, sparks: 90);
  }

  void _openEnvelope() {
    _coins.burstFromKey(
      _envelopeKey,
      count: 40,
      spread: pi / 2,
      minSpeed: 250,
      maxSpeed: 600,
      gravity: 800,
    );
    setState(() {
      _fortune = ((_fortune ?? -1) + 1) % _fortunes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ThemeScaffold(
      child: ColoredBox(
        color: const Color(0xFF5B0A0A),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF3D0404),
                    Color(0xFF8E1414),
                    Color(0xFFC62828),
                  ],
                ),
              ),
            ),
            const CustomPaint(painter: _CloudPatternPainter()),
            ParticleEffects(
              controller: _fireworks,
              config: ParticleConfig.fireworks.copyWith(
                gradientColors: const [
                  Color(0xFFFFD740),
                  Color(0xFFFFFFFF),
                  Color(0xFFFF6E40),
                ],
                emitters: const [
                  ParticleEmitter(
                    extent: Size(10000, 0),
                    rate: 0.2,
                    fireworks: true,
                    sparkCount: 70,
                  ),
                ],
              ),
            ),
            // Gold coins and red envelopes falling
            const ParticleEffects(
              config: ParticleConfig(
                particleType: ParticleType.custom,
                customParticle: _Coin(),
                particleCount: 16,
                minSize: 14,
                maxSize: 28,
                enableRotation: true,
                rotationSpeed: 0.6,
                velocityMultiplier: 0.45,
                animationDuration: Duration(seconds: 14),
                enableOpacityAnimation: false,
                depthEffect: 0.7,
                seed: 19,
              ),
            ),
            const ParticleEffects(
              config: ParticleConfig(
                particleType: ParticleType.custom,
                customParticle: Text('🧧', style: TextStyle(fontSize: 40)),
                particleCount: 7,
                minSize: 22,
                maxSize: 34,
                enableRotation: true,
                rotationSpeed: 0.3,
                velocityMultiplier: 0.35,
                animationDuration: Duration(seconds: 16),
                enableOpacityAnimation: false,
                depthEffect: 0.5,
                seed: 27,
              ),
            ),
            // The dragon and its golden trail
            Flyer(
              top: topPadding + 190,
              period: const Duration(seconds: 13),
              amplitude: 26,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🐉', style: TextStyle(fontSize: 46)),
                  SizedBox(key: _dragonTailKey, width: 8, height: 24),
                ],
              ),
            ),
            ParticleEffects(
              config: ParticleConfig(
                particleCount: 0,
                particleTypes: const [
                  ParticleType.sparkle,
                  ParticleType.circle,
                ],
                minSize: 2,
                maxSize: 7,
                gradientColors: const [Color(0xFFFFE082), Color(0xFFFFD54F)],
                enableGlow: true,
                glowRadius: 3,
                blendMode: BlendMode.plus,
                lifecycle: ParticleLifecycle.shrink,
                emitters: [
                  ParticleEmitter(
                    followKey: _dragonTailKey,
                    rate: 40,
                    spread: 2 * pi,
                    minSpeed: 10,
                    maxSpeed: 45,
                    gravity: 30,
                    lifespan: const Duration(milliseconds: 1400),
                  ),
                ],
              ),
            ),

            ListView(
              padding: EdgeInsets.only(top: topPadding + 260),
              children: [
                const GradientText(
                  '新年快乐',
                  gradient: _gold,
                  glow: Color(0x99FFC107),
                  style: TextStyle(fontSize: 64, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Happy Lunar New Year',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFE9A8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '恭喜发财 · Gong Xi Fa Cai',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    letterSpacing: 1.5,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: FestiveButton(
                    label: '🧨  Light firecrackers',
                    gradient: _gold,
                    onPressed: _lightFirecrackers,
                  ),
                ),
                const SizedBox(height: 36),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    tint: const Color(0xFFFFE082),
                    child: Column(
                      children: [
                        const Text(
                          'Open a red envelope',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: _openEnvelope,
                          child: Text(
                            '🧧',
                            key: _envelopeKey,
                            style: const TextStyle(fontSize: 72),
                          ),
                        ),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: Text(
                            _fortune == null
                                ? 'Tap the envelope for your fortune'
                                : _fortunes[_fortune!],
                            key: ValueKey(_fortune),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              height: 1.5,
                              fontSize: 16,
                              color: Color(0xFFFFF3C4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const MadeWith(color: Color(0xFFFFCDD2)),
              ],
            ),

            // Lanterns hanging from the top, swaying above the page
            Positioned(
              top: 0,
              // Clear of the back button
              left: 56,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < 4; i++)
                    AnimatedBuilder(
                      animation: _sway,
                      builder: (context, child) => Transform.rotate(
                        alignment: Alignment.topCenter,
                        angle: (_sway.value - 0.5) * 0.16 * (i.isEven ? 1 : -1),
                        child: child,
                      ),
                      child: _Lantern(
                        glowKey: _lanternKeys[i],
                        stringLength: topPadding + 20 + (i % 2) * 36,
                      ),
                    ),
                ],
              ),
            ),
            // Sparks drifting down from the lanterns
            ParticleEffects(
              config: ParticleConfig(
                particleCount: 0,
                minSize: 2,
                maxSize: 4,
                gradientColors: const [Color(0xFFFFE082), Color(0xFFFFAB40)],
                enableGlow: true,
                glowRadius: 2,
                blendMode: BlendMode.plus,
                lifecycle: ParticleLifecycle.shrink,
                emitters: [
                  for (final key in _lanternKeys)
                    ParticleEmitter(
                      followKey: key,
                      extent: const Size(10, 4),
                      rate: 5,
                      angle: pi / 2,
                      spread: pi / 3,
                      minSpeed: 10,
                      maxSpeed: 40,
                      gravity: 60,
                      lifespan: const Duration(milliseconds: 1600),
                    ),
                ],
              ),
            ),
            ParticleEffects(
              controller: _firecrackers,
              config: const ParticleConfig(
                particleCount: 0,
                particleTypes: [ParticleType.square, ParticleType.streak],
                minSize: 3,
                maxSize: 8,
                gradientColors: [
                  Color(0xFFFF1744),
                  Color(0xFFFFD740),
                  Color(0xFFFFFFFF),
                ],
                enableGlow: true,
                glowRadius: 2,
                enableRotation: true,
                rotationSpeed: 3,
                blendMode: BlendMode.plus,
                enableOpacityAnimation: false,
              ),
            ),
            ParticleEffects(
              controller: _coins,
              config: const ParticleConfig(
                particleCount: 0,
                particleType: ParticleType.custom,
                customParticle: _Coin(),
                minSize: 12,
                maxSize: 22,
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

/// A gold coin with a square hole, used as a custom widget particle.
class _Coin extends StatelessWidget {
  const _Coin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFFFF3C4), Color(0xFFFFC107), Color(0xFFB77B00)],
        ),
        border: Border.all(color: const Color(0xFF9A6700), width: 2),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.3,
          heightFactor: 0.3,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF8E1414),
              border: Border.all(color: const Color(0xFF9A6700)),
            ),
          ),
        ),
      ),
    );
  }
}

/// A red paper lantern on a string.
class _Lantern extends StatelessWidget {
  const _Lantern({required this.glowKey, required this.stringLength});

  final GlobalKey glowKey;
  final double stringLength;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFC107);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 1.5, height: stringLength, color: gold),
        Container(
          width: 34,
          height: 8,
          decoration: BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Container(
          width: 62,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.elliptical(31, 25)),
            gradient: const RadialGradient(
              colors: [Color(0xFFFF8A65), Color(0xFFE53935), Color(0xFFB71C1C)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5252).withValues(alpha: 0.6),
                blurRadius: 24,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '福',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFE082),
              ),
            ),
          ),
        ),
        Container(
          width: 34,
          height: 8,
          decoration: BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Tassel
        SizedBox(
          key: glowKey,
          width: 6,
          height: 22,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [gold, Color(0x00FFC107)],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A faint pattern of auspicious clouds.
class _CloudPatternPainter extends CustomPainter {
  const _CloudPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.08);
    for (double y = 60; y < size.height; y += 120) {
      for (double x = (y ~/ 120).isEven ? 30 : 90; x < size.width; x += 120) {
        for (final r in [12.0, 20.0, 28.0]) {
          canvas.drawArc(
            Rect.fromCircle(center: Offset(x, y), radius: r),
            pi,
            pi,
            false,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CloudPatternPainter oldDelegate) => false;
}
