import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'common.dart';

/// Holi, the festival of colours: gulal powder bursting in clouds, colour
/// that stains a white cotton cloth wherever it lands, a pichkari (water
/// gun) you squirt by dragging, and water balloons.
class HoliPage extends StatefulWidget {
  const HoliPage({super.key});

  @override
  State<HoliPage> createState() => _HoliPageState();
}

/// A patch of colour that has landed on the cloth.
class _Stain {
  const _Stain(this.center, this.color, this.radius, this.seed);

  final Offset center;
  final Color color;
  final double radius;
  final int seed;
}

class _HoliPageState extends State<HoliPage> with TickerProviderStateMixin {
  static const _colors = [
    Color(0xFFE91E63), // pink
    Color(0xFFFFC107), // yellow
    Color(0xFF00C853), // green
    Color(0xFF2979FF), // blue
    Color(0xFFAA00FF), // purple
    Color(0xFFFF6D00), // orange
  ];
  static const _names = ['Pink', 'Yellow', 'Green', 'Blue', 'Purple', 'Orange'];
  static const _balloonColors = [0, 3, 2, 1];

  /// A soft blooming cloud of powder per colour...
  final _clouds = List.generate(_colors.length, (_) => ParticleController());

  /// ...and a spray of fine grains and drops per colour.
  final _grains = List.generate(_colors.length, (_) => ParticleController());

  final _stains = ValueNotifier<List<_Stain>>(const []);
  final _bowlKeys = List.generate(_colors.length, (_) => GlobalKey());
  final _balloonKeys = List.generate(_balloonColors.length, (_) => GlobalKey());
  final _popped = <int>{};
  final _random = Random();
  int _selected = 0;
  Offset? _lastSquirt;
  late final Timer _autoPuffs;
  bool _seeded = false;

  late final _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    // People throwing colour now and then, all around the page
    _autoPuffs = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      if (!mounted) return;
      final size = MediaQuery.sizeOf(context);
      _puff(
        Offset(
          size.width * (0.1 + _random.nextDouble() * 0.8),
          size.height * (0.1 + _random.nextDouble() * 0.75),
        ),
        _random.nextInt(_colors.length),
        stain: _random.nextDouble() < 0.5,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    // The cloth is already splashed with colour when the page opens
    final size = MediaQuery.sizeOf(context);
    final random = Random(12);
    _stains.value = [
      for (int i = 0; i < 14; i++)
        _Stain(
          Offset(
            size.width * random.nextDouble(),
            size.height * random.nextDouble(),
          ),
          _colors[i % _colors.length],
          40 + random.nextDouble() * 50,
          random.nextInt(1 << 30),
        ),
    ];
  }

