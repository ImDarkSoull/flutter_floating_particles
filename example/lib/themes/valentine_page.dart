import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// Valentine's Day: rising hearts, rose petals settling on a love letter,
/// a constellation of hearts and a heart explosion.
class ValentinePage extends StatefulWidget {
  const ValentinePage({super.key});

  @override
  State<ValentinePage> createState() => _ValentinePageState();
}

class _ValentinePageState extends State<ValentinePage> {
  final _love = ParticleController();
  final _letterKey = GlobalKey();
  final _buttonKey = GlobalKey();

  static const _pink = LinearGradient(
    colors: [Color(0xFFFFE4EC), Color(0xFFFF80AB), Color(0xFFFF4081)],
  );

  @override
  void dispose() {
    _love.dispose();
    super.dispose();
  }

  void _sendLove() {
    _love.burstFromKey(
      _buttonKey,
      count: 70,
      minSpeed: 200,
      maxSpeed: 650,
      gravity: 350,
      drag: 0.8,
    );
    _love.confettiCannon(count: 30);
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ThemeScaffold(
      child: ColoredBox(
        color: const Color(0xFF2B0A2E),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1F0620),
                    Color(0xFF4A0E3B),
                    Color(0xFF8E1650),
                    Color(0xFFC2185B),
                  ],
                ),
              ),
            ),
            // Soft hearts rising behind everything. This layer wraps the
            // page, so taps anywhere reach it and pop the hearts.
            ParticleEffects(
              interaction: ParticleInteraction.pop,
              layer: ParticleLayer.background,
              config: const ParticleConfig(
                particleType: ParticleType.heart,
                direction: ParticleDirection.bottomToTop,
                particleCount: 30,
                minSize: 8,
                maxSize: 26,
                gradientColors: [
                  Color(0xFFFF80AB),
                  Color(0xFFFF4081),
                  Color(0xFFF50057),
                  Color(0xFFFFCDD2),
                ],
                enableGlow: true,
                glowRadius: 4,
                velocityMultiplier: 0.4,
                animationDuration: Duration(seconds: 16),
                minOpacity: 0.4,
                maxOpacity: 0.9,
                depthEffect: 0.8,
                seed: 14,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Rose petals falling onto the love letter
                  ParticleEffects(
                    colliders: [_letterKey],
                    collision: const ParticleCollision(
                      settleDuration: Duration(seconds: 12),
                      maxSettled: 120,
                    ),
                    config: const ParticleConfig(
                      particleType: ParticleType.petal,
                      particleCount: 35,
                      minSize: 8,
                      maxSize: 15,
                      gradientColors: [
                        Color(0xFFD50000),
                        Color(0xFFC51162),
                        Color(0xFFFF1744),
                      ],
                      enableRotation: true,
                      velocityMultiplier: 0.45,
                      animationDuration: Duration(seconds: 13),
                      minOpacity: 0.8,
                      wind: 0.2,
                      depthEffect: 0.5,
                      seed: 6,
                    ),
                    child: ListView(
                      padding: EdgeInsets.only(top: topPadding + 80),
                      children: [
                        const Eyebrow(
                          '✦  14 FEBRUARY  ✦',
                          color: Color(0xFFFFCDD2),
                        ),
                        const SizedBox(height: 12),
                        const GradientText(
                          'Be My\nValentine',
                          gradient: _pink,
                          glow: Color(0x99FF4081),
                          style: TextStyle(
                            fontSize: 58,
                            height: 0.95,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: GlassCard(
                            key: _letterKey,
                            tint: const Color(0xFFFFCDD2),
                            child: const Column(
                              children: [
                                Text('💌', style: TextStyle(fontSize: 36)),
                                SizedBox(height: 10),
                                Text(
                                  'Roses are red, violets are blue,\n'
                                  'every heart on this screen\n'
                                  'is floating for you.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 17,
                                    height: 1.6,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Watch the petals land on this letter',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFFCDD2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        // A constellation of hearts that follows your finger
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            tint: const Color(0xFFFFCDD2),
                            child: SizedBox(
                              height: 220,
                              child: ParticleEffects(
                                interaction: ParticleInteraction.attract,
                                config: ParticleConfig.network.copyWith(
                                  particleType: ParticleType.heart,
                                  particleCount: 34,
                                  minSize: 5,
                                  maxSize: 10,
                                  particleColor: const Color(0xFFFF80AB),
                                  connections: const ParticleConnections(
                                    maxDistance: 80,
                                    color: Color(0xFFFFCDD2),
                                    maxOpacity: 0.55,
                                  ),
                                  seed: 8,
                                ),
                                child: const Center(
                                  child: Text(
                                    'Connect the hearts',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: FestiveButton(
                            key: _buttonKey,
                            label: '💘  Send love',
                            gradient: _pink,
                            glow: const Color(0xFFFF4081),
                            textColor: const Color(0xFF6A0033),
                            onPressed: _sendLove,
                          ),
                        ),
                        const MadeWith(
                          hint:
                              'Tap a heart to pop it · drag to draw with hearts',
                        ),
                      ],
                    ),
                  ),

                  // Drawing with little hearts
                  const ParticleEffects(
                    interaction: ParticleInteraction(
                      mode: ParticleInteractionMode.none,
                      emitOnDrag: 2,
                    ),
                    config: ParticleConfig(
                      particleCount: 0,
                      particleType: ParticleType.heart,
                      minSize: 6,
                      maxSize: 12,
                      gradientColors: [Color(0xFFFF80AB), Color(0xFFFFFFFF)],
                      enableGlow: true,
                      glowRadius: 2,
                      lifecycle: ParticleLifecycle.shrink,
                    ),
                  ),
                  // The heart explosion
                  ParticleEffects(
                    controller: _love,
                    config: const ParticleConfig(
                      particleCount: 0,
                      particleTypes: [
                        ParticleType.heart,
                        ParticleType.heart,
                        ParticleType.sparkle,
                      ],
                      minSize: 8,
                      maxSize: 20,
                      gradientColors: [
                        Color(0xFFFF4081),
                        Color(0xFFF50057),
                        Color(0xFFFF80AB),
                        Color(0xFFFFFFFF),
                      ],
                      enableGlow: true,
                      glowRadius: 3,
                      enableRotation: true,
                      rotationSpeed: 0.5,
                      enableOpacityAnimation: false,
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
