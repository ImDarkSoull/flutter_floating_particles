import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// New Year's Eve: a city skyline, a live countdown to midnight, champagne
/// bubbles and a fireworks finale.
class NewYearPage extends StatefulWidget {
  const NewYearPage({super.key});

  @override
  State<NewYearPage> createState() => _NewYearPageState();
}

class _NewYearPageState extends State<NewYearPage> {
  final _finale = ParticleController();
  final _confetti = ParticleController();
  final _sparkles = ParticleController();
  final _yearKey = GlobalKey();
  final _glassKey = GlobalKey();
  final _wishKeys = List.generate(4, (_) => GlobalKey());

  static const _wishes = ['✈️  Travel', '💪  Health', '📚  Learn', '❤️  Love'];

  static const _gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF3C4), Color(0xFFFFD54F), Color(0xFFE8A93A)],
  );

  int get _nextYear {
    final now = DateTime.now();
    // Until the first day of the year is over, celebrate that year
    return now.month == 1 && now.day == 1 ? now.year : now.year + 1;
  }

  @override
  void dispose() {
    _finale.dispose();
    _confetti.dispose();
    _sparkles.dispose();
    super.dispose();
  }

  void _ringIn() {
    staggered(6, const Duration(milliseconds: 350), () => mounted, (i) {
      _finale.fireworks(shells: 3, sparks: 100);
      if (i == 0) _confetti.confettiCannon(count: 80);
      if (i == 3) _confetti.confettiCannon(count: 60);
    });
    _sparkles.burstFromKey(
      _yearKey,
      count: 80,
      minSpeed: 100,
      maxSpeed: 420,
      gravity: 200,
      drag: 1,
      lifespan: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final year = _nextYear;

    return ThemeScaffold(
      child: ColoredBox(
        color: const Color(0xFF020314),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF01020D),
                    Color(0xFF0B1B3A),
                    Color(0xFF1C2F5E),
                    Color(0xFF3B2A5E),
                  ],
                ),
              ),
            ),
            const ParticleEffects(
              config: ParticleConfig(
                particleTypes: [ParticleType.sparkle, ParticleType.circle],
                direction: ParticleDirection.none,
                particleCount: 80,
                minSize: 1.2,
                maxSize: 4,
                particleColor: Colors.white,
                enableGlow: true,
                glowRadius: 2,
                minOpacity: 0.1,
                velocityMultiplier: 0.3,
                driftAmplitude: 2,
                seed: 17,
              ),
            ),
            // A lively fireworks show over the city
            ParticleEffects(
              config: ParticleConfig.fireworks.copyWith(
                emitters: const [
                  ParticleEmitter(
                    extent: Size(10000, 0),
                    rate: 0.55,
                    fireworks: true,
                    sparkCount: 70,
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 260,
              child: CustomPaint(painter: _SkylinePainter()),
            ),

            ListView(
              padding: EdgeInsets.only(top: topPadding + 80),
              children: [
                const Eyebrow(
                  '✦  COUNTDOWN TO MIDNIGHT  ✦',
                  color: Color(0xFFFFE9A8),
                ),
                const SizedBox(height: 10),
                const GradientText(
                  'Happy New Year',
                  gradient: _gold,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Center(
                  child: GradientText(
                    '$year',
                    key: _yearKey,
                    gradient: _gold,
                    glow: const Color(0x99FFC107),
                    style: const TextStyle(
                      fontSize: 108,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                EverySecond(
                  builder: (context, now) {
                    final remaining = DateTime(year).difference(now);
                    if (remaining.isNegative) {
                      return const Center(
                        child: Text(
                          '🎉  Happy New Year!  🎉',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }
                    return CountdownTiles(remaining: remaining);
                  },
                ),
                const SizedBox(height: 34),
                Center(
                  child: FestiveButton(
                    label: '🎉  Ring in $year',
                    gradient: _gold,
                    onPressed: _ringIn,
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    child: Column(
                      children: [
                        Text(
                          'Cheers to $year!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Champagne with bubbles rising from it
                        Text(
                          '🥂',
                          key: _glassKey,
                          style: const TextStyle(fontSize: 64),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Tap a wish for the new year',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            for (int i = 0; i < _wishes.length; i++)
                              ActionChip(
                                key: _wishKeys[i],
                                label: Text(_wishes[i]),
                                onPressed: () => _sparkles.burstFromKey(
                                  _wishKeys[i],
                                  count: 30,
                                  minSpeed: 60,
                                  maxSpeed: 220,
                                  gravity: 150,
                                  drag: 1,
                                  lifespan: const Duration(milliseconds: 1400),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 180),
                const MadeWith(),
              ],
            ),

            // Champagne bubbles
            ParticleEffects(
              config: ParticleConfig(
                particleCount: 0,
                particleType: ParticleType.ring,
                minSize: 3,
                maxSize: 7,
                particleColor: const Color(0xFFFFF3C4),
                enableOpacityAnimation: false,
                maxOpacity: 0.8,
                emitters: [
                  ParticleEmitter(
                    followKey: _glassKey,
                    extent: const Size(40, 10),
                    rate: 10,
                    spread: pi / 6,
                    minSpeed: 20,
                    maxSpeed: 60,
                    gravity: -40,
                    lifespan: const Duration(milliseconds: 1400),
                  ),
                ],
              ),
            ),
            // The finale
            ParticleEffects(
              controller: _finale,
              config: ParticleConfig.fireworks.copyWith(emitters: const []),
            ),
            ParticleEffects(
              controller: _sparkles,
              config: const ParticleConfig(
                particleCount: 0,
                particleTypes: [ParticleType.sparkle, ParticleType.star],
                minSize: 4,
                maxSize: 10,
                gradientColors: [Color(0xFFFFF8E1), Color(0xFFFFD54F)],
                enableGlow: true,
                glowRadius: 3,
                enableRotation: true,
                blendMode: BlendMode.plus,
                lifecycle: ParticleLifecycle.shrink,
              ),
            ),
            ParticleEffects(
              controller: _confetti,
              config: const ParticleConfig(
                particleCount: 0,
                particleTypes: [
                  ParticleType.square,
                  ParticleType.circle,
                  ParticleType.streak,
                ],
                minSize: 5,
                maxSize: 11,
                gradientColors: [
                  Color(0xFFFFD54F),
                  Color(0xFFE0E0E0),
                  Color(0xFFFFFFFF),
                  Color(0xFF90CAF9),
                ],
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

/// A city skyline with lit windows.
class _SkylinePainter extends CustomPainter {
  const _SkylinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(7);
    final w = size.width;
    final h = size.height;

    void row(double minHeight, double maxHeight, Color color, bool windows) {
      double x = -10;
      while (x < w) {
        final bw = 26 + random.nextDouble() * 40;
        final bh = minHeight + random.nextDouble() * (maxHeight - minHeight);
        final rect = Rect.fromLTWH(x, h - bh, bw, bh);
        canvas.drawRect(rect, Paint()..color = color);
        if (random.nextDouble() < 0.25) {
          // A spire
          canvas.drawRect(
            Rect.fromLTWH(x + bw / 2 - 1.5, h - bh - 18, 3, 18),
            Paint()..color = color,
          );
        }
        if (windows) {
          for (double wy = h - bh + 8; wy < h - 6; wy += 11) {
            for (double wx = x + 5; wx < x + bw - 6; wx += 9) {
              if (random.nextDouble() < 0.45) {
                canvas.drawRect(
                  Rect.fromLTWH(wx, wy, 4, 5),
                  Paint()
                    ..color = const Color(
                      0xFFFFE082,
                    ).withValues(alpha: 0.4 + random.nextDouble() * 0.5),
                );
              }
            }
          }
        }
        x += bw + 2;
      }
    }

    row(90, 200, const Color(0xFF16203F), false);
    row(50, 150, const Color(0xFF0A1128), true);
  }

  @override
  bool shouldRepaint(_SkylinePainter oldDelegate) => false;
}
