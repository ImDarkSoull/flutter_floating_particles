import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'direction.dart';
import 'json_utils.dart';
import 'particle_behaviors.dart';
import 'particle_coverage.dart';
import 'particle_emitter.dart';
import 'particle_type.dart';

/// Configuration class that defines how particle effects should behave and appear.
///
/// This class provides extensive customization options for particle animations,
/// from basic properties like count and size to advanced effects like glow and rotation.
///
/// Start from a preset and tweak it with [copyWith]:
///
/// ```dart
/// ParticleConfig.snow.copyWith(particleCount: 200, wind: 0.2)
/// ```
@immutable
class ParticleConfig {
  /// The visual shape of particles
  final ParticleType particleType;

  /// Direction of particle movement
  final ParticleDirection direction;

  /// How far across the screen particles travel before fading out
  final ParticleCoverage particleCoverage;

  /// Total number of continuously animated particles.
  ///
  /// Use 0 together with `ParticleController.burst` for burst-only effects.
  final int particleCount;

  /// Minimum size of particles in logical pixels
  final double minSize;

  /// Maximum size of particles in logical pixels
  final double maxSize;

  /// Time for a particle with average speed to cross the screen once.
  ///
  /// Also the period of `ParticleEffects.onAnimationComplete`.
  final Duration animationDuration;

  /// Fixed color for all particles (if null, uses gradientColors or white).
  ///
  /// For image and custom widget particles the color tints the image.
  final Color? particleColor;

  /// Path of an image asset or an `http(s)` URL for [ParticleType.image].
  ///
  /// Raster formats supported by Flutter and SVG (`.svg`) are accepted.
  /// Ignored when [image] is set.
  final String? imagePath;

  /// Any [ImageProvider] for [ParticleType.image], e.g. [AssetImage],
  /// [NetworkImage], [MemoryImage] or `FileImage`. Takes precedence over
  /// [imagePath].
  final ImageProvider? image;

  /// Widget used as the particle for [ParticleType.custom].
  ///
  /// It is rendered once, in a [maxSize] x [maxSize] box, and scaled to each
  /// particle's size. Reuse the same instance (or a `const` widget) to avoid
  /// re-rendering it.
  final Widget? customParticle;

  /// Shape used for [ParticleType.path].
  ///
  /// Any coordinates can be used: the path is scaled to fit the particle
  /// size, keeping its aspect ratio. Handy for shapes converted from SVG
  /// path data.
  final Path? customPath;

  /// Minimum opacity value for particles
  final double minOpacity;

  /// Maximum opacity value for particles
  final double maxOpacity;

  /// Whether to add a soft halo around particles. The particle itself stays
  /// sharp; use [enableBlur] to soften it.
  final bool enableGlow;

  /// Radius of the glow in logical pixels for a particle of average size.
  /// Smaller and larger particles get proportionally less or more glow.
  final double glowRadius;

  /// Whether particles should spin during animation.
  ///
  /// [ParticleType.streak] particles always point along their motion instead.
  final bool enableRotation;

  /// Multiplier for how fast particles spin when [enableRotation] is true
  final double rotationSpeed;

  /// Speed multiplier for particle movement (1.0 = normal speed)
  final double velocityMultiplier;

  /// Whether particles should have varying sizes between [minSize] and
  /// [maxSize]. When false, every particle uses [maxSize].
  final bool enableSizeVariation;

  /// Whether particle opacity should twinkle between [minOpacity] and
  /// [maxOpacity]. When false, particles use [maxOpacity].
  final bool enableOpacityAnimation;

  /// Palette that each particle randomly picks its color from. Ignored when
  /// [particleColor] is set.
  final List<Color>? gradientColors;

  /// Whether to apply blur effect to particles
  final bool enableBlur;

  /// Sigma value for blur effect, in logical pixels for a particle of
  /// average size
  final double blurSigma;

  /// Seed for particle placement. Effects with different seeds get different
  /// layouts; null keeps the default layout.
  final int? seed;

  /// Sideways drift per unit of travel, e.g. 0.3 moves falling particles 0.3
  /// pixels right for every pixel they fall. Negative values blow the other
  /// way. Particles wrap around the edges.
  final double wind;

