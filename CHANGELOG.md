## 2.0.0

### Breaking changes

* `ParticlePainter` is no longer exported. Use `ParticleEffects`, which can now be used without a child as a standalone layer.
* `ParticleType` gains `streak` and `path`, and `ParticleDirection` gains `none` and `radial`. Exhaustive `switch` statements over these enums need the new cases.
* `velocityMultiplier`, `enableSizeVariation`, `onAnimationComplete` and `loadingWidget` previously had no effect and now work, so effects that set them look or behave differently.
* Glow now adds a halo around a sharp particle instead of blurring the whole particle. Use `enableBlur` for a soft look.
* The `rain` preset now uses the new `streak` shape. `fireAshes` and the new `fireflies` preset use additive blending.
* Custom widget particles are rendered once at `maxSize` and scaled per particle, instead of being laid out at each particle's size.
* `ParticleCoverage` moved to `particle_coverage.dart` (it is still exported from the main library) and gained a `fraction` getter.
* Requires Flutter 3.32 or later.

### Performance

* All particles are drawn from one pre-rendered sprite in a single `drawRawAtlas` call, with glow and blur baked into the sprite instead of being applied to every particle on every frame.
* Animation runs on a `Ticker` that repaints the painter directly: no widget rebuilds, no `DateTime.now()` per particle, and no per-particle allocations.
* The ticker stops while the effect is disabled, paused, frozen for reduced motion, or has nothing to animate.
* Removed the `http` and `vector_math` dependencies. Images load through Flutter's `ImageProvider`s (with Flutter's image cache and web support), and SVGs through `flutter_svg`'s loaders.

### New features

* `ParticleController` to pause, resume and `burst()` particles, with gravity, drag, spread, direction and lifespan.
* `ParticleInteraction`: particles move away from or toward the pointer, or burst on tap, without blocking the child.
* `layer: ParticleLayer.background` to paint particles behind the child.
* The child is now optional, so the widget can be used as a standalone particle layer.
* `respectReduceMotion` (default true) freezes particles when the platform asks for reduced motion.
* `clipBehavior` keeps particles within the widget's bounds.
* `ParticleType.streak` for rain, and `ParticleType.path` with `customPath` for any custom shape.
* `ParticleDirection.none` (wandering in place) and `ParticleDirection.radial` (flying outward from the center).
* `ParticleConfig.image` accepts any `ImageProvider`.
* New `ParticleConfig` options: `seed`, `wind`, `driftAmplitude`, `edgeFade`, `blendMode` and `rotationSpeed`.
* `ParticleConfig.copyWith`, and asserts for invalid configurations.
* New `fireflies` and `starfield` presets. `ParticleEffectType.config` returns the preset for each effect type.
* `ParticleEffects.preloadImageProvider`.

### Bug fixes

* Fixed failed image loads (e.g. a 404 URL) being retried on every frame.
* Fixed `ParticleConfig` equality ignoring `gradientColors`, so color-only changes now regenerate particles.
* Fixed different custom widgets of the same type sharing one cached image, and custom widget snapshots being blurry on high-density screens.
* Fixed `setState` being called after dispose while images were loading.
* Fixed particles vanishing mid-screen and snapping at cycle boundaries. Particles now enter and leave off-screen (or fade out with partial `particleCoverage`), and `diagonal` particles are spread across the screen.
* Fixed cached images, codecs, SVG pictures and offscreen render trees not being disposed.
* Fixed SVG decoding of non-ASCII content and stretching of non-square SVGs.
* Changing `animationDuration` no longer makes particles jump.
* Fixed square outlines and stray lines around particles on Impeller's OpenGL ES backend (most Android devices).
* Fixed custom widget particles failing with "Invalid image dimensions" when created while the app starts (e.g. on Android).

### Package

* Rewrote the README and the example app, which now covers every feature.
* Added pub.dev topics and screenshots, API docs for every public member, stricter lints, and tests for the new features.

## 1.0.2

* Significant performance optimization for low-end devices:
  * Implemented RepaintBoundary for GPU-accelerated animation layering.
  * Optimized rendering of complex shapes with cached paths.
* Added new `ParticleType.leaf` for realistic falling leaves effect.
* Added support for network images in `ParticleType.image`. Support both HTTP/HTTPS URLs.
* Added support for SVG images (both local assets and network URLs) via `flutter_svg`.

## 1.0.1

* Fixed Dart analysis warnings and lints across the package and example.
* Improved performance by using `const` constructors where applicable.
* Updated deprecated API usage for better compatibility with recent Flutter versions.
* Improved unit test robustness by disabling debug banners during testing.

## 1.0.0

* initial draft of the Flutter Floating particles.
