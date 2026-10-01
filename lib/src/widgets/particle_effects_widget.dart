import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../models/particle_collision.dart';
import '../models/particle_config.dart';
import '../models/particle_data.dart';
import '../models/particle_interaction.dart';
import '../models/particle_layer.dart';
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

  /// Offset that particles shift by (times [ParticleConfig.parallaxFactor]),
  /// e.g. a [ScrollParallax] or tilt readings (optional).
  final ValueListenable<Offset>? parallax;

  /// Widgets that particles land on (or hide behind) and bounce off, such as
  /// cards that collect snow. See [collision].
  final List<GlobalKey> colliders;

  /// How particles react to [colliders].
  final ParticleCollision collision;

  /// Called when a particle is tapped (optional). Combine with
  /// [ParticleInteraction.popOnTap] to pop tapped particles.
  final ValueChanged<ParticleTapDetails>? onParticleTap;

  /// Whether to draw fewer particles when frames take too long, and more
  /// again once the device keeps up.
  final bool adaptiveQuality;

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
    this.parallax,
    this.colliders = const [],
    this.collision = const ParticleCollision(),
    this.onParticleTap,
    this.adaptiveQuality = false,
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

  ParticleAtlas? _atlas;

  /// What [_atlas] was built from, to skip needless rebuilds
  List<Object>? _atlasSources;
  (double, double, double)? _atlasSettings;

  /// Incremented on each atlas load so that a stale load is ignored
  int _loadGeneration = 0;

  bool _isLoading = false;
  bool _reduceMotion = false;

  /// Number of completed cycles already reported to onAnimationComplete
  int _reportedCycles = 0;

  // Adaptive quality
  bool _listeningToTimings = false;
  double _frameBudgetMicros = 1e6 / 60;
  double _averageFrameMicros = 0;
  int _slowFrames = 0;
  int _fastFrames = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _system.interaction = widget.interaction;
    _system.collision = widget.collision;
    _generateParticles();
    widget.controller?._attach(this);
    widget.parallax?.addListener(_onParallaxChanged);
    _onParallaxChanged();
    _updateTimingsListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = _readReduceMotion();
    final refreshRate = View.maybeOf(context)?.display.refreshRate ?? 60;
    _frameBudgetMicros = 1e6 / (refreshRate > 0 ? refreshRate : 60);
    _prepareAtlas();
    _updateTicker();
  }

  @override
  void didUpdateWidget(ParticleEffects oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.parallax != widget.parallax) {
      oldWidget.parallax?.removeListener(_onParallaxChanged);
      widget.parallax?.addListener(_onParallaxChanged);
      _onParallaxChanged();
    }

    _system.interaction = widget.interaction;
    _system.collision = widget.collision;
    if (!_tracksPointer) _system.pointer = null;
    if (widget.colliders.isEmpty) _system.colliderRects = const [];

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
      _prepareAtlas();
    }

    if (oldWidget.respectReduceMotion != widget.respectReduceMotion) {
      _reduceMotion = _readReduceMotion();
    }

    if (!widget.isEnabled && oldWidget.isEnabled) {
      _system.clearBursts();
    }

    _updateTimingsListener();
    _updateTicker();
    _system.markNeedsPaint();
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    widget.parallax?.removeListener(_onParallaxChanged);
    if (_listeningToTimings) {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    }
    _ticker.dispose();
    _atlas?.dispose();
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

  bool get _isPaused => widget.controller?.isPaused ?? false;

  bool get _shouldAnimate =>
      widget.isEnabled &&
      !_reduceMotion &&
      !_isPaused &&
      _system.atlas != null &&
      (_system.particles.isNotEmpty ||
          _system.hasBursts ||
          _system.hasEmitters);

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
    final frameTime = min((elapsed - _lastElapsed).inMicroseconds / 1e6, 0.1);
    _lastElapsed = elapsed;
    final timeScale = widget.controller?.timeScale ?? 1.0;

    _resolveWidgetRects();
    _system.advance(frameTime * timeScale);

    final cycles = _system.cycles.floor();
    if (cycles > _reportedCycles) {
      _reportedCycles = cycles;
      widget.onAnimationComplete?.call();
    }

    // Burst-only effects stop ticking once the last burst has faded
    if (_system.particles.isEmpty &&
        !_system.hasBursts &&
        !_system.hasEmitters) {
      _updateTicker();
    }
  }

  /// Updates collider and emitter-follow bounds from their widgets.
  void _resolveWidgetRects() {
    final colliders = widget.colliders;
    if (colliders.isNotEmpty) {
      _system.colliderRects = [for (final key in colliders) ?_rectOf(key)];
    }
    final emitters = widget.config.emitters;
    if (emitters != null && emitters.any((e) => e.followKey != null)) {
      _system.emitterRects = [
        for (final emitter in emitters)
          emitter.followKey == null ? null : _rectOf(emitter.followKey!),
      ];
    }
  }

  /// The bounds of the widget with [key] in this widget's coordinates.
  Rect? _rectOf(GlobalKey key) {
    final target = key.currentContext?.findRenderObject();
    final self = context.findRenderObject();
    if (target is! RenderBox ||
        self is! RenderBox ||
        !target.attached ||
        !target.hasSize ||
        !self.hasSize) {
      return null;
    }
    return MatrixUtils.transformRect(
      target.getTransformTo(self),
      Offset.zero & target.size,
    );
  }

  void _onParallaxChanged() {
    _system.parallax = widget.parallax?.value ?? Offset.zero;
    _system.markNeedsPaint();
  }

  void _onControllerChanged() {
    _updateTicker();
  }

  void _burst(BurstRequest request) {
    if (!widget.isEnabled || _reduceMotion) return;
    _system.addBurst(request);
    _updateTicker();
  }

  void _fireworks(FireworksRequest request) {
    if (!widget.isEnabled || _reduceMotion) return;
    _system.addFireworks(request);
    _updateTicker();
  }

  void _updateTimingsListener() {
    final shouldListen = widget.adaptiveQuality;
    if (shouldListen == _listeningToTimings) return;
    _listeningToTimings = shouldListen;
    if (shouldListen) {
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
    } else {
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
      _system.qualityFactor = 1.0;
    }
  }

  /// Lowers the particle count while frames miss their budget, and raises
  /// it again once they comfortably fit.
  void _onTimings(List<FrameTiming> timings) {
    if (!_ticker.isActive) return;
    for (final timing in timings) {
      final micros = timing.totalSpan.inMicroseconds.toDouble();
      _averageFrameMicros = _averageFrameMicros == 0
          ? micros
          : _averageFrameMicros * 0.9 + micros * 0.1;
      if (_averageFrameMicros > _frameBudgetMicros) {
        _slowFrames++;
        _fastFrames = 0;
      } else if (_averageFrameMicros < _frameBudgetMicros * 0.6) {
        _fastFrames++;
        _slowFrames = 0;
      }
    }
    if (_slowFrames >= 30) {
      _slowFrames = 0;
      _system.qualityFactor = max(0.25, _system.qualityFactor * 0.85);
    } else if (_fastFrames >= 120) {
      _fastFrames = 0;
      _system.qualityFactor = min(1.0, _system.qualityFactor * 1.1);
    }
  }

  /// Builds (or starts loading) the sprites for the current configuration.
  void _prepareAtlas() {
    final config = widget.config;
    final devicePixelRatio =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    final resolution = (config.maxSize * devicePixelRatio).clamp(16.0, 256.0);

    // Glow and blur sigmas are given for a particle of average size; convert
    // them to sprite pixels. The halo is kept within about the particle's
    // own size, so it doesn't spread too thin to see.
    final averageSize = (config.minSize + config.maxSize) / 2;
    final pixelsPerLogical = resolution / averageSize;
    final glowSigma = config.enableGlow
        ? min(config.glowRadius * pixelsPerLogical, resolution * 0.6)
        : 0.0;
    final blurSigma = config.enableBlur
        ? min(config.blurSigma * pixelsPerLogical, resolution)
        : 0.0;

    final sources = _spriteSources(config);
    final settings = (resolution, glowSigma, blurSigma);
    if (listEquals(sources, _atlasSources) && settings == _atlasSettings) {
      return;
    }
    _atlasSources = sources;
    _atlasSettings = settings;
    final generation = ++_loadGeneration;

    ParticleSprite fromPath(Path path) => ParticleSprite.fromPath(
      path,
      resolution: resolution,
      glowSigma: glowSigma,
      blurSigma: blurSigma,
    );
    ParticleSprite spriteFor(Object source, ui.Image? image) {
      if (source is ParticleType) {
        return fromPath(ParticleShapes.forType(source)!);
      }
      if (source is Path) return fromPath(ParticleShapes.normalize(source));
      // Fall back to circles if an image could not be loaded
      if (image == null) return fromPath(ParticleShapes.circle);
      return ParticleSprite.fromImage(
        image,
        resolution: resolution,
        glowSigma: glowSigma,
        blurSigma: blurSigma,
      );
    }

    ParticleAtlas pack(List<ui.Image?> images) => ParticleAtlas.pack([
      for (int i = 0; i < sources.length; i++) spriteFor(sources[i], images[i]),
    ], ParticleSprite.fromPath(ParticleShapes.circle, resolution: 32));

    final needsLoading = sources.any((s) => s is! ParticleType && s is! Path);
    if (!needsLoading) {
      _setAtlas(pack(List.filled(sources.length, null)));
      _isLoading = false;
      return;
    }

    // Hide particles until the images are ready. Set synchronously: this
    // runs from didChangeDependencies or didUpdateWidget, and both are
    // followed by a build.
    _setAtlas(null);
    _isLoading = true;

    final futures = [
      for (final source in sources)
        source is ParticleType || source is Path
            ? Future<ui.Image?>.value(null)
            : _loadSourceImage(source),
    ];
    Future.wait(futures).then((images) {
      if (!mounted || generation != _loadGeneration) {
        for (final image in images) {
          image?.dispose();
        }
        return;
      }
      final atlas = pack(images);
      for (final image in images) {
        image?.dispose();
      }
      setState(() {
        _setAtlas(atlas);
        _isLoading = false;
      });
      _updateTicker();
    });
  }

  /// What each sprite is drawn from: a [ParticleType] for built-in shapes, a
  /// [Path], an [ImageProvider], an image path [String] or a [Widget].
  List<Object> _spriteSources(ParticleConfig config) {
    final types = config.particleTypes;
    final sources = <Object>[];
    for (final type
        in (types == null || types.isEmpty) ? [config.particleType] : types) {
      switch (type) {
        case ParticleType.path:
          sources.add(config.customPath ?? ParticleType.circle);
        case ParticleType.image:
          final images = config.images;
          if (images != null && images.isNotEmpty) {
            sources.addAll(images);
          } else {
            sources.add(
              config.image ?? config.imagePath ?? ParticleType.circle,
            );
          }
        case ParticleType.custom:
          sources.add(config.customParticle ?? ParticleType.circle);
        default:
          sources.add(type);
      }
    }
    return sources;
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

  void _setAtlas(ParticleAtlas? atlas) {
    final old = _atlas;
    _atlas = atlas;
    _system.atlas = atlas;
    final sources = _atlasSources ?? const [];
    _system.alignedSprites = {
      for (int i = 0; i < sources.length; i++)
        if (sources[i] == ParticleType.streak) i,
    };
    old?.dispose();
    _system.markNeedsPaint();
  }

  /// Whether pointer positions are needed.
  bool get _tracksPointer =>
      widget.interaction != null ||
      (widget.config.connections?.connectPointer ?? false);

  void _handlePointer(PointerEvent event) {
    if (!_tracksPointer || !widget.isEnabled) return;
    _system.pointer = event.localPosition;
    _system.markNeedsPaint();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _handlePointer(event);
    if (!widget.isEnabled) return;
    final interaction = widget.interaction;

    if (widget.onParticleTap != null || (interaction?.popOnTap ?? false)) {
      final details = (interaction?.popOnTap ?? false)
          ? _system.popAt(event.localPosition)
          : _system.particleAt(event.localPosition);
      if (details != null) {
        widget.onParticleTap?.call(details);
        _updateTicker();
        // A popped particle takes the tap instead of a new burst
        if (interaction?.popOnTap ?? false) return;
      }
    }

    final count = interaction?.tapBurstCount ?? 0;
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

  void _handlePointerMove(PointerMoveEvent event) {
    _handlePointer(event);
    final count = widget.interaction?.emitOnDrag ?? 0;
    if (count > 0 && widget.isEnabled && !_reduceMotion) {
      _system.emitAt(event.localPosition, count);
      _updateTicker();
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
        onPointerMove: _handlePointerMove,
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
