import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../models/direction.dart';
import '../models/particle_config.dart';
import '../models/particle_data.dart';
import '../models/particle_interaction.dart';
import '../models/particle_type.dart';
import 'particle_sprite.dart';

/// Parameters for a one-shot burst of particles.
@immutable
class BurstRequest {
  /// Creates a burst request. See `ParticleController.burst`.
  const BurstRequest({
    this.position,
    this.alignment = Alignment.center,
    this.count = 40,
    this.angle = -pi / 2,
    this.spread = 2 * pi,
    this.minSpeed = 150,
    this.maxSpeed = 450,
    this.gravity = 600,
    this.drag = 0.5,
    this.lifespan = const Duration(seconds: 3),
  });

  /// Origin in local coordinates; overrides [alignment] when set.
  final Offset? position;

  /// Origin relative to the particle area, used when [position] is null.
  final Alignment alignment;

  /// Number of particles to emit.
  final int count;

  /// Center direction of the burst in radians (0 = right, -pi/2 = up).
  final double angle;

  /// Width in radians of the cone particles are emitted in.
  final double spread;

  /// Minimum launch speed in logical pixels per second.
  final double minSpeed;

  /// Maximum launch speed in logical pixels per second.
  final double maxSpeed;

  /// Downward acceleration in logical pixels per second squared.
  final double gravity;

  /// Fraction of speed lost per second to air resistance.
  final double drag;

  /// Maximum time a burst particle stays alive.
  final Duration lifespan;
}

/// A particle emitted by a burst, moved by simple physics.
class BurstParticle {
  /// Creates a burst particle.
  BurstParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.spin,
    required this.life,
    required this.gravity,
    required this.drag,
  });

  /// Horizontal position in logical pixels.
  double x;

  /// Vertical position in logical pixels.
  double y;

  /// Horizontal velocity in logical pixels per second.
  double vx;

  /// Vertical velocity in logical pixels per second.
  double vy;

  /// Current rotation in radians.
  double rotation;

  /// Seconds since the particle was emitted.
  double age = 0;

  /// Size in logical pixels.
  final double size;

  /// Particle color.
  final Color color;

  /// Rotation speed in radians per second.
  final double spin;

  /// Lifespan in seconds.
  final double life;

  /// Downward acceleration in logical pixels per second squared.
  final double gravity;

  /// Fraction of speed lost per second.
  final double drag;
}

/// Animation state and rendering for one particle effect.
///
/// The owning widget advances time with [advance]; every change notifies
/// listeners, which repaints [ParticlePainter] without rebuilding widgets.
class ParticleSystem extends ChangeNotifier {
  /// Creates a particle system for [config].
  ParticleSystem({required this.config});

  /// Maximum number of live burst particles.
  static const int maxBurstParticles = 5000;

  /// The configuration being animated.
  ParticleConfig config;

  /// The continuously animated particles.
  List<ParticleData> particles = const [];

  /// The sprite particles are drawn with; nothing is drawn while null.
  ParticleSprite? sprite;

  /// Pointer interaction, if enabled.
  ParticleInteraction? interaction;

  /// Current pointer position in local coordinates, if any.
  Offset? pointer;

  /// Animation time in seconds.
  double seconds = 0;

  final List<BurstParticle> _bursts = [];
  final List<BurstRequest> _pendingBursts = [];
  final Random _random = Random();
  Size _size = Size.zero;

  // Bilinear, without mipmaps: sprites made with toImageSync have no valid
  // mipmaps on some backends (e.g. Impeller on OpenGL ES), and sampling them
  // draws stray lines and square outlines around particles.
  final Paint _paint = Paint()..filterQuality = FilterQuality.low;
  Float32List _transforms = Float32List(0);
  Float32List _rects = Float32List(0);
  Int32List _colors = Int32List(0);
  ParticleSprite? _rectsSprite;

  /// Whether any burst particles are alive or waiting to be emitted.
  bool get hasBursts => _bursts.isNotEmpty || _pendingBursts.isNotEmpty;

  /// Number of live burst particles.
  int get burstParticleCount => _bursts.length;

  /// Animation time in cycles of [ParticleConfig.animationDuration].
  double get cycles {
    final durationMs = config.animationDuration.inMilliseconds;
    return durationMs > 0 ? seconds * 1000 / durationMs : 0;
  }

