import 'dart:math';
import 'package:flutter/material.dart';

import 'particle_config.dart';

/// Represents the properties of an individual particle.
///
/// Each particle has unique characteristics like position, size, color,
/// and animation properties that make the overall effect look natural.
@immutable
class ParticleData {
  /// Initial horizontal position as a percentage (0.0 to 1.0)
  final double initialX;

  /// Initial vertical position as a percentage (0.0 to 1.0)
  final double initialY;

  /// Size of the particle in logical pixels
  final double size;

  /// Movement speed multiplier for this particle
  final double velocity;

  /// Fraction of the screen (0.0 to 1.0) the particle travels
  final double screenOccupancy;

  /// Rotation speed in turns per animation cycle
  final double rotationSpeed;

  /// Phase offset for animation timing to create variety, in radians
  final double animationOffset;

  /// Color of this specific particle
  final Color color;

  /// Optional image path for image-based particles
  final String? imagePath;

  /// Random value (0.0 to 1.0) choosing which of several particle types or
  /// images this particle uses
  final double variant;

  /// Depth (0.0 = far, 1.0 = near), derived from the particle's size
  final double depth;

  /// Creates a particle with the given properties.
  const ParticleData({
    required this.initialX,
    required this.initialY,
    required this.size,
    required this.velocity,
    required this.screenOccupancy,
    required this.rotationSpeed,
    required this.animationOffset,
    required this.color,
    this.imagePath,
    this.variant = 0.0,
    this.depth = 1.0,
  });

  /// Generates a random particle with properties based on the given configuration.
  ///
  /// Uses a seeded random generator (from [index] and
  /// [ParticleConfig.seed]) to ensure consistent results across rebuilds
  /// while still providing natural-looking variation between particles.
  static ParticleData generate(int index, ParticleConfig config) {
    final seed = config.seed;
    final random = Random(seed == null ? index : seed * 1000003 + index);
    final initialX = random.nextDouble();
    final initialY = random.nextDouble();
    // Always draw the value so the remaining properties don't depend on
    // whether size variation is enabled.
    final sizeFactor = random.nextDouble();
    final sizeRange = config.maxSize - config.minSize;
    final size = config.enableSizeVariation
        ? config.minSize + sizeFactor * sizeRange
        : config.maxSize;

    return ParticleData(
      initialX: initialX,
      initialY: initialY,
      size: size,
      velocity: 0.5 + random.nextDouble() * 0.5,
      screenOccupancy: config.particleCoverage.fraction,
      rotationSpeed: (random.nextDouble() - 0.5) * 4,
      animationOffset: random.nextDouble() * 2 * pi,
      color: pickColor(config, random),
      imagePath: config.imagePath,
      // Drawn last so adding it didn't change the other properties
      variant: random.nextDouble(),
      depth: sizeRange > 0 ? (size - config.minSize) / sizeRange : 1.0,
    );
  }

  /// Picks a particle color based on the configuration.
  static Color pickColor(ParticleConfig config, Random random) {
    // Use specific color if provided
    if (config.particleColor != null) {
      return config.particleColor!;
    }

    // Pick from the palette if provided
    final palette = config.gradientColors;
    if (palette != null && palette.isNotEmpty) {
      return palette[random.nextInt(palette.length)];
    }

    // Default to white
    return Colors.white;
  }
}
