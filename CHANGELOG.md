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
