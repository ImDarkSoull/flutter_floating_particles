import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../models/particle_config.dart';
import '../models/particle_interaction.dart';
import '../models/particle_layer.dart';
import '../models/particle_data.dart';
import '../models/particle_type.dart';
import '../rendering/particle_image_cache.dart';
import '../rendering/particle_shapes.dart';
import '../rendering/particle_sprite.dart';
import '../rendering/particle_system.dart';

part 'particle_controller.dart';

/// Paints animated particles over (or behind) a child widget.
///
/// The child remains fully interactive while particles animate. Without a
/// child, the widget fills the available space, so it can also be used as a
/// standalone layer, e.g. inside a [Stack].
///
/// Example usage:
/// ```dart
/// ParticleEffects(
///   config: ParticleConfig.snow,
///   child: Scaffold(
///     body: YourContent(),
///   ),
/// )
/// ```
///
/// Stack several [ParticleEffects] to combine effects, use a
/// [ParticleController] to pause, resume or burst particles, and
/// [interaction] to make particles react to touch.
class ParticleEffects extends StatefulWidget {
  /// The widget to show particles over or behind.
  final Widget? child;

  /// Configuration defining the particle animation behavior
  final ParticleConfig config;

  /// Whether particles are shown. When false, nothing is painted and the
  /// animation stops.
  final bool isEnabled;

  /// Optional controller to pause, resume and burst particles.
  final ParticleController? controller;

  /// Whether particles are painted behind or in front of [child].
  final ParticleLayer layer;

  /// Makes particles react to touch and mouse input (optional).
  final ParticleInteraction? interaction;

  /// Whether to freeze particles when the platform asks for reduced motion
  /// (see [MediaQueryData.disableAnimations]).
  final bool respectReduceMotion;

  /// How particles that extend past this widget's bounds are clipped.
  final Clip clipBehavior;

  /// Callback triggered each time the animation completes a cycle
  /// ([ParticleConfig.animationDuration]) (optional)
  final VoidCallback? onAnimationComplete;

  /// Widget shown centered over [child] while image or custom widget
  /// particles are loading (optional)
  final Widget? loadingWidget;

  /// Creates a particle effect.
  const ParticleEffects({
    super.key,
    this.child,
    this.config = const ParticleConfig(),
    this.isEnabled = true,
    this.controller,
    this.layer = ParticleLayer.foreground,
    this.interaction,
    this.respectReduceMotion = true,
    this.clipBehavior = Clip.hardEdge,
    this.onAnimationComplete,
    this.loadingWidget,
  });

  @override
  State<ParticleEffects> createState() => _ParticleEffectsState();

  /// Preloads particle images (asset paths or URLs) to ensure smooth
  /// animation. Call this method early in your app to preload images.
  static Future<void> preloadImages(List<String> imagePaths) async {
    await Future.wait(imagePaths.map(preloadImage));
  }

  /// Preloads a single particle image (asset path or URL).
  ///
  /// An image that previously failed to load is retried.
  static Future<void> preloadImage(String imagePath) async {
    final image = await ParticleImageCache.loadPath(
      imagePath,
      _defaultImageConfiguration(),
      retryFailed: true,
    );
    image?.dispose();
  }

  /// Preloads an [ImageProvider] used as [ParticleConfig.image].
  static Future<void> preloadImageProvider(ImageProvider provider) async {
    final image = await ParticleImageCache.loadProvider(
      provider,
      _defaultImageConfiguration(),
      retryFailed: true,
    );
    image?.dispose();
  }

  /// Preloads custom widgets for particle effects.
  /// Call this method early in your app to preload custom widgets.
  static Future<void> preloadCustomWidgets(
    List<Widget> widgets,
    double size,
  ) async {
    await Future.wait(widgets.map((w) => preloadCustomWidget(w, size)));
  }

  /// Preloads a single custom widget, rendered in a [size] x [size] box.
  /// Use the particle config's `maxSize` so the preloaded image is reused.
  static Future<void> preloadCustomWidget(Widget widget, double size) async {
    final view = _defaultView();
    if (view == null) return;
    final image = await ParticleImageCache.loadWidget(
      widget,
      size,
      view,
      retryFailed: true,
    );
    image?.dispose();
  }

  /// Clears all cached particle images to free memory.
  ///
  /// Effects that are currently showing keep working; their images are
  /// loaded again the next time they are needed.
  static void clearImageCache() {
    ParticleImageCache.clear();
  }

  static ui.FlutterView? _defaultView() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    return dispatcher.implicitView ?? dispatcher.views.firstOrNull;
  }

  static ImageConfiguration _defaultImageConfiguration() {
    return ImageConfiguration(
      devicePixelRatio: _defaultView()?.devicePixelRatio,
      platform: defaultTargetPlatform,
    );
  }
}

