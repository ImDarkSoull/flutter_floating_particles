# 🌟 Flutter Floating Particles

[![pub package](https://img.shields.io/pub/v/flutter_floating_particles.svg)](https://pub.dev/packages/flutter_floating_particles) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![GitHub stars](https://img.shields.io/github/stars/nitesh695/flutter_floating_particles?style=social)](https://github.com/nitesh695/flutter_floating_particles)

Beautiful, fast and highly customizable particle effects for Flutter. Add snow, rain, confetti, bubbles, fireflies, starfields and more to any screen, with images, SVGs, custom shapes or widgets as particles, one-shot bursts and touch interaction.

## ✨ Features

- ✅ **10 ready-made effects**: snow, rain, fire ashes, bubbles, stars, hearts, confetti, falling leaves, fireflies, starfield
- ✅ **Any particle**: circle, square, star, heart, leaf, rain streak, your own `Path`, images (asset, network, SVG, any `ImageProvider`) or any widget
- ✅ **7 motion styles**: falling, rising, sideways, diagonal, wandering in place, and flying outward from the center, plus wind, drift and edge fading
- ✅ **Bursts**: confetti cannons and explosions with gravity, via `ParticleController`
- ✅ **Interactive**: particles move away from or toward a finger or mouse, or burst on tap, without blocking your UI
- ✅ **Glow, blur, rotation, twinkle and additive blending**
- ✅ **Fast**: every particle is drawn in a single GPU batch, with no per-frame widget rebuilds
- ✅ **Accessible**: honours the system "reduce motion" setting
- ✅ **Only one dependency** (`flutter_svg`, for SVG images)

## 📸 Preview

<img src="https://raw.githubusercontent.com/nitesh695/flutter_floating_particles/main/example/assets/demo.gif" width="400" alt="Demo GIF" />

## 📦 Installation

```yaml
dependencies:
  flutter_floating_particles: ^2.0.0
```

```dart
import 'package:flutter_floating_particles/flutter_floating_particles.dart';
```

## 🔧 Usage

### Wrap any widget with a preset

```dart
ParticleEffects(
  config: ParticleConfig.snow,
  child: YourWidget(),
)
```

Presets: `snow`, `rain`, `fireAshes`, `bubbles`, `stars`, `hearts`, `confetti`, `fallingLeaves`, `fireflies`, `starfield`.

To choose a preset at runtime (e.g. from a settings screen), use `ParticleEffectType`:

```dart
ParticleEffects(config: ParticleEffectType.values[index].config, child: ...)
```

### Tweak a preset

```dart
ParticleEffects(
  config: ParticleConfig.snow.copyWith(particleCount: 200, wind: 0.2),
  child: YourWidget(),
)
```

### Fully custom configuration

```dart
ParticleEffects(
  config: const ParticleConfig(
    particleType: ParticleType.star,
    direction: ParticleDirection.bottomToTop,
    particleCount: 60,
    minSize: 4,
    maxSize: 12,
    gradientColors: [Colors.amber, Colors.cyan, Colors.pinkAccent],
    enableGlow: true,
    enableRotation: true,
    velocityMultiplier: 0.8,
    edgeFade: 0.2,
  ),
  child: YourWidget(),
)
```

### Behind or in front of your content

Particles are painted on top by default. With `ParticleLayer.background` they are painted behind the child; the child needs a transparent background for them to show.

```dart
ParticleEffects(
  layer: ParticleLayer.background,
  config: ParticleConfig.stars,
  child: YourTransparentContent(),
)
```

### As a standalone layer

Without a `child`, `ParticleEffects` fills the available space, so you can position it anywhere, for example in a `Stack`:

```dart
Stack(
  children: [
    const Positioned.fill(child: ParticleEffects(config: ParticleConfig.fireflies)),
    YourContent(),
  ],
)
```

### Combine effects

Nest or stack several `ParticleEffects`:

```dart
ParticleEffects(
  config: ParticleConfig.rain,
  child: ParticleEffects(
    config: ParticleConfig.fallingLeaves,
    child: YourWidget(),
  ),
)
```

### Image particles

`imagePath` accepts an asset path or an `http(s)` URL, in any format Flutter decodes (PNG, JPG, GIF, WebP) or SVG:

```dart
const ParticleConfig(
  particleType: ParticleType.image,
  imagePath: 'assets/flutter_logo.png', // or 'https://example.com/heart.svg'
  minSize: 10,
  maxSize: 24,
  enableRotation: true,
)
```

Or use any `ImageProvider`, e.g. `MemoryImage`, `FileImage`, or one from another package. Set `particleColor` or `gradientColors` to tint the images.

```dart
ParticleConfig(
  particleType: ParticleType.image,
  image: const AssetImage('assets/flutter_logo.png'),
  gradientColors: const [Colors.amber, Colors.cyan],
)
```

Show something while images load, and preload them early to avoid the wait:

```dart
ParticleEffects(
  config: config,
  loadingWidget: const CircularProgressIndicator(),
  child: YourWidget(),
)

await ParticleEffects.preloadImages(['assets/a.png', 'https://example.com/b.png']);
```

### Custom shapes

Pass any `Path`, in any coordinates; it is scaled to the particle size. This is also an easy way to use SVG path data.

```dart
final bolt = Path()
  ..moveTo(14, 0)
  ..lineTo(2, 14)
  ..lineTo(10, 14)
  ..lineTo(6, 24)
  ..lineTo(18, 9)
  ..lineTo(10, 9)
  ..close();

ParticleConfig(
  particleType: ParticleType.path,
  customPath: bolt,
  particleColor: Colors.yellowAccent,
)
```

### Custom widget particles

The widget is rendered once, in a `maxSize` × `maxSize` box, and scaled for each particle. Use a `const` widget, or keep the same instance, so it isn't rendered again on every rebuild.

```dart
const ParticleConfig(
  particleType: ParticleType.custom,
  customParticle: Icon(Icons.ac_unit, color: Colors.white),
  minSize: 10,
  maxSize: 30,
)
```

### Bursts and the controller

`ParticleController` pauses and resumes the animation, and emits one-shot bursts that fly out and fall under gravity. Use `particleCount: 0` for an effect that only shows bursts:

```dart
final controller = ParticleController();

ParticleEffects(
  controller: controller,
  config: ParticleConfig.confetti.copyWith(particleCount: 0),
  child: YourWidget(),
)

// An explosion from the center
controller.burst(count: 80);

// A confetti cannon from the bottom-left corner, aimed up and to the right
controller.burst(
  alignment: Alignment.bottomLeft,
  angle: -pi / 3,
  spread: pi / 6,
  minSpeed: 600,
  maxSpeed: 1100,
);

controller.pause();
controller.resume();
controller.dispose(); // when you no longer need it
```

### Touch and mouse interaction

Particles can react to the pointer, while taps still reach your widgets:

```dart
ParticleEffects(
  interaction: ParticleInteraction.repel, // or .attract, .tapToBurst
  config: ParticleConfig.fireflies,
  child: YourWidget(),
)

// Or fine-tune it
const ParticleInteraction(
  mode: ParticleInteractionMode.attract,
  radius: 150,
  strength: 80,
  tapBurstCount: 20,
)
```

### Callbacks and accessibility

```dart
ParticleEffects(
  onAnimationComplete: () => debugPrint('cycle done'),
  respectReduceMotion: true, // default: freeze when the OS asks for reduced motion
  clipBehavior: Clip.hardEdge, // default: keep particles inside the widget
  child: YourWidget(),
)
```

## 📜 API Reference

### ParticleEffects

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `child` | `Widget?` | Widget to show particles over or behind. Fills the available space when null | `null` |
| `config` | `ParticleConfig` | How particles look and move | `ParticleConfig()` |
| `isEnabled` | `bool` | Show particles; when false nothing is painted or animated | `true` |
| `controller` | `ParticleController?` | Pause, resume and burst | `null` |
| `layer` | `ParticleLayer` | `foreground` or `background` | `foreground` |
| `interaction` | `ParticleInteraction?` | React to touch and mouse input | `null` |
| `respectReduceMotion` | `bool` | Freeze when the platform asks for reduced motion | `true` |
| `clipBehavior` | `Clip` | Clip particles to the widget bounds | `Clip.hardEdge` |
| `onAnimationComplete` | `VoidCallback?` | Called once per `animationDuration` | `null` |
| `loadingWidget` | `Widget?` | Shown while image or widget particles load | `null` |

Static helpers: `preloadImage`, `preloadImages`, `preloadImageProvider`, `preloadCustomWidget`, `preloadCustomWidgets`, `clearImageCache`.

### ParticleConfig

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `particleType` | `ParticleType` | Shape of the particles | `circle` |
| `direction` | `ParticleDirection` | How particles move | `topToBottom` |
| `particleCoverage` | `ParticleCoverage` | How far across the screen particles travel before fading out | `full` |
| `particleCount` | `int` | Number of continuously animated particles | `50` |
| `minSize` / `maxSize` | `double` | Particle size range in logical pixels | `2.0` / `6.0` |
| `enableSizeVariation` | `bool` | Vary sizes; when false all particles are `maxSize` | `true` |
| `animationDuration` | `Duration` | Time for an average particle to cross the screen | `10s` |
| `velocityMultiplier` | `double` | Speed multiplier | `1.0` |
| `particleColor` | `Color?` | Single color (tints images) | `null` (white) |
| `gradientColors` | `List<Color>?` | Palette each particle picks a random color from | `null` |
| `minOpacity` / `maxOpacity` | `double` | Opacity range | `0.3` / `1.0` |
| `enableOpacityAnimation` | `bool` | Twinkle between the opacities | `true` |
| `enableGlow` / `glowRadius` | `bool` / `double` | Soft halo around particles | `false` / `4.0` |
| `enableBlur` / `blurSigma` | `bool` / `double` | Blur the particles themselves | `false` / `1.0` |
| `enableRotation` / `rotationSpeed` | `bool` / `double` | Spin particles, with a speed multiplier | `false` / `1.0` |
| `wind` | `double` | Sideways drift per unit of travel; particles wrap around the edges | `0.0` |
| `driftAmplitude` | `double?` | Side-to-side wobble in pixels; `null` uses a default for the direction | `null` |
| `edgeFade` | `double` | Fraction of the path (0–0.5) to fade in and out over | `0.0` |
| `blendMode` | `BlendMode` | e.g. `BlendMode.plus` for glowing fire and sparks | `srcOver` |
| `seed` | `int?` | Different seeds give different particle layouts | `null` |
| `imagePath` | `String?` | Asset path or URL for `ParticleType.image` (PNG, JPG, GIF, WebP, SVG) | `null` |
| `image` | `ImageProvider?` | Any image provider for `ParticleType.image` | `null` |
| `customPath` | `Path?` | Shape for `ParticleType.path` | `null` |
| `customParticle` | `Widget?` | Widget for `ParticleType.custom` | `null` |

### Enums

```dart
enum ParticleType { circle, square, star, heart, leaf, streak, path, image, custom }

enum ParticleDirection {
  topToBottom, bottomToTop, leftToRight, rightToLeft, diagonal,
  none,   // wander in place
  radial, // fly outward from the center
}

enum ParticleCoverage { quarter, semiHalf, half, semiFull, full }

enum ParticleLayer { background, foreground }
```

## 🎯 Performance Tips

- Every particle is drawn in one batched call, so even hundreds of particles are cheap. Still, test on your lowest-end target device before shipping large counts.
- Glow and blur are pre-rendered once, so they cost almost nothing per frame.
- The animation pauses automatically when the effect is off screen in an inactive route (`TickerMode`), disabled, paused, or has nothing to animate.
- Reuse `ParticleConfig` objects (for example, `static const` configs) instead of building new ones with new widgets or paths in every `build`.

## 🔄 Migrating from 1.x

- `ParticlePainter` is no longer exported; use `ParticleEffects` (with or without a child).
- `ParticleType` and `ParticleDirection` have new values, so exhaustive `switch` statements over them need new cases.
- `velocityMultiplier`, `enableSizeVariation`, `onAnimationComplete` and `loadingWidget` now take effect, so effects that set them look or behave differently.
- Glow now adds a halo around a sharp particle instead of blurring the whole particle; use `enableBlur` for a soft look.
- The `rain` preset uses the new `streak` shape.

See the [changelog](CHANGELOG.md) for details.

## 📄 License

This package is licensed under the **MIT License**.

## 🙏 Support

If you like this package, ⭐ **Star it on [GitHub](https://github.com/nitesh695/flutter_floating_particles)**!
