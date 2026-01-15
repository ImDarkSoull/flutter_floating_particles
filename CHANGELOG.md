## 1.0.2

* Significant performance optimization for low-end devices:
  * Reduced memory usage by reusing `Paint` objects.
  * Implemented RepaintBoundary for GPU-accelerated animation layering.
  * Optimized rendering of complex shapes with cached paths.
* Added new `ParticleType.leaf` for realistic falling leaves effect.
* Fixed rendering issue for Heart shape particles.
* Updated example app to showcase new Leaf particles.

## 1.0.1

* Fixed Dart analysis warnings and lints across the package and example.
* Improved performance by using `const` constructors where applicable.
* Updated deprecated API usage for better compatibility with recent Flutter versions.
* Improved unit test robustness by disabling debug banners during testing.

## 1.0.0

* initial draft of the Flutter Floating particles.