class _ParticleEffectsState extends State<ParticleEffects>
    with SingleTickerProviderStateMixin {
  late final ParticleSystem _system = ParticleSystem(config: widget.config);
  late final ParticlePainter _painter = ParticlePainter(_system);
  late final Ticker _ticker;

  /// Ticker time at the previous frame
  Duration _lastElapsed = Duration.zero;

  ParticleSprite? _sprite;

  /// Identifies what [_sprite] was built from, to skip needless rebuilds
  Object? _spriteKey;

  /// Incremented on each sprite load so that a stale load is ignored
  int _loadGeneration = 0;

  bool _isLoading = false;
  bool _reduceMotion = false;

  /// Number of completed cycles already reported to onAnimationComplete
  int _reportedCycles = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _system.interaction = widget.interaction;
    _generateParticles();
    widget.controller?._attach(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = _readReduceMotion();
    _prepareSprite();
    _updateTicker();
  }

  @override
  void didUpdateWidget(ParticleEffects oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }

    _system.interaction = widget.interaction;
    if (widget.interaction == null) _system.pointer = null;

    if (oldWidget.config != widget.config) {
      // Keep the animation phase when the cycle duration changes, so
      // particles don't jump
      final oldMs = oldWidget.config.animationDuration.inMilliseconds;
      final newMs = widget.config.animationDuration.inMilliseconds;
      if (oldMs > 0 && newMs > 0 && oldMs != newMs) {
        _system.seconds *= newMs / oldMs;
      }
      _system.config = widget.config;
      _generateParticles();
      _prepareSprite();
    }

    if (oldWidget.respectReduceMotion != widget.respectReduceMotion) {
      _reduceMotion = _readReduceMotion();
    }

    if (!widget.isEnabled && oldWidget.isEnabled) {
      _system.clearBursts();
    }

    _updateTicker();
    _system.markNeedsPaint();
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _ticker.dispose();
    _sprite?.dispose();
    _system.dispose();
    super.dispose();
  }

  bool _readReduceMotion() {
    return widget.respectReduceMotion &&
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
  }

  /// Generates all particles based on the current configuration.
  void _generateParticles() {
    final config = widget.config;
    _system.particles = List.generate(
      config.particleCount,
      (i) => ParticleData.generate(i, config),
      growable: false,
    );
  }

  bool get _shouldAnimate =>
      widget.isEnabled &&
      !_reduceMotion &&
      !(widget.controller?.isPaused ?? false) &&
      _system.sprite != null &&
      (_system.particles.isNotEmpty || _system.hasBursts);

  /// Starts or stops the ticker to match [_shouldAnimate].
  void _updateTicker() {
    final shouldAnimate = _shouldAnimate;
    if (shouldAnimate && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (!shouldAnimate && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    // Clamp so a long pause between frames doesn't make particles jump
    final dt = min((elapsed - _lastElapsed).inMicroseconds / 1e6, 0.1);
    _lastElapsed = elapsed;
    _system.advance(dt);

    final cycles = _system.cycles.floor();
    if (cycles > _reportedCycles) {
      _reportedCycles = cycles;
      widget.onAnimationComplete?.call();
    }

    // Burst-only effects stop ticking once the last burst has faded
    if (_system.particles.isEmpty && !_system.hasBursts) {
      _updateTicker();
    }
  }

  void _onControllerChanged() {
    _updateTicker();
  }

  void _burst(BurstRequest request) {
    if (!widget.isEnabled || _reduceMotion) return;
    _system.addBurst(request);
    _updateTicker();
  }

  /// Builds (or starts loading) the sprite for the current configuration.
  void _prepareSprite() {
    final config = widget.config;
    final devicePixelRatio =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    final resolution = (config.maxSize * devicePixelRatio).clamp(16.0, 256.0);

    // Glow and blur sigmas are given for a particle of average size; convert
    // them to sprite pixels.
    final averageSize = (config.minSize + config.maxSize) / 2;
    final pixelsPerLogical = resolution / averageSize;
    // The halo is kept within about the particle's own size, so it doesn't
    // spread too thin to see
    final glowSigma = config.enableGlow
        ? min(config.glowRadius * pixelsPerLogical, resolution * 0.6)
        : 0.0;
    final blurSigma = config.enableBlur
        ? min(config.blurSigma * pixelsPerLogical, resolution)
        : 0.0;

    final source = _spriteSource(config);
    final key = (source, resolution, glowSigma, blurSigma);
    if (key == _spriteKey) return;
    _spriteKey = key;
    final generation = ++_loadGeneration;

    ParticleSprite fromPath(Path path) => ParticleSprite.fromPath(
      path,
      resolution: resolution,
      glowSigma: glowSigma,
      blurSigma: blurSigma,
    );

    if (source is ParticleType) {
      _setSprite(fromPath(ParticleShapes.forType(source)!));
      _isLoading = false;
      return;
    }
    if (source is Path) {
      _setSprite(fromPath(ParticleShapes.normalize(source)));
      _isLoading = false;
      return;
    }

    // Hide particles until the image is ready. Set synchronously: this runs
    // from didChangeDependencies or didUpdateWidget, and both are followed
    // by a build.
    _setSprite(null);
    _isLoading = true;

    _loadSourceImage(source).then((image) {
      if (!mounted || generation != _loadGeneration) {
        image?.dispose();
        return;
      }
      // Fall back to circles if the image could not be loaded
      final sprite = image == null
          ? fromPath(ParticleShapes.circle)
          : ParticleSprite.fromImage(
              image,
              resolution: resolution,
              glowSigma: glowSigma,
              blurSigma: blurSigma,
            );
      image?.dispose();
      setState(() {
        _setSprite(sprite);
        _isLoading = false;
      });
      _updateTicker();
    });
  }

  /// What the sprite is drawn from: a [ParticleType] for built-in shapes, a
  /// [Path], an [ImageProvider], an image path [String] or a [Widget].
  Object _spriteSource(ParticleConfig config) {
    switch (config.particleType) {
      case ParticleType.path:
        return config.customPath ?? ParticleType.circle;
      case ParticleType.image:
        return config.image ?? config.imagePath ?? ParticleType.circle;
      case ParticleType.custom:
        return config.customParticle ?? ParticleType.circle;
      case ParticleType.circle:
      case ParticleType.square:
      case ParticleType.star:
      case ParticleType.heart:
      case ParticleType.leaf:
      case ParticleType.streak:
        return config.particleType;
    }
  }

  Future<ui.Image?> _loadSourceImage(Object source) {
    if (source is Widget) {
      return ParticleImageCache.loadWidget(
        source,
        widget.config.maxSize,
        View.of(context),
      );
    }
    final configuration = createLocalImageConfiguration(context);
    if (source is ImageProvider) {
      return ParticleImageCache.loadProvider(source, configuration);
    }
    return ParticleImageCache.loadPath(source as String, configuration);
  }

  void _setSprite(ParticleSprite? sprite) {
    final old = _sprite;
    _sprite = sprite;
    _system.sprite = sprite;
    old?.dispose();
    _system.markNeedsPaint();
  }

  void _handlePointer(PointerEvent event) {
    if (widget.interaction == null || !widget.isEnabled) return;
    _system.pointer = event.localPosition;
    _system.markNeedsPaint();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _handlePointer(event);
    final count = widget.interaction?.tapBurstCount ?? 0;
    if (count > 0) {
      _burst(
        BurstRequest(
          position: event.localPosition,
          count: count,
          minSpeed: 80,
          maxSpeed: 300,
          gravity: 300,
          lifespan: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  void _handlePointerEnd(PointerEvent event) {
    // A mouse keeps hovering after a click; touches and styluses leave
    if (event.kind == PointerDeviceKind.mouse) return;
    _clearPointer();
  }

  void _clearPointer() {
    if (_system.pointer == null) return;
    _system.pointer = null;
    _system.markNeedsPaint();
  }

  @override
  Widget build(BuildContext context) {
    Widget? particles;
    if (widget.isEnabled) {
      Widget painter = RepaintBoundary(
        child: CustomPaint(painter: _painter, size: Size.infinite),
      );
      if (widget.clipBehavior != Clip.none) {
        painter = ClipRect(clipBehavior: widget.clipBehavior, child: painter);
      }
      particles = Positioned.fill(
        key: const ValueKey('particles'),
        child: IgnorePointer(child: painter),
      );
    }

    // Keys keep the child's state when particles are toggled or moved
    // between layers
    final content = KeyedSubtree(
      key: const ValueKey('child'),
      child: widget.child ?? const SizedBox.expand(),
    );

    return MouseRegion(
      opaque: false,
      onExit: (_) => _clearPointer(),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointer,
        onPointerHover: _handlePointer,
        onPointerUp: _handlePointerEnd,
        onPointerCancel: _handlePointerEnd,
        child: Stack(
          children: [
            if (particles != null && widget.layer == ParticleLayer.background)
              particles,
            content,
            if (particles != null && widget.layer == ParticleLayer.foreground)
              particles,

            // Loading indicator for image/custom widget particles
            if (widget.isEnabled && _isLoading && widget.loadingWidget != null)
              Positioned.fill(
                key: const ValueKey('loading'),
                child: IgnorePointer(
                  child: Center(child: widget.loadingWidget),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