  /// Advances the animation by [dt] seconds and repaints.
  void advance(double dt) {
    seconds += dt;
    _spawnPendingBursts();
    _updateBursts(dt);
    notifyListeners();
  }

  /// Queues a burst; it is emitted as soon as the particle area has a size.
  void addBurst(BurstRequest request) {
    _pendingBursts.add(request);
    notifyListeners();
  }

  /// Removes all burst particles.
  void clearBursts() {
    _bursts.clear();
    _pendingBursts.clear();
    notifyListeners();
  }

  /// Repaints without advancing time.
  void markNeedsPaint() => notifyListeners();

  void _spawnPendingBursts() {
    if (_pendingBursts.isEmpty || _size.isEmpty) return;
    for (final request in _pendingBursts) {
      _spawn(request);
    }
    _pendingBursts.clear();
  }

  void _spawn(BurstRequest request) {
    final origin = request.position ?? request.alignment.alongSize(_size);
    final lifespan = request.lifespan.inMicroseconds / 1e6;
    if (lifespan <= 0) return;

    for (int i = 0; i < request.count; i++) {
      if (_bursts.length >= maxBurstParticles) break;
      final angle =
          request.angle + (_random.nextDouble() - 0.5) * request.spread;
      final speed =
          request.minSpeed +
          _random.nextDouble() * (request.maxSpeed - request.minSpeed);
      final size = config.enableSizeVariation
          ? config.minSize +
                _random.nextDouble() * (config.maxSize - config.minSize)
          : config.maxSize;

      _bursts.add(
        BurstParticle(
          x: origin.dx,
          y: origin.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          size: size,
          color: ParticleData.pickColor(config, _random),
          rotation: _random.nextDouble() * 2 * pi,
          spin: (_random.nextDouble() - 0.5) * 4 * pi * config.rotationSpeed,
          life: lifespan * (0.7 + 0.3 * _random.nextDouble()),
          gravity: request.gravity,
          drag: request.drag,
        ),
      );
    }
  }

  void _updateBursts(double dt) {
    if (_bursts.isEmpty) return;
    for (final p in _bursts) {
      p.vy += p.gravity * dt;
      final damping = max(0.0, 1 - p.drag * dt);
      p.vx *= damping;
      p.vy *= damping;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rotation += p.spin * dt;
      p.age += dt;
    }
    _bursts.removeWhere((p) => p.age >= p.life);
  }

  /// Draws all particles into [canvas].
  void paint(Canvas canvas, Size size) {
    _size = size;
    _spawnPendingBursts();

    final sprite = this.sprite;
    if (sprite == null) return;

    _ensureCapacity(particles.length + _bursts.length, sprite);

    final cycles = this.cycles;
    int count = 0;
    for (final particle in particles) {
      if (_writeAmbient(count, particle, size, cycles, sprite)) count++;
    }
    for (final particle in _bursts) {
      if (_writeBurst(count, particle, sprite)) count++;
    }
    if (count == 0) return;

    _paint.blendMode = config.blendMode;
    canvas.drawRawAtlas(
      sprite.image,
      Float32List.sublistView(_transforms, 0, count * 4),
      Float32List.sublistView(_rects, 0, count * 4),
      Int32List.sublistView(_colors, 0, count),
      BlendMode.modulate,
      null,
      _paint,
    );
  }

  void _ensureCapacity(int count, ParticleSprite sprite) {
    if (_colors.length < count) {
      // Grow with headroom so bursts don't reallocate every frame
      final capacity = max(count, _colors.length * 2);
      _transforms = Float32List(capacity * 4);
      _rects = Float32List(capacity * 4);
      _colors = Int32List(capacity);
      _rectsSprite = null;
    }
    if (!identical(_rectsSprite, sprite)) {
      final width = sprite.image.width.toDouble();
      final height = sprite.image.height.toDouble();
      for (int i = 0; i < _rects.length; i += 4) {
        _rects[i] = 0;
        _rects[i + 1] = 0;
        _rects[i + 2] = width;
        _rects[i + 3] = height;
      }
      _rectsSprite = sprite;
    }
  }

