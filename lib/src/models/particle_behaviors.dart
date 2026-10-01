import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'json_utils.dart';

/// How particles change size, opacity and color over their life.
///
/// For continuously animated particles the life is one trip across the
/// screen; for bursts and emitted particles it is their lifespan.
@immutable
class ParticleLifecycle {
  /// Scale factor at the start of the particle's life.
  final double startScale;

  /// Scale factor at the end of the particle's life.
  final double endScale;

  /// Opacity multiplier at the start of the particle's life.
  final double startOpacity;

  /// Opacity multiplier at the end of the particle's life.
  final double endOpacity;

  /// Colors the particle passes through over its life, evenly spaced.
  /// Null keeps each particle's own color.
  final List<Color>? colors;

  /// Creates a lifecycle.
  const ParticleLifecycle({
    this.startScale = 1.0,
    this.endScale = 1.0,
    this.startOpacity = 1.0,
    this.endOpacity = 1.0,
    this.colors,
  }) : assert(startScale >= 0 && endScale >= 0),
       assert(startOpacity >= 0 && startOpacity <= 1),
       assert(endOpacity >= 0 && endOpacity <= 1);

  /// Particles shrink away to nothing.
  static const ParticleLifecycle shrink = ParticleLifecycle(endScale: 0);

  /// Particles grow and fade out, like smoke or bubbles.
  static const ParticleLifecycle growAndFade = ParticleLifecycle(
    startScale: 0.4,
    endScale: 1.6,
    endOpacity: 0,
  );

  /// Embers that burn from yellow through orange to a dark red.
  static const ParticleLifecycle ember = ParticleLifecycle(
    endScale: 0.3,
    colors: [Color(0xFFFFF59D), Color(0xFFFFA726), Color(0xFFD32F2F)],
  );

  /// Scale at [t] (0.0 to 1.0) through the particle's life.
  double scaleAt(double t) => startScale + (endScale - startScale) * t;

  /// Opacity multiplier at [t] (0.0 to 1.0) through the particle's life.
  double opacityAt(double t) => startOpacity + (endOpacity - startOpacity) * t;

  /// Color at [t] (0.0 to 1.0) through the particle's life, or null when
  /// [colors] is not set.
  Color? colorAt(double t) {
    final colors = this.colors;
    if (colors == null || colors.isEmpty) return null;
    if (colors.length == 1) return colors.first;
    final position = t.clamp(0.0, 1.0) * (colors.length - 1);
    final index = position.floor().clamp(0, colors.length - 2);
    return Color.lerp(colors[index], colors[index + 1], position - index);
  }

  /// Converts this lifecycle to JSON.
  Map<String, Object?> toJson() => {
    'startScale': startScale,
    'endScale': endScale,
    'startOpacity': startOpacity,
    'endOpacity': endOpacity,
    if (colors != null) 'colors': colors!.map(colorToJson).toList(),
  };