  /// Amplitude in logical pixels of the side-to-side wobble. Null uses a
  /// default that depends on [direction]; 0 moves particles in straight lines.
  final double? driftAmplitude;

  /// Fraction of the path (0.0 to 0.5) over which particles fade in when
  /// they appear and fade out before they disappear.
  final double edgeFade;

  /// How particles are composited with what is painted below them.
  ///
  /// [BlendMode.plus] makes overlapping particles brighten each other, which
  /// suits fire, sparks and fireflies.
  final BlendMode blendMode;

  /// Several particle types to mix in one effect; each particle picks one at
  /// random. Overrides [particleType] when set.
  final List<ParticleType>? particleTypes;

  /// Several images to mix for [ParticleType.image]; each particle picks one
  /// at random. Overrides [image] and [imagePath] when set.
  final List<ImageProvider>? images;

  /// How particles change size, opacity and color over their life.
  final ParticleLifecycle? lifecycle;

  /// A fading tail behind each particle.
  final ParticleTrail? trail;

  /// Droplets that splash up where particles reach the end of their path.
  final ParticleSplash? splash;

  /// Lines between nearby particles.
  final ParticleConnections? connections;

  /// Sources that continuously spawn extra particles (fountains, smoke,
  /// fireworks). They run alongside the [particleCount] particles.
  final List<ParticleEmitter>? emitters;

  /// Strength (0.0 to 1.0) of the depth effect: smaller particles are
  /// treated as farther away, so they move slower, look fainter and shift
  /// less with [parallaxFactor].
  final double depthEffect;

  /// How much particles shift with `ParticleEffects.parallax` (1.0 = as
  /// much as the parallax offset, 0.0 = not at all).
  final double parallaxFactor;

  /// Upper limit on the number of particles drawn at once, including bursts
  /// and emitted particles. Null allows up to 5000 extra particles.
  final int? maxParticles;

