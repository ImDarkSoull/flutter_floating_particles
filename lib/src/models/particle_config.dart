import 'package:flutter/material.dart';
import '../../flutter_floating_particles.dart';

/// Configuration class that defines how particle effects should behave and appear.
///
/// This class provides extensive customization options for particle animations,
/// from basic properties like count and size to advanced effects like glow and rotation.
class ParticleConfig {
  /// The visual shape of particles
  final ParticleType particleType;

  /// Direction of particle movement
  final ParticleDirection direction;

  final ParticleCoverage particleCoverage;

  /// Total number of particles to animate
  final int particleCount;

  /// Minimum size of particles in logical pixels
  final double minSize;

  /// Maximum size of particles in logical pixels
  final double maxSize;

  /// Duration for one complete animation cycle
  final Duration animationDuration;

  /// Fixed color for all particles (if null, uses gradientColors or white)
  final Color? particleColor;

  /// Path to image asset for image-based particles
  final String? imagePath;

  /// Custom widget to use as particle (overrides other shape settings)
  final Widget? customParticle;

  /// Minimum opacity value for particles
  final double minOpacity;

  /// Maximum opacity value for particles
  final double maxOpacity;

  /// Whether to add a glow effect around particles
  final bool enableGlow;

  /// Radius of the glow effect in logical pixels
  final double glowRadius;

  /// Whether particles should rotate during animation
  final bool enableRotation;

  /// Speed multiplier for particle movement (1.0 = normal speed)
  final double velocityMultiplier;

  /// Whether particles should have varying sizes
  final bool enableSizeVariation;

  /// Whether particle opacity should animate over time
  final bool enableOpacityAnimation;

  /// List of colors to randomly choose from for particles
  final List<Color>? gradientColors;

  /// Whether to apply blur effect to particles
  final bool enableBlur;

  /// Sigma value for blur effect
  final double blurSigma;

  const ParticleConfig({
    this.particleType = ParticleType.circle,
    this.direction = ParticleDirection.topToBottom,
    this.particleCoverage = ParticleCoverage.full,
    this.particleCount = 50,
    this.minSize = 2.0,
    this.maxSize = 6.0,
    this.animationDuration = const Duration(seconds: 10),
    this.particleColor,
    this.imagePath,
    this.customParticle,
    this.minOpacity = 0.3,
    this.maxOpacity = 1.0,
    this.enableGlow = false,
    this.glowRadius = 4.0,
    this.enableRotation = false,
    this.velocityMultiplier = 1.0,
    this.enableSizeVariation = true,
    this.enableOpacityAnimation = true,
    this.gradientColors,
    this.enableBlur = false,
    this.blurSigma = 1.0,
  });

  // Predefined configurations for common effects

  /// Snow falling from top to bottom with white circular particles
  static const ParticleConfig snow = ParticleConfig(
    particleType: ParticleType.circle,
    direction: ParticleDirection.topToBottom,
    particleCount: 100,
    minSize: 2.0,
    maxSize: 8.0,
    particleColor: Colors.white,
    enableGlow: true,
    glowRadius: 3.0,
    velocityMultiplier: 0.5,
    animationDuration: Duration(seconds: 15),
    minOpacity: 0.6,
    maxOpacity: 1.0,
  );

  /// Fire ashes rising from bottom to top with warm colors
  static const ParticleConfig fireAshes = ParticleConfig(
    particleType: ParticleType.circle,
    direction: ParticleDirection.bottomToTop,
    particleCoverage: ParticleCoverage.full,
    particleCount: 30,
    minSize: 1.0,
    maxSize: 4.0,
    gradientColors: [
      Colors.orange,
      Colors.red,
      Colors.yellow,
      Color(0xFFFF6B35),
    ],
    enableGlow: true,
    glowRadius: 6.0,
    velocityMultiplier: 0.8,
    animationDuration: Duration(seconds: 12),
    minOpacity: 0.4,
    maxOpacity: 0.9,
  );

  /// Falling leaves with rotation effect
  static const ParticleConfig fallingLeaves = ParticleConfig(
    particleType: ParticleType.leaf,
    direction: ParticleDirection.topToBottom,
    particleCoverage: ParticleCoverage.full,
    particleCount: 20,
    minSize: 8.0,
    maxSize: 15.0,
    gradientColors: [Colors.orange, Colors.red, Colors.brown, Colors.yellow],
    enableRotation: true,
    velocityMultiplier: 0.6,
    animationDuration: Duration(seconds: 20),
    minOpacity: 0.7,
    maxOpacity: 1.0,
  );

