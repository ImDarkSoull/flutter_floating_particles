import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// How particles interact with the widgets given as `colliders` to
/// `ParticleEffects`.
@immutable
class ParticleCollision {
  /// Whether falling particles land and pile up on top of colliders (like
  /// snow on a card). Otherwise particles simply disappear behind them.
  final bool settle;

  /// How long landed particles stay before melting away.
  final Duration settleDuration;

  /// Maximum number of landed particles per collider; the oldest melt first.
  final int maxSettled;

  /// Fraction of speed kept when bursts and emitted particles bounce off a
  /// collider.
  final double restitution;

  /// Creates a collision behavior.
  const ParticleCollision({
    this.settle = true,
    this.settleDuration = const Duration(seconds: 6),
    this.maxSettled = 200,
    this.restitution = 0.4,
  }) : assert(maxSettled >= 0),
       assert(restitution >= 0 && restitution <= 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleCollision &&
          settle == other.settle &&
          settleDuration == other.settleDuration &&
          maxSettled == other.maxSettled &&
          restitution == other.restitution;

  @override
  int get hashCode =>
      Object.hash(settle, settleDuration, maxSettled, restitution);
}

/// Describes a particle that was tapped, for `ParticleEffects.onParticleTap`.
@immutable
class ParticleTapDetails {
  /// Creates tap details.
  const ParticleTapDetails({
    required this.position,
    required this.color,
    required this.size,
    required this.isBurstParticle,
  });

  /// Center of the tapped particle in the effect's local coordinates.
  final Offset position;

  /// Color of the tapped particle.
  final Color color;

  /// Size of the tapped particle in logical pixels.
  final double size;

  /// Whether the particle came from a burst or emitter rather than the
  /// continuously animated particles.
  final bool isBurstParticle;
}
