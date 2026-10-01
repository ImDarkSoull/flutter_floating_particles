import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../models/direction.dart';
import '../models/particle_behaviors.dart';
import '../models/particle_collision.dart';
import '../models/particle_config.dart';
import '../models/particle_data.dart';
import '../models/particle_emitter.dart';
import '../models/particle_interaction.dart';
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

/// A request to launch firework shells from the bottom edge.
@immutable
class FireworksRequest {
  /// Creates a fireworks request.
  const FireworksRequest({this.shells = 3, this.sparkCount = 70});

  /// Number of shells to launch.
  final int shells;

  /// Sparks per shell.
  final int sparkCount;
}

/// What a [PhysicsParticle] is.
enum PhysicsKind {
  /// A burst, emitted, splash or pop particle.
  normal,

  /// A firework shell that explodes into sparks when its life ends.
  shell,

  /// A firework spark.
  spark,

  /// A particle resting on a collider.
  settled,
}

/// A particle moved by simple physics: bursts, emitters, fireworks, splashes
/// and particles resting on colliders.
class PhysicsParticle {
  /// Creates a physics particle.
  PhysicsParticle({
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
    required this.sprite,
    this.kind = PhysicsKind.normal,
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

  /// Seconds since the particle was created.
  double age = 0;

  /// Lifespan in seconds.
  double life;

  /// What kind of particle this is.
  PhysicsKind kind;

  /// Size in logical pixels.
  final double size;

  /// Particle color.
  final Color color;

  /// Rotation speed in radians per second.
  final double spin;

  /// Downward acceleration in logical pixels per second squared.
  final double gravity;

  /// Fraction of speed lost per second.
  final double drag;

  /// Index of the sprite in the atlas.
  final int sprite;

  /// Ghost copies drawn behind the particle; -1 uses the config's trail.
  int trailLength = -1;

  /// Seconds between ghost copies; -1 uses the config's trail.
  double trailSpacing = -1;

  /// Sparks a shell explodes into.
  int sparkCount = 0;

  /// Collider a settled particle rests on.
  int collider = -1;

  /// Position of a settled particle relative to its collider's top left.
  double relX = 0;

  /// Position of a settled particle relative to its collider's top left.
  double relY = 0;
}

/// Animation state and rendering for one particle effect.
///
/// The owning widget advances time with [advance]; every change notifies
/// listeners, which repaints [ParticlePainter] without rebuilding widgets.
class ParticleSystem extends ChangeNotifier {
  /// Creates a particle system for [config].
  ParticleSystem({required this.config}) : _random = Random(config.seed);

  /// Default maximum number of live physics particles.
  static const int maxBurstParticles = 5000;

  /// The configuration being animated.
  ParticleConfig config;

  /// The sprites particles are drawn with; nothing is drawn while null.
  ParticleAtlas? atlas;

  /// Atlas regions (e.g. streaks) that point along their motion instead of
  /// spinning, even when mixed with other particle types.
  Set<int> alignedSprites = const {};

  /// Pointer interaction, if enabled.
  ParticleInteraction? interaction;

  /// Current pointer position in local coordinates, if any.
  Offset? pointer;

  /// Parallax offset; particles shift by it times the config's
  /// `parallaxFactor`.
  Offset parallax = Offset.zero;

  /// Fraction (0.0 to 1.0) of the continuous particles that are drawn,
  /// lowered by adaptive quality on slow devices.
  double qualityFactor = 1.0;

  /// Collider bounds in local coordinates.
  List<Rect> colliderRects = const [];

  /// How particles react to colliders.
  ParticleCollision collision = const ParticleCollision();

  /// Bounds of each emitter's `followKey` widget (null when unresolved), in
  /// the order of the config's emitters.
  List<Rect?> emitterRects = const [];

  /// Animation time in seconds.
  double seconds = 0;

  List<ParticleData> _particles = const [];

  /// Position along the path at the previous frame, to detect wrapping.
  Float64List _lastProgress = Float64List(0);

  /// Whether a continuous particle is hidden until it wraps around (after
  /// being popped or landing on a collider).
  Uint8List _hidden = Uint8List(0);

  /// When a hidden particle that never wraps (e.g. wandering in place)
  /// reappears, in [seconds].
  Float64List _hiddenUntil = Float64List(0);

  final List<PhysicsParticle> _physics = [];
  final List<Object> _pending = [];
  final Random _random;
  List<double> _emitterCarry = const [];
  Size _size = Size.zero;

  final Paint _paint = Paint()
    // Bilinear, without mipmaps: sprites made with toImageSync have no
    // valid mipmaps on some backends (e.g. Impeller on OpenGL ES), and
    // sampling them draws stray lines and square outlines around particles.
    ..filterQuality = FilterQuality.low;
  Float32List _transforms = Float32List(0);
  Float32List _rects = Float32List(0);
  Int32List _colors = Int32List(0);

  // Particles drawn in the current frame, for tap hit testing and
  // connections
  int _hitCount = 0;
  Float32List _hitX = Float32List(0);
  Float32List _hitY = Float32List(0);
  Float32List _hitRadius = Float32List(0);
  Float32List _hitOpacity = Float32List(0);
  Int32List _hitId = Int32List(0);
  Int32List _hitColor = Int32List(0);
  Int32List _hitSprite = Int32List(0);

  final List<Float32List> _lineBuffers = List.generate(
    4,
    (_) => Float32List(0),
  );
  final List<int> _lineCounts = List.filled(4, 0);
  final Paint _linePaint = Paint()..strokeCap = StrokeCap.round;

  // Output of _sample()
  double _sx = 0, _sy = 0, _sdx = 0, _sdy = 1;
  double _sProgress = 0, _sSizeFactor = 1, _sFade = 1;
  bool _sUsesProgress = true;

  /// The continuously animated particles.
  List<ParticleData> get particles => _particles;

  set particles(List<ParticleData> value) {
    _particles = value;
    _lastProgress = Float64List(value.length)
      ..fillRange(0, value.length, double.nan);
    _hidden = Uint8List(value.length);
    _hiddenUntil = Float64List(value.length);
  }

  /// The size of the particle area at the last paint.
  Size get size => _size;

  /// Whether any physics particles are alive or waiting to be emitted.
  bool get hasBursts => _physics.isNotEmpty || _pending.isNotEmpty;

  /// Whether the config has emitters, which need continuous animation.
  bool get hasEmitters => config.emitters?.isNotEmpty ?? false;

  /// Number of live physics particles (bursts, emitted, fireworks...).
  int get burstParticleCount => _physics.length;

  /// Animation time in cycles of [ParticleConfig.animationDuration].
  double get cycles {
    final durationMs = config.animationDuration.inMilliseconds;
    return durationMs > 0 ? seconds * 1000 / durationMs : 0;
  }

  int get _ambientLimit {
    int limit = (_particles.length * qualityFactor).ceil();
    final maxParticles = config.maxParticles;
    if (maxParticles != null) limit = min(limit, maxParticles);
    return min(limit, _particles.length);
  }

  int get _physicsCap {
    final maxParticles = config.maxParticles;
    if (maxParticles == null) return maxBurstParticles;
    return max(0, maxParticles - _ambientLimit);
  }

  bool get _canSpawn => _physics.length < _physicsCap;

  /// Advances the animation by [dt] seconds and repaints.
  void advance(double dt) {
    seconds += dt;
    _spawnPending();
    _emit(dt);
    _updatePhysics(dt);
    notifyListeners();
  }

  /// Queues a burst; it is emitted as soon as the particle area has a size.
  void addBurst(BurstRequest request) {
    _pending.add(request);
    notifyListeners();
  }

  /// Queues firework shells.
  void addFireworks(FireworksRequest request) {
    _pending.add(request);
    notifyListeners();
  }

  /// Emits [count] slow particles at [position], e.g. while dragging.
  void emitAt(Offset position, int count) {
    for (int i = 0; i < count && _canSpawn; i++) {
      _physics.add(
        _make(
          x: position.dx + (_random.nextDouble() - 0.5) * 6,
          y: position.dy + (_random.nextDouble() - 0.5) * 6,
          vx: (_random.nextDouble() - 0.5) * 80,
          vy: (_random.nextDouble() - 0.5) * 80 - 20,
          life: 0.6 + _random.nextDouble() * 0.6,
          gravity: 40,
          drag: 1.5,
        ),
      );
    }
    notifyListeners();
  }

  /// Removes all physics particles.
  void clearBursts() {
    _physics.clear();
    _pending.clear();
    notifyListeners();
  }

  /// Restarts the animation from the beginning.
  void reset() {
    seconds = 0;
    _physics.clear();
    _pending.clear();
    _hidden.fillRange(0, _hidden.length, 0);
    _lastProgress.fillRange(0, _lastProgress.length, double.nan);
    _emitterCarry = const [];
    notifyListeners();
  }

  /// Hides a continuous particle until it wraps around, or for one cycle
  /// if it never wraps.
  void _hide(int index) {
    _hidden[index] = 1;
    final durationSeconds = config.animationDuration.inMicroseconds / 1e6;
    _hiddenUntil[index] = seconds + max(durationSeconds, 1.0);
  }

  /// Repaints without advancing time.
  void markNeedsPaint() => notifyListeners();

  /// The particle drawn at [position] in the last frame, if any.
  ParticleTapDetails? particleAt(Offset position) {
    final index = _hitIndexAt(position);
    return index < 0 ? null : _detailsFor(index);
  }

  /// Pops the particle at [position] with a small burst and returns it, or
  /// returns null if there is no particle there.
  ParticleTapDetails? popAt(Offset position) {
    final index = _hitIndexAt(position);
    if (index < 0) return null;
    final details = _detailsFor(index);

    final id = _hitId[index];
    if (id >= 0) {
      _hide(id);
    } else if (-1 - id < _physics.length) {
      final particle = _physics[-1 - id];
      // A popped firework shell explodes right away
      particle.age = particle.life;
    }

    for (int i = 0; i < 10 && _canSpawn; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 60 + _random.nextDouble() * 140;
      _physics.add(
        _make(
          x: details.position.dx,
          y: details.position.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          life: 0.5 + _random.nextDouble() * 0.3,
          gravity: 250,
          drag: 1,
          size: max(1.5, details.size * 0.35),
          color: details.color,
          sprite: _hitSprite[index],
        ),
      );
    }
    notifyListeners();
    return details;
  }

  int _hitIndexAt(Offset position) {
    int best = -1;
    double bestDistance = double.infinity;
    for (int i = 0; i < _hitCount; i++) {
      final dx = _hitX[i] - position.dx;
      final dy = _hitY[i] - position.dy;
      final distance = sqrt(dx * dx + dy * dy);
      // Some slop so small particles are still easy to hit
      if (distance <= _hitRadius[i] + 14 && distance < bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    return best;
  }

  ParticleTapDetails _detailsFor(int index) => ParticleTapDetails(
    position: Offset(_hitX[index], _hitY[index]),
    color: Color(_hitColor[index]),
    size: _hitRadius[index] * 2,
    isBurstParticle: _hitId[index] < 0,
  );

  PhysicsParticle _make({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required double life,
    required double gravity,
    required double drag,
    PhysicsKind kind = PhysicsKind.normal,
    double? size,
    Color? color,
    int? sprite,
  }) {
    final config = this.config;
    return PhysicsParticle(
      x: x,
      y: y,
      vx: vx,
      vy: vy,
      size:
          size ??
          (config.enableSizeVariation
              ? config.minSize +
                    _random.nextDouble() * (config.maxSize - config.minSize)
              : config.maxSize),
      color: color ?? ParticleData.pickColor(config, _random),
      rotation: _random.nextDouble() * 2 * pi,
      spin: (_random.nextDouble() - 0.5) * 4 * pi * config.rotationSpeed,
      life: life,
      gravity: gravity,
      drag: drag,
      sprite: sprite ?? atlas?.indexFor(_random.nextDouble()) ?? 0,
      kind: kind,
    );
  }

  void _spawnPending() {
    if (_pending.isEmpty || _size.isEmpty) return;
    for (final request in _pending) {
      if (request is BurstRequest) {
        _spawnBurst(request);
      } else if (request is FireworksRequest) {
        for (int i = 0; i < request.shells; i++) {
          _spawnShell(
            _size.width * (0.15 + 0.7 * _random.nextDouble()),
            _size.height + 10,
            request.sparkCount,
          );
        }
      }
    }
    _pending.clear();
  }

  void _spawnBurst(BurstRequest request) {
    final origin = request.position ?? request.alignment.alongSize(_size);
    final lifespan = request.lifespan.inMicroseconds / 1e6;
    if (lifespan <= 0) return;

    for (int i = 0; i < request.count && _canSpawn; i++) {
      final angle =
          request.angle + (_random.nextDouble() - 0.5) * request.spread;
      final speed =
          request.minSpeed +
          _random.nextDouble() * (request.maxSpeed - request.minSpeed);
      _physics.add(
        _make(
          x: origin.dx,
          y: origin.dy,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed,
          life: lifespan * (0.7 + 0.3 * _random.nextDouble()),
          gravity: request.gravity,
          drag: request.drag,
        ),
      );
    }
  }

  void _spawnShell(double x, double startY, int sparkCount) {
    if (!_canSpawn) return;
    const gravity = 250.0;
    // Explode somewhere in the upper part of the area, above the start
    final targetY = min(
      _size.height * (0.12 + 0.3 * _random.nextDouble()),
      startY - 60,
    );
    final speed = sqrt(2 * gravity * max(1.0, startY - targetY));
    final shell = _make(
      x: x,
      y: startY,
      vx: (_random.nextDouble() - 0.5) * 40,
      vy: -speed,
      life: speed / gravity,
      gravity: gravity,
      drag: 0,
      kind: PhysicsKind.shell,
      size: config.maxSize * 1.1,
    );
    shell
      ..sparkCount = sparkCount
      ..trailLength = 10
      ..trailSpacing = 0.018;
    _physics.add(shell);
  }

  void _explode(PhysicsParticle shell) {
    for (int i = 0; i < shell.sparkCount && _canSpawn; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      // sqrt spreads sparks evenly over a disc instead of bunching them
      final speed = 20 + 230 * sqrt(_random.nextDouble());
      final spark = _make(
        x: shell.x,
        y: shell.y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        life: 1.1 + _random.nextDouble() * 0.8,
        gravity: 90,
        drag: 1.1,
        kind: PhysicsKind.spark,
        color: _random.nextDouble() < 0.2
            ? const Color(0xFFFFFFFF)
            : shell.color,
        sprite: shell.sprite,
      );
      spark
        ..trailLength = 4
        ..trailSpacing = 0.035;
      _physics.add(spark);
    }
  }

  void _emit(double dt) {
    final emitters = config.emitters;
    if (emitters == null || emitters.isEmpty || _size.isEmpty) return;
    if (_emitterCarry.length != emitters.length) {
      _emitterCarry = List.filled(emitters.length, 0.0);
    }

    for (int i = 0; i < emitters.length; i++) {
      final emitter = emitters[i];
      final area = _emitterArea(emitter, i);
      if (area == null) continue;

      _emitterCarry[i] += emitter.rate * dt;
      final whole = _emitterCarry[i].floor();
      _emitterCarry[i] -= whole;
      // Cap per frame so a long pause doesn't release a flood
      final count = min(whole, 200);

      for (int j = 0; j < count && _canSpawn; j++) {
        final x = area.left + _random.nextDouble() * area.width;
        final y = area.top + _random.nextDouble() * area.height;
        if (emitter.fireworks) {
          _spawnShell(x, y, emitter.sparkCount);
          continue;
        }
        final angle =
            emitter.angle + (_random.nextDouble() - 0.5) * emitter.spread;
        final speed =
            emitter.minSpeed +
            _random.nextDouble() * (emitter.maxSpeed - emitter.minSpeed);
        final lifespan = emitter.lifespan.inMicroseconds / 1e6;
        _physics.add(
          _make(
            x: x,
            y: y,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            life: lifespan * (0.7 + 0.3 * _random.nextDouble()),
            gravity: emitter.gravity,
            drag: emitter.drag,
          ),
        );
      }
    }
  }

  Rect? _emitterArea(ParticleEmitter emitter, int index) {
    if (emitter.followKey != null) {
      final rect = index < emitterRects.length ? emitterRects[index] : null;
      if (rect == null) return null;
      if (emitter.extent == Size.zero) return rect;
      return Rect.fromCenter(
        center: rect.center,
        width: emitter.extent.width,
        height: emitter.extent.height,
      );
    }
    final center = emitter.position ?? emitter.alignment.alongSize(_size);
    return Rect.fromCenter(
      center: center,
      width: min(emitter.extent.width, _size.width * 0.8),
      height: min(emitter.extent.height, _size.height),
    );
  }

  void _updatePhysics(double dt) {
    if (_physics.isEmpty) return;
    final rects = colliderRects;
    List<PhysicsParticle>? exploded;

    for (final p in _physics) {
      p.age += dt;
      if (p.kind == PhysicsKind.settled) {
        // Stay on the collider as it moves (e.g. while scrolling)
        if (p.collider < rects.length) {
          final rect = rects[p.collider];
          p.x = rect.left + p.relX;
          p.y = rect.top + p.relY;
        }
        continue;
      }

      p.vy += p.gravity * dt;
      final damping = max(0.0, 1 - p.drag * dt);
      p.vx *= damping;
      p.vy *= damping;
      final previousX = p.x;
      final previousY = p.y;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.rotation += p.spin * dt;

      if (rects.isNotEmpty && p.kind == PhysicsKind.normal) {
        _bounce(p, previousX, previousY, rects);
      }
      if (p.kind == PhysicsKind.shell && p.age >= p.life) {
        (exploded ??= []).add(p);
      }
    }

    _physics.removeWhere((p) => p.age >= p.life);
    if (exploded != null) {
      for (final shell in exploded) {
        _explode(shell);
      }
    }
  }

  void _bounce(
    PhysicsParticle p,
    double previousX,
    double previousY,
    List<Rect> rects,
  ) {
    final restitution = collision.restitution;
    for (int i = 0; i < rects.length; i++) {
      final rect = rects[i];
      if (!rect.contains(Offset(p.x, p.y))) continue;

      if (previousY <= rect.top) {
        p.y = rect.top;
        p.vy = -p.vy * restitution;
        p.vx *= 0.85;
        if (collision.settle && p.vy.abs() < 40) {
          _settle(p, i, rect);
        }
      } else if (previousY >= rect.bottom) {
        p.y = rect.bottom;
        p.vy = -p.vy * restitution;
      } else if (previousX <= rect.left) {
        p.x = rect.left;
        p.vx = -p.vx * restitution;
      } else {
        p.x = rect.right;
        p.vx = -p.vx * restitution;
      }
      return;
    }
  }

  void _settle(PhysicsParticle p, int collider, Rect rect) {
    _makeRoomOn(collider);
    p
      ..kind = PhysicsKind.settled
      ..collider = collider
      ..relX = p.x - rect.left
      ..relY = -p.size * 0.3
      ..vx = 0
      ..vy = 0
      ..age = 0
      ..life = collision.settleDuration.inMicroseconds / 1e6;
  }

  void _spawnSettled(
    double x,
    Rect rect,
    int collider,
    double size,
    Color color,
    int sprite,
  ) {
    if (!_canSpawn) return;
    _makeRoomOn(collider);
    final particle = PhysicsParticle(
      x: x,
      y: rect.top - size * 0.3,
      vx: 0,
      vy: 0,
      size: size,
      color: color,
      rotation: _random.nextDouble() * 2 * pi,
      spin: 0,
      life: collision.settleDuration.inMicroseconds / 1e6,
      gravity: 0,
      drag: 0,
      sprite: sprite,
      kind: PhysicsKind.settled,
    );
    particle
      ..collider = collider
      ..relX = x - rect.left
      ..relY = -size * 0.3;
    _physics.add(particle);
  }

  /// Melts the oldest particle on [collider] if it is full.
  void _makeRoomOn(int collider) {
    int count = 0;
    int oldest = -1;
    for (int i = 0; i < _physics.length; i++) {
      final p = _physics[i];
      if (p.kind != PhysicsKind.settled || p.collider != collider) continue;
      count++;
      if (oldest < 0) oldest = i;
    }
    if (count >= collision.maxSettled && oldest >= 0) {
      _physics.removeAt(oldest);
    }
  }

  void _splashAt(ParticleData particle, double cycles, Size size) {
    final splash = config.splash;
    final atlas = this.atlas;
    if (splash == null || atlas == null) return;
    final direction = config.direction;
    if (direction != ParticleDirection.topToBottom &&
        direction != ParticleDirection.diagonal) {
      return;
    }

    // Where the particle left its path
    _sample(particle, cycles, size, 1.0);
    final x = _sx;
    final y = min(_sy, size.height - 1);
    final lifespan = splash.lifespan.inMicroseconds / 1e6;
    for (int i = 0; i < splash.count && _canSpawn; i++) {
      final speed =
          splash.minSpeed +
          _random.nextDouble() * (splash.maxSpeed - splash.minSpeed);
      _physics.add(
        _make(
          x: x,
          y: y,
          vx: (_random.nextDouble() - 0.5) * speed * 1.2,
          vy: -speed,
          life: lifespan * (0.7 + 0.3 * _random.nextDouble()),
          gravity: 900,
          drag: 0.5,
          size: splash.size,
          color: splash.color ?? particle.color,
          sprite: atlas.circleIndex,
        ),
      );
    }
  }

  /// Draws all particles into [canvas].
  void paint(Canvas canvas, Size size) {
    _size = size;
    _spawnPending();

    final atlas = this.atlas;
    if (atlas == null) return;

    final ambientLimit = _ambientLimit;
    final ambientTrail = config.trail?.length ?? 0;
    int capacity = ambientLimit * (1 + ambientTrail);
    for (final p in _physics) {
      capacity += 1 + _trailLengthOf(p);
    }
    _ensureCapacity(capacity);
    _ensureHitCapacity(ambientLimit + _physics.length);
    _hitCount = 0;

    final cycles = this.cycles;
    int count = 0;
    for (int i = 0; i < ambientLimit; i++) {
      count = _paintAmbient(i, count, size, cycles, atlas);
    }
    // Splashes and landings above may have added physics particles
    _ensureCapacity(count + _physics.length * (1 + _maxPhysicsTrail()));
    _ensureHitCapacity(_hitCount + _physics.length);
    for (int i = 0; i < _physics.length; i++) {
      count = _paintPhysics(i, count, atlas);
    }

    final connections = config.connections;
    if (connections != null) _paintConnections(canvas, connections);

    if (count == 0) return;
    _paint.blendMode = config.blendMode;
    canvas.drawRawAtlas(
      atlas.image,
      Float32List.sublistView(_transforms, 0, count * 4),
      Float32List.sublistView(_rects, 0, count * 4),
      Int32List.sublistView(_colors, 0, count),
      BlendMode.modulate,
      null,
      _paint,
    );
  }

  int _maxPhysicsTrail() {
    int longest = config.trail?.length ?? 0;
    for (final p in _physics) {
      longest = max(longest, _trailLengthOf(p));
    }
    return longest;
  }

  int _trailLengthOf(PhysicsParticle p) {
    if (p.kind == PhysicsKind.settled) return 0;
    return p.trailLength >= 0 ? p.trailLength : (config.trail?.length ?? 0);
  }

  void _ensureCapacity(int count) {
    if (_colors.length >= count) return;
    // Grow with headroom so bursts don't reallocate every frame
    final capacity = max(count, _colors.length * 2);
    final transforms = Float32List(capacity * 4);
    final rects = Float32List(capacity * 4);
    final colors = Int32List(capacity);
    // Keep entries already written this frame
    transforms.setRange(0, _transforms.length, _transforms);
    rects.setRange(0, _rects.length, _rects);
    colors.setRange(0, _colors.length, _colors);
    _transforms = transforms;
    _rects = rects;
    _colors = colors;
  }

  void _ensureHitCapacity(int count) {
    if (_hitId.length >= count) return;
    final capacity = max(count, _hitId.length * 2);
    Float32List growF(Float32List old) =>
        Float32List(capacity)..setRange(0, old.length, old);
    Int32List growI(Int32List old) =>
        Int32List(capacity)..setRange(0, old.length, old);
    _hitX = growF(_hitX);
    _hitY = growF(_hitY);
    _hitRadius = growF(_hitRadius);
    _hitOpacity = growF(_hitOpacity);
    _hitId = growI(_hitId);
    _hitColor = growI(_hitColor);
    _hitSprite = growI(_hitSprite);
  }

  /// Scales a property down for far particles when depth is enabled; [far]
  /// is the factor for the farthest particles.
  double _depthScale(ParticleData particle, double far) =>
      1 - config.depthEffect * (1 - far) * (1 - particle.depth);

  /// Computes where a continuous particle is at [cycles], writing the result
  /// to the `_s*` fields. [forcedProgress] evaluates a fixed position along
  /// the path instead.
  void _sample(
    ParticleData particle,
    double cycles,
    Size size,
    double? forcedProgress,
  ) {
    final config = this.config;
    final width = size.width;
    final height = size.height;

    // Phase offset as a fraction of a cycle
    final phase = particle.animationOffset / (2 * pi);
    final speed =
        particle.velocity *
        config.velocityMultiplier *
        _depthScale(particle, 0.4);
    // Position along the path, 0.0 (entering) to 1.0 (leaving)
    final progress = forcedProgress ?? (cycles * speed + phase) % 1.0;

    // Distance outside the edge where particles start and end, so they are
    // fully hidden when they wrap around
    final margin = particle.size * 1.2 + 2;
    final coverage = particle.screenOccupancy;
    final exitMargin = coverage >= 1.0 ? margin : 0.0;
    // Drift uses whole sine periods per path so it matches at the wrap
    final wave = progress * 2 * pi + particle.animationOffset;
    final wind = config.wind;
    final drift = config.driftAmplitude;

    double x, y;
    double dx, dy;
    double sizeFactor = 1.0;
    bool usesProgress = true;
    bool wrapX = wind != 0;
    bool wrapY = false;
    double fadeIn = config.edgeFade;

    switch (config.direction) {
      case ParticleDirection.topToBottom:
        final t = progress * (margin + height * coverage + exitMargin);
        x = particle.initialX * width + (drift ?? 30) * sin(wave) + wind * t;
        y = -margin + t;
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
        dx = wind;
        dy = -1;
        break;

      case ParticleDirection.leftToRight:
        final t = progress * (margin + width * coverage + exitMargin);
        x = -margin + t;
        y = particle.initialY * height + (drift ?? 15) * cos(wave) + wind * t;
        dx = 1;
        dy = wind;
        wrapX = false;
        wrapY = wind != 0;
        break;

      case ParticleDirection.rightToLeft:
        final t = progress * (margin + width * coverage + exitMargin);
        x = width + margin - t;
        y = particle.initialY * height + (drift ?? 15) * cos(wave) + wind * t;
        dx = -1;
        dy = wind;
        wrapX = false;
        wrapY = wind != 0;
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
        wrapX = false;
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
        wrapX = false;
        break;
    }

    // Shift with the parallax offset; near particles shift more
    final parallax = this.parallax;
    if (parallax != Offset.zero) {
      final factor = config.parallaxFactor * _depthScale(particle, 0.25);
      x -= parallax.dx * factor;
      y -= parallax.dy * factor;
      if (parallax.dx != 0) wrapX = true;
      if (parallax.dy != 0) wrapY = true;
    }
    if (wrapX) x = _wrap(x, -margin, width + margin);
    if (wrapY) y = _wrap(y, -margin, height + margin);

    double fade = 1.0;
    if (usesProgress) {
      final fadeOut = max(config.edgeFade, coverage < 1.0 ? 0.2 : 0.0);
      if (fadeIn > 0 && progress < fadeIn) fade *= progress / fadeIn;
      if (fadeOut > 0 && progress > 1 - fadeOut) {
        fade *= (1 - progress) / fadeOut;
      }
    }

    _sx = x;
    _sy = y;
    _sdx = dx;
    _sdy = dy;
    _sProgress = progress;
    _sSizeFactor = sizeFactor;
    _sFade = fade;
    _sUsesProgress = usesProgress;
  }

  int _paintAmbient(
    int index,
    int count,
    Size size,
    double cycles,
    ParticleAtlas atlas,
  ) {
    final particle = _particles[index];
    final config = this.config;

    _sample(particle, cycles, size, null);
    final progress = _sProgress;
    final last = _lastProgress[index];
    _lastProgress[index] = progress;
    if (_sUsesProgress && !last.isNaN && progress < last - 0.5) {
      // The particle reached the end of its path and started over
      if (_hidden[index] != 0) {
        _hidden[index] = 0;
      } else if (config.splash != null) {
        _splashAt(particle, cycles, size);
        _sample(particle, cycles, size, null);
      }
    }
    // Particles that never wrap come back after a cycle instead
    if (_hidden[index] != 0 &&
        !_sUsesProgress &&
        seconds >= _hiddenUntil[index]) {
      _hidden[index] = 0;
    }
    if (_hidden[index] != 0) return count;

    double x = _sx;
    double y = _sy;

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

    final regionIndex = atlas.indexFor(particle.variant);

    // Land on (or hide behind) colliders
    final rects = colliderRects;
    for (int i = 0; i < rects.length; i++) {
      final rect = rects[i];
      if (!rect.contains(Offset(x, y))) continue;
      _hide(index);
      if (collision.settle &&
          _sdy > 0 &&
          y - rect.top < max(particle.size * 2, 30)) {
        _spawnSettled(x, rect, i, particle.size, particle.color, regionIndex);
      }
      return count;
    }

    final lifecycle = config.lifecycle;
    final opacity =
        _twinkle(particle, cycles) *
        _sFade *
        _depthScale(particle, 0.35) *
        (lifecycle?.opacityAt(progress) ?? 1);
    if (opacity <= 0) return count;
    final scaleFactor = _sSizeFactor * (lifecycle?.scaleAt(progress) ?? 1);
    final color = lifecycle?.colorAt(progress) ?? particle.color;

    double rotation = 0;
    if (_alignsWithMotion(regionIndex)) {
      rotation = atan2(-_sdx, _sdy);
    } else if (config.enableRotation) {
      rotation =
          cycles * 2 * pi * particle.rotationSpeed * config.rotationSpeed +
          particle.animationOffset;
    }

    final region = atlas.regions[regionIndex];
    final particleSize = particle.size * scaleFactor;
    final scale = particleSize / region.contentExtent;
    _recordHit(x, y, particleSize / 2, opacity, index, color, regionIndex);
    _write(count++, region, x, y, rotation, scale, color, opacity);

    final trail = config.trail;
    final durationMs = config.animationDuration.inMilliseconds;
    if (trail != null && trail.length > 0 && durationMs > 0) {
      final spacingCycles = trail.spacing.inMicroseconds / 1000 / durationMs;
      for (int k = 1; k <= trail.length; k++) {
        _sample(particle, cycles - k * spacingCycles, size, null);
        // Stop at the start of the path, where the particle wrapped around
        if (_sUsesProgress && _sProgress > progress) break;
        final f = k / trail.length;
        _write(
          count++,
          region,
          _sx,
          _sy,
          rotation,
          scale * (1 + (trail.endScale - 1) * f),
          color,
          opacity * (1 + (trail.endOpacity - 1) * f),
        );
      }
    }
    return count;
  }

  /// Whether the sprite in [region] points along its motion.
  bool _alignsWithMotion(int region) => alignedSprites.contains(region);

  int _paintPhysics(int index, int count, ParticleAtlas atlas) {
    final p = _physics[index];
    final config = this.config;
    final t = (p.age / p.life).clamp(0.0, 1.0);

    // Fade out over the last 30% of the particle's life
    final fade = p.kind == PhysicsKind.shell
        ? 1.0
        : (t > 0.7 ? (1 - t) / 0.3 : 1.0);
    final lifecycle = p.kind == PhysicsKind.settled ? null : config.lifecycle;
    final opacity = config.maxOpacity * fade * (lifecycle?.opacityAt(t) ?? 1);
    if (opacity <= 0) return count;
    final scaleFactor = lifecycle?.scaleAt(t) ?? 1;
    final color = lifecycle?.colorAt(t) ?? p.color;

    final regionIndex = p.sprite.clamp(0, atlas.regions.length - 1);
    double rotation = 0;
    if (_alignsWithMotion(regionIndex)) {
      rotation = atan2(-p.vx, p.vy);
    } else if (config.enableRotation) {
      rotation = p.rotation;
    }

    final region = atlas.regions[regionIndex];
    final particleSize = p.size * scaleFactor;
    final scale = particleSize / region.contentExtent;
    _recordHit(
      p.x,
      p.y,
      particleSize / 2,
      opacity,
      -1 - index,
      color,
      regionIndex,
    );
    _write(count++, region, p.x, p.y, rotation, scale, color, opacity);

    final trailLength = _trailLengthOf(p);
    if (trailLength > 0) {
      final trail = config.trail ?? const ParticleTrail();
      final spacing = p.trailSpacing >= 0
          ? p.trailSpacing
          : trail.spacing.inMicroseconds / 1e6;
      for (int k = 1; k <= trailLength; k++) {
        final tau = k * spacing;
        // Where the particle was tau seconds ago
        final x = p.x - p.vx * tau;
        final y = p.y - p.vy * tau + 0.5 * p.gravity * tau * tau;
        final f = k / trailLength;
        _write(
          count++,
          region,
          x,
          y,
          rotation,
          scale * (1 + (trail.endScale - 1) * f),
          color,
          opacity * (1 + (trail.endOpacity - 1) * f),
        );
      }
    }
    return count;
  }

  void _recordHit(
    double x,
    double y,
    double radius,
    double opacity,
    int id,
    Color color,
    int sprite,
  ) {
    final i = _hitCount++;
    _hitX[i] = x;
    _hitY[i] = y;
    _hitRadius[i] = radius;
    _hitOpacity[i] = opacity;
    _hitId[i] = id;
    _hitColor[i] = color.toARGB32();
    _hitSprite[i] = sprite;
  }

  void _paintConnections(Canvas canvas, ParticleConnections connections) {
    final maxDistance = connections.maxDistance;
    final maxDistanceSquared = maxDistance * maxDistance;
    _lineCounts.fillRange(0, 4, 0);

    // Bucket continuous particles into a grid so only neighbors are compared
    final cells = <int, List<int>>{};
    int cellKey(int cx, int cy) => cx * 73856093 ^ cy * 19349663;
    for (int i = 0; i < _hitCount; i++) {
      if (_hitId[i] < 0) continue;
      final cx = (_hitX[i] / maxDistance).floor();
      final cy = (_hitY[i] / maxDistance).floor();
      (cells[cellKey(cx, cy)] ??= []).add(i);
    }

    for (int i = 0; i < _hitCount; i++) {
      if (_hitId[i] < 0) continue;
      final xi = _hitX[i];
      final yi = _hitY[i];
      final cx = (xi / maxDistance).floor();
      final cy = (yi / maxDistance).floor();
      for (int ox = -1; ox <= 1; ox++) {
        for (int oy = -1; oy <= 1; oy++) {
          final cell = cells[cellKey(cx + ox, cy + oy)];
          if (cell == null) continue;
          for (final j in cell) {
            if (j <= i) continue;
            final dx = _hitX[j] - xi;
            final dy = _hitY[j] - yi;
            final distanceSquared = dx * dx + dy * dy;
            if (distanceSquared >= maxDistanceSquared) continue;
            final strength =
                (1 - sqrt(distanceSquared) / maxDistance) *
                min(_hitOpacity[i], _hitOpacity[j]);
            _addLine(strength, xi, yi, _hitX[j], _hitY[j]);
          }
        }
      }
    }

    final pointer = this.pointer;
    if (connections.connectPointer && pointer != null) {
      final reach = maxDistance * 1.3;
      for (int i = 0; i < _hitCount; i++) {
        if (_hitId[i] < 0) continue;
        final dx = _hitX[i] - pointer.dx;
        final dy = _hitY[i] - pointer.dy;
        final distance = sqrt(dx * dx + dy * dy);
        if (distance >= reach) continue;
        _addLine(
          1 - distance / reach,
          pointer.dx,
          pointer.dy,
          _hitX[i],
          _hitY[i],
        );
      }
    }

    // Lines are drawn in four opacity buckets, one call each
    final color = connections.color;
    _linePaint.strokeWidth = connections.strokeWidth;
    for (int b = 0; b < 4; b++) {
      final lines = _lineCounts[b];
      if (lines == 0) continue;
      _linePaint.color = color.withValues(
        alpha: color.a * connections.maxOpacity * (b + 1) / 4,
      );
      canvas.drawRawPoints(
        ui.PointMode.lines,
        Float32List.sublistView(_lineBuffers[b], 0, lines * 4),
        _linePaint,
      );
    }
  }

  void _addLine(double strength, double x1, double y1, double x2, double y2) {
    if (strength <= 0.05) return;
    final bucket = (strength * 4).floor().clamp(0, 3);
    final lines = _lineCounts[bucket];
    var buffer = _lineBuffers[bucket];
    if (buffer.length < (lines + 1) * 4) {
      final grown = Float32List(max(64, buffer.length * 2));
      grown.setRange(0, lines * 4, buffer);
      buffer = _lineBuffers[bucket] = grown;
    }
    final i = lines * 4;
    buffer[i] = x1;
    buffer[i + 1] = y1;
    buffer[i + 2] = x2;
    buffer[i + 3] = y2;
    _lineCounts[bucket] = lines + 1;
  }

  /// Twinkling opacity between [ParticleConfig.minOpacity] and
  /// [ParticleConfig.maxOpacity].
  double _twinkle(ParticleData particle, double cycles) {
    final config = this.config;
    if (!config.enableOpacityAnimation) return config.maxOpacity;
    final phase = particle.animationOffset / (2 * pi);
    final wave =
        0.5 + 0.5 * sin((cycles + phase) * 4 * pi + particle.animationOffset);
    return config.minOpacity + (config.maxOpacity - config.minOpacity) * wave;
  }

  void _write(
    int index,
    SpriteRegion region,
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
    _transforms[i + 2] = x - scos * region.anchorX + ssin * region.anchorY;
    _transforms[i + 3] = y - ssin * region.anchorX - scos * region.anchorY;

    final rect = region.rect;
    _rects[i] = rect.left;
    _rects[i + 1] = rect.top;
    _rects[i + 2] = rect.right;
    _rects[i + 3] = rect.bottom;

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
