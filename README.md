# 🌟 Flutter Floating Particles

[![pub package](https://img.shields.io/pub/v/flutter_floating_particles.svg)](https://pub.dev/packages/flutter_floating_particles) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![GitHub stars](https://img.shields.io/github/stars/nitesh695/flutter_floating_particles?style=social)](https://github.com/nitesh695/flutter_floating_particles)

A beautiful and customizable particle effects package for Flutter! Create stunning visual effects like snow, rain, confetti, bubbles, and more with smooth animations and extensive customization options.

## ✨ Features

- ✅ **Multiple particle types** (Circle, Square, Star, Heart, Leaf, Image, Custom Widget) 🎨
- ✅ **Pre-built effects** (Snow, Rain, Confetti, Bubbles, Stars, Hearts) ❄️
- ✅ **Custom particle effects** with full control over behavior 🎯
- ✅ **Gradient color support** for vibrant particles 🌈
- ✅ **Glow and blur effects** for enhanced visuals ✨
- ✅ **Rotation animations** for dynamic movement 🔄
- ✅ **Performance optimized** for smooth 60fps animations 🚀

## 📸 Preview

<img src="https://raw.githubusercontent.com/nitesh695/flutter_floating_particles/main/example/assets/demo.gif" width="400" alt="Demo GIF" />

## 📦 Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_floating_particles: ^latest_version
```

## 🔧 Usage

### 1️⃣ Import the Package

```dart
import 'package:flutter_floating_particles/flutter_floating_particles.dart';
```

### 2️⃣ Basic Usage with Pre-built Effects

```dart
ParticleEffects(
  config: ParticleConfig.snow,
  isEnabled: true,
  child: YourWidget(),
)
```

### 3️⃣ Custom Particle Configuration

```dart
ParticleEffects(
  config: ParticleConfig(
    particleType: ParticleType.circle,
    direction: ParticleDirection.topToBottom,
    particleCount: 50,
    minSize: 2.0,
    maxSize: 8.0,
    particleColor: Colors.white,
    enableGlow: true,
    velocityMultiplier: 0.8,
  ),
  isEnabled: true,
  child: YourWidget(),
)
```

### 4️⃣ Image Particles

```dart
ParticleEffects(
  config: ParticleConfig(
    particleType: ParticleType.image,
    imagePath: "assets/flutter_logo.png",
    particleCount: 30,
    minSize: 10.0,
    maxSize: 20.0,
    enableRotation: true,
  ),
  isEnabled: true,
  child: YourWidget(),
)
```

### 5️⃣ Custom Widget Particles

```dart
ParticleEffects(
  config: ParticleConfig(
    particleType: ParticleType.custom,
    customParticle: Icon(Icons.star, color: Colors.yellow),
    particleCount: 25,
    enableRotation: true,
  ),
  isEnabled: true,
  child: YourWidget(),
)
```

## 📜 API Reference

### ParticleEffects Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `config` | `ParticleConfig` | Configuration for particle behavior and appearance | Required |
| `isEnabled` | `bool` | Whether particle effects are active | `true` |
| `child` | `Widget` | The child widget to overlay particles on | Required |

### ParticleConfig Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `particleType` | `ParticleType` | Type of particle (circle, square, star, heart, leaf, image, custom) | `ParticleType.circle` |
| `direction` | `ParticleDirection` | Movement direction of particles | `ParticleDirection.topToBottom` |
| `particleCount` | `int` | Number of particles to display | `50` |
| `minSize` | `double` | Minimum particle size | `2.0` |
| `maxSize` | `double` | Maximum particle size | `8.0` |
| `particleColor` | `Color?` | Color for single-color particles | `Colors.white` |
| `gradientColors` | `List<Color>?` | Colors for gradient particles | `null` |
| `velocityMultiplier` | `double` | Speed multiplier for particle movement | `1.0` |
| `enableGlow` | `bool` | Whether to enable glow effects | `false` |
| `glowRadius` | `double` | Radius of the glow effect | `2.0` |
| `enableBlur` | `bool` | Whether to enable blur effects | `false` |
| `blurSigma` | `double` | Blur intensity | `1.0` |
| `enableRotation` | `bool` | Whether particles should rotate | `false` |
| `minOpacity` | `double` | Minimum particle opacity | `0.5` |
| `maxOpacity` | `double` | Maximum particle opacity | `1.0` |
| `animationDuration` | `Duration` | Duration for one complete cycle | `Duration(seconds: 10)` |
| `imagePath` | `String?` | Asset path for image particles | `null` |
| `customParticle` | `Widget?` | Custom widget for particles | `null` |

### Pre-built Effects

```dart
// Available pre-built configurations
ParticleConfig.snow
ParticleConfig.rain
ParticleConfig.confetti
ParticleConfig.bubbles
ParticleConfig.stars
ParticleConfig.hearts
ParticleConfig.fallingLeaves
```

### ParticleType Enum

```dart
enum ParticleType {
  circle,
  square,
  star,
  heart,
  leaf,
  image,
  custom,
}
```

### ParticleDirection Enum

```dart
enum ParticleDirection {
  topToBottom,
  bottomToTop,
  leftToRight,
  rightToLeft,
}
```

## 🎯 Performance Tips

- Use reasonable particle counts (30-100 for mobile devices)
- Consider disabling effects on low-end devices
- Use `isEnabled: false` to completely stop particle rendering
- Image particles are more resource-intensive than shape particles

## 📄 License

This package is licensed under the **MIT License**.

## 🙏 Support

If you like this package, ⭐ **Star it on [GitHub](https://github.com/nitesh695/flutter_floating_particles)**!  
For issues or feature requests, open an issue on [GitHub](https://github.com/nitesh695/flutter_floating_particles/issues).