  @override
  void dispose() {
    _autoPuffs.cancel();
    _wobble.dispose();
    _stains.dispose();
    for (final controller in [..._clouds, ..._grains]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addStain(Offset center, int color, double radius) {
    final stains = [
      ..._stains.value,
      _Stain(center, _colors[color], radius, _random.nextInt(1 << 30)),
    ];
    // Keep the cloth from getting too busy
    _stains.value = stains.length > 90
        ? stains.sublist(stains.length - 90)
        : stains;
  }

  /// A handful of gulal: a blooming cloud and a spray of grains.
  void _puff(
    Offset position,
    int color, {
    bool thrownUp = false,
    bool stain = true,
  }) {
    final spread = thrownUp ? pi / 1.6 : 2 * pi;
    _clouds[color].burst(
      position: position,
      count: 18,
      spread: spread,
      minSpeed: 30,
      maxSpeed: thrownUp ? 380 : 190,
      gravity: -15,
      drag: 2.4,
      lifespan: const Duration(milliseconds: 2600),
    );
    _grains[color].burst(
      position: position,
      count: 50,
      spread: spread,
      minSpeed: 120,
      maxSpeed: thrownUp ? 620 : 480,
      gravity: 380,
      drag: 1.3,
      lifespan: const Duration(milliseconds: 1300),
    );
    if (stain) {
      _addStain(
        thrownUp ? position - const Offset(0, 90) : position,
        color,
        45 + _random.nextDouble() * 35,
      );
    }
  }

  /// Squirts coloured water from the pichkari while dragging.
  void _squirt(Offset position) {
    _grains[_selected].burst(
      position: position,
      count: 3,
      spread: pi / 3,
      angle: -pi / 2,
      minSpeed: 60,
      maxSpeed: 180,
      gravity: 700,
      drag: 0.5,
      lifespan: const Duration(milliseconds: 700),
    );
    final last = _lastSquirt;
    if (last == null || (position - last).distance > 22) {
      _lastSquirt = position;
      _addStain(position, _selected, 12 + _random.nextDouble() * 10);
    }
  }

  void _popBalloon(int index) {
    if (_popped.contains(index)) return;
    final color = _balloonColors[index];
    _grains[color].burstFromKey(
      _balloonKeys[index],
      count: 70,
      minSpeed: 150,
      maxSpeed: 600,
      gravity: 700,
      drag: 0.9,
      lifespan: const Duration(milliseconds: 1600),
    );
    final box = _balloonKeys[index].currentContext?.findRenderObject();
    final page = context.findRenderObject();
    if (box is RenderBox && page is RenderBox) {
      final center = box.localToGlobal(
        box.size.center(Offset.zero),
        ancestor: page,
      );
      _addStain(center, color, 70);
    }
    setState(() => _popped.add(index));
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _popped.remove(index));
    });
  }

  void _throwFromBowl(int index) {
    setState(() => _selected = index);
    final box = _bowlKeys[index].currentContext?.findRenderObject();
    final page = context.findRenderObject();
    if (box is RenderBox && page is RenderBox) {
      final top = box.localToGlobal(
        Offset(box.size.width / 2, box.size.height * 0.3),
        ancestor: page,
      );
      _puff(top, index, thrownUp: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return ThemeScaffold(
      dark: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapUp: (details) => _puff(details.localPosition, _selected),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerMove: (event) => _squirt(event.localPosition),
          onPointerUp: (_) => _lastSquirt = null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // White cotton cloth, stained wherever colour lands
              const RepaintBoundary(
                child: CustomPaint(painter: _ClothPainter()),
              ),
              RepaintBoundary(
                child: CustomPaint(painter: _StainPainter(_stains)),
              ),
              // Fine powder hanging in the air
              const ParticleEffects(
                config: ParticleConfig(
                  direction: ParticleDirection.none,
                  particleCount: 40,
                  minSize: 3,
                  maxSize: 9,
                  gradientColors: _colors,
                  enableBlur: true,
                  blurSigma: 2,
                  minOpacity: 0.1,
                  maxOpacity: 0.45,
                  velocityMultiplier: 0.3,
                  driftAmplitude: 30,
                  seed: 8,
                ),
              ),

              ListView(
                padding: EdgeInsets.only(top: topPadding + 84),
                children: [
                  const Eyebrow(
                    '✦  THE FESTIVAL OF COLOURS  ✦',
                    color: Color(0xFFAD1457),
                  ),
                  const SizedBox(height: 10),
                  const _PowderTitle(),
                  const SizedBox(height: 10),
                  const Text(
                    'होलीको शुभकामना',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6A1B9A),
                      shadows: [Shadow(color: Colors.white, blurRadius: 10)],
                    ),
                  ),
                  const Text(
                    '“Bura na mano, Holi hai!”',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    'Pick your gulal · ${_names[_selected]}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (int i = 0; i < _colors.length; i++)
                          GestureDetector(
                            onTap: () => _throwFromBowl(i),
                            child: AnimatedSlide(
                              offset: Offset(0, i == _selected ? -0.18 : 0),
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              child: _GulalBowl(
                                key: _bowlKeys[i],
                                color: _colors[i],
                                selected: i == _selected,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Pop a water balloon',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (int i = 0; i < _balloonColors.length; i++)
                        GestureDetector(
                          onTap: () => _popBalloon(i),
                          child: AnimatedScale(
                            scale: _popped.contains(i) ? 0 : 1,
                            duration: Duration(
                              milliseconds: _popped.contains(i) ? 90 : 500,
                            ),
                            curve: _popped.contains(i)
                                ? Curves.easeIn
                                : Curves.elasticOut,
                            child: AnimatedBuilder(
                              animation: _wobble,
                              builder: (context, child) => Transform.rotate(
                                angle: sin(_wobble.value * pi + i) * 0.06,
                                child: Transform.scale(
                                  scaleX:
                                      1 +
                                      sin(_wobble.value * pi * 2 + i) * 0.02,
                                  scaleY:
                                      1 -
                                      sin(_wobble.value * pi * 2 + i) * 0.02,
                                  child: child,
                                ),
                              ),
                              child: _WaterBalloon(
                                key: _balloonKeys[i],
                                color: _colors[_balloonColors[i]],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF6A1B9A,
                            ).withValues(alpha: 0.12),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Text(
                        'May your life be filled with every colour of joy, '
                        'love and laughter.\n\nTap anywhere to throw gulal, '
                        'drag to squirt the pichkari — and watch the colour '
                        'stain the cloth!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.5,
                          height: 1.55,
                          color: Color(0xFF4E342E),
                        ),
                      ),
                    ),
                  ),
                  const MadeWith(color: Color(0xFF6D4C41)),
                ],
              ),

              // Powder clouds and grains, one pair of layers per colour
              for (int i = 0; i < _colors.length; i++) ...[
                ParticleEffects(
                  controller: _clouds[i],
                  config: ParticleConfig(
                    particleCount: 0,
                    minSize: 34,
                    maxSize: 80,
                    particleColor: _colors[i],
                    enableBlur: true,
                    blurSigma: 10,
                    minOpacity: 0,
                    maxOpacity: 0.62,
                    enableOpacityAnimation: false,
                    lifecycle: const ParticleLifecycle(
                      startScale: 0.35,
                      endScale: 1.9,
                      endOpacity: 0,
                    ),
                  ),
                ),
                ParticleEffects(
                  controller: _grains[i],
                  config: ParticleConfig(
                    particleCount: 0,
                    particleTypes: const [
                      ParticleType.circle,
                      ParticleType.circle,
                      ParticleType.raindrop,
                    ],
                    minSize: 2,
                    maxSize: 6,
                    particleColor: _colors[i],
                    enableOpacityAnimation: false,
                    maxOpacity: 0.95,
                    enableRotation: true,
                    lifecycle: const ParticleLifecycle(endScale: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Happy Holi" in bright colours with a powdery glow.
class _PowderTitle extends StatelessWidget {
  const _PowderTitle();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 80,
      height: 0.9,
      fontWeight: FontWeight.w900,
      letterSpacing: -2,
    );
    return Center(
      child: Stack(
        children: [
          // Coloured powder glowing around the letters
          Text(
            'Happy\nHoli',
            textAlign: TextAlign.center,
            style: style.copyWith(
              color: Colors.transparent,
              shadows: const [
                Shadow(
                  color: Color(0xAAE91E63),
                  blurRadius: 24,
                  offset: Offset(-8, -6),
                ),
                Shadow(
                  color: Color(0xAAFFC107),
                  blurRadius: 24,
                  offset: Offset(8, -4),
                ),
                Shadow(
                  color: Color(0xAA2979FF),
                  blurRadius: 24,
                  offset: Offset(-6, 8),
                ),
                Shadow(
                  color: Color(0xAA00C853),
                  blurRadius: 24,
                  offset: Offset(8, 8),
                ),
              ],
            ),
          ),
          // A white outline keeps the letters crisp over the stains
          Text(
            'Happy\nHoli',
            textAlign: TextAlign.center,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 8
                ..strokeJoin = StrokeJoin.round
                ..color = Colors.white,
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE91E63),
                Color(0xFFFF6D00),
                Color(0xFFFFC107),
                Color(0xFF00C853),
                Color(0xFF2979FF),
                Color(0xFFAA00FF),
              ],
            ).createShader(bounds),
            child: Text(
              'Happy\nHoli',
              textAlign: TextAlign.center,
              style: style.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// A white cotton cloth with a fine weave and soft folds.
class _ClothPainter extends CustomPainter {
  const _ClothPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = const Color(0xFFFBF7F0));
    // Soft folds
    for (final (x, alpha) in [(0.2, 0.05), (0.55, 0.035), (0.85, 0.05)]) {
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(x * 2 - 1.4, -1),
            end: Alignment(x * 2 - 0.6, 1),
            colors: [
              Colors.transparent,
              const Color(0xFF8D6E63).withValues(alpha: alpha),
              Colors.transparent,
            ],
          ).createShader(bounds),
      );
    }
    // Weave
    // Uneven threads, as in hand-woven cotton
    final random = Random(1);
    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..strokeWidth = 0.5
          ..color = const Color(
            0xFF8D6E63,
          ).withValues(alpha: 0.012 + random.nextDouble() * 0.02),
      );
    }
    for (double x = 0; x < size.width; x += 2) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..strokeWidth = 0.5
          ..color = const Color(
            0xFF8D6E63,
          ).withValues(alpha: 0.01 + random.nextDouble() * 0.015),
      );
    }
  }

  @override
  bool shouldRepaint(_ClothPainter oldDelegate) => false;
}

/// Colour soaked into the cloth: a soft irregular blot and a spray of
/// specks around it.
class _StainPainter extends CustomPainter {
  _StainPainter(this.stains) : super(repaint: stains);

  final ValueNotifier<List<_Stain>> stains;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stain in stains.value) {
      final random = Random(stain.seed);
      // Overlapping soft blobs give an irregular shape
      for (int i = 0; i < 7; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final distance = random.nextDouble() * stain.radius * 0.45;
        final radius = stain.radius * (0.35 + random.nextDouble() * 0.35);
        canvas.drawCircle(
          stain.center + Offset(cos(angle), sin(angle)) * distance,
          radius,
          Paint()
            ..color = stain.color.withValues(alpha: 0.2)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4),
        );
      }
      // Specks where grains of powder landed
      for (int i = 0; i < 36; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final distance = stain.radius * (0.5 + random.nextDouble() * 1.2);
        canvas.drawCircle(
          stain.center + Offset(cos(angle), sin(angle)) * distance,
          0.6 + random.nextDouble() * 2,
          Paint()..color = stain.color.withValues(alpha: 0.45),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StainPainter oldDelegate) => false;
}

/// A brass bowl heaped with gulal powder.
class _GulalBowl extends StatelessWidget {
  const _GulalBowl({super.key, required this.color, required this.selected});

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 54,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          if (selected)
            BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 22),
        ],
      ),
      child: CustomPaint(painter: _GulalBowlPainter(color)),
    );
  }
}