  /// Writes the atlas entry for a continuously animated particle. Returns
  /// false if the particle is invisible and was skipped.
  bool _writeAmbient(
    int index,
    ParticleData particle,
    Size size,
    double cycles,
    ParticleSprite sprite,
  ) {
    final config = this.config;
    final width = size.width;
    final height = size.height;

    // Phase offset as a fraction of a cycle
    final phase = particle.animationOffset / (2 * pi);
    final speed = particle.velocity * config.velocityMultiplier;
    // Position along the path, 0.0 (entering) to 1.0 (leaving)
    final progress = (cycles * speed + phase) % 1.0;

    // Half the sprite's extent (including glow) in logical pixels, so
    // particles are fully hidden when they wrap around
    final spriteScale = particle.size / sprite.contentExtent;
    final margin =
        max(sprite.image.width, sprite.image.height) * spriteScale / 2 + 2;
    final coverage = particle.screenOccupancy;
    final exitMargin = coverage >= 1.0 ? margin : 0.0;
    // Drift uses whole sine periods per path so it matches at the wrap
    final wave = progress * 2 * pi + particle.animationOffset;
    final wind = config.wind;
    final drift = config.driftAmplitude;

    double x, y;
    // Direction of motion, for streak orientation
    double dx, dy;
    double sizeFactor = 1.0;
    bool usesProgress = true;
    double fadeIn = config.edgeFade;

    switch (config.direction) {
      case ParticleDirection.topToBottom:
        final t = progress * (margin + height * coverage + exitMargin);
        x = particle.initialX * width + (drift ?? 30) * sin(wave) + wind * t;
        y = -margin + t;
        if (wind != 0) x = _wrap(x, -margin, width + margin);
        dx = wind;
        dy = 1;
        break;

      case ParticleDirection.bottomToTop:
        final t = progress * (margin + height * coverage + exitMargin);
        x =
            particle.initialX * width +
            (drift ?? 20) * sin(2 * wave) +
            wind * t;
        y = height + margin - t;
        if (wind != 0) x = _wrap(x, -margin, width + margin);
        dx = wind;
        dy = -1;
        break;

      case ParticleDirection.leftToRight:
        final t = progress * (margin + width * coverage + exitMargin);
        x = -margin + t;
        y = particle.initialY * height + (drift ?? 15) * cos(wave) + wind * t;
        if (wind != 0) y = _wrap(y, -margin, height + margin);
        dx = 1;
        dy = wind;
        break;

      case ParticleDirection.rightToLeft:
        final t = progress * (margin + width * coverage + exitMargin);
        x = width + margin - t;
        y = particle.initialY * height + (drift ?? 15) * cos(wave) + wind * t;
        if (wind != 0) y = _wrap(y, -margin, height + margin);
        dx = -1;
        dy = wind;
        break;

      case ParticleDirection.diagonal:
        // Start points are spread along a line through the top-left corner
        // so that particles moving at 45° cover the whole screen.
        final t = progress * (margin + height * coverage + exitMargin);
        final startX = particle.initialX * (width + height) - height;
        x = startX + t * (1 + wind);
        y = -margin + t;
        dx = 1 + wind;
        dy = 1;
        break;

      case ParticleDirection.none:
        // Wander around the initial position
        usesProgress = false;
        final t = cycles * speed * 2 * pi + particle.animationOffset;
        final amplitude = drift ?? 12;
        x = particle.initialX * width + amplitude * sin(t * 0.5);
        y = particle.initialY * height + amplitude * cos(t * 0.37 + phase);
        dx = cos(t * 0.5);
        dy = -sin(t * 0.37 + phase);
        break;

      case ParticleDirection.radial:
        // Accelerate outward from the center and grow, like a starfield
        final angle = particle.initialX * 2 * pi;
        final reach =
            sqrt(width * width + height * height) / 2 * coverage + exitMargin;
        final r = progress * progress * reach;
        dx = cos(angle);
        dy = sin(angle);
        x = width / 2 + dx * r;
        y = height / 2 + dy * r;
        sizeFactor = 0.2 + 0.8 * progress;
        fadeIn = max(fadeIn, 0.1);
        break;
    }

    // Push or pull particles near the pointer
    final pointer = this.pointer;
    final interaction = this.interaction;
    if (pointer != null &&
        interaction != null &&
        interaction.mode != ParticleInteractionMode.none) {
      final offsetX = x - pointer.dx;
      final offsetY = y - pointer.dy;
      final distance = sqrt(offsetX * offsetX + offsetY * offsetY);
      if (distance > 0 && distance < interaction.radius) {
        final falloff = 1 - distance / interaction.radius;
        final push = interaction.strength * falloff * falloff;
        if (interaction.mode == ParticleInteractionMode.repel) {
          x += offsetX / distance * push;
          y += offsetY / distance * push;
        } else {
          final pull = min(push, distance);
          x -= offsetX / distance * pull;
          y -= offsetY / distance * pull;
        }
      }
    }

    double opacity = _twinkle(particle, cycles, phase);
    if (usesProgress) {
      final fadeOut = max(config.edgeFade, coverage < 1.0 ? 0.2 : 0.0);
      if (fadeIn > 0 && progress < fadeIn) {
        opacity *= progress / fadeIn;
      }
      if (fadeOut > 0 && progress > 1 - fadeOut) {
        opacity *= (1 - progress) / fadeOut;
      }
    }
    if (opacity <= 0) return false;

    double rotation = 0;
    if (config.particleType == ParticleType.streak) {
      rotation = atan2(-dx, dy);
    } else if (config.enableRotation) {
      rotation =
          cycles * 2 * pi * particle.rotationSpeed * config.rotationSpeed +
          particle.animationOffset;
    }

    _write(
      index,
      sprite,
      x,
      y,
      rotation,
      spriteScale * sizeFactor,
      particle.color,
      opacity,
    );
    return true;
  }