  /// Creates a lifecycle from [toJson] output.
  factory ParticleLifecycle.fromJson(Map<String, Object?> json) {
    return ParticleLifecycle(
      startScale: readDoubleIn(json['startScale'], 0) ?? 1.0,
      endScale: readDoubleIn(json['endScale'], 0) ?? 1.0,
      startOpacity: readDoubleIn(json['startOpacity'], 0, 1) ?? 1.0,
      endOpacity: readDoubleIn(json['endOpacity'], 0, 1) ?? 1.0,
      colors: readColors(json['colors']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleLifecycle &&
          startScale == other.startScale &&
          endScale == other.endScale &&
          startOpacity == other.startOpacity &&
          endOpacity == other.endOpacity &&
          listEqualsNullable(colors, other.colors);

  @override
  int get hashCode => Object.hash(
    startScale,
    endScale,
    startOpacity,
    endOpacity,
    colors == null ? null : Object.hashAll(colors!),
  );
}

/// A fading tail drawn behind each particle, for comets, sparks and magic.
@immutable
class ParticleTrail {
  /// Number of ghost copies drawn behind the particle.
  final int length;

  /// Time between ghost copies; longer spacing gives longer tails.
  final Duration spacing;

  /// Scale of the last ghost relative to the particle.
  final double endScale;

  /// Opacity of the last ghost relative to the particle.
  final double endOpacity;

  /// Creates a trail.
  const ParticleTrail({
    this.length = 6,
    this.spacing = const Duration(milliseconds: 25),
    this.endScale = 0.4,
    this.endOpacity = 0.0,
  }) : assert(length >= 0),
       assert(endScale >= 0),
       assert(endOpacity >= 0 && endOpacity <= 1);

  /// Converts this trail to JSON.
  Map<String, Object?> toJson() => {
    'length': length,
    'spacingMs': spacing.inMilliseconds,
    'endScale': endScale,
    'endOpacity': endOpacity,
  };

  /// Creates a trail from [toJson] output.
  factory ParticleTrail.fromJson(Map<String, Object?> json) {
    return ParticleTrail(
      length: readCount(json['length']) ?? 6,
      spacing: readMs(json['spacingMs']) ?? const Duration(milliseconds: 25),
      endScale: readDoubleIn(json['endScale'], 0) ?? 0.4,
      endOpacity: readDoubleIn(json['endOpacity'], 0, 1) ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleTrail &&
          length == other.length &&
          spacing == other.spacing &&
          endScale == other.endScale &&
          endOpacity == other.endOpacity;

  @override
  int get hashCode => Object.hash(length, spacing, endScale, endOpacity);
}

/// Small droplets that bounce up where a particle reaches the end of its
/// path, like rain splashing on the ground.
@immutable
class ParticleSplash {
  /// Number of droplets per splash.
  final int count;

  /// Droplet size in logical pixels.
  final double size;

  /// Minimum droplet speed in logical pixels per second.
  final double minSpeed;

  /// Maximum droplet speed in logical pixels per second.
  final double maxSpeed;

  /// How long droplets live.
  final Duration lifespan;

  /// Droplet color; null uses the particle's color.
  final Color? color;

  /// Creates a splash.
  const ParticleSplash({
    this.count = 4,
    this.size = 2.0,
    this.minSpeed = 60,
    this.maxSpeed = 160,
    this.lifespan = const Duration(milliseconds: 450),
    this.color,
  }) : assert(count >= 0),
       assert(size > 0),
       assert(minSpeed >= 0 && maxSpeed >= minSpeed);

  /// Converts this splash to JSON.
  Map<String, Object?> toJson() => {
    'count': count,
    'size': size,
    'minSpeed': minSpeed,
    'maxSpeed': maxSpeed,
    'lifespanMs': lifespan.inMilliseconds,
    if (color != null) 'color': colorToJson(color!),
  };

  /// Creates a splash from [toJson] output.
  factory ParticleSplash.fromJson(Map<String, Object?> json) {
    final minSpeed = readDoubleIn(json['minSpeed'], 0) ?? 60;
    return ParticleSplash(
      count: readCount(json['count']) ?? 4,
      size: readPositive(json['size']) ?? 2.0,
      minSpeed: minSpeed,
      maxSpeed: readDoubleIn(json['maxSpeed'], minSpeed) ?? max(minSpeed, 160),
      lifespan: readMs(json['lifespanMs']) ?? const Duration(milliseconds: 450),
      color: readColor(json['color']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleSplash &&
          count == other.count &&
          size == other.size &&
          minSpeed == other.minSpeed &&
          maxSpeed == other.maxSpeed &&
          lifespan == other.lifespan &&
          color == other.color;

  @override
  int get hashCode =>
      Object.hash(count, size, minSpeed, maxSpeed, lifespan, color);
}

/// Lines drawn between nearby particles, for "network" and constellation
/// backgrounds.
@immutable
class ParticleConnections {
  /// Particles closer than this (in logical pixels) are connected.
  final double maxDistance;

  /// Line color.
  final Color color;

  /// Line width in logical pixels.
  final double strokeWidth;

  /// Opacity of the line between two particles that touch; lines fade out
  /// as the distance approaches [maxDistance].
  final double maxOpacity;

  /// Whether to also connect particles to the pointer. Works when the
  /// pointer is tracked, i.e. with an `interaction` or on hover.
  final bool connectPointer;

  /// Creates connections.
  const ParticleConnections({
    this.maxDistance = 100,
    this.color = const Color(0xFFFFFFFF),
    this.strokeWidth = 1.0,
    this.maxOpacity = 0.4,
    this.connectPointer = true,
  }) : assert(maxDistance > 0),
       assert(strokeWidth > 0),
       assert(maxOpacity >= 0 && maxOpacity <= 1);

  /// Converts these connections to JSON.
  Map<String, Object?> toJson() => {
    'maxDistance': maxDistance,
    'color': colorToJson(color),
    'strokeWidth': strokeWidth,
    'maxOpacity': maxOpacity,
    'connectPointer': connectPointer,
  };

  /// Creates connections from [toJson] output.
  factory ParticleConnections.fromJson(Map<String, Object?> json) {
    return ParticleConnections(
      maxDistance: readPositive(json['maxDistance']) ?? 100,
      color: readColor(json['color']) ?? const Color(0xFFFFFFFF),
      strokeWidth: readPositive(json['strokeWidth']) ?? 1.0,
      maxOpacity: readDoubleIn(json['maxOpacity'], 0, 1) ?? 0.4,
      connectPointer: readBool(json['connectPointer']) ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleConnections &&
          maxDistance == other.maxDistance &&
          color == other.color &&
          strokeWidth == other.strokeWidth &&
          maxOpacity == other.maxOpacity &&
          connectPointer == other.connectPointer;

  @override
  int get hashCode =>
      Object.hash(maxDistance, color, strokeWidth, maxOpacity, connectPointer);
}
