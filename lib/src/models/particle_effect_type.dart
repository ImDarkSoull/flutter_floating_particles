import 'particle_config.dart';

/// Names of the predefined effects, each mapped to a [ParticleConfig] preset.
///
/// Handy for pickers and settings screens:
///
/// ```dart
/// ParticleEffects(config: ParticleEffectType.snow.config, child: ...)
/// ```
enum ParticleEffectType {
  /// [ParticleConfig.snow]
  snow,

  /// [ParticleConfig.rain]
  rain,

  /// [ParticleConfig.fireAshes]
  fireAshes,

  /// [ParticleConfig.bubbles]
  bubbles,

  /// [ParticleConfig.stars]
  stars,

  /// [ParticleConfig.hearts]
  hearts,

  /// [ParticleConfig.confetti]
  confetti,

  /// [ParticleConfig.fallingLeaves]
  fallingLeaves,

  /// [ParticleConfig.fireflies]
  fireflies,

  /// [ParticleConfig.starfield]
  starfield;

  /// The preset configuration for this effect.
  ParticleConfig get config => switch (this) {
    snow => ParticleConfig.snow,
    rain => ParticleConfig.rain,
    fireAshes => ParticleConfig.fireAshes,
    bubbles => ParticleConfig.bubbles,
    stars => ParticleConfig.stars,
    hearts => ParticleConfig.hearts,
    confetti => ParticleConfig.confetti,
    fallingLeaves => ParticleConfig.fallingLeaves,
    fireflies => ParticleConfig.fireflies,
    starfield => ParticleConfig.starfield,
  };
}
