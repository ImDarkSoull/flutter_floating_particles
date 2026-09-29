/// How particles react to a pointer.
enum ParticleInteractionMode {
  /// Particles are pushed away from the pointer.
  repel,

  /// Particles are pulled toward the pointer.
  attract,

  /// Particles ignore the pointer (useful together with
  /// [ParticleInteraction.tapBurstCount]).
  none,
}

/// Makes particles respond to touch and mouse input.
///
/// Pointer events are observed without being consumed, so the child of
/// `ParticleEffects` stays fully interactive.
class ParticleInteraction {
  /// How particles near the pointer move.
  final ParticleInteractionMode mode;

  /// Distance in logical pixels within which particles are affected.
  final double radius;

  /// Maximum displacement in logical pixels, reached right at the pointer.
  final double strength;

  /// Number of particles to burst from the pointer on each tap; 0 disables.
  final int tapBurstCount;

  /// Creates a pointer interaction.
  const ParticleInteraction({
    this.mode = ParticleInteractionMode.repel,
    this.radius = 100,
    this.strength = 60,
    this.tapBurstCount = 0,
  }) : assert(radius > 0),
       assert(strength >= 0),
       assert(tapBurstCount >= 0);

  /// Particles move out of the pointer's way.
  static const ParticleInteraction repel = ParticleInteraction();

  /// Particles gather around the pointer.
  static const ParticleInteraction attract = ParticleInteraction(
    mode: ParticleInteractionMode.attract,
  );

  /// Each tap bursts particles from the tap position.
  static const ParticleInteraction tapToBurst = ParticleInteraction(
    mode: ParticleInteractionMode.none,
    tapBurstCount: 30,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleInteraction &&
          mode == other.mode &&
          radius == other.radius &&
          strength == other.strength &&
          tapBurstCount == other.tapBurstCount;

  @override
  int get hashCode => Object.hash(mode, radius, strength, tapBurstCount);
}
