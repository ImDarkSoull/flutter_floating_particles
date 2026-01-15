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

  /// Callback triggered when animation completes a cycle (optional)
  final VoidCallback? onAnimationComplete;

  /// Widget to show while images are loading (only for image particles)
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
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  final List<ParticleData> _particles = [];
  bool _isInitialized = false;

  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _setupAnimation();
    _initializeParticles();
  }

  /// Initialize particles with image/widget preloading if needed
  void _initializeParticles() async {
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
      try {
        if (widget.config.particleType == ParticleType.image &&
            widget.config.imagePath != null) {
          await ParticlePainter.preloadImage(widget.config.imagePath!);
        }

        if (widget.config.particleType == ParticleType.custom &&
            widget.config.customParticle != null) {
          // Preload widget with average particle size
          final avgSize = (widget.config.minSize + widget.config.maxSize) / 2;
          await ParticlePainter.preloadCustomWidget(
            widget.config.customParticle!,
            avgSize,
          );
        }
      } catch (e) {
        debugPrint('Error preloading particle resources: $e');
      }
    }

    _generateParticles();
    setState(() {
      _isInitialized = true;
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

    if (widget.isEnabled) {
      _animationController.repeat();
    }
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
        _generateParticles();
      }

      // Update animation duration if it changed
      if (oldWidget.config.animationDuration !=
          widget.config.animationDuration) {
        _animationController.duration = widget.config.animationDuration;
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
                        screenSize: MediaQuery.of(context).size,
                        startTime: _startTime,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Predefined particle effect types for SimpleParticleEffects.
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
