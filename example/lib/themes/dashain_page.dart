import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// Dashain, Nepal's biggest festival, on a clear autumn afternoon: kites
/// (changa) over the Himalayas, a bamboo swing (ping), marigolds, golden
/// rice terraces, and tika and jamara blessings.
class DashainPage extends StatefulWidget {
  const DashainPage({super.key});

  @override
  State<DashainPage> createState() => _DashainPageState();
}

class _DashainPageState extends State<DashainPage>
    with TickerProviderStateMixin {
  final _blessingBurst = ParticleController();
  final _powderBurst = ParticleController();
  final _paperBurst = ParticleController();
  final _plateKey = GlobalKey();
  final _kiteKeys = List.generate(3, (_) => GlobalKey());
  int _blessing = 0;

  late final _wind = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();
  late final _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);
  late final _sky = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 90),
  )..repeat();

  /// Runs from 0 to 1 while a kite that was cut drifts away.
  late final _cuts = List.generate(
    3,
    (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    ),
  );

  static const _blessingTexts = [
    'May this Dashain bring you health, wealth and happiness.',
    'May the blessings of Durga Bhawani be with you and your family.',
    'May your life soar as high as the kites in the Dashain sky.',
    'Wishing you the victory of good over evil, today and always.',
  ];

  static const _kitePapers = [
    (Color(0xFFE53935), Color(0xFFFFEB3B)),
    (Color(0xFF1E88E5), Color(0xFFFFFFFF)),
    (Color(0xFF8E24AA), Color(0xFFFF9800)),
  ];

  @override
  void dispose() {
    _wind.dispose();
    _swing.dispose();
    _sky.dispose();
    for (final cut in _cuts) {
      cut.dispose();
    }
    _blessingBurst.dispose();
    _powderBurst.dispose();
    _paperBurst.dispose();
    super.dispose();
  }

  void _receiveTika() {
    _powderBurst.burstFromKey(
      _plateKey,
      count: 26,
      spread: pi / 1.6,
      minSpeed: 60,
      maxSpeed: 260,
      gravity: -20,
      drag: 2,
      lifespan: const Duration(milliseconds: 2200),
    );
    _blessingBurst.burstFromKey(
      _plateKey,
      count: 110,
      spread: pi / 1.5,
      minSpeed: 250,
      maxSpeed: 700,
      gravity: 700,
    );
    setState(() => _blessing = (_blessing + 1) % _blessingTexts.length);
  }

  /// "Chet!" - the kite's string is cut, as in a kite fight.
  void _cutKite(int index) {
    if (_cuts[index].isAnimating) return;
    _paperBurst.burstFromKey(
      _kiteKeys[index],
      count: 36,
      minSpeed: 60,
      maxSpeed: 260,
      gravity: 220,
      drag: 1.2,
      lifespan: const Duration(milliseconds: 1800),
    );
    _cuts[index].forward(from: 0).then((_) {
      if (mounted) _cuts[index].value = 0;
    });
  }

  /// Where each kite flies, bobbing on the wind.
  Offset _kitePosition(int index, Size size, double t) {
    return switch (index) {
      0 => Offset(
        size.width * 0.3 + sin(t * 2 * pi) * 14,
        size.height * 0.11 + cos(t * 2 * pi * 2) * 9,
      ),
      1 => Offset(
        size.width * 0.56 + sin(t * 2 * pi + 2) * 18,
        size.height * 0.06 + cos(t * 2 * pi + 1) * 10,
      ),
      _ => Offset(
        size.width * 0.8 + sin(t * 2 * pi + 4) * 12,
        size.height * 0.15 + cos(t * 2 * pi * 2 + 3) * 9,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final size = MediaQuery.sizeOf(context);

    return ThemeScaffold(
      child: ColoredBox(
        color: const Color(0xFF1E6FD9),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Afternoon sky
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A5FC7),
                    Color(0xFF3F8EE3),
                    Color(0xFF8CC7F2),
                    Color(0xFFD7ECF7),
                    Color(0xFFF8E6C8),
                  ],
                  stops: [0, 0.25, 0.5, 0.68, 0.8],
                ),
              ),
            ),
            CustomPaint(painter: _SunPainter(_sky)),
            CustomPaint(painter: _CloudsPainter(_sky)),
            // A flock of birds
            ParticleEffects(
              config: ParticleConfig(
                particleType: ParticleType.path,
                customPath: _bird,
                direction: ParticleDirection.rightToLeft,
                particleCount: 7,
                minSize: 7,
                maxSize: 13,
                particleColor: const Color(0xFF2B3A4A),
                velocityMultiplier: 0.35,
                animationDuration: const Duration(seconds: 30),
                enableOpacityAnimation: false,
                maxOpacity: 0.75,
                driftAmplitude: 12,
                depthEffect: 0.6,
                seed: 2,
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 400,
              child: CustomPaint(painter: _LandscapePainter()),
            ),

            // Kite strings, drawn behind the page
            CustomPaint(
              painter: _KiteStringsPainter(
                wind: _wind,
                cuts: _cuts,
                position: (i, t) => _kitePosition(i, size, t),
              ),
            ),

            // Marigold petals and whole flowers drifting down
            const ParticleEffects(
              config: ParticleConfig(
                particleType: ParticleType.petal,
                particleCount: 34,
                minSize: 6,
                maxSize: 12,
                gradientColors: [
                  Color(0xFFFF9800),
                  Color(0xFFFFB300),
                  Color(0xFFF57C00),
                  Color(0xFFE65100),
                ],
                enableRotation: true,
                velocityMultiplier: 0.45,
                animationDuration: Duration(seconds: 15),
                minOpacity: 0.85,
                wind: 0.3,
                depthEffect: 0.6,
                seed: 9,
              ),
            ),
            const ParticleEffects(
              config: ParticleConfig(
                particleType: ParticleType.custom,
                customParticle: _Marigold(),
                particleCount: 8,
                minSize: 16,
                maxSize: 28,
                enableRotation: true,
                rotationSpeed: 0.4,
                velocityMultiplier: 0.35,
                animationDuration: Duration(seconds: 17),
                enableOpacityAnimation: false,
                wind: 0.2,
                depthEffect: 0.5,
                seed: 3,
              ),
            ),

            // The page
            ListView(
              padding: EdgeInsets.only(top: topPadding + 215),
              children: [
                const _Title(),
                const SizedBox(height: 12),
                _Ping(swing: _swing),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _TikaCard(
                    plateKey: _plateKey,
                    blessing: _blessingTexts[_blessing],
                    blessingIndex: _blessing,
                    onReceive: _receiveTika,
                  ),
                ),
                const MadeWith(
                  color: Color(0xFF4E342E),
                  hint: 'Tap a kite to cut its string — चेट! 🪁',
                ),
              ],
            ),

            // Kites fly above the page so they can be tapped
            for (int i = 0; i < 3; i++)
              AnimatedBuilder(
                animation: Listenable.merge([_wind, _cuts[i]]),
                builder: (context, child) {
                  final base = _kitePosition(i, size, _wind.value);
                  final cut = _cuts[i].value;
                  // A cut kite tumbles away on the wind, then a new one
                  // appears
                  final drift = Offset(
                    cut * 260 + sin(cut * 9) * 24,
                    -cut * 40 + cut * cut * 320,
                  );
                  final flutter = sin(_wind.value * 2 * pi * 3 + i) * 0.12;
                  final opacity = cut == 0 ? 1.0 : (1 - cut).clamp(0.0, 1.0);
                  return Positioned(
                    left: base.dx + drift.dx - 34,
                    top: base.dy + drift.dy - 40,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.rotate(
                        angle: flutter + cut * 5 * pi,
                        child: child,
                      ),
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () => _cutKite(i),
                  child: _Kite(key: _kiteKeys[i], paper: _kitePapers[i]),
                ),
              ),
            for (int i = 0; i < 3; i++)
              AnimatedBuilder(
                animation: _cuts[i],
                builder: (context, _) {
                  final cut = _cuts[i].value;
                  if (cut == 0 || cut > 0.45) return const SizedBox.shrink();
                  final base = _kitePosition(i, size, _wind.value);
                  return Positioned(
                    left: base.dx - 30,
                    // Kept below the status bar for kites flying high
                    top: max(topPadding + 8, base.dy - 70) + 40 - cut * 90,
                    child: Opacity(
                      opacity: (1 - cut / 0.45).clamp(0.0, 1.0),
                      child: const Text(
                        'चेट!',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Color(0xFFD50000),
                              offset: Offset(2, 2),
                            ),
                            Shadow(color: Color(0x88000000), blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Paper bits from cut kites
            ParticleEffects(
              controller: _paperBurst,
              config: const ParticleConfig(
                particleCount: 0,
                particleTypes: [ParticleType.square, ParticleType.triangle],
                minSize: 4,
                maxSize: 9,
                gradientColors: [
                  Color(0xFFE53935),
                  Color(0xFFFFEB3B),
                  Color(0xFF1E88E5),
                  Color(0xFFFFFFFF),
                  Color(0xFF8E24AA),
                  Color(0xFFFF9800),
                ],
                enableRotation: true,
                rotationSpeed: 2.5,
                enableOpacityAnimation: false,
              ),
            ),
            // Tika: a soft cloud of red powder, then red tika, rice grains,
            // jamara and marigold petals
            ParticleEffects(
              controller: _powderBurst,
              config: const ParticleConfig(
                particleCount: 0,
                minSize: 30,
                maxSize: 60,
                particleColor: Color(0xFFD50000),
                enableBlur: true,
                blurSigma: 9,
                minOpacity: 0,
                maxOpacity: 0.55,
                enableOpacityAnimation: false,
                lifecycle: ParticleLifecycle.growAndFade,
              ),
            ),
            ParticleEffects(
              controller: _blessingBurst,
              config: const ParticleConfig(
                particleCount: 0,
                particleTypes: [
                  ParticleType.circle,
                  ParticleType.circle,
                  ParticleType.raindrop,
                  ParticleType.streak,
                  ParticleType.petal,
                ],
                minSize: 3,
                maxSize: 11,
                gradientColors: [
                  Color(0xFFD50000),
                  Color(0xFFB71C1C),
                  Color(0xFFFFFDE7),
                  Color(0xFFDCE775),
                  Color(0xFFFF9800),
                ],
                enableRotation: true,
                enableOpacityAnimation: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Title and banner
// ---------------------------------------------------------------------------

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Eyebrow('✦  बडा दशैं  ✦', color: Color(0xFF7A1F00), letterSpacing: 0),
        SizedBox(height: 8),
        _ExtrudedText('Happy\nDashain', size: 62),
        SizedBox(height: 16),
        _Banner('विजया दशमीको हार्दिक मंगलमय शुभकामना'),
      ],
    );
  }
}

/// Bold 3D lettering: a warm gradient face on a deep red extrusion.
class _ExtrudedText extends StatelessWidget {
  const _ExtrudedText(this.text, {required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: size,
      height: 0.95,
      fontWeight: FontWeight.w900,
      letterSpacing: -1,
    );
    return Center(
      child: Stack(
        children: [
          // Extrusion, from back to front
          for (int i = 7; i >= 1; i--)
            Transform.translate(
              offset: Offset(0, i * 1.1),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: style.copyWith(
                  color: Color.lerp(
                    const Color(0xFF5D0000),
                    const Color(0xFF9E0E0E),
                    1 - i / 7,
                  ),
                  shadows: i == 7
                      ? const [
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF59D), Color(0xFFFFB300), Color(0xFFFF6D00)],
            ).createShader(bounds),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: style.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// A red festive ribbon with gold trim and notched ends.
class _Banner extends StatelessWidget {
  const _Banner(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        painter: const _BannerPainter(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 10),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFFF3C4),
              shadows: [Shadow(color: Color(0x66000000), blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  const _BannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const notch = 14.0;
    final ribbon = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w - notch, h / 2)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..lineTo(notch, h / 2)
      ..close();
    canvas.drawShadow(ribbon, Colors.black, 4, false);
    canvas.drawPath(
      ribbon,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE53935), Color(0xFFB71C1C), Color(0xFF8E0000)],
        ).createShader(Offset.zero & size),
    );
    final trim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFFFD54F);
    canvas
      ..drawLine(Offset(notch * 0.6, 4), Offset(w - notch * 0.6, 4), trim)
      ..drawLine(
        Offset(notch * 0.6, h - 4),
        Offset(w - notch * 0.6, h - 4),
        trim,
      );
  }

  @override
  bool shouldRepaint(_BannerPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Sky and landscape
// ---------------------------------------------------------------------------

class _SunPainter extends CustomPainter {
  _SunPainter(this.time) : super(repaint: time);

  final Animation<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final sun = Offset(size.width * 0.86, size.height * 0.2);

    // Slowly turning light rays
    canvas.save();
    canvas.translate(sun.dx, sun.dy);
    canvas.rotate(time.value * 2 * pi);
    final ray = Paint()
      ..color = const Color(0xFFFFF3C4).withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (int i = 0; i < 12; i++) {
      canvas.rotate(2 * pi / 12);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.height * 0.6, -26)
          ..lineTo(size.height * 0.6, 26)
          ..close(),
        ray,
      );
    }
    canvas.restore();

    // Glow and disc
    canvas.drawCircle(
      sun,
      170,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF8D6),
            const Color(0xFFFFE082).withValues(alpha: 0.6),
            const Color(0xFFFFCA28).withValues(alpha: 0.18),
            const Color(0xFFFFCA28).withValues(alpha: 0),
          ],
          stops: const [0.12, 0.3, 0.6, 1],
        ).createShader(Rect.fromCircle(center: sun, radius: 170)),
    );
    canvas.drawCircle(
      sun,
      30,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.white, Color(0xFFFFF3C4)],
        ).createShader(Rect.fromCircle(center: sun, radius: 30))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Lens flare along the line through the screen center
    final center = size.center(Offset.zero);
    for (final (t, r, alpha) in [
      (0.55, 18.0, 0.14),
      (0.8, 8.0, 0.2),
      (1.25, 34.0, 0.08),
      (1.5, 12.0, 0.12),
    ]) {
      final p = Offset.lerp(sun, center, t)!;
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(_SunPainter oldDelegate) => false;
}

/// Soft cumulus clouds, shaded underneath, drifting at different speeds.
class _CloudsPainter extends CustomPainter {
  _CloudsPainter(this.time) : super(repaint: time);

  final Animation<double> time;

  static const _clouds = [
    // x, y, scale, speed
    (0.05, 0.1, 1.2, 1.0),
    (0.55, 0.05, 0.8, 1.6),
    (0.3, 0.27, 1.5, 0.7),
    (0.8, 0.33, 1.0, 1.2),
  ];

  static const _puffs = [
    (0.0, 0.0, 28.0),
    (30.0, -14.0, 36.0),
    (66.0, -6.0, 30.0),
    (92.0, 4.0, 22.0),
    (48.0, 8.0, 30.0),
    (18.0, 10.0, 24.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (fx, fy, scale, speed) in _clouds) {
      final travel = size.width + 260 * scale;
      final x =
          (fx * size.width + time.value * speed * travel * 2) % travel -
          140 * scale;
      final y = size.height * fy;

      // Shadowed base, then the sunlit top
      for (final (dx, dy, r) in _puffs) {
        canvas.drawCircle(
          Offset(x + dx * scale, y + (dy + 8) * scale),
          r * scale,
          Paint()
            ..color = const Color(0xFFB8CCE0).withValues(alpha: 0.85)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale),
        );
      }
      for (final (dx, dy, r) in _puffs) {
        final center = Offset(x + dx * scale, y + dy * scale);
        canvas.drawCircle(
          center,
          r * scale * 0.92,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-0.2, -0.5),
              colors: [Colors.white, Color(0xFFEFF5FB)],
            ).createShader(Rect.fromCircle(center: center, radius: r * scale))
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * scale),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CloudsPainter oldDelegate) => false;
}

/// The Himalayas in afternoon light, hazy foothills with a village and a
/// pagoda, and golden rice terraces at harvest time.
class _LandscapePainter extends CustomPainter {
  const _LandscapePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Far peaks fade into the haze, near ones are sharper
    _range(
      canvas,
      size,
      peaks: const [
        (0.08, 0.2),
        (0.3, 0.06),
        (0.5, 0.22),
        (0.7, 0.02),
        (0.93, 0.16),
      ],
      base: 0.42,
      rockLit: const Color(0xFFA9BCD3),
      rockShade: const Color(0xFF8499B4),
      snowShade: const Color(0xFFD3E0EF),
    );
    _range(
      canvas,
      size,
      peaks: const [
        (0.0, 0.3),
        (0.2, 0.18),
        (0.42, 0.34),
        (0.62, 0.2),
        (0.86, 0.3),
      ],
      base: 0.5,
      rockLit: const Color(0xFF8FA6C1),
      rockShade: const Color(0xFF687F9E),
      snowShade: const Color(0xFFC6D5E8),
    );

    // Haze where the mountains meet the hills
    final haze = Rect.fromLTWH(0, h * 0.38, w, h * 0.2);
    canvas.drawRect(
      haze,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF3E7D3).withValues(alpha: 0),
            const Color(0xFFF3E7D3).withValues(alpha: 0.7),
            const Color(0xFFF3E7D3).withValues(alpha: 0),
          ],
        ).createShader(haze),
    );

    // Green foothills
    final hills = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.56)
      ..cubicTo(w * 0.2, h * 0.48, w * 0.35, h * 0.58, w * 0.55, h * 0.52)
      ..cubicTo(w * 0.75, h * 0.46, w * 0.9, h * 0.55, w, h * 0.5)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(
      hills,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6E9A6A), Color(0xFF3F6B45)],
        ).createShader(Rect.fromLTWH(0, h * 0.46, w, h * 0.3)),
    );

    // Trees along the ridge
    final random = Random(11);
    for (int i = 0; i < 26; i++) {
      final x = random.nextDouble() * w;
      final y = h * (0.54 + random.nextDouble() * 0.08);
      final r = 6 + random.nextDouble() * 7;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF2E5436),
            const Color(0xFF41704A),
            random.nextDouble(),
          )!,
      );
    }

    // A village on the hillside
    for (final (fx, fy, s) in const [
      (0.18, 0.6, 1.0),
      (0.26, 0.62, 0.8),
      (0.62, 0.58, 0.9),
      (0.7, 0.6, 1.1),
      (0.8, 0.585, 0.8),
    ]) {
      _house(canvas, Offset(w * fx, h * fy), s);
    }
    _pagoda(canvas, Offset(w * 0.44, h * 0.6));

    // Golden rice terraces in front
    const colors = [
      Color(0xFFD9B44A),
      Color(0xFFC49A2C),
      Color(0xFFB7C455),
      Color(0xFFD9B44A),
      Color(0xFF9FB24A),
      Color(0xFFCDA23A),
    ];
    for (int i = 0; i < colors.length; i++) {
      final top = h * (0.66 + i * 0.06);
      final dip = i.isEven ? 0.0 : 8.0;
      Path edge() => Path()
        ..moveTo(0, top + 10)
        ..quadraticBezierTo(w * 0.3, top - 14 + dip, w * 0.55, top)
        ..quadraticBezierTo(w * 0.8, top + 12, w, top - 4);
      canvas.drawPath(
        edge()
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = colors[i],
      );
      // The lit edge of each terrace wall
      canvas.drawPath(
        edge(),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFF1B8).withValues(alpha: 0.6),
      );
    }
  }

  /// A mountain range with sunlit and shadowed faces and snow caps.
  void _range(
    Canvas canvas,
    Size size, {
    required List<(double, double)> peaks,
    required double base,
    required Color rockLit,
    required Color rockShade,
    required Color snowShade,
  }) {
    final w = size.width;
    final h = size.height;
    final baseY = h * base;
    for (final (px, py) in peaks) {
      final peak = Offset(w * px, h * py);
      final spread = w * 0.26;
      final left = Offset(peak.dx - spread, baseY);
      final right = Offset(peak.dx + spread, baseY);
      // The ridge line runs down from the peak, slightly off-center
      final ridge = Offset(peak.dx + spread * 0.18, baseY);

      canvas.drawPath(
        Path()
          ..moveTo(peak.dx, peak.dy)
          ..lineTo(left.dx, left.dy)
          ..lineTo(ridge.dx, ridge.dy)
          ..close(),
        Paint()..color = rockLit,
      );
      canvas.drawPath(
        Path()
          ..moveTo(peak.dx, peak.dy)
          ..lineTo(ridge.dx, ridge.dy)
          ..lineTo(right.dx, right.dy)
          ..close(),
        Paint()..color = rockShade,
      );

      // Snow cap with a jagged lower edge
      final depth = 0.42;
      final capLeft = Offset.lerp(peak, left, depth)!;
      final capRight = Offset.lerp(peak, right, depth)!;
      final capRidge = Offset.lerp(peak, ridge, depth * 1.2)!;
      void jagged(Path path, Offset from, Offset to) {
        const steps = 5;
        for (int s = 1; s <= steps; s++) {
          final p = Offset.lerp(from, to, s / steps)!;
          path.lineTo(p.dx, p.dy + (s == steps ? 0 : (s.isEven ? -5 : 4)));
        }
      }

      final litSnow = Path()
        ..moveTo(peak.dx, peak.dy)
        ..lineTo(capLeft.dx, capLeft.dy);
      jagged(litSnow, capLeft, capRidge);
      canvas.drawPath(litSnow..close(), Paint()..color = Colors.white);

      final shadeSnow = Path()
        ..moveTo(peak.dx, peak.dy)
        ..lineTo(capRidge.dx, capRidge.dy);
      jagged(shadeSnow, capRidge, capRight);
      canvas.drawPath(shadeSnow..close(), Paint()..color = snowShade);
    }
  }

  /// A small Nepali house: brick walls, a white band and a tin roof.
  void _house(Canvas canvas, Offset base, double s) {
    final wall = Rect.fromLTWH(
      base.dx - 10 * s,
      base.dy - 12 * s,
      20 * s,
      12 * s,
    );
    canvas
      ..drawRect(wall, Paint()..color = const Color(0xFFB5513A))
      ..drawRect(
        Rect.fromLTWH(wall.left, wall.top, wall.width, 3 * s),
        Paint()..color = const Color(0xFFF1E4D0),
      )
      ..drawRect(
        Rect.fromLTWH(base.dx - 2 * s, base.dy - 7 * s, 4 * s, 5 * s),
        Paint()..color = const Color(0xFF3E2723),
      )
      ..drawPath(
        Path()
          ..moveTo(wall.left - 3 * s, wall.top)
          ..lineTo(wall.left + 4 * s, wall.top - 7 * s)
          ..lineTo(wall.right - 4 * s, wall.top - 7 * s)
          ..lineTo(wall.right + 3 * s, wall.top)
          ..close(),
        Paint()..color = const Color(0xFF6D7B8A),
      );
  }

  /// A three-tiered pagoda temple with a golden pinnacle.
  void _pagoda(Canvas canvas, Offset base) {
    const brick = Color(0xFF8D3B24);
    const roof = Color(0xFF4E3B30);
    double y = base.dy;
    double width = 30;
    for (int tier = 0; tier < 3; tier++) {
      final wallHeight = 9.0 - tier;
      canvas.drawRect(
        Rect.fromLTWH(
          base.dx - width * 0.35,
          y - wallHeight,
          width * 0.7,
          wallHeight,
        ),
        Paint()..color = brick,
      );
      y -= wallHeight;
      canvas.drawPath(
        Path()
          ..moveTo(base.dx - width / 2, y + 2)
          ..lineTo(base.dx - width * 0.25, y - 6)
          ..lineTo(base.dx + width * 0.25, y - 6)
          ..lineTo(base.dx + width / 2, y + 2)
          ..close(),
        Paint()..color = roof,
      );
      y -= 6;
      width *= 0.72;
    }
    canvas.drawRect(
      Rect.fromLTWH(base.dx - 1.5, y - 8, 3, 8),
      Paint()..color = const Color(0xFFFFC107),
    );
  }

  @override
  bool shouldRepaint(_LandscapePainter oldDelegate) => false;
}