  /// Writes the atlas entry for a burst particle. Returns false if the
  /// particle is invisible and was skipped.
  bool _writeBurst(int index, BurstParticle particle, ParticleSprite sprite) {
    final lifeFraction = particle.age / particle.life;
    // Fade out over the last 30% of the particle's life
    final fade = lifeFraction > 0.7 ? (1 - lifeFraction) / 0.3 : 1.0;
    final opacity = config.maxOpacity * fade;
    if (opacity <= 0) return false;

    double rotation = 0;
    if (config.particleType == ParticleType.streak) {
      rotation = atan2(-particle.vx, particle.vy);
    } else if (config.enableRotation) {
      rotation = particle.rotation;
    }

    _write(
      index,
      sprite,
      particle.x,
      particle.y,
      rotation,
      particle.size / sprite.contentExtent,
      particle.color,
      opacity,
    );
    return true;
  }

  /// Twinkling opacity between [ParticleConfig.minOpacity] and
  /// [ParticleConfig.maxOpacity].
  double _twinkle(ParticleData particle, double cycles, double phase) {
    final config = this.config;
    if (!config.enableOpacityAnimation) return config.maxOpacity;
    final wave =
        0.5 + 0.5 * sin((cycles + phase) * 4 * pi + particle.animationOffset);
    return config.minOpacity + (config.maxOpacity - config.minOpacity) * wave;
  }

  void _write(
    int index,
    ParticleSprite sprite,
    double x,
    double y,
    double rotation,
    double scale,
    Color color,
    double opacity,
  ) {
    final scos = cos(rotation) * scale;
    final ssin = sin(rotation) * scale;
    final i = index * 4;
    // Same layout as RSTransform.fromComponents, anchored at the sprite center
    _transforms[i] = scos;
    _transforms[i + 1] = ssin;
    _transforms[i + 2] = x - scos * sprite.anchorX + ssin * sprite.anchorY;
    _transforms[i + 3] = y - ssin * sprite.anchorX - scos * sprite.anchorY;

    final alpha = (color.a * opacity.clamp(0.0, 1.0) * 255).round();
    _colors[index] = (alpha << 24) | (color.toARGB32() & 0x00FFFFFF);
  }

  static double _wrap(double value, double low, double high) {
    final range = high - low;
    if (range <= 0) return value;
    return (value - low) % range + low;
  }
}

/// Paints a [ParticleSystem], repainting whenever it notifies.
class ParticlePainter extends CustomPainter {
  /// Creates a painter for [system].
  ParticlePainter(this.system) : super(repaint: system);

  /// The system being painted.
  final ParticleSystem system;

  @override
  void paint(Canvas canvas, Size size) => system.paint(canvas, size);

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) =>
      !identical(oldDelegate.system, system);
}
