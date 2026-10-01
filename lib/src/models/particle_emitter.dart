import 'dart:math';

import 'package:flutter/widgets.dart';

import 'json_utils.dart';

/// Continuously spawns particles from a point, line or area, e.g. smoke from
/// a chimney, a fountain, sparks from a widget, or a fireworks show.
///
/// Emitted particles use the shapes, colors and sizes of the effect's
/// `ParticleConfig` and move with simple physics.
@immutable
class ParticleEmitter {
  /// Where particles are emitted, relative to the particle area. Ignored
  /// when [position] or [followKey] is set.
  final Alignment alignment;

  /// Emission point in local coordinates; overrides [alignment].
  final Offset? position;

  /// Emit from the widget with this key, following it as it moves. The
  /// emission area is the widget's bounds unless [extent] is set.
  final GlobalKey? followKey;

  /// Size of the emission area centered on the emission point. Use a zero
  /// height for a line, or [Size.zero] for a single point.
  final Size extent;

  /// Particles (or firework shells) emitted per second.
  final double rate;

  /// Center direction of emission in radians (0 = right, -pi/2 = up).
  final double angle;

  /// Width in radians of the cone particles are emitted in.
  final double spread;

  /// Minimum launch speed in logical pixels per second.
  final double minSpeed;

  /// Maximum launch speed in logical pixels per second.
  final double maxSpeed;

  /// Downward acceleration in logical pixels per second squared; negative
  /// values make particles float up.
  final double gravity;

  /// Fraction of speed lost per second to air resistance.
  final double drag;

  /// Maximum time an emitted particle stays alive.
  final Duration lifespan;

  /// Whether each emission is a firework shell that rises from the emitter
  /// and explodes into [sparkCount] sparks.
  final bool fireworks;

  /// Number of sparks per firework shell.
  final int sparkCount;

  /// Creates an emitter.
  const ParticleEmitter({
    this.alignment = Alignment.bottomCenter,
    this.position,
    this.followKey,
    this.extent = Size.zero,
    this.rate = 20,
    this.angle = -pi / 2,
    this.spread = pi / 6,
    this.minSpeed = 100,
    this.maxSpeed = 250,
    this.gravity = 0,
    this.drag = 0.2,
    this.lifespan = const Duration(seconds: 3),
    this.fireworks = false,
    this.sparkCount = 60,
  }) : assert(rate >= 0),
       assert(minSpeed >= 0 && maxSpeed >= minSpeed),
       assert(drag >= 0),
       assert(sparkCount >= 0);

  /// A fountain shooting up from the bottom center and falling back down.
  static const ParticleEmitter fountain = ParticleEmitter(
    rate: 60,
    spread: pi / 8,
    minSpeed: 350,
    maxSpeed: 550,
    gravity: 500,
    lifespan: Duration(seconds: 2),
  );

  /// Smoke rising slowly from the bottom center; pair it with
  /// `ParticleLifecycle.growAndFade`.
  static const ParticleEmitter smoke = ParticleEmitter(
    rate: 12,
    spread: pi / 5,
    minSpeed: 30,
    maxSpeed: 70,
    gravity: -10,
    drag: 0.1,
    lifespan: Duration(seconds: 4),
  );

  /// Firework shells launched from along the bottom edge.
  static const ParticleEmitter fireworksShow = ParticleEmitter(
    extent: Size(10000, 0),
    rate: 0.7,
    fireworks: true,
  );

  /// Converts this emitter to JSON. [followKey] is not included.
  Map<String, Object?> toJson() => {
    'alignment': pairToJson(alignment.x, alignment.y),
    if (position != null) 'position': pairToJson(position!.dx, position!.dy),
    'extent': pairToJson(extent.width, extent.height),
    'rate': rate,
    'angle': angle,
    'spread': spread,
    'minSpeed': minSpeed,
    'maxSpeed': maxSpeed,
    'gravity': gravity,
    'drag': drag,
    'lifespanMs': lifespan.inMilliseconds,
    'fireworks': fireworks,
    'sparkCount': sparkCount,
  };

  /// Creates an emitter from [toJson] output.
  factory ParticleEmitter.fromJson(Map<String, Object?> json) {
    final alignment = readPair(json['alignment']);
    final position = readPair(json['position']);
    final extent = readPair(json['extent']);
    final minSpeed = readDoubleIn(json['minSpeed'], 0) ?? 100;
    return ParticleEmitter(
      alignment: alignment == null
          ? Alignment.bottomCenter
          : Alignment(alignment.$1, alignment.$2),
      position: position == null ? null : Offset(position.$1, position.$2),
      extent: extent == null
          ? Size.zero
          : Size(max(0, extent.$1), max(0, extent.$2)),
      rate: readDoubleIn(json['rate'], 0) ?? 20,
      angle: readDouble(json['angle']) ?? -pi / 2,
      spread: readDouble(json['spread']) ?? pi / 6,
      minSpeed: minSpeed,
      maxSpeed: readDoubleIn(json['maxSpeed'], minSpeed) ?? max(minSpeed, 250),
      gravity: readDouble(json['gravity']) ?? 0,
      drag: readDoubleIn(json['drag'], 0) ?? 0.2,
      lifespan: readMs(json['lifespanMs']) ?? const Duration(seconds: 3),
      fireworks: readBool(json['fireworks']) ?? false,
      sparkCount: readCount(json['sparkCount']) ?? 60,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleEmitter &&
          alignment == other.alignment &&
          position == other.position &&
          followKey == other.followKey &&
          extent == other.extent &&
          rate == other.rate &&
          angle == other.angle &&
          spread == other.spread &&
          minSpeed == other.minSpeed &&
          maxSpeed == other.maxSpeed &&
          gravity == other.gravity &&
          drag == other.drag &&
          lifespan == other.lifespan &&
          fireworks == other.fireworks &&
          sparkCount == other.sparkCount;

  @override
  int get hashCode => Object.hash(
    alignment,
    position,
    followKey,
    extent,
    rate,
    angle,
    spread,
    minSpeed,
    maxSpeed,
    gravity,
    drag,
    lifespan,
    fireworks,
    sparkCount,
  );
}