/// A bird in flight, for the flock.
final Path _bird = Path()
  ..moveTo(-1, 0)
  ..quadraticBezierTo(-0.5, -0.55, 0, -0.05)
  ..quadraticBezierTo(0.5, -0.55, 1, 0)
  ..quadraticBezierTo(0.5, -0.3, 0, 0.1)
  ..quadraticBezierTo(-0.5, -0.3, -1, 0)
  ..close();

// ---------------------------------------------------------------------------
// Kites
// ---------------------------------------------------------------------------

/// A Nepali kite (changa): translucent paper on bamboo sticks.
class _Kite extends StatelessWidget {
  const _Kite({super.key, required this.paper});

  final (Color, Color) paper;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 96,
      child: CustomPaint(painter: _KitePainter(paper)),
    );
  }
}

class _KitePainter extends CustomPainter {
  const _KitePainter(this.paper);

  final (Color, Color) paper;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const h = 76.0;
    final top = Offset(w / 2, 0);
    final right = Offset(w, h * 0.42);
    final bottom = Offset(w / 2, h);
    final left = Offset(0, h * 0.42);
    final kite = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(bottom.dx, bottom.dy)
      ..lineTo(left.dx, left.dy)
      ..close();

    canvas.drawShadow(kite, Colors.black, 3, true);
    // Paper lit from behind by the sun
    canvas.drawPath(
      kite,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.2, -0.3),
          radius: 0.9,
          colors: [Color.lerp(paper.$1, Colors.white, 0.35)!, paper.$1],
        ).createShader(kite.getBounds()),
    );
    // A contrasting band across the middle
    canvas
      ..save()
      ..clipPath(kite)
      ..drawRect(
        Rect.fromLTWH(0, h * 0.42 - 9, w, 18),
        Paint()..color = paper.$2.withValues(alpha: 0.9),
      )
      ..drawCircle(
        Offset(w / 2, h * 0.42),
        9,
        Paint()..color = paper.$1.withValues(alpha: 0.9),
      )
      ..restore();

    // Bamboo spine and bow
    final bamboo = Paint()
      ..color = const Color(0xFF8D6E3F)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas
      ..drawLine(top, bottom, bamboo)
      ..drawPath(
        Path()
          ..moveTo(left.dx, left.dy)
          ..quadraticBezierTo(w / 2, h * 0.42 - 12, right.dx, right.dy),
        bamboo,
      )
      ..drawPath(
        kite,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.black.withValues(alpha: 0.2),
      );

    // Small paper tassel
    canvas.drawPath(
      Path()
        ..moveTo(bottom.dx, bottom.dy)
        ..lineTo(bottom.dx - 7, bottom.dy + 16)
        ..lineTo(bottom.dx, bottom.dy + 12)
        ..lineTo(bottom.dx + 7, bottom.dy + 16)
        ..close(),
      Paint()..color = paper.$2,
    );
  }

  @override
  bool shouldRepaint(_KitePainter oldDelegate) => oldDelegate.paper != paper;
}