  /// Bubbles floating upward with transparency
  static const ParticleConfig bubbles = ParticleConfig(
    particleType: ParticleType.circle,
    direction: ParticleDirection.bottomToTop,
    particleCoverage: ParticleCoverage.full,
    particleCount: 25,
    minSize: 4.0,
    maxSize: 20.0,
    particleColor: Colors.lightBlue,
    minOpacity: 0.2,
    maxOpacity: 0.7,
    enableGlow: true,
    glowRadius: 2.0,
    velocityMultiplier: 0.4,
    animationDuration: Duration(seconds: 18),
    enableBlur: true,
    blurSigma: 0.5,
  );

  /// Stars twinkling and falling
  static const ParticleConfig stars = ParticleConfig(
    particleType: ParticleType.star,
    direction: ParticleDirection.topToBottom,
    particleCoverage: ParticleCoverage.full,
    particleCount: 40,
    minSize: 3.0,
    maxSize: 10.0,
    gradientColors: [Colors.white, Colors.yellow, Colors.lightBlue],
    enableGlow: true,
    glowRadius: 5.0,
    enableRotation: true,
    velocityMultiplier: 0.3,
    animationDuration: Duration(seconds: 25),
    minOpacity: 0.5,
    maxOpacity: 1.0,
  );

  /// Hearts floating for romantic effects
  static const ParticleConfig hearts = ParticleConfig(
    particleType: ParticleType.heart,
    direction: ParticleDirection.bottomToTop,
    particleCoverage: ParticleCoverage.full,
    particleCount: 15,
    minSize: 6.0,
    maxSize: 16.0,
    gradientColors: [Colors.pink, Colors.red, Colors.pinkAccent],
    enableGlow: true,
    glowRadius: 4.0,
    velocityMultiplier: 0.5,
    animationDuration: Duration(seconds: 16),
    minOpacity: 0.6,
    maxOpacity: 0.9,
  );

  /// Rain drops falling quickly
  static const ParticleConfig rain = ParticleConfig(
    particleType: ParticleType.square, // Thin rectangles for rain
    direction: ParticleDirection.topToBottom,
    particleCoverage: ParticleCoverage.full,
    particleCount: 150,
    minSize: 1.0,
    maxSize: 3.0,
    particleColor: Color(0xFF4A90E2),
    velocityMultiplier: 1.5,
    animationDuration: Duration(seconds: 8),
    minOpacity: 0.4,
    maxOpacity: 0.8,
    enableBlur: true,
    blurSigma: 0.3,
  );

  /// Confetti celebration effect
  static const ParticleConfig confetti = ParticleConfig(
    particleType: ParticleType.square,
    direction: ParticleDirection.topToBottom,
    particleCoverage: ParticleCoverage.full,
    particleCount: 80,
    minSize: 4.0,
    maxSize: 8.0,
    gradientColors: [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ],
    enableRotation: true,
    velocityMultiplier: 1.2,
    animationDuration: Duration(seconds: 10),
    minOpacity: 0.8,
    maxOpacity: 1.0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticleConfig &&
          runtimeType == other.runtimeType &&
          particleType == other.particleType &&
          particleCoverage == other.particleCoverage &&
          direction == other.direction &&
          particleCount == other.particleCount &&
          minSize == other.minSize &&
          maxSize == other.maxSize &&
          animationDuration == other.animationDuration &&
          particleColor == other.particleColor &&
          imagePath == other.imagePath &&
          customParticle == other.customParticle &&
          minOpacity == other.minOpacity &&
          maxOpacity == other.maxOpacity &&
          enableGlow == other.enableGlow &&
          glowRadius == other.glowRadius &&
          enableRotation == other.enableRotation &&
          velocityMultiplier == other.velocityMultiplier &&
          enableSizeVariation == other.enableSizeVariation &&
          enableOpacityAnimation == other.enableOpacityAnimation &&
          enableBlur == other.enableBlur &&
          blurSigma == other.blurSigma;

  @override
  int get hashCode => Object.hashAll([
    particleType,
    direction,
    particleCount,
    particleCoverage,
    minSize,
    maxSize,
    animationDuration,
    particleColor,
    imagePath,
    customParticle,
    minOpacity,
    maxOpacity,
    enableGlow,
    glowRadius,
    enableRotation,
    velocityMultiplier,
    enableSizeVariation,
    enableOpacityAnimation,
    enableBlur,
    blurSigma,
  ]);
}
