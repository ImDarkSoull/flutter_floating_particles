import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// An original speedster theme: a runner blazing across with streak trails
/// and electric sparks, speed lines, and slow motion.
class LightspeedPage extends StatefulWidget {
  const LightspeedPage({super.key});

  @override
  State<LightspeedPage> createState() => _LightspeedPageState();
}

class _LightspeedPageState extends State<LightspeedPage> {
  final _trailKey = GlobalKey();
  bool _slowMotion = false;

  @override
  void dispose() {
    // Slow motion affects the whole app, so always restore it
    timeDilation = 1;
    super.dispose();
  }

  void _toggleSlowMotion() {
    setState(() => _slowMotion = !_slowMotion);
    timeDilation = _slowMotion ? 6 : 1;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);

    return ThemeScaffold(
      child: ColoredBox(
        color: const Color(0xFF1A0500),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    Color(0xFF7A1C00),
                    Color(0xFF2E0A00),
                    Color(0xFF0D0200),
                  ],
                ),
              ),
            ),
            // Speed lines rushing out from the center
            const ParticleEffects(
              config: ParticleConfig(
                particleType: ParticleType.streak,
                direction: ParticleDirection.radial,
                particleCount: 110,
                minSize: 8,
                maxSize: 26,
                gradientColors: [
                  Color(0xFFFFD180),
                  Color(0xFFFF6E40),
                  Colors.white,
                ],
                velocityMultiplier: 1.4,
                animationDuration: Duration(seconds: 4),
                enableOpacityAnimation: false,
                minOpacity: 0.6,
                blendMode: BlendMode.plus,
              ),
            ),
            // The runner and the lightning that follows
            Flyer(
              top: size.height * 0.52,
              leftToRight: true,
              period: const Duration(milliseconds: 2600),
              amplitude: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(key: _trailKey, width: 10, height: 40),
                  // Flipped so the runner faces the way they're going
                  Transform.flip(
                    flipX: true,
                    child: const Text('🏃', style: TextStyle(fontSize: 58)),
                  ),
                ],
              ),
            ),
            IgnorePointer(
              child: ParticleEffects(
                config: ParticleConfig(
                  particleCount: 0,
                  particleTypes: const [
                    ParticleType.streak,
                    ParticleType.streak,
                    ParticleType.sparkle,
                  ],
                  minSize: 6,
                  maxSize: 22,
                  gradientColors: const [
                    Color(0xFFFFEA00),
                    Color(0xFFFF9100),
                    Color(0xFFFF3D00),
                    Colors.white,
                  ],
                  enableGlow: true,
                  glowRadius: 3,
                  blendMode: BlendMode.plus,
                  lifecycle: ParticleLifecycle.shrink,
                  trail: const ParticleTrail(length: 4),
                  emitters: [
                    ParticleEmitter(
                      followKey: _trailKey,
                      rate: 120,
                      angle: pi,
                      spread: pi / 5,
                      minSpeed: 150,
                      maxSpeed: 420,
                      drag: 1.8,
                      lifespan: const Duration(milliseconds: 700),
                    ),
                  ],
                ),
              ),
            ),
            // Electric crackle around the runner
            IgnorePointer(
              child: ParticleEffects(
                config: ParticleConfig(
                  particleCount: 0,
                  particleType: ParticleType.sparkle,
                  minSize: 4,
                  maxSize: 10,
                  particleColor: const Color(0xFFFFF59D),
                  enableGlow: true,
                  glowRadius: 3,
                  blendMode: BlendMode.plus,
                  lifecycle: ParticleLifecycle.shrink,
                  emitters: [
                    ParticleEmitter(
                      followKey: _trailKey,
                      extent: const Size(70, 60),
                      rate: 30,
                      spread: 2 * pi,
                      minSpeed: 40,
                      maxSpeed: 160,
                      drag: 2,
                      lifespan: const Duration(milliseconds: 400),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: padding.top + 110,
              child: const IgnorePointer(
                child: Column(
                  children: [
                    Eyebrow(
                      '✦  FASTER THAN LIGHT  ✦',
                      color: Color(0xFFFFD180),
                    ),
                    SizedBox(height: 8),
                    GradientText(
                      'LIGHTSPEED',
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFFEA00),
                          Color(0xFFFF6D00),
                          Color(0xFFFF1744),
                        ],
                      ),
                      glow: Color(0xAAFF6D00),
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
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
              bottom: padding.bottom + 48,
              child: Center(
                child: FestiveButton(
                  label: _slowMotion ? '⚡  Full speed' : '🐢  Slow motion',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFEA00), Color(0xFFFF6D00)],
                  ),
                  glow: const Color(0xFFFF6D00),
                  textColor: const Color(0xFF3A0A00),
                  onPressed: _toggleSlowMotion,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
