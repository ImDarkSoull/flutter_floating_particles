import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';
import 'scenery.dart';

/// Height of the stone ledge the guardian stands on.
const _ledgeHeight = 170.0;

/// The searchlight on the rooftop, as a fraction of the page size.
const _lamp = Offset(0.24, 0.585);

/// The clock tower's belfry, where the bats roost.
const _belfry = Offset(0.56, 0.5);

/// An original dark-knight theme: a gothic city in the rain, a caped guardian
/// on a gargoyle ledge, lightning over the clock tower, a searchlight you can
/// aim, and a swarm of bats to summon.
class VigilantePage extends StatefulWidget {
  const VigilantePage({super.key});

  @override
  State<VigilantePage> createState() => _VigilantePageState();
}

class _VigilantePageState extends State<VigilantePage>
    with TickerProviderStateMixin {
  final _bats = ParticleController();
  final _ledgeKey = GlobalKey();
  final _ledgeTopKey = GlobalKey();
  final _random = Random();
  final _aim = ValueNotifier<Offset?>(null);
  Timer? _timer;

  /// The current lightning bolt, in page coordinates.
  List<Offset> _bolt = const [];

  late final _sweep = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);
  late final _clouds = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 80),
  )..repeat();
  late final _cape = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();
  late final _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _scheduleStrike();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sweep.dispose();
    _clouds.dispose();
    _cape.dispose();
    _flash.dispose();
    _aim.dispose();
    _bats.dispose();
    super.dispose();
  }

  void _scheduleStrike() {
    _timer = Timer(Duration(milliseconds: 4000 + _random.nextInt(5000)), () {
      if (!mounted) return;
      _strike();
      _scheduleStrike();
    });
  }

  /// Lightning over the city, which startles a few bats from the belfry.
  void _strike({int bats = 8}) {
    final size = MediaQuery.sizeOf(context);
    final start = Offset(
      size.width * (0.1 + _random.nextDouble() * 0.8),
      size.height * 0.27,
    );
    final end = Offset(
      start.dx + (_random.nextDouble() - 0.5) * 120,
      size.height * (0.46 + _random.nextDouble() * 0.08),
    );
    const segments = 12;
    final points = <Offset>[start];
    for (int i = 1; i < segments; i++) {
      final base = Offset.lerp(start, end, i / segments)!;
      points.add(base + Offset((_random.nextDouble() - 0.5) * 44, 0));
    }
    points.add(end);
    setState(() => _bolt = points);
    _flash.forward(from: 0);
    _releaseBats(bats);
  }

  void _releaseBats(int count) {
    final size = MediaQuery.sizeOf(context);
    _bats.burst(
      position: Offset(size.width * _belfry.dx, size.height * _belfry.dy),
      count: count,
      angle: -pi / 2,
      spread: pi * 1.3,
      minSpeed: 120,
      maxSpeed: 380,
      gravity: -40,
      drag: 0.35,
      lifespan: const Duration(seconds: 3),
    );
  }

  void _summon() {
    _strike(bats: 0);
    _releaseBats(48);
  }

  void _aimAt(Offset position, Size size) {
    _aim.value = Offset(
      position.dx.clamp(0, size.width),
      position.dy.clamp(0, size.height * 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);

    return ThemeScaffold(
      child: ColoredBox(
        color: const Color(0xFF05070D),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _bats.burst(
                position: details.localPosition,
                count: 16,
                minSpeed: 120,
                maxSpeed: 340,
                gravity: -40,
                drag: 0.4,
                lifespan: const Duration(milliseconds: 2400),
              ),
              onPanStart: (details) => _aimAt(details.localPosition, size),
              onPanUpdate: (details) => _aimAt(details.localPosition, size),
              onPanEnd: (_) => _aim.value = null,
              onPanCancel: () => _aim.value = null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF05080F),
                          Color(0xFF111A2B),
                          Color(0xFF2B2C38),
                          Color(0xFF4A3B34),
                        ],
                        stops: [0, 0.35, 0.6, 0.8],
                      ),
                    ),
                  ),
                  // Moon, storm clouds and lightning
                  AnimatedBuilder(
                    animation: Listenable.merge([_clouds, _flash]),
                    builder: (context, _) => CustomPaint(
                      painter: _SkyPainter(
                        clouds: _clouds.value,
                        flash: _flicker(_flash.value),
                        bolt: _bolt,
                      ),
                    ),
                  ),
                  // The searchlight, which you can aim by dragging
                  AnimatedBuilder(
                    animation: Listenable.merge([_sweep, _aim]),
                    builder: (context, _) => CustomPaint(
                      painter: _SearchlightPainter(
                        sweep: _sweep.value,
                        aim: _aim.value,
                      ),
                    ),
                  ),
                  // Bats circling the city
                  IgnorePointer(
                    child: ParticleEffects(
                      config: ParticleConfig(
                        particleType: ParticleType.path,
                        customPath: batPath,
                        direction: ParticleDirection.leftToRight,
                        particleCount: 10,
                        minSize: 10,
                        maxSize: 22,
                        particleColor: const Color(0xFF07090E),
                        velocityMultiplier: 0.8,
                        animationDuration: const Duration(seconds: 9),
                        enableOpacityAnimation: false,
                        driftAmplitude: 50,
                        depthEffect: 0.6,
                        seed: 8,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 400,
                    child: CustomPaint(
                      painter: CitySkylinePainter(
                        far: Color(0xFF1C2130),
                        near: Color(0xFF141824),
                        window: Color(0xFFFFCC80),
                        seed: 21,
                      ),
                    ),
                  ),
                  // Mist rolling between the buildings
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: _ledgeHeight - 40,
                    height: 220,
                    child: IgnorePointer(
                      child: ParticleEffects(
                        config: ParticleConfig(
                          particleCount: 0,
                          minSize: 60,
                          maxSize: 130,
                          particleColor: Color(0xFF8D97AD),
                          enableBlur: true,
                          blurSigma: 14,
                          minOpacity: 0,
                          maxOpacity: 0.14,
                          enableOpacityAnimation: false,
                          lifecycle: ParticleLifecycle.growAndFade,
                          emitters: [
                            ParticleEmitter(
                              alignment: Alignment(0, 0.6),
                              extent: Size(10000, 60),
                              rate: 5,
                              angle: 0,
                              spread: 0.3,
                              minSpeed: 8,
                              maxSpeed: 24,
                              gravity: 0,
                              drag: 0,
                              lifespan: Duration(seconds: 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // The gothic skyline, lit up by lightning
                  AnimatedBuilder(
                    animation: _flash,
                    builder: (context, _) => CustomPaint(
                      painter: _GothicSkylinePainter(_flicker(_flash.value)),
                    ),
                  ),
                  // Distant rain behind the ledge
                  IgnorePointer(
                    child: ParticleEffects(
                      config: ParticleConfig.rain.copyWith(
                        particleCount: 70,
                        minSize: 6,
                        maxSize: 12,
                        particleColor: const Color(0xFF7D8BA8),
                        maxOpacity: 0.3,
                        wind: 0.22,
                        seed: 3,
                      ),
                    ),
                  ),
                  // The ledge, the gargoyle and the guardian
                  AnimatedBuilder(
                    animation: Listenable.merge([_cape, _flash]),
                    builder: (context, _) => CustomPaint(
                      painter: _LedgePainter(
                        cape: _cape.value,
                        flash: _flicker(_flash.value),
                      ),
                    ),
                  ),
                  Positioned(
                    key: _ledgeKey,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _ledgeHeight,
                    child: const SizedBox.expand(),
                  ),
                  Positioned(
                    key: _ledgeTopKey,
                    left: 0,
                    right: 0,
                    bottom: _ledgeHeight - 1,
                    height: 2,
                    child: const SizedBox.expand(),
                  ),
                  // Heavy rain, stopped by the ledge
                  IgnorePointer(
                    child: ParticleEffects(
                      colliders: [_ledgeKey],
                      collision: const ParticleCollision(settle: false),
                      config: ParticleConfig.rain.copyWith(
                        particleCount: 110,
                        minSize: 14,
                        maxSize: 28,
                        particleColor: const Color(0xFFB4C3DD),
                        maxOpacity: 0.55,
                        wind: 0.25,
                        depthEffect: 0.8,
                      ),
                    ),
                  ),
                  // Rain splashing on the stone
                  IgnorePointer(
                    child: ParticleEffects(
                      config: ParticleConfig(
                        particleCount: 0,
                        minSize: 1.2,
                        maxSize: 2.4,
                        particleColor: const Color(0xFFCFD8EA),
                        enableOpacityAnimation: false,
                        maxOpacity: 0.7,
                        emitters: [
                          ParticleEmitter(
                            followKey: _ledgeTopKey,
                            rate: 45,
                            angle: -pi / 2,
                            spread: pi * 0.8,
                            minSpeed: 30,
                            maxSpeed: 90,
                            gravity: 500,
                            drag: 0.2,
                            lifespan: const Duration(milliseconds: 380),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: ParticleEffects(
                      controller: _bats,
                      config: ParticleConfig(
                        particleCount: 0,
                        particleType: ParticleType.path,
                        customPath: batPath,
                        minSize: 10,
                        maxSize: 26,
                        particleColor: const Color(0xFF06070B),
                        enableOpacityAnimation: false,
                        maxOpacity: 1,
                      ),
                    ),
                  ),
                  // The whole scene lights up for a moment
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _flash,
                      builder: (context, _) => ColoredBox(
                        color: const Color(
                          0xFFCFDBFF,
                        ).withValues(alpha: _flicker(_flash.value) * 0.16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: padding.top + 64,
              child: IgnorePointer(
                child: Column(
                  children: [
                    const Eyebrow(
                      '✦  THE CITY NEVER SLEEPS  ✦',
                      color: Color(0xFFFFD58A),
                    ),
                    const SizedBox(height: 10),
                    // One line, scaled down to fit narrow screens
                    const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: GradientText(
                        'NIGHT WATCH',
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Color(0xFFE3E8F1),
                            Color(0xFFA9B3C6),
                          ],
                        ),
                        glow: Color(0x66FFC76B),
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Its guardian never does.',
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: padding.bottom + 28,
              child: Column(
                children: [
                  Text(
                    'Tap to scatter bats · drag to aim the light',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FestiveButton(
                    label: '🦇  Summon the swarm',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                    ),
                    glow: const Color(0xFFFFB300),
                    textColor: const Color(0xFF1A1300),
                    onPressed: _summon,
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

/// Two quick flashes, then a slow fade, for the flash animation's [t].
double _flicker(double t) {
  if (t <= 0 || t >= 1) return 0;
  if (t < 0.08) return 1;
  if (t < 0.16) return 0.25;
  if (t < 0.26) return 0.9;
  return (1 - (t - 0.26) / 0.74) * 0.6;
}

/// The moon, drifting storm clouds lit by the city, and lightning.
class _SkyPainter extends CustomPainter {
  const _SkyPainter({
    required this.clouds,
    required this.flash,
    required this.bolt,
  });

  final double clouds;
  final double flash;
  final List<Offset> bolt;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // A pale moon with a halo
    final moon = Offset(w * 0.84, h * 0.36);
    canvas
      ..drawCircle(
        moon,
        120,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x40D5DDEA), Color(0x00D5DDEA)],
          ).createShader(Rect.fromCircle(center: moon, radius: 120)),
      )
      ..drawCircle(
        moon,
        42,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.35, -0.35),
            colors: [Color(0xFFF7F4EA), Color(0xFFC3C8D4)],
          ).createShader(Rect.fromCircle(center: moon, radius: 42)),
      );
    for (final (dx, dy, r) in const [
      (-12.0, -8.0, 9.0),
      (14.0, 10.0, 6.0),
      (5.0, -21.0, 5.0),
      (-6.0, 19.0, 7.0),
      (22.0, -8.0, 4.0),
    ]) {
      canvas.drawCircle(
        moon + Offset(dx, dy),
        r,
        Paint()..color = const Color(0x1A1B2233),
      );
    }

    // Storm clouds drifting across, lit amber from the city below
    final random = Random(5);
    for (int i = 0; i < 22; i++) {
      final depth = random.nextDouble();
      final y = h * (0.03 + random.nextDouble() * 0.42);
      final r = 50 + random.nextDouble() * 90;
      final x =
          ((random.nextDouble() + clouds * (0.6 + depth)) % 1.5 - 0.25) * w;
      final low = (y / (h * 0.45)).clamp(0.0, 1.0);
      final base = Color.lerp(
        const Color(0xFF151C2B),
        const Color(0xFF3C3638),
        low,
      )!;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = Color.lerp(
            base,
            const Color(0xFF9AA9C8),
            flash * 0.55,
          )!.withValues(alpha: 0.6)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.4),
      );
    }

    // The bolt, with a soft glow around a bright core
    if (flash > 0.05 && bolt.length > 1) {
      final path = Path()..moveTo(bolt.first.dx, bolt.first.dy);
      for (final point in bolt.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..color = const Color(0xFF9FB6FF).withValues(alpha: flash * 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        )
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.white.withValues(alpha: flash),
        );
    }
  }

  @override
  bool shouldRepaint(_SkyPainter oldDelegate) =>
      oldDelegate.clouds != clouds ||
      oldDelegate.flash != flash ||
      oldDelegate.bolt != bolt;
}

/// A searchlight beam from the rooftop, projecting an emblem on the clouds.
class _SearchlightPainter extends CustomPainter {
  const _SearchlightPainter({required this.sweep, this.aim});

  final double sweep;
  final Offset? aim;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeInOut.transform(sweep);
    final source = Offset(size.width * _lamp.dx, size.height * _lamp.dy);
    final target =
        aim ?? Offset(size.width * (0.3 + t * 0.45), size.height * 0.31);
    final direction = target - source;
    if (direction.distance < 1) return;
    final side = Offset(-direction.dy, direction.dx) / direction.distance;

    Path beam(double start, double end) => Path()
      ..moveTo(source.dx - side.dx * start, source.dy - side.dy * start)
      ..lineTo(target.dx - side.dx * end, target.dy - side.dy * end)
      ..lineTo(target.dx + side.dx * end, target.dy + side.dy * end)
      ..lineTo(source.dx + side.dx * start, source.dy + side.dy * start)
      ..close();

    final shader = LinearGradient(
      colors: [
        const Color(0xFFFFF4D6).withValues(alpha: 0.45),
        const Color(0xFFFFF4D6).withValues(alpha: 0.08),
      ],
    ).createShader(Rect.fromPoints(source, target));
    // The beam widens as it goes up, with a brighter core
    canvas
      ..drawPath(
        beam(8, 82),
        Paint()
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      )
      ..drawPath(
        beam(3, 36),
        Paint()
          ..shader = shader
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

    // The pool of light on the clouds, with the emblem in its shadow
    canvas
      ..drawOval(
        Rect.fromCenter(center: target, width: 230, height: 150),
        Paint()
          ..color = const Color(0xFFFFE9B0).withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      )
      ..drawOval(
        Rect.fromCenter(center: target, width: 180, height: 116),
        Paint()
          ..color = const Color(0xFFFFF1C9).withValues(alpha: 0.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      )
      ..save()
      ..translate(target.dx, target.dy + 4)
      ..scale(70, 70 * 0.9)
      ..drawPath(
        batPath,
        Paint()..color = const Color(0xFF14161C).withValues(alpha: 0.9),
      )
      ..restore();

    // The lamp on the rooftop
    canvas
      ..drawCircle(
        source,
        24,
        Paint()
          ..color = const Color(0x66FFE7A8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      )
      ..drawCircle(source, 7, Paint()..color = const Color(0xFFFFF8E1));
  }

  @override
  bool shouldRepaint(_SearchlightPainter oldDelegate) =>
      oldDelegate.sweep != sweep || oldDelegate.aim != aim;
}

enum _Roof { flat, spire, stepped, dome, clock }

/// Gothic towers in front of the city: spires, a domed hall and a clock
/// tower, lit up by lightning.
class _GothicSkylinePainter extends CustomPainter {
  const _GothicSkylinePainter(this.flash);

  final double flash;

  // Left, width and top as fractions of the page, and the roof shape
  static const _buildings = [
    (-0.02, 0.14, 0.66, _Roof.spire),
    (0.12, 0.06, 0.71, _Roof.flat),
    (0.17, 0.14, 0.60, _Roof.flat),
    (0.31, 0.10, 0.68, _Roof.stepped),
    (0.41, 0.10, 0.72, _Roof.dome),
    (0.51, 0.10, 0.52, _Roof.clock),
    (0.61, 0.08, 0.69, _Roof.spire),
    (0.69, 0.13, 0.64, _Roof.stepped),
    (0.82, 0.07, 0.71, _Roof.spire),
    (0.89, 0.13, 0.66, _Roof.flat),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final random = Random(12);
    final stone = Paint()
      ..color = Color.lerp(
        const Color(0xFF0B0E16),
        const Color(0xFF2E3A55),
        flash * 0.7,
      )!;
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Color.lerp(
        const Color(0x33FFC98A),
        const Color(0xCCCBD8FF),
        flash,
      )!;

    for (final (left, width, top, roof) in _buildings) {
      final x = w * left;
      final bw = w * width;
      final y = h * top;
      final outline = Path()..moveTo(x, h);
      outline.lineTo(x, y);
      switch (roof) {
        case _Roof.flat:
          // Crenellations along the parapet
          final teeth = max(3, (bw / 10).round());
          final step = bw / (teeth * 2 - 1);
          for (int i = 0; i < teeth * 2 - 1; i++) {
            final up = i.isEven;
            outline
              ..lineTo(x + step * i, up ? y - 6 : y)
              ..lineTo(x + step * (i + 1), up ? y - 6 : y);
          }
        case _Roof.spire:
          outline
            ..lineTo(x + bw * 0.2, y - 8)
            ..lineTo(x + bw * 0.5, y - bw * 1.3)
            ..lineTo(x + bw * 0.8, y - 8);
        case _Roof.stepped:
          outline
            ..lineTo(x + bw * 0.15, y)
            ..lineTo(x + bw * 0.15, y - 16)
            ..lineTo(x + bw * 0.35, y - 16)
            ..lineTo(x + bw * 0.35, y - 30)
            ..lineTo(x + bw * 0.65, y - 30)
            ..lineTo(x + bw * 0.65, y - 16)
            ..lineTo(x + bw * 0.85, y - 16)
            ..lineTo(x + bw * 0.85, y);
        case _Roof.dome:
          // Drawn separately below
          break;
        case _Roof.clock:
          outline
            ..lineTo(x + bw * 0.12, y - 10)
            ..lineTo(x + bw * 0.5, y - bw * 1.6)
            ..lineTo(x + bw * 0.88, y - 10);
      }
      outline
        ..lineTo(x + bw, y)
        ..lineTo(x + bw, h)
        ..close();
      if (roof == _Roof.dome) {
        // A dome on top of a plain block
        canvas.drawRect(Rect.fromLTRB(x, y, x + bw, h), stone);
        final dome = Path()
          ..moveTo(x, y)
          ..arcToPoint(Offset(x + bw, y), radius: Radius.circular(bw / 2))
          ..close();
        canvas
          ..drawPath(dome, stone)
          ..drawPath(dome, rim)
          ..drawRect(
            Rect.fromLTWH(x + bw / 2 - 1, y - bw / 2 - 14, 2, 14),
            stone,
          );
      } else {
        canvas
          ..drawPath(outline, stone)
          ..drawPath(outline, rim);
      }

      // Tall arched windows, some lit
      for (double wy = y + 14; wy < h - _ledgeHeight; wy += 22) {
        for (double wx = x + 5; wx < x + bw - 9; wx += 11) {
          if (random.nextDouble() > 0.3) continue;
          final window = RRect.fromRectAndCorners(
            Rect.fromLTWH(wx, wy, 5, 11),
            topLeft: const Radius.circular(2.5),
            topRight: const Radius.circular(2.5),
          );
          canvas.drawRRect(
            window,
            Paint()
              ..color = const Color(
                0xFFFFC876,
              ).withValues(alpha: 0.35 + random.nextDouble() * 0.55),
          );
        }
      }

      if (roof == _Roof.clock) {
        // A glowing clock face under the spire
        final face = Offset(x + bw / 2, y + bw * 0.45);
        final r = bw * 0.32;
        canvas
          ..drawCircle(
            face,
            r * 2,
            Paint()
              ..color = const Color(0x55FFC26B)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r),
          )
          ..drawCircle(face, r, Paint()..color = const Color(0xFFFFE3A3))
          ..drawCircle(
            face,
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = const Color(0xFF3A2A14),
          );
        final hands = Paint()
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF2A1D0C);
        canvas
          ..drawLine(face, face + Offset(0, -r * 0.8), hands)
          ..drawLine(face, face + Offset(-r * 0.45, -r * 0.2), hands);
      }
    }


  }

  @override
  bool shouldRepaint(_GothicSkylinePainter oldDelegate) =>
      oldDelegate.flash != flash;
}

/// The stone ledge in the foreground, a gargoyle and the caped guardian.
class _LedgePainter extends CustomPainter {
  const _LedgePainter({required this.cape, required this.flash});

  final double cape;
  final double flash;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final top = h - _ledgeHeight;
    final lit = Color.lerp(
      const Color(0x40FFC98A),
      const Color(0xFFD6E2FF),
      flash,
    )!;

    // The wall below the ledge
    canvas.drawRect(
      Rect.fromLTRB(0, top + 12, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(
              const Color(0xFF1B1E26),
              const Color(0xFF3A465E),
              flash * 0.6,
            )!,
            const Color(0xFF07080B),
          ],
        ).createShader(Rect.fromLTRB(0, top, w, h)),
    );
    final joints = Paint()
      ..strokeWidth = 1
      ..color = Colors.black.withValues(alpha: 0.35);
    for (double y = top + 44; y < h; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(w, y), joints);
      final offset = ((y - top) ~/ 32).isEven ? 0.0 : 36.0;
      for (double x = offset; x < w; x += 72) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 32), joints);
      }
    }

    // The overhanging cornice, wet and catching the light on its edge
    final cornice = Rect.fromLTRB(-4, top - 6, w + 4, top + 14);
    canvas
      ..drawRect(
        cornice,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF262A34),
            const Color(0xFF4F5C78),
            flash * 0.6,
          )!,
      )
      ..drawRect(
        Rect.fromLTRB(-4, top + 14, w + 4, top + 20),
        Paint()..color = Colors.black.withValues(alpha: 0.5),
      )
      ..drawLine(
        Offset(0, top - 5),
        Offset(w, top - 5),
        Paint()
          ..strokeWidth = 1.5
          ..color = lit,
      );
    for (double x = 60; x < w; x += 90) {
      canvas.drawLine(Offset(x, top - 6), Offset(x, top + 14), joints);
    }

    final silhouette = Paint()
      ..color = Color.lerp(
        const Color(0xFF0B0C11),
        const Color(0xFF1E2536),
        flash * 0.5,
      )!;
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round
      ..color = lit;

    // The guardian, standing at the edge with the cape blowing in the wind
    canvas
      ..save()
      ..translate(w * 0.7, top - 6);
    final phase = cape * 2 * pi;
    final capePath = Path()
      ..moveTo(-22, -108)
      ..quadraticBezierTo(-36, -60, -30 + sin(phase) * 3, -4);
    const folds = 7;
    for (int i = 1; i <= folds; i++) {
      final f = i / folds;
      final x = -30 + f * 118;
      final y = -4 - f * 34 + sin(phase + i * 1.2) * (4 + f * 8);
      final mid = -30 + (f - 0.5 / folds) * 118;
      capePath.quadraticBezierTo(mid, y + 10, x, y);
    }
    capePath
      ..quadraticBezierTo(
        60 + sin(phase + 0.8) * 8,
        -86 + cos(phase) * 4,
        22,
        -108,
      )
      ..close();
    final body = Path()
      ..moveTo(-15, 0)
      ..lineTo(-5, 0)
      ..lineTo(-3, -48)
      ..lineTo(3, -48)
      ..lineTo(5, 0)
      ..lineTo(15, 0)
      ..lineTo(12, -56)
      ..lineTo(15, -90)
      ..lineTo(27, -102)
      ..lineTo(23, -112)
      ..lineTo(9, -116)
      ..lineTo(8, -123)
      ..lineTo(9.5, -135)
      ..lineTo(8, -148)
      ..lineTo(3.5, -138)
      ..lineTo(-3.5, -138)
      ..lineTo(-8, -148)
      ..lineTo(-9.5, -135)
      ..lineTo(-8, -123)
      ..lineTo(-9, -116)
      ..lineTo(-23, -112)
      ..lineTo(-27, -102)
      ..lineTo(-15, -90)
      ..lineTo(-12, -56)
      ..close();
    canvas
      ..drawPath(capePath, silhouette)
      ..drawPath(capePath, rim)
      ..drawPath(body, silhouette)
      ..drawPath(body, rim)
      // Belt
      ..drawRect(
        const Rect.fromLTWH(-12.5, -60, 25, 4),
        Paint()..color = const Color(0x99C9A24A),
      );
    // Glowing eyes
    final eyes = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    for (final dx in const [-4.0, 4.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(dx, -129), width: 4.5, height: 2),
        eyes,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LedgePainter oldDelegate) =>
      oldDelegate.cape != cape || oldDelegate.flash != flash;
}