  /// Creates a particle configuration.
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
    this.image,
    this.customParticle,
    this.customPath,
    this.minOpacity = 0.3,
    this.maxOpacity = 1.0,
    this.enableGlow = false,
    this.glowRadius = 4.0,
    this.enableRotation = false,
    this.rotationSpeed = 1.0,
    this.velocityMultiplier = 1.0,
    this.enableSizeVariation = true,
    this.enableOpacityAnimation = true,
    this.gradientColors,
    this.enableBlur = false,
    this.blurSigma = 1.0,
    this.seed,
    this.wind = 0.0,
    this.driftAmplitude,
    this.edgeFade = 0.0,
    this.blendMode = BlendMode.srcOver,
    this.particleTypes,
    this.images,
    this.lifecycle,
    this.trail,
    this.splash,
    this.connections,
    this.emitters,
    this.depthEffect = 0.0,
    this.parallaxFactor = 0.5,
    this.maxParticles,
  }) : assert(particleCount >= 0),
       assert(minSize > 0),
       assert(maxSize >= minSize),
       assert(minOpacity >= 0 && minOpacity <= 1),
       assert(maxOpacity >= 0 && maxOpacity <= 1),
       assert(minOpacity <= maxOpacity),
       assert(glowRadius >= 0),
       assert(blurSigma >= 0),
       assert(edgeFade >= 0 && edgeFade <= 0.5),
       assert(depthEffect >= 0 && depthEffect <= 1),
       assert(maxParticles == null || maxParticles >= 0);

  // Predefined configurations for common effects

  /// Snowflakes drifting down from top to bottom, slowly spinning
  static const ParticleConfig snow = ParticleConfig(
    particleType: ParticleType.snowflake,
    direction: ParticleDirection.topToBottom,
    particleCount: 100,
    // Large enough for the snowflake's arms to show
    minSize: 4.0,
    maxSize: 12.0,
    particleColor: Colors.white,
    enableGlow: true,
    glowRadius: 1.5,
    enableRotation: true,
    rotationSpeed: 0.3,
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
    blendMode: BlendMode.plus,
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
    wind: 0.15,
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

  /// Rain streaks falling quickly with a slight slant
  static const ParticleConfig rain = ParticleConfig(
    particleType: ParticleType.streak,
    direction: ParticleDirection.topToBottom,
    particleCoverage: ParticleCoverage.full,
    particleCount: 120,
    minSize: 10.0,
    maxSize: 22.0,
    particleColor: Color(0xFF8FB8E8),
    velocityMultiplier: 1.5,
    animationDuration: Duration(seconds: 3),
    minOpacity: 0.3,
    maxOpacity: 0.7,
    driftAmplitude: 0,
    wind: 0.08,
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
    rotationSpeed: 2.0,
    velocityMultiplier: 1.2,
    animationDuration: Duration(seconds: 10),
    minOpacity: 0.8,
    maxOpacity: 1.0,
    enableOpacityAnimation: false,
  );

  /// Glowing fireflies wandering in place
  static const ParticleConfig fireflies = ParticleConfig(
    particleType: ParticleType.circle,
    direction: ParticleDirection.none,
    particleCount: 35,
    minSize: 3.0,
    maxSize: 6.0,
    gradientColors: [Color(0xFFFFF59D), Color(0xFFDCE775), Color(0xFFFFD54F)],
    enableGlow: true,
    glowRadius: 4.0,
    velocityMultiplier: 0.5,
    animationDuration: Duration(seconds: 8),
    minOpacity: 0.0,
    maxOpacity: 1.0,
    driftAmplitude: 40,
    blendMode: BlendMode.plus,
  );

  /// Stars streaming outward from the center, like flying through space
  static const ParticleConfig starfield = ParticleConfig(
    particleType: ParticleType.circle,
    direction: ParticleDirection.radial,
    particleCount: 150,
    minSize: 1.0,
    maxSize: 4.0,
    particleColor: Colors.white,
    velocityMultiplier: 0.6,
    animationDuration: Duration(seconds: 4),
    minOpacity: 0.6,
    maxOpacity: 1.0,
    enableOpacityAnimation: false,
  );

  /// Fireworks launched from the bottom edge, exploding into glowing sparks
  /// with trails. Use `ParticleController.fireworks` for more on demand.
  static const ParticleConfig fireworks = ParticleConfig(
    particleCount: 0,
    minSize: 2.0,
    maxSize: 4.0,
    gradientColors: [
      Color(0xFFFF5252),
      Color(0xFFFFD740),
      Color(0xFF69F0AE),
      Color(0xFF40C4FF),
      Color(0xFFE040FB),
    ],
    enableGlow: true,
    glowRadius: 3.0,
    enableOpacityAnimation: false,
    blendMode: BlendMode.plus,
    lifecycle: ParticleLifecycle(endScale: 0.4),
    emitters: [ParticleEmitter.fireworksShow],
  );

  /// Cherry blossom petals drifting down in the wind
  static const ParticleConfig sakura = ParticleConfig(
    particleType: ParticleType.petal,
    particleCount: 40,
    minSize: 8.0,
    maxSize: 16.0,
    gradientColors: [Color(0xFFFFC1D6), Color(0xFFFFA3C4), Color(0xFFFFE4EE)],
    enableRotation: true,
    velocityMultiplier: 0.5,
    animationDuration: Duration(seconds: 14),
    minOpacity: 0.7,
    wind: 0.35,
    depthEffect: 0.6,
  );

  /// Drifting dots connected by lines, like a network or constellation.
  /// Particles connect to the pointer too when an interaction is set.
  static const ParticleConfig network = ParticleConfig(
    direction: ParticleDirection.none,
    particleCount: 60,
    minSize: 2.0,
    maxSize: 4.0,
    particleColor: Color(0xFFB3E5FC),
    velocityMultiplier: 0.4,
    driftAmplitude: 40,
    enableOpacityAnimation: false,
    connections: ParticleConnections(maxDistance: 110),
  );

  /// A heavy snowfall of snowflakes with depth
  static const ParticleConfig blizzard = ParticleConfig(
    particleTypes: [ParticleType.snowflake, ParticleType.circle],
    particleCount: 160,
    minSize: 3.0,
    maxSize: 14.0,
    particleColor: Colors.white,
    enableRotation: true,
    rotationSpeed: 0.3,
    velocityMultiplier: 0.9,
    animationDuration: Duration(seconds: 9),
    minOpacity: 0.5,
    wind: 0.25,
    depthEffect: 0.8,
  );

  /// Returns a copy of this configuration with the given fields replaced.
  ///
  /// Nullable fields cannot be reset to null this way; create a new
  /// [ParticleConfig] for that.
  ParticleConfig copyWith({
    ParticleType? particleType,
    ParticleDirection? direction,
    ParticleCoverage? particleCoverage,
    int? particleCount,
    double? minSize,
    double? maxSize,
    Duration? animationDuration,
    Color? particleColor,
    String? imagePath,
    ImageProvider? image,
    Widget? customParticle,
    Path? customPath,
    double? minOpacity,
    double? maxOpacity,
    bool? enableGlow,
    double? glowRadius,
    bool? enableRotation,
    double? rotationSpeed,
    double? velocityMultiplier,
    bool? enableSizeVariation,
    bool? enableOpacityAnimation,
    List<Color>? gradientColors,
    bool? enableBlur,
    double? blurSigma,
    int? seed,
    double? wind,
    double? driftAmplitude,
    double? edgeFade,
    BlendMode? blendMode,
    List<ParticleType>? particleTypes,
    List<ImageProvider>? images,
    ParticleLifecycle? lifecycle,
    ParticleTrail? trail,
    ParticleSplash? splash,
    ParticleConnections? connections,
    List<ParticleEmitter>? emitters,
    double? depthEffect,
    double? parallaxFactor,
    int? maxParticles,
  }) {
    return ParticleConfig(
      particleType: particleType ?? this.particleType,
      direction: direction ?? this.direction,
      particleCoverage: particleCoverage ?? this.particleCoverage,
      particleCount: particleCount ?? this.particleCount,
      minSize: minSize ?? this.minSize,
      maxSize: maxSize ?? this.maxSize,
      animationDuration: animationDuration ?? this.animationDuration,
      particleColor: particleColor ?? this.particleColor,
      imagePath: imagePath ?? this.imagePath,
      image: image ?? this.image,
      customParticle: customParticle ?? this.customParticle,
      customPath: customPath ?? this.customPath,
      minOpacity: minOpacity ?? this.minOpacity,
      maxOpacity: maxOpacity ?? this.maxOpacity,
      enableGlow: enableGlow ?? this.enableGlow,
      glowRadius: glowRadius ?? this.glowRadius,
      enableRotation: enableRotation ?? this.enableRotation,
      rotationSpeed: rotationSpeed ?? this.rotationSpeed,
      velocityMultiplier: velocityMultiplier ?? this.velocityMultiplier,
      enableSizeVariation: enableSizeVariation ?? this.enableSizeVariation,
      enableOpacityAnimation:
          enableOpacityAnimation ?? this.enableOpacityAnimation,
      gradientColors: gradientColors ?? this.gradientColors,
      enableBlur: enableBlur ?? this.enableBlur,
      blurSigma: blurSigma ?? this.blurSigma,
      seed: seed ?? this.seed,
      wind: wind ?? this.wind,
      driftAmplitude: driftAmplitude ?? this.driftAmplitude,
      edgeFade: edgeFade ?? this.edgeFade,
      blendMode: blendMode ?? this.blendMode,
      particleTypes: particleTypes ?? this.particleTypes,
      images: images ?? this.images,
      lifecycle: lifecycle ?? this.lifecycle,
      trail: trail ?? this.trail,
      splash: splash ?? this.splash,
      connections: connections ?? this.connections,
      emitters: emitters ?? this.emitters,
      depthEffect: depthEffect ?? this.depthEffect,
      parallaxFactor: parallaxFactor ?? this.parallaxFactor,
      maxParticles: maxParticles ?? this.maxParticles,
    );
  }

  /// Converts this configuration to JSON, e.g. to store effects on a server.
  ///
  /// [customParticle], [customPath] and image providers other than
  /// [AssetImage] and [NetworkImage] cannot be serialized and are left out,
  /// as are emitters' `followKey`s.
  Map<String, Object?> toJson() => {
    'particleType': particleType.name,
    'direction': direction.name,
    'particleCoverage': particleCoverage.name,
    'particleCount': particleCount,
    'minSize': minSize,
    'maxSize': maxSize,
    'animationDurationMs': animationDuration.inMilliseconds,
    if (particleColor != null) 'particleColor': colorToJson(particleColor!),
    if (imagePath != null) 'imagePath': imagePath,
    if (imageToJson(image) != null) 'image': imageToJson(image),
    'minOpacity': minOpacity,
    'maxOpacity': maxOpacity,
    'enableGlow': enableGlow,
    'glowRadius': glowRadius,
    'enableRotation': enableRotation,
    'rotationSpeed': rotationSpeed,
    'velocityMultiplier': velocityMultiplier,
    'enableSizeVariation': enableSizeVariation,
    'enableOpacityAnimation': enableOpacityAnimation,
    if (gradientColors != null)
      'gradientColors': gradientColors!.map(colorToJson).toList(),
    'enableBlur': enableBlur,
    'blurSigma': blurSigma,
    if (seed != null) 'seed': seed,
    'wind': wind,
    if (driftAmplitude != null) 'driftAmplitude': driftAmplitude,
    'edgeFade': edgeFade,
    'blendMode': blendMode.name,
    if (particleTypes != null)
      'particleTypes': particleTypes!.map((t) => t.name).toList(),
    if (images != null)
      'images': [
        for (final image in images!)
          if (imageToJson(image) != null) imageToJson(image),
      ],
    if (lifecycle != null) 'lifecycle': lifecycle!.toJson(),
    if (trail != null) 'trail': trail!.toJson(),
    if (splash != null) 'splash': splash!.toJson(),
    if (connections != null) 'connections': connections!.toJson(),
    if (emitters != null)
      'emitters': emitters!.map((emitter) => emitter.toJson()).toList(),
    'depthEffect': depthEffect,
    'parallaxFactor': parallaxFactor,
    if (maxParticles != null) 'maxParticles': maxParticles,
  };

  /// Creates a configuration from [toJson] output, such as JSON a user
  /// pasted or a server sent. Missing fields and values of the wrong type
  /// use their defaults, and out-of-range values are clamped, so any
  /// decoded JSON object gives a valid configuration.
  factory ParticleConfig.fromJson(Map<String, Object?> json) {
    Map<String, Object?>? map(Object? value) =>
        value is Map ? value.cast<String, Object?>() : null;
    List<Object?>? list(Object? value) => value is List ? value : null;
    const defaults = ParticleConfig();
    final minSize = readPositive(json['minSize']) ?? defaults.minSize;
    final maxOpacity =
        readDoubleIn(json['maxOpacity'], 0, 1) ?? defaults.maxOpacity;

    return ParticleConfig(
      particleType: readEnum(
        ParticleType.values,
        json['particleType'],
        defaults.particleType,
      ),
      direction: readEnum(
        ParticleDirection.values,
        json['direction'],
        defaults.direction,
      ),
      particleCoverage: readEnum(
        ParticleCoverage.values,
        json['particleCoverage'],
        defaults.particleCoverage,
      ),
      particleCount: readCount(json['particleCount']) ?? defaults.particleCount,
      minSize: minSize,
      maxSize: max(minSize, readDouble(json['maxSize']) ?? defaults.maxSize),
      animationDuration:
          readMs(json['animationDurationMs'], 1) ?? defaults.animationDuration,
      particleColor: readColor(json['particleColor']),
      imagePath: readString(json['imagePath']),
      image: readImage(json['image']),
      minOpacity: min(
        maxOpacity,
        readDoubleIn(json['minOpacity'], 0, 1) ?? defaults.minOpacity,
      ),
      maxOpacity: maxOpacity,
      enableGlow: readBool(json['enableGlow']) ?? defaults.enableGlow,
      glowRadius: readDoubleIn(json['glowRadius'], 0) ?? defaults.glowRadius,
      enableRotation:
          readBool(json['enableRotation']) ?? defaults.enableRotation,
      rotationSpeed:
          readDouble(json['rotationSpeed']) ?? defaults.rotationSpeed,
      velocityMultiplier:
          readDouble(json['velocityMultiplier']) ?? defaults.velocityMultiplier,
      enableSizeVariation:
          readBool(json['enableSizeVariation']) ?? defaults.enableSizeVariation,
      enableOpacityAnimation:
          readBool(json['enableOpacityAnimation']) ??
          defaults.enableOpacityAnimation,
      gradientColors: readColors(json['gradientColors']),
      enableBlur: readBool(json['enableBlur']) ?? defaults.enableBlur,
      blurSigma: readDoubleIn(json['blurSigma'], 0) ?? defaults.blurSigma,
      seed: readInt(json['seed']),
      wind: readDouble(json['wind']) ?? defaults.wind,
      driftAmplitude: readDouble(json['driftAmplitude']),
      edgeFade: readDoubleIn(json['edgeFade'], 0, 0.5) ?? defaults.edgeFade,
      blendMode: readEnum(
        BlendMode.values,
        json['blendMode'],
        defaults.blendMode,
      ),
      particleTypes: list(json['particleTypes'])
          ?.map(
            (name) => readEnum(ParticleType.values, name, ParticleType.circle),
          )
          .toList(),
      images: list(json['images'])?.map(readImage).nonNulls.toList(),
      lifecycle: map(json['lifecycle']) == null
          ? null
          : ParticleLifecycle.fromJson(map(json['lifecycle'])!),
      trail: map(json['trail']) == null
          ? null
          : ParticleTrail.fromJson(map(json['trail'])!),
      splash: map(json['splash']) == null
          ? null
          : ParticleSplash.fromJson(map(json['splash'])!),
      connections: map(json['connections']) == null
          ? null
          : ParticleConnections.fromJson(map(json['connections'])!),
      emitters: list(
        json['emitters'],
      )?.map(map).nonNulls.map(ParticleEmitter.fromJson).toList(),
      depthEffect:
          readDoubleIn(json['depthEffect'], 0, 1) ?? defaults.depthEffect,
      parallaxFactor:
          readDouble(json['parallaxFactor']) ?? defaults.parallaxFactor,
      maxParticles: readCount(json['maxParticles']),
    );
  }

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
          image == other.image &&
          customParticle == other.customParticle &&
          customPath == other.customPath &&
          minOpacity == other.minOpacity &&
          maxOpacity == other.maxOpacity &&
          enableGlow == other.enableGlow &&
          glowRadius == other.glowRadius &&
          enableRotation == other.enableRotation &&
          rotationSpeed == other.rotationSpeed &&
          velocityMultiplier == other.velocityMultiplier &&
          enableSizeVariation == other.enableSizeVariation &&
          enableOpacityAnimation == other.enableOpacityAnimation &&
          listEquals(gradientColors, other.gradientColors) &&
          enableBlur == other.enableBlur &&
          blurSigma == other.blurSigma &&
          seed == other.seed &&
          wind == other.wind &&
          driftAmplitude == other.driftAmplitude &&
          edgeFade == other.edgeFade &&
          blendMode == other.blendMode &&
          listEquals(particleTypes, other.particleTypes) &&
          listEquals(images, other.images) &&
          lifecycle == other.lifecycle &&
          trail == other.trail &&
          splash == other.splash &&
          connections == other.connections &&
          listEquals(emitters, other.emitters) &&
          depthEffect == other.depthEffect &&
          parallaxFactor == other.parallaxFactor &&
          maxParticles == other.maxParticles;

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
    image,
    customParticle,
    customPath,
    minOpacity,
    maxOpacity,
    enableGlow,
    glowRadius,
    enableRotation,
    rotationSpeed,
    velocityMultiplier,
    enableSizeVariation,
    enableOpacityAnimation,
    gradientColors == null ? null : Object.hashAll(gradientColors!),
    enableBlur,
    blurSigma,
    seed,
    wind,
    driftAmplitude,
    edgeFade,
    blendMode,
    particleTypes == null ? null : Object.hashAll(particleTypes!),
    images == null ? null : Object.hashAll(images!),
    lifecycle,
    trail,
    splash,
    connections,
    emitters == null ? null : Object.hashAll(emitters!),
    depthEffect,
    parallaxFactor,
    maxParticles,
  ]);
}