class _KiteStringsPainter extends CustomPainter {
  _KiteStringsPainter({
    required this.wind,
    required this.cuts,
    required this.position,
  }) : super(repaint: Listenable.merge([wind, ...cuts]));

  final Animation<double> wind;
  final List<Animation<double>> cuts;
  final Offset Function(int index, double t) position;

  @override
  void paint(Canvas canvas, Size size) {
    final anchors = [
      Offset(size.width * 0.08, size.height),
      Offset(size.width * 0.5, size.height),
      Offset(size.width * 0.92, size.height),
    ];
    for (int i = 0; i < anchors.length; i++) {
      final kite = position(i, wind.value) + const Offset(0, -8);
      final anchor = anchors[i];
      final cut = cuts[i].value;
      // A cut string falls slack and fades away
      final opacity = cut == 0 ? 0.75 : (1 - cut * 1.6).clamp(0.0, 1.0) * 0.75;
      if (opacity <= 0) continue;
      final sag = Offset(
        (kite.dx + anchor.dx) / 2 + 30,
        (kite.dy + anchor.dy) / 2 + 40 + cut * 260,
      );
      canvas.drawPath(
        Path()
          ..moveTo(kite.dx, kite.dy + cut * 200)
          ..quadraticBezierTo(sag.dx, sag.dy, anchor.dx, anchor.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_KiteStringsPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Marigold
// ---------------------------------------------------------------------------

/// A marigold flower with layered, ruffled petals.
class _Marigold extends StatelessWidget {
  const _Marigold();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _MarigoldPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _MarigoldPainter extends CustomPainter {
  const _MarigoldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    const rings = [
      (1.0, 16, Color(0xFFE65100)),
      (0.78, 14, Color(0xFFF57C00)),
      (0.56, 12, Color(0xFFFF9800)),
      (0.34, 9, Color(0xFFFFB300)),
    ];
    for (final (extent, count, color) in rings) {
      final petalRadius = radius * 0.28 * (0.6 + extent * 0.4);
      for (int i = 0; i < count; i++) {
        final angle = i * 2 * pi / count + extent;
        final at =
            center + Offset(cos(angle), sin(angle)) * radius * extent * 0.6;
        canvas
          ..drawCircle(at, petalRadius, Paint()..color = color)
          // Ruffled petal edge
          ..drawCircle(
            at,
            petalRadius,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.8
              ..color = Colors.black.withValues(alpha: 0.12),
          );
      }
    }
    canvas.drawCircle(
      center,
      radius * 0.14,
      Paint()..color = const Color(0xFFBF6A00),
    );
  }

  @override
  bool shouldRepaint(_MarigoldPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Ping (bamboo swing)
// ---------------------------------------------------------------------------

class _Ping extends StatelessWidget {
  const _Ping({required this.swing});

  final Animation<double> swing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: CustomPaint(
        painter: _PingPainter(swing),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PingPainter extends CustomPainter {
  _PingPainter(this.swing) : super(repaint: swing);

  final Animation<double> swing;

  /// A bamboo pole with cylindrical shading and knots.
  void _bamboo(Canvas canvas, Offset from, Offset to, double width) {
    final direction = to - from;
    final length = direction.distance;
    canvas
      ..save()
      ..translate(from.dx, from.dy)
      ..rotate(atan2(direction.dy, direction.dx));
    final rect = Rect.fromLTWH(0, -width / 2, length, width);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(width / 2)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6B5427),
            Color(0xFFD2B46C),
            Color(0xFF9C7F3E),
            Color(0xFF5E4A22),
          ],
          stops: [0, 0.35, 0.65, 1],
        ).createShader(rect),
    );
    // Knots
    for (double x = 40; x < length - 10; x += 46) {
      canvas.drawRect(
        Rect.fromLTWH(x, -width / 2, 3, width),
        Paint()..color = const Color(0xFF5B4520).withValues(alpha: 0.8),
      );
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final top = Offset(cx, 20);
    final ground = size.height;

    // Four poles lashed together at the top
    for (final dx in [-128.0, -86.0, 86.0, 128.0]) {
      _bamboo(canvas, top, Offset(cx + dx, ground), 8);
    }
    // Rope lashing
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        top + Offset(-7, 2 + i * 3.0),
        top + Offset(7, 5 + i * 3.0),
        Paint()
          ..strokeWidth = 2
          ..color = const Color(0xFFBCA27A),
      );
    }

    // The swing, pivoting from the top
    final angle = (swing.value - 0.5) * 1.0;
    const ropeLength = 196.0;
    final seat = top + Offset(sin(angle) * ropeLength, cos(angle) * ropeLength);
    final side = Offset(cos(angle), -sin(angle)) * 20;
    final rope = Paint()
      ..strokeWidth = 3
      ..color = const Color(0xFFC8AD7F);
    final twist = Paint()
      ..strokeWidth = 3
      ..color = const Color(0xFF9E8358);
    for (final end in [seat - side, seat + side]) {
      canvas.drawLine(top, end, rope);
      // Twisted jute
      for (double t = 0.05; t < 1; t += 0.06) {
        final p = Offset.lerp(top, end, t)!;
        canvas.drawLine(p, p + const Offset(1.5, 1.5), twist);
      }
    }
    // Wooden seat
    canvas.drawLine(
      seat - side * 1.3,
      seat + side * 1.3,
      Paint()
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF6D4C2A),
    );

    // Marigold garland where the poles meet
    for (int i = -4; i <= 4; i++) {
      final at = top + Offset(i * 8.5, 6 + (i * i) * 1.1);
      canvas
        ..drawCircle(
          at,
          5.5,
          Paint()
            ..color = i.isEven
                ? const Color(0xFFFF9800)
                : const Color(0xFFFFB300),
        )
        ..drawCircle(at, 2, Paint()..color = const Color(0xFFE65100));
    }

    // Marigold garlands wound up both ropes
    for (final end in [seat - side, seat + side]) {
      for (int i = 0; i < 8; i++) {
        final at = Offset.lerp(top, end, 0.3 + i * 0.09)!;
        canvas
          ..drawCircle(
            at,
            4.5,
            Paint()
              ..color = i.isEven
                  ? const Color(0xFFFF9800)
                  : const Color(0xFFFFB300),
          )
          ..drawCircle(at, 1.6, Paint()..color = const Color(0xFFE65100));
      }
    }

    // A red cloth with gold trim draped over the seat, tassels swaying
    final along = Offset(cos(angle), -sin(angle));
    final down = Offset(sin(angle), cos(angle));
    final left = seat - side * 1.25;
    final right = seat + side * 1.25;
    final cloth = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..lineTo(right.dx + down.dx * 16, right.dy + down.dy * 16)
      ..quadraticBezierTo(
        seat.dx + down.dx * 26,
        seat.dy + down.dy * 26,
        left.dx + down.dx * 16,
        left.dy + down.dy * 16,
      )
      ..close();
    canvas
      ..drawPath(
        cloth,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD50000), Color(0xFF8E0000)],
          ).createShader(cloth.getBounds()),
      )
      ..drawPath(
        cloth,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFFFFD54F),
      );
    for (final t in [0.15, 0.5, 0.85]) {
      final base =
          Offset.lerp(left, right, t)! + down * (16 + sin(t * pi) * 10);
      final tip = base + down * 10 + along * sin(angle * 3) * 3;
      canvas
        ..drawLine(
          base,
          tip,
          Paint()
            ..strokeWidth = 2
            ..color = const Color(0xFFFFD54F),
        )
        ..drawCircle(tip, 2.5, Paint()..color = const Color(0xFFFFC107));
    }
  }

  @override
  bool shouldRepaint(_PingPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Tika plate
// ---------------------------------------------------------------------------

class _TikaCard extends StatelessWidget {
  const _TikaCard({
    required this.plateKey,
    required this.blessing,
    required this.blessingIndex,
    required this.onReceive,
  });

  final GlobalKey plateKey;
  final String blessing;
  final int blessingIndex;
  final VoidCallback onReceive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF8EC), Color(0xFFFCE9CF)],
        ),
        border: Border.all(color: const Color(0xFFE0B96A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A3E00).withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'टीका र जमरा',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF8E1B00),
            ),
          ),
          const Text(
            'Tika & Jamara',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF8D6E63),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            key: plateKey,
            height: 150,
            width: double.infinity,
            child: const CustomPaint(painter: _TikaPlatePainter()),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            child: Text(
              blessing,
              key: ValueKey(blessingIndex),
              textAlign: TextAlign.center,
              style: const TextStyle(
                height: 1.5,
                fontSize: 15.5,
                fontStyle: FontStyle.italic,
                color: Color(0xFF5D3A1A),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FestiveButton(
            label: '🙏  Receive tika',
            gradient: const LinearGradient(
              colors: [Color(0xFFC62828), Color(0xFFEF6C00)],
            ),
            glow: const Color(0xFFFF3D00),
            textColor: Colors.white,
            onPressed: onReceive,
          ),
        ],
      ),
    );
  }
}

