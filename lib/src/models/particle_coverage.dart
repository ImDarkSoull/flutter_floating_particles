/// How far across the screen particles travel before disappearing.
///
/// With anything less than [full], particles fade out once they have covered
/// the given fraction of the screen, which is useful for effects that should
/// stay near one edge (e.g. snow that only drifts through the top quarter).
enum ParticleCoverage {
  /// Particles travel 25% of the screen.
  quarter(0.25),

  /// Particles travel 35% of the screen.
  semiHalf(0.35),

  /// Particles travel 50% of the screen.
  half(0.5),

  /// Particles travel 75% of the screen.
  semiFull(0.75),

  /// Particles travel across the whole screen.
  full(1.0);

  const ParticleCoverage(this.fraction);

  /// The fraction of the screen (0.0 to 1.0) that particles travel.
  final double fraction;
}
