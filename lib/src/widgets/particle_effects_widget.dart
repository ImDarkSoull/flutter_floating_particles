import 'package:flutter/material.dart';
import '../../flutter_floating_particles.dart';

/// The main widget that wraps any child widget with particle effects.
///
/// This widget creates an animated overlay of particles that move across
/// the screen according to the provided configuration. The child widget
/// remains fully interactive while particles animate in the background.
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
class ParticleEffects extends StatefulWidget {
  /// The child widget to wrap with particle effects
  final Widget child;

  /// Configuration defining the particle animation behavior
  final ParticleConfig config;

  /// Whether the particle animation is currently enabled
  final bool isEnabled;

  /// Callback triggered each time the animation completes a cycle
  /// ([ParticleConfig.animationDuration]) (optional)
  final VoidCallback? onAnimationComplete;

  /// Widget shown centered over [child] while image or custom widget
  /// particles are loading (optional)
  final Widget? loadingWidget;

  const ParticleEffects({
    super.key,
    required this.child,
    this.config = const ParticleConfig(),
    this.isEnabled = true,
    this.onAnimationComplete,
    this.loadingWidget,
  });

  @override
  State<ParticleEffects> createState() => _ParticleEffectsState();

  /// Preloads particle images to ensure smooth animation
  /// Call this method early in your app to preload images
  static Future<void> preloadImages(List<String> imagePaths) async {
    final futures = imagePaths.map(
      (path) => ParticlePainter.preloadImage(path),
    );
    await Future.wait(futures);
  }

  /// Preloads a single particle image
  static Future<void> preloadImage(String imagePath) async {
    await ParticlePainter.preloadImage(imagePath);
  }

  /// Preloads custom widgets for particle effects
  /// Call this method early in your app to preload custom widgets
  static Future<void> preloadCustomWidgets(
    List<Widget> widgets,
    double size,
  ) async {
    final futures = widgets.map(
      (widget) => ParticlePainter.preloadCustomWidget(widget, size),
    );
    await Future.wait(futures);
  }

  /// Preloads a single custom widget
  static Future<void> preloadCustomWidget(Widget widget, double size) async {
    await ParticlePainter.preloadCustomWidget(widget, size);
  }

  /// Clears all cached particle images to free memory
  static void clearImageCache() {
    ParticlePainter.clearImageCache();
  }
}

class _ParticleEffectsState extends State<ParticleEffects>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final List<ParticleData> _particles = [];
  bool _isInitialized = false;
  bool _isLoading = false;

  /// Incremented on each load so that a stale load finishing late is ignored
  int _loadGeneration = 0;

  late DateTime _startTime;

  /// Number of completed cycles already reported to onAnimationComplete
  int _reportedCycles = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _setupAnimation();
    _initializeParticles();
  }

  /// Initialize particles with image/widget preloading if needed
  Future<void> _initializeParticles() async {
    final generation = ++_loadGeneration;
    bool needsLoading = false;

    // Check if we need to preload an image
    if (widget.config.particleType == ParticleType.image &&
        widget.config.imagePath != null) {
      needsLoading = true;
    }

    // Check if we need to preload a custom widget
    if (widget.config.particleType == ParticleType.custom &&
        widget.config.customParticle != null) {
      needsLoading = true;
    }

    if (needsLoading) {
      // Set synchronously: this runs from initState or didUpdateWidget, and
      // both are followed by a build.
      _isLoading = true;
      try {
        if (widget.config.particleType == ParticleType.image &&
            widget.config.imagePath != null) {
          await ParticlePainter.preloadImage(widget.config.imagePath!);
        }

        if (widget.config.particleType == ParticleType.custom &&
            widget.config.customParticle != null) {
          // Render at the largest particle size; smaller ones scale down
          await ParticlePainter.preloadCustomWidget(
            widget.config.customParticle!,
            widget.config.maxSize,
          );
        }
      } catch (e) {
        debugPrint('Error preloading particle resources: $e');
      }
    }

    // The widget was disposed, or a newer config started loading meanwhile
    if (!mounted || generation != _loadGeneration) return;

    _generateParticles();
    setState(() {
      _isInitialized = true;
      _isLoading = false;
    });
  }

  /// Sets up the animation controller and animation curve.
  void _setupAnimation() {
    _animationController = AnimationController(
      duration: widget.config.animationDuration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _animationController.addListener(_reportCompletedCycles);

    if (widget.isEnabled) {
      _animationController.repeat();
    }
  }

  /// Calls [ParticleEffects.onAnimationComplete] once per completed cycle.
  ///
  /// Cycles are counted from [_startTime], the same clock the painter uses.
  void _reportCompletedCycles() {
    final callback = widget.onAnimationComplete;
    final cycles = _elapsedCycles();
    if (cycles > _reportedCycles) {
      _reportedCycles = cycles;
      callback?.call();
    }
  }

  int _elapsedCycles() {
    final durationMs = widget.config.animationDuration.inMilliseconds;
    if (durationMs <= 0) return 0;
    return DateTime.now().difference(_startTime).inMilliseconds ~/ durationMs;
  }

  /// Generates all particles based on the current configuration.
  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < widget.config.particleCount; i++) {
      _particles.add(ParticleData.generate(i, widget.config));
    }
  }

  @override
  void didUpdateWidget(ParticleEffects oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle image/widget path changes
    bool needsImageReload = false;
    bool needsWidgetReload = false;

    if (oldWidget.config.particleType != widget.config.particleType ||
        oldWidget.config.imagePath != widget.config.imagePath) {
      needsImageReload =
          widget.config.particleType == ParticleType.image &&
          widget.config.imagePath != null;
    }

    if (oldWidget.config.particleType != widget.config.particleType ||
        oldWidget.config.customParticle != widget.config.customParticle) {
      needsWidgetReload =
          widget.config.particleType == ParticleType.custom &&
          widget.config.customParticle != null;
    }

    // Regenerate particles if configuration changed
    if (oldWidget.config != widget.config) {
      if (needsImageReload || needsWidgetReload) {
        _initializeParticles(); // This will handle image/widget loading
      } else {
        // Supersede any load still in progress for the previous config
        _loadGeneration++;
        _isLoading = false;
        _generateParticles();
      }

      // Update animation duration if it changed
      if (oldWidget.config.animationDuration !=
          widget.config.animationDuration) {
        _animationController.duration = widget.config.animationDuration;
        _reportedCycles = _elapsedCycles();
      }
    }

    // Handle enable/disable state changes
    if (oldWidget.isEnabled != widget.isEnabled) {
      if (widget.isEnabled) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.removeListener(_reportCompletedCycles);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Child widget (the content being wrapped)
        widget.child,

        // Particle overlay
        if (widget.isEnabled && _isInitialized)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: ParticlePainter(
                        particles: _particles,
                        animation: _animation,
                        config: widget.config,
                        startTime: _startTime,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
            ),
          ),

        // Loading indicator for image/custom widget particles
        if (widget.isEnabled && _isLoading && widget.loadingWidget != null)
          Positioned.fill(
            child: IgnorePointer(child: Center(child: widget.loadingWidget)),
          ),
      ],
    );
  }
}

/// Names of the predefined effects available as [ParticleConfig] presets.
enum ParticleEffectType {
  snow,
  rain,
  fireAshes,
  bubbles,
  stars,
  hearts,
  confetti,
  fallingLeaves,
}