/// A brass thali with red tika, rice, jamara, a diyo and marigolds.
class _TikaPlatePainter extends CustomPainter {
  const _TikaPlatePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.6);
    final plate = Rect.fromCenter(center: center, width: 250, height: 104);

    // Shadow under the plate
    canvas.drawOval(
      plate.shift(const Offset(0, 8)).inflate(2),
      Paint()
        ..color = const Color(0xFF5D3A1A).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Polished brass rim and dish
    canvas.drawOval(
      plate,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8A6A1F),
            Color(0xFFF3D27A),
            Color(0xFFB08A2E),
            Color(0xFF7A5A18),
          ],
          stops: [0, 0.35, 0.7, 1],
        ).createShader(plate),
    );
    final dish = plate.deflate(14);
    canvas
      ..drawOval(
        dish,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFFF5D98A), Color(0xFFC89B3C), Color(0xFF9C7424)],
          ).createShader(dish),
      )
      ..drawOval(
        dish.deflate(10),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF8A6A1F).withValues(alpha: 0.5),
      );

    // Marigolds on the back of the rim
    for (int i = 0; i < 6; i++) {
      final angle = pi * 1.08 + i * pi * 0.84 / 5;
      final at = Offset(
        center.dx + cos(angle) * plate.width / 2 * 0.96,
        center.dy + sin(angle) * plate.height / 2 * 0.96,
      );
      canvas
        ..save()
        ..translate(at.dx - 12, at.dy - 12);
      const _MarigoldPainter().paint(canvas, const Size(24, 24));
      canvas.restore();
    }

    // Red tika: rice mixed with vermilion and yogurt, heaped up
    final mound = Rect.fromCenter(
      center: center + const Offset(-30, -4),
      width: 94,
      height: 46,
    );
    final heap = Path()
      ..moveTo(mound.left, mound.bottom)
      ..cubicTo(
        mound.left + 8,
        mound.top - 6,
        mound.right - 8,
        mound.top - 6,
        mound.right,
        mound.bottom,
      )
      ..close();
    canvas.drawPath(
      heap,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.6),
          colors: [Color(0xFFFF5252), Color(0xFFD50000), Color(0xFF8E0000)],
        ).createShader(mound),
    );
    final random = Random(5);
    for (int i = 0; i < 80; i++) {
      final t = 0.08 + random.nextDouble() * 0.84;
      final x = mound.left + t * mound.width;
      final top = mound.bottom - sin(t * pi) * (mound.height - 6);
      final y = top + 3 + random.nextDouble() * (mound.bottom - top - 3);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(random.nextDouble() * pi)
        // Rice grains, most of them stained red
        ..drawOval(
          const Rect.fromLTWH(-2, -1, 4, 2),
          Paint()
            ..color = random.nextDouble() < 0.35
                ? const Color(0xFFFFF8E1)
                : const Color(0xFFFF8A80),
        )
        ..restore();
    }

    // Jamara, tied with a red thread
    final jamaraBase = center + const Offset(62, 6);
    for (int i = 0; i < 28; i++) {
      final lean = (i - 14) * 1.6;
      final height = 52 + random.nextDouble() * 24;
      canvas.drawPath(
        Path()
          ..moveTo(jamaraBase.dx + (i - 14) * 0.6, jamaraBase.dy)
          ..quadraticBezierTo(
            jamaraBase.dx + lean * 0.5,
            jamaraBase.dy - height / 2,
            jamaraBase.dx + lean,
            jamaraBase.dy - height,
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(
            const Color(0xFFF4F7C5),
            const Color(0xFFC0CA33),
            random.nextDouble(),
          )!,
      );
    }
    canvas.drawRect(
      Rect.fromCenter(
        center: jamaraBase + const Offset(0, -12),
        width: 16,
        height: 4,
      ),
      Paint()..color = const Color(0xFFD50000),
    );

    // A small lit diyo
    final diyo = center + const Offset(14, 26);
    final flame = Rect.fromCenter(
      center: diyo + const Offset(0, -11),
      width: 6,
      height: 12,
    );
    canvas
      ..drawCircle(
        diyo + const Offset(0, -14),
        12,
        Paint()
          ..color = const Color(0xFFFFB300).withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      )
      ..drawOval(
        Rect.fromCenter(center: diyo, width: 26, height: 10),
        Paint()..color = const Color(0xFFA1441C),
      )
      ..drawOval(
        flame,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.white, Color(0xFFFFD54F), Color(0xFFFF6D00)],
          ).createShader(flame),
      );
  }

  @override
  bool shouldRepaint(_TikaPlatePainter oldDelegate) => false;
}
