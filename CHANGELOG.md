## Unreleased

* Fixed failed image loads (e.g. a 404 URL) being retried on every frame.
* Fixed `velocityMultiplier`, `enableSizeVariation`, `onAnimationComplete` and `loadingWidget` having no effect.
* Fixed `ParticleConfig` equality ignoring `gradientColors`, so color-only changes now regenerate particles.
* Fixed different custom widgets of the same type sharing one cached image. Custom widgets are now rendered once at `maxSize` and the device pixel ratio, then scaled per particle.
* Fixed `setState` being called after dispose while images were loading.
* Fixed particles vanishing mid-screen and snapping at cycle boundaries. Particles now enter and leave off-screen (or fade out with partial `particleCoverage`), and `diagonal` particles are spread across the screen.
* Fixed cached images, codecs, SVG pictures and offscreen render trees not being disposed.
* Fixed SVG decoding of non-ASCII content and stretching of non-square SVGs.
* Deprecated the unused `ParticlePainter.screenSize` parameter.

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
