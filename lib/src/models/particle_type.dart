/// The visual shape of each particle.
enum ParticleType {
  /// Simple circular particles - great for snow, bubbles, or dots
  circle,

  /// Square/rectangular particles - good for confetti or geometric effects
  square,

  /// Star-shaped particles - perfect for magical or celebratory effects
  star,

  /// Heart-shaped particles - ideal for romantic or love-themed animations
  heart,

  /// Leaf-shaped particles - perfect for nature or autumn themes
  leaf,

  /// Thin streaks aligned with the direction of motion - ideal for rain
  streak,

  /// A custom shape given by [ParticleConfig.customPath]
  path,

  /// An image from [ParticleConfig.image] or [ParticleConfig.imagePath]
  /// (asset or network; PNG, JPG, GIF, WebP or SVG)
  image,

  /// A widget from [ParticleConfig.customParticle], rendered once to an image
  custom,
}
