import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

/// A complete Christmas landing page, showing what the package can do:
///
/// * twinkling stars, falling snow in two depth layers and parallax scroll
/// * a sleigh trailing gold sparkles (an emitter following a widget)
/// * automatic and on-demand fireworks
/// * snow that piles up on the greeting card (colliders)
/// * a sparkling tree star, and bursts from the tree, gifts and button
/// * tap snowflakes to pop them, drag anywhere to paint magic dust
/// * a "make a wish" constellation that follows your finger
class XmasPage extends StatefulWidget {
  const XmasPage({super.key});

  @override
  State<XmasPage> createState() => _XmasPageState();
}

class _XmasPageState extends State<XmasPage> with TickerProviderStateMixin {
  final _scroll = ScrollController();
  late final _parallax = ScrollParallax(_scroll);

  final _fireworks = ParticleController();
  final _sparkles = ParticleController();
  final _confetti = ParticleController();

  final _cardKey = GlobalKey();
  final _starKey = GlobalKey();
  final _sleighTailKey = GlobalKey();
  final _celebrateKey = GlobalKey();
  final _giftKeys = List.generate(3, (_) => GlobalKey());
  final _openedGifts = <int>{};

  late final _sleigh = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();
  late final _lights = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();
  late final _aurora = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  late Timer _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _clock.cancel();
    _sleigh.dispose();
    _lights.dispose();
    _aurora.dispose();
    _parallax.dispose();
    _scroll.dispose();
    _fireworks.dispose();
    _sparkles.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _celebrate() {
    _fireworks.fireworks(shells: 6, sparks: 90);
    _confetti.confettiCannon(count: 70);
    _sparkles.burstFromKey(
      _celebrateKey,
      count: 50,
      minSpeed: 120,
      maxSpeed: 380,
      gravity: 250,
      lifespan: const Duration(milliseconds: 1600),
    );
  }

  void _shakeTree() {
    _sparkles.burstFromKey(
      _starKey,
      count: 60,
      minSpeed: 80,
      maxSpeed: 320,
      gravity: 220,
      lifespan: const Duration(seconds: 2),
    );
  }

