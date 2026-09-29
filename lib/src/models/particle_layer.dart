/// Where particles are painted relative to the child of a `ParticleEffects`.
enum ParticleLayer {
  /// Particles are painted behind the child. The child must be at least
  /// partly transparent for them to show.
  background,

  /// Particles are painted on top of the child.
  foreground,
}
