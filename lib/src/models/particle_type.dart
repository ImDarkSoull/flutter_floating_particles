/// The visual shape of each particle.
enum ParticleType {
  /// Simple circular particles - great for dots, bubbles, or distant snow
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

  /// Six-armed snowflakes
  snowflake,

  /// Four-pointed sparkles - great for magic and twinkling stars
  sparkle,

  /// Flower petals - lovely for cherry blossoms and weddings
  petal,

  /// Teardrop-shaped raindrops
  raindrop,

  /// Hollow rings - good for bubbles
  ring,

  /// Triangles
  triangle,

  /// Diamonds
  diamond,

  /// A custom shape given by [ParticleConfig.customPath]
  path,

  /// An image from [ParticleConfig.image] or [ParticleConfig.imagePath]
  /// (asset or network; PNG, JPG, GIF, WebP or SVG)
  image,

  /// A widget from [ParticleConfig.customParticle], rendered once to an image
  custom,
}