  void _openGift(int index) {
    _confetti.burstFromKey(
      _giftKeys[index],
      count: 80,
      spread: pi / 2.2,
      minSpeed: 250,
      maxSpeed: 700,
      gravity: 700,
    );
    setState(() => _openedGifts.add(index));
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: const Color(0xFF070B1F),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Night sky, aurora and moon
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF050818),
                  Color(0xFF0E1638),
                  Color(0xFF22194A),
                  Color(0xFF3A2456),
                ],
                stops: [0, 0.35, 0.7, 1],
              ),
            ),
          ),
          CustomPaint(painter: _AuroraPainter(_aurora)),
          Positioned(top: topPadding + 14, right: 22, child: const _Moon()),

          // Twinkling stars that barely move with the scroll
          ParticleEffects(
            parallax: _parallax,
            config: const ParticleConfig(
              particleTypes: [ParticleType.sparkle, ParticleType.circle],
              direction: ParticleDirection.none,
              particleCount: 90,
              minSize: 1.2,
              maxSize: 5,
              gradientColors: [
                Colors.white,
                Color(0xFFFFF3C4),
                Color(0xFFCDE7FF),
              ],
              enableGlow: true,
              glowRadius: 2,
              minOpacity: 0.1,
              velocityMultiplier: 0.25,
              driftAmplitude: 2,
              parallaxFactor: 0.05,
              seed: 24,
            ),
          ),

          // A gentle fireworks show behind the page
          ParticleEffects(
            config: ParticleConfig.fireworks.copyWith(
              emitters: const [
                ParticleEmitter(
                  extent: Size(10000, 0),
                  rate: 0.22,
                  fireworks: true,
                  sparkCount: 80,
                ),
              ],
            ),
          ),

          // Santa's sleigh flying across the sky
          AnimatedBuilder(
            animation: _sleigh,
            builder: (context, child) {
              final size = MediaQuery.sizeOf(context);
              final t = _sleigh.value;
              return Positioned(
                left: size.width * 1.25 - t * size.width * 1.9,
                top: topPadding + 150 + sin(t * 2 * pi * 2) * 18,
                child: child!,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🦌 🦌 🦌  🛷',
                  style: TextStyle(fontSize: 26, height: 1),
                ),
                SizedBox(key: _sleighTailKey, width: 6, height: 20),
              ],
            ),
          ),
          ParticleEffects(
            config: ParticleConfig(
              particleCount: 0,
              particleTypes: const [ParticleType.sparkle, ParticleType.circle],
              minSize: 2,
              maxSize: 7,
              gradientColors: const [
                Color(0xFFFFE082),
                Color(0xFFFFD54F),
                Colors.white,
              ],
              enableGlow: true,
              glowRadius: 3,
              blendMode: BlendMode.plus,
              lifecycle: ParticleLifecycle.shrink,
              emitters: [
                ParticleEmitter(
                  followKey: _sleighTailKey,
                  rate: 45,
                  spread: 2 * pi,
                  minSpeed: 10,
                  maxSpeed: 50,
                  gravity: 30,
                  lifespan: const Duration(milliseconds: 1600),
                ),
              ],
            ),
          ),

          // Far snow: small, slow and faint
          ParticleEffects(
            parallax: _parallax,
            config: const ParticleConfig(
              particleType: ParticleType.snowflake,
              particleCount: 70,
              minSize: 3,
              maxSize: 5,
              particleColor: Colors.white,
              minOpacity: 0.25,
              maxOpacity: 0.6,
              velocityMultiplier: 0.35,
              animationDuration: Duration(seconds: 16),
              wind: 0.1,
              parallaxFactor: 0.15,
              seed: 5,
            ),
          ),

          // The page, with near snow that piles up on the greeting card and
          // pops when tapped
          ParticleEffects(
            parallax: _parallax,
            colliders: [_cardKey],
            collision: const ParticleCollision(
              settleDuration: Duration(seconds: 12),
              maxSettled: 260,
            ),
            interaction: const ParticleInteraction(
              radius: 70,
              strength: 40,
              popOnTap: true,
            ),
            config: const ParticleConfig(
              particleType: ParticleType.snowflake,
              particleCount: 90,
              minSize: 4,
              maxSize: 13,
              particleColor: Colors.white,
              enableGlow: true,
              glowRadius: 1.5,
              enableRotation: true,
              rotationSpeed: 0.3,
              velocityMultiplier: 0.7,
              animationDuration: Duration(seconds: 11),
              minOpacity: 0.6,
              wind: 0.12,
              depthEffect: 0.7,
              parallaxFactor: 0.35,
              seed: 12,
            ),
            child: CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: topPadding + 96)),
                const SliverToBoxAdapter(child: _Title()),
                SliverToBoxAdapter(child: _Countdown(now: _now)),
                SliverToBoxAdapter(
                  child: _TreeSection(
                    lights: _lights,
                    starKey: _starKey,
                    onTap: _shakeTree,
                  ),
                ),
                SliverToBoxAdapter(child: _GreetingCard(cardKey: _cardKey)),
                SliverToBoxAdapter(
                  child: _Gifts(
                    keys: _giftKeys,
                    opened: _openedGifts,
                    onOpen: _openGift,
                  ),
                ),
                const SliverToBoxAdapter(child: _WishSection()),
                SliverToBoxAdapter(
                  child: _CelebrateButton(
                    buttonKey: _celebrateKey,
                    onPressed: _celebrate,
                  ),
                ),
                const SliverToBoxAdapter(child: _Footer()),
              ],
            ),
          ),

          // Gold sparkles: the tree star's aura, bursts, and magic dust
          // painted by dragging anywhere
          ParticleEffects(
            controller: _sparkles,
            interaction: const ParticleInteraction(
              mode: ParticleInteractionMode.none,
              emitOnDrag: 2,
            ),
            config: ParticleConfig(
              particleCount: 0,
              particleTypes: const [ParticleType.sparkle, ParticleType.star],
              minSize: 3,
              maxSize: 9,
              gradientColors: const [
                Color(0xFFFFE082),
                Color(0xFFFFF8E1),
                Color(0xFFFFCA28),
              ],
              enableGlow: true,
              glowRadius: 3,
              enableRotation: true,
              blendMode: BlendMode.plus,
              lifecycle: ParticleLifecycle.shrink,
              emitters: [
                ParticleEmitter(
                  followKey: _starKey,
                  extent: const Size(40, 40),
                  rate: 10,
                  spread: 2 * pi,
                  minSpeed: 15,
                  maxSpeed: 45,
                  gravity: -5,
                  lifespan: const Duration(milliseconds: 1500),
                ),
              ],
            ),
          ),

          // Celebration fireworks, in front of the page so they're seen
          // wherever it is scrolled to
          ParticleEffects(
            controller: _fireworks,
            config: ParticleConfig.fireworks.copyWith(emitters: const []),
          ),

          // Confetti from the gifts and the celebration cannons
          ParticleEffects(
            controller: _confetti,
            config: const ParticleConfig(
              particleCount: 0,
              particleTypes: [
                ParticleType.square,
                ParticleType.circle,
                ParticleType.star,
                ParticleType.triangle,
              ],
              minSize: 5,
              maxSize: 10,
              gradientColors: [
                Color(0xFFE53935),
                Color(0xFF43A047),
                Color(0xFFFFD54F),
                Colors.white,
                Color(0xFFD81B60),
              ],
              enableRotation: true,
              rotationSpeed: 2,
              enableOpacityAnimation: false,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sky
// ---------------------------------------------------------------------------

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * 2 * pi;
    final bands = [
      (const Color(0xFF26FFB0), 0.16, 0.0, 0.30),
      (const Color(0xFF2EC5FF), 0.24, 1.8, 0.22),
      (const Color(0xFFB266FF), 0.32, 3.6, 0.18),
    ];
    for (final (color, height, phase, alpha) in bands) {
      final path = Path()..moveTo(0, 0);
      for (double x = 0; x <= size.width; x += 8) {
        final u = x / size.width;
        final y =
            size.height *
            (height +
                0.035 * sin(u * 5 + t + phase) +
                0.02 * sin(u * 11 - t * 1.5 + phase));
        path.lineTo(x, y);
      }
      path
        ..lineTo(size.width, 0)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.75, 1],
          ).createShader(Offset.zero & Size(size.width, size.height * 0.45))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) => false;
}