class _GulalBowlPainter extends CustomPainter {
  const _GulalBowlPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rimY = h * 0.52;

    // Powder heaped above the rim
    final heap = Path()
      ..moveTo(w * 0.08, rimY)
      ..cubicTo(w * 0.2, h * 0.08, w * 0.8, h * 0.08, w * 0.92, rimY)
      ..close();
    canvas.drawPath(
      heap,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.5),
          colors: [
            Color.lerp(color, Colors.white, 0.35)!,
            color,
            Color.lerp(color, Colors.black, 0.2)!,
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, rimY)),
    );
    // Powder grain
    final random = Random(color.toARGB32());
    for (int i = 0; i < 40; i++) {
      final t = 0.12 + random.nextDouble() * 0.76;
      final top = rimY - sin(t * pi) * (rimY - h * 0.16);
      canvas.drawCircle(
        Offset(w * t, top + random.nextDouble() * (rimY - top)),
        0.7,
        Paint()
          ..color = (random.nextBool() ? Colors.white : Colors.black)
              .withValues(alpha: 0.18),
      );
    }

    // Brass bowl
    final bowl = Path()
      ..moveTo(0, rimY)
      ..quadraticBezierTo(w * 0.05, h, w / 2, h)
      ..quadraticBezierTo(w * 0.95, h, w, rimY)
      ..close();
    canvas.drawPath(
      bowl,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF8A6A1F),
            Color(0xFFF3D27A),
            Color(0xFFB08A2E),
            Color(0xFF7A5A18),
          ],
          stops: [0, 0.35, 0.7, 1],
        ).createShader(Rect.fromLTWH(0, rimY, w, h - rimY)),
    );
    canvas.drawOval(
      Rect.fromLTWH(0, rimY - 3, w, 6),
      Paint()..color = const Color(0xFFD9B45A),
    );
  }

  @override
  bool shouldRepaint(_GulalBowlPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A glossy water balloon with a knot and a string.
class _WaterBalloon extends StatelessWidget {
  const _WaterBalloon({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 92,
      child: CustomPaint(painter: _WaterBalloonPainter(color)),
    );
  }
}

class _WaterBalloonPainter extends CustomPainter {
  const _WaterBalloonPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final body = Rect.fromLTWH(2, 0, w - 4, 64);
    // Water weighs the bottom down: rounder at the bottom
    final balloon = Path()
      ..moveTo(w / 2, 0)
      ..cubicTo(w * 1.05, 0, w * 1.0, 60, w / 2, 64)
      ..cubicTo(0, 60, -w * 0.05, 0, w / 2, 0)
      ..close();

    canvas.drawShadow(balloon, color, 6, true);
    canvas.drawPath(
      balloon,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.9,
          colors: [
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(body),
    );
    // Water sloshing inside
    canvas.save();
    canvas.clipPath(balloon);
    canvas.drawRect(
      Rect.fromLTWH(0, 40, w, 30),
      Paint()
        ..color = Color.lerp(
          color,
          Colors.black,
          0.15,
        )!.withValues(alpha: 0.45),
    );
    canvas.restore();
    // Specular highlights
    canvas.drawOval(
      Rect.fromLTWH(w * 0.24, 9, w * 0.2, 14),
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
    canvas.drawCircle(
      Offset(w * 0.62, 46),
      2.5,
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
    // Knot and string
    canvas.drawPath(
      Path()
        ..moveTo(w / 2 - 4, 68)
        ..lineTo(w / 2 + 4, 68)
        ..lineTo(w / 2, 63)
        ..close(),
      Paint()..color = Color.lerp(color, Colors.black, 0.3)!,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w / 2, 68)
        ..quadraticBezierTo(w / 2 + 8, 78, w / 2 - 2, 90),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF6D4C41),
    );
  }

  @override
  bool shouldRepaint(_WaterBalloonPainter oldDelegate) =>
      oldDelegate.color != color;
}