class _Moon extends StatelessWidget {
  const _Moon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFFFFDE7), Color(0xFFFFE9A8), Color(0xFFF5C866)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFE082).withValues(alpha: 0.45),
            blurRadius: 60,
            spreadRadius: 12,
          ),
        ],
      ),
      child: const Stack(
        children: [
          _Crater(left: 14, top: 16, size: 10),
          _Crater(left: 34, top: 30, size: 13),
          _Crater(left: 21, top: 39, size: 7),
        ],
      ),
    );
  }
}

class _Crater extends StatelessWidget {
  const _Crater({required this.left, required this.top, required this.size});

  final double left;
  final double top;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE8B95A).withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Title and countdown
// ---------------------------------------------------------------------------

const _gold = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFFFF3C4), Color(0xFFFFD54F), Color(0xFFE8A93A)],
);

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final nextYear = _nextChristmas(DateTime.now()).year + 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Text(
            '✦  THE MAGIC OF THE SEASON  ✦',
            style: TextStyle(
              color: Color(0xFFFFE9A8),
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ShaderMask(
            shaderCallback: (bounds) => _gold.createShader(bounds),
            child: const Text(
              'Merry\nChristmas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 62,
                height: 0.95,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -1,
                shadows: [Shadow(color: Color(0x99FFC107), blurRadius: 28)],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'and a happy new year $nextYear',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 15,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

DateTime _nextChristmas(DateTime now) {
  final thisYear = DateTime(now.year, 12, 25);
  return now.isBefore(thisYear.add(const Duration(days: 1)))
      ? thisYear
      : DateTime(now.year + 1, 12, 25);
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final christmas = _nextChristmas(now);
    final remaining = christmas.difference(now);

    final Widget content;
    if (remaining.isNegative) {
      content = const _Glass(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Text(
          "🎄  It's Christmas!  🎄",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      );
    } else {
      final parts = [
        (remaining.inDays, 'DAYS'),
        (remaining.inHours % 24, 'HOURS'),
        (remaining.inMinutes % 60, 'MINUTES'),
        (remaining.inSeconds % 60, 'SECONDS'),
      ];
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (value, label) in parts)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: _CountdownTile(value: value, label: label),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
      child: Center(child: content),
    );
  }
}

class _CountdownTile extends StatelessWidget {
  const _CountdownTile({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.5,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tree
// ---------------------------------------------------------------------------

class _TreeSection extends StatelessWidget {
  const _TreeSection({
    required this.lights,
    required this.starKey,
    required this.onTap,
  });

  final Animation<double> lights;
  final GlobalKey starKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            SizedBox(
              width: 260,
              height: 360,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned.fill(
                    top: 34,
                    child: CustomPaint(painter: _TreePainter(lights)),
                  ),
                  Icon(
                    key: starKey,
                    Icons.star_rounded,
                    size: 58,
                    color: const Color(0xFFFFD54F),
                    shadows: const [
                      Shadow(color: Color(0xFFFFC107), blurRadius: 30),
                      Shadow(color: Color(0x88FFFFFF), blurRadius: 8),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the tree ✨',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  _TreePainter(this.lights) : super(repaint: lights);

  final Animation<double> lights;

  static const _bulbColors = [
    Color(0xFFFF5252),
    Color(0xFFFFD740),
    Color(0xFF40C4FF),
    Color(0xFF69F0AE),
    Color(0xFFFF80AB),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Soft glow behind the tree
    canvas.drawCircle(
      Offset(cx, h * 0.55),
      w * 0.55,
      Paint()
        ..color = const Color(0xFF2E7D32).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50),
    );

    // Trunk
    final trunk = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h * 0.93),
        width: w * 0.13,
        height: h * 0.12,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      trunk,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF5D3A1A), Color(0xFF8D5A2B), Color(0xFF5D3A1A)],
        ).createShader(trunk.outerRect),
    );

    // Four tiers, from the bottom up
    const tiers = [
      (0.36, 0.88, 0.50),
      (0.22, 0.68, 0.40),
      (0.10, 0.48, 0.30),
      (0.0, 0.29, 0.20),
    ];
    final bulbs = <Offset>[];
    for (final (top, bottom, halfWidth) in tiers) {
      final topY = h * top;
      final bottomY = h * bottom;
      final half = w * halfWidth;
      final path = Path()..moveTo(cx, topY);
      path.quadraticBezierTo(
        cx + half * 0.45,
        (topY + bottomY) / 2,
        cx + half,
        bottomY,
      );
      // Scalloped bottom edge
      const scallops = 5;
      for (int i = 0; i < scallops; i++) {
        final x1 = cx + half - (i + 1) * 2 * half / scallops;
        final xm = (cx + half - i * 2 * half / scallops + x1) / 2;
        path.quadraticBezierTo(xm, bottomY + h * 0.035, x1, bottomY);
      }
      path
        ..quadraticBezierTo(cx - half * 0.45, (topY + bottomY) / 2, cx, topY)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3DD68C), Color(0xFF1B8A50), Color(0xFF0A3D24)],
            stops: [0, 0.55, 1],
          ).createShader(Rect.fromLTRB(cx - half, topY, cx + half, bottomY)),
      );

      // Snow along the edge
      final snow = Path()..moveTo(cx + half, bottomY);
      for (int i = 0; i < scallops; i++) {
        final x1 = cx + half - (i + 1) * 2 * half / scallops;
        final xm = (cx + half - i * 2 * half / scallops + x1) / 2;
        snow.quadraticBezierTo(xm, bottomY + h * 0.035, x1, bottomY);
      }
      canvas.drawPath(
        snow,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.85),
      );

      // A garland across the tier, with bulbs along it
      final garland = Path();
      final garlandY = topY + (bottomY - topY) * 0.62;
      final garlandHalf = half * 0.62;
      garland.moveTo(cx - garlandHalf, garlandY - h * 0.03);
      garland.quadraticBezierTo(
        cx,
        garlandY + h * 0.05,
        cx + garlandHalf,
        garlandY - h * 0.03,
      );
      canvas.drawPath(
        garland,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.8),
      );
      for (final metric in garland.computeMetrics()) {
        const count = 6;
        for (int i = 0; i <= count; i++) {
          final tangent = metric.getTangentForOffset(metric.length * i / count);
          if (tangent != null) bulbs.add(tangent.position);
        }
      }
    }

    // Blinking bulbs
    final t = lights.value * 2 * pi;
    for (int i = 0; i < bulbs.length; i++) {
      final color = _bulbColors[i % _bulbColors.length];
      final brightness = 0.55 + 0.45 * sin(t + i * 1.7);
      canvas.drawCircle(
        bulbs[i],
        7,
        Paint()
          ..color = color.withValues(alpha: 0.55 * brightness)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        bulbs[i],
        3.2,
        Paint()..color = Color.lerp(color, Colors.white, 0.3 * brightness)!,
      );
    }
  }

  @override
  bool shouldRepaint(_TreePainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Greeting card (snow piles up on it)
// ---------------------------------------------------------------------------

class _Glass extends StatelessWidget {
  const _Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: panel,
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.cardKey});

  final GlobalKey cardKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 12),
      child: _Glass(
        key: cardKey,
        child: Column(
          children: [
            const Text('🎄', style: TextStyle(fontSize: 34)),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (bounds) => _gold.createShader(bounds),
              child: const Text(
                "Season's Greetings",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'May your days be merry and bright, your home be warm, '
              'and your heart be full of wonder. Watch the snow settle on '
              'this card — then tap a snowflake to pop it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '— with love, flutter_floating_particles',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFFFFE9A8).withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gifts
// ---------------------------------------------------------------------------

class _Gifts extends StatelessWidget {
  const _Gifts({
    required this.keys,
    required this.opened,
    required this.onOpen,
  });

  final List<GlobalKey> keys;
  final Set<int> opened;
  final ValueChanged<int> onOpen;

  static const _gifts = [
    (Color(0xFFE53935), Color(0xFFFFD54F), '☕  Hot cocoa'),
    (Color(0xFF2E7D32), Color(0xFFFFFFFF), '🧣  A cozy scarf'),
    (Color(0xFF3949AB), Color(0xFFFF80AB), '🍪  Warm cookies'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 8),
      child: Column(
        children: [
          const Text(
            'Open a gift',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _gifts.length; i++)
                GestureDetector(
                  onTap: () => onOpen(i),
                  child: Column(
                    children: [
                      _GiftBox(
                        key: keys[i],
                        box: _gifts[i].$1,
                        ribbon: _gifts[i].$2,
                        open: opened.contains(i),
                      ),
                      const SizedBox(height: 10),
                      AnimatedOpacity(
                        opacity: opened.contains(i) ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        child: SizedBox(
                          width: 96,
                          child: Text(
                            _gifts[i].$3,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GiftBox extends StatelessWidget {
  const _GiftBox({
    super.key,
    required this.box,
    required this.ribbon,
    required this.open,
  });

  final Color box;
  final Color ribbon;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final darker = Color.lerp(box, Colors.black, 0.25)!;
    return SizedBox(
      width: 88,
      height: 104,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Box
          Container(
            width: 80,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(colors: [box, darker]),
              boxShadow: [
                BoxShadow(
                  color: box.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(child: Container(width: 13, color: ribbon)),
          ),
          // Lid and bow, which fly off when opened
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            bottom: open ? 92 : 64,
            child: AnimatedRotation(
              turns: open ? -0.06 : 0,
              duration: const Duration(milliseconds: 500),
              child: SizedBox(
                width: 88,
                height: 40,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 88,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: darker,
                      ),
                      child: Center(child: Container(width: 13, color: ribbon)),
                    ),
                    Positioned(top: 0, child: _Bow(color: ribbon)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bow extends StatelessWidget {
  const _Bow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget loop(double angle) => Transform.rotate(
      angle: angle,
      child: Container(
        width: 22,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    return SizedBox(
      width: 48,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: 2, child: loop(0.5)),
          Positioned(right: 2, child: loop(-0.5)),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Make a wish
// ---------------------------------------------------------------------------

class _WishSection extends StatelessWidget {
  const _WishSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 12),
      child: _Glass(
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 250,
          child: ParticleEffects(
            interaction: const ParticleInteraction(
              mode: ParticleInteractionMode.attract,
              radius: 120,
              strength: 50,
            ),
            config: ParticleConfig.network.copyWith(
              particleCount: 45,
              particleTypes: const [ParticleType.sparkle, ParticleType.circle],
              minSize: 2,
              maxSize: 6,
              particleColor: const Color(0xFFFFF3C4),
              enableGlow: true,
              glowRadius: 2,
              connections: const ParticleConnections(
                maxDistance: 85,
                color: Color(0xFFFFE9A8),
                maxOpacity: 0.5,
              ),
              seed: 3,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Make a wish',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Touch the stars and draw your constellation',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Celebrate and footer
// ---------------------------------------------------------------------------

class _CelebrateButton extends StatelessWidget {
  const _CelebrateButton({required this.buttonKey, required this.onPressed});

  final GlobalKey buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 8),
      // The glow sits outside the Material, whose ink is clipped to the pill
      child: DecoratedBox(
        key: buttonKey,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC107).withValues(alpha: 0.5),
              blurRadius: 30,
            ),
          ],
        ),
        child: Material(
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          color: Colors.transparent,
          child: Ink(
            decoration: const BoxDecoration(gradient: _gold),
            child: InkWell(
              onTap: onPressed,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text(
                    '🎆  Celebrate',
                    style: TextStyle(
                      color: Color(0xFF3A2400),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _HillsPainter())),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
            child: Text(
              'Drag anywhere to paint magic dust ✨\n'
              'Made with flutter_floating_particles',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.6,
                fontSize: 12,
                color: const Color(0xFF3A4A6B).withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HillsPainter extends CustomPainter {
  const _HillsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void hill(double baseY, double amplitude, double phase, Color color) {
      final path = Path()..moveTo(0, h);
      for (double x = 0; x <= w; x += 6) {
        path.lineTo(x, baseY + amplitude * sin(x / w * pi * 2 + phase));
      }
      path
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    void pine(double x, double baseY, double height) {
      final path = Path()
        ..moveTo(x, baseY - height)
        ..lineTo(x + height * 0.32, baseY)
        ..lineTo(x - height * 0.32, baseY)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xFF1B3B4B));
      // Snow cap
      final cap = Path()
        ..moveTo(x, baseY - height)
        ..lineTo(x + height * 0.12, baseY - height * 0.62)
        ..lineTo(x - height * 0.12, baseY - height * 0.62)
        ..close();
      canvas.drawPath(
        cap,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }

    hill(h * 0.35, 18, 0.6, const Color(0xFF9FB6D9));
    for (final (fx, height) in [
      (0.1, 46.0),
      (0.18, 34.0),
      (0.8, 52.0),
      (0.9, 38.0),
    ]) {
      pine(w * fx, h * 0.42, height);
    }
    hill(h * 0.52, 22, 2.4, const Color(0xFFD5E3F5));
    hill(h * 0.66, 14, 4.1, const Color(0xFFF4F8FF));
  }

  @override
  bool shouldRepaint(_HillsPainter oldDelegate) => false;
}
