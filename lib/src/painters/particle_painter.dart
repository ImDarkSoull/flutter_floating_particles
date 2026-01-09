import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../models/particle_config.dart';
import '../models/particle_data.dart';
import '../models/particle_type.dart';
import '../models/direction.dart';

/// Custom painter responsible for rendering all particles on the canvas.
///
/// This painter efficiently draws hundreds of particles using Flutter's
/// CustomPainter API, providing smooth 60fps animations.
class ParticlePainter extends CustomPainter {
  /// List of all particles to render
  final List<ParticleData> particles;

  /// Current animation progress (0.0 to 1.0)
  final Animation<double> animation;

  /// Configuration defining how particles should look and behave
  final ParticleConfig config;

  /// Screen dimensions for positioning calculations
  final Size screenSize;

  /// Start time for time-based animation
  final DateTime startTime;

  /// Cache for loaded images
  static final Map<String, ui.Image> _imageCache = {};

  /// Loading states for images
  static final Map<String, bool> _imageLoadingStates = {};

  /// Cache for custom widget images
  static final Map<String, ui.Image> _customWidgetCache = {};

  /// Loading states for custom widgets
  static final Map<String, bool> _customWidgetLoadingStates = {};

  const ParticlePainter({
    required this.particles,
    required this.animation,
    required this.config,
    required this.screenSize,
    required this.startTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Preload image if needed
    if (config.particleType == ParticleType.image &&
        config.imagePath != null &&
        !_imageCache.containsKey(config.imagePath!) &&
        !(_imageLoadingStates[config.imagePath!] ?? false)) {
      _loadImage(config.imagePath!);
    }

    // Draw each particle
    for (final particle in particles) {
      _drawParticle(canvas, size, particle);
    }
  }

  /// Loads an image from assets and caches it
  static Future<void> _loadImage(String imagePath) async {
    if (_imageLoadingStates[imagePath] == true) return;

    _imageLoadingStates[imagePath] = true;

    try {
      final ByteData data = await rootBundle.load(imagePath);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      _imageCache[imagePath] = frameInfo.image;
    } catch (e) {
      debugPrint('Error loading image $imagePath: $e');
    } finally {
      _imageLoadingStates[imagePath] = false;
    }
  }

  /// Converts a widget to an image and caches it
  static Future<void> _loadCustomWidget(Widget widget, double size) async {
    final String widgetKey = '${widget.runtimeType}_${size.round()}';

    if (_customWidgetLoadingStates[widgetKey] == true) return;

    _customWidgetLoadingStates[widgetKey] = true;

    try {
      final ui.Image image = await _widgetToImage(widget, size);
      _customWidgetCache[widgetKey] = image;
    } catch (e) {
      debugPrint('Error converting widget to image: $e');
    } finally {
      _customWidgetLoadingStates[widgetKey] = false;
    }
  }

  /// Converts a Flutter widget to ui.Image
  static Future<ui.Image> _widgetToImage(Widget widget, double size) async {
    final repaintBoundary = RenderRepaintBoundary();
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration.fromView(view),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: size, height: size, child: widget),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 1.0);
    return image;
  }

  /// Preloads an image (call this from your widget to preload images)
  static Future<void> preloadImage(String imagePath) async {
    if (!_imageCache.containsKey(imagePath)) {
      await _loadImage(imagePath);
    }
  }

  /// Preloads a custom widget (call this to preload custom widgets)
  static Future<void> preloadCustomWidget(Widget widget, double size) async {
    final String widgetKey = '${widget.runtimeType}_${size.round()}';
    if (!_customWidgetCache.containsKey(widgetKey)) {
      await _loadCustomWidget(widget, size);
    }
  }

  /// Gets the cached image for a custom widget
  static ui.Image? getCustomWidgetImage(Widget widget, double size) {
    final String widgetKey = '${widget.runtimeType}_${size.round()}';
    return _customWidgetCache[widgetKey];
  }

  /// Checks if a custom widget is loading
  static bool isCustomWidgetLoading(Widget widget, double size) {
    final String widgetKey = '${widget.runtimeType}_${size.round()}';
    return _customWidgetLoadingStates[widgetKey] ?? false;
  }

  /// Clears the image cache (useful for memory management)
  static void clearImageCache() {
    _imageCache.clear();
    _imageLoadingStates.clear();
    _customWidgetCache.clear();
    _customWidgetLoadingStates.clear();
  }

  /// Draws a single particle at its current animation position.
  void _drawParticle(Canvas canvas, Size size, ParticleData particle) {
    // Use time-based animation for continuous movement
    final currentTime = DateTime.now();
    final elapsedTime = currentTime.difference(startTime).inMilliseconds;
    final timeProgress =
        (elapsedTime / config.animationDuration.inMilliseconds) % 1.0;

    final position = _calculatePosition(size, particle, timeProgress);
    final opacity = _calculateOpacity(particle, timeProgress);
    final rotation = config.enableRotation
        ? timeProgress * 2 * pi * particle.rotationSpeed
        : 0.0;

    // Skip drawing if particle is completely transparent
    if (opacity <= 0.0) {
      return;
    }

    canvas.save();
    canvas.translate(position.dx, position.dy);

    if (config.enableRotation) {
      canvas.rotate(rotation);
    }

    final paint = Paint()
      ..color = particle.color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    // Apply glow effect if enabled
    if (config.enableGlow) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, config.glowRadius);
    }

    // Apply blur effect if enabled
    if (config.enableBlur) {
      paint.imageFilter = ui.ImageFilter.blur(
        sigmaX: config.blurSigma,
        sigmaY: config.blurSigma,
      );
    }

    _drawParticleShape(canvas, particle, paint);

    canvas.restore();
  }

  /// Calculates the current position of a particle based on time progress.
  Offset _calculatePosition(
    Size size,
    ParticleData particle,
    double timeProgress,
  ) {
    double x, y;

    // Calculate particle-specific progress with offset for staggered animation
    final particleProgress = (timeProgress + particle.animationOffset) % 1.0;
    final adjustedProgress =
        particleProgress * particle.velocity * particle.screenOccupancy;

    switch (config.direction) {
      case ParticleDirection.topToBottom:
        x = particle.initialX * size.width;
        // Particles continuously fall from top to bottom
        y = (adjustedProgress * (size.height));
        // Add natural horizontal drift
        x += 30 * sin(adjustedProgress * 2 * pi + particle.animationOffset);
        break;

      case ParticleDirection.bottomToTop:
        x = particle.initialX * size.width;
        y = size.height + 100 - (adjustedProgress * (size.height + 200));
        x += 20 * sin(adjustedProgress * 3 * pi + particle.animationOffset);
        break;

      case ParticleDirection.leftToRight:
        x = -100 + (adjustedProgress * (size.width + 200));
        y = particle.initialY * size.height;
        y += 15 * cos(adjustedProgress * 2 * pi + particle.animationOffset);
        break;

      case ParticleDirection.rightToLeft:
        x = size.width + 100 - (adjustedProgress * (size.width + 200));
        y = particle.initialY * size.height;
        y += 15 * cos(adjustedProgress * 2 * pi + particle.animationOffset);
        break;

      case ParticleDirection.diagonal:
        x = adjustedProgress * size.width;
        y = adjustedProgress * size.height;
        break;
    }

    return Offset(x, y);
  }

  /// Calculates the current opacity of a particle.
  double _calculateOpacity(ParticleData particle, double timeProgress) {
    if (!config.enableOpacityAnimation) {
      return config.maxOpacity;
    }

    // Use time-based progress for continuous animation
    final particleProgress = (timeProgress + particle.animationOffset) % 1.0;

    // Create smooth opacity animation using sine wave
    final baseOpacity =
        config.minOpacity +
        (config.maxOpacity - config.minOpacity) *
            (0.5 +
                0.5 *
                    sin(particleProgress * 4 * pi + particle.animationOffset));

    return baseOpacity.clamp(0.0, 1.0);
  }

  /// Draws the actual shape of the particle.
  void _drawParticleShape(Canvas canvas, ParticleData particle, Paint paint) {
    switch (config.particleType) {
      case ParticleType.circle:
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
        break;

      case ParticleType.square:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size,
          ),
          paint,
        );
        break;

      case ParticleType.star:
        _drawStar(canvas, particle.size, paint);
        break;

      case ParticleType.heart:
        _drawHeart(canvas, particle.size, paint);
        break;

      case ParticleType.image:
        _drawImage(canvas, particle, paint);
        break;

      case ParticleType.custom:
        _drawCustomWidget(canvas, particle, paint);
        break;
    }
  }

  /// Draws a custom widget particle
  void _drawCustomWidget(Canvas canvas, ParticleData particle, Paint paint) {
    if (config.customParticle == null) {
      // Fallback to circle if no custom widget provided
      canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      return;
    }

    final String widgetKey =
        '${config.customParticle.runtimeType}_${particle.size.round()}';
    final image = _customWidgetCache[widgetKey];

    if (image == null) {
      // Widget not converted to image yet, show circle as placeholder
      canvas.drawCircle(Offset.zero, particle.size / 2, paint);

      // Trigger widget to image conversion if not already loading
      if (!(_customWidgetLoadingStates[widgetKey] ?? false)) {
        _loadCustomWidget(config.customParticle!, particle.size);
      }
      return;
    }

    // Calculate the scale to fit the image within the particle size
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    // Create destination rectangle centered at origin
    final destRect = Rect.fromCenter(
      center: Offset.zero,
      width: particle.size,
      height: particle.size,
    );

    // Source rectangle (entire image)
    final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);

    // Apply color filter and opacity
    Paint imagePaint = Paint()
      ..colorFilter = ColorFilter.mode(
        Colors.white.withValues(alpha: paint.color.a),
        BlendMode.modulate,
      )
      ..maskFilter = paint.maskFilter
      ..imageFilter = paint.imageFilter;

    // Draw the widget as image
    canvas.drawImageRect(image, srcRect, destRect, imagePaint);
  }

  /// Draws an image particle
  void _drawImage(Canvas canvas, ParticleData particle, Paint paint) {
    final imagePath = particle.imagePath ?? config.imagePath;

    if (imagePath == null) {
      // Fallback to circle if no image path provided
      canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      return;
    }

    final image = _imageCache[imagePath];

    if (image == null) {
      // Image not loaded yet, show circle as placeholder
      canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      return;
    }

    // Calculate the scale to fit the image within the particle size
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();
    final aspectRatio = imageWidth / imageHeight;

    double drawWidth, drawHeight;

    if (aspectRatio > 1) {
      // Landscape image
      drawWidth = particle.size;
      drawHeight = particle.size / aspectRatio;
    } else {
      // Portrait or square image
      drawHeight = particle.size;
      drawWidth = particle.size * aspectRatio;
    }

    // Create destination rectangle centered at origin
    final destRect = Rect.fromCenter(
      center: Offset.zero,
      width: drawWidth,
      height: drawHeight,
    );

    // Source rectangle (entire image)
    final srcRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);

    // Apply color filter if particle has a specific color
    Paint imagePaint = paint;
    if (config.particleColor != null ||
        (config.gradientColors != null && config.gradientColors!.isNotEmpty)) {
      imagePaint = Paint()
        ..colorFilter = ColorFilter.mode(
          particle.color.withValues(alpha: paint.color.a),
          BlendMode.modulate,
        )
        ..maskFilter = paint.maskFilter
        ..imageFilter = paint.imageFilter;
    } else {
      // Just apply opacity
      imagePaint = Paint()
        ..colorFilter = ColorFilter.mode(
          Colors.white.withValues(alpha: paint.color.a),
          BlendMode.modulate,
        )
        ..maskFilter = paint.maskFilter
        ..imageFilter = paint.imageFilter;
    }

    // Draw the image
    canvas.drawImageRect(image, srcRect, destRect, imagePaint);
  }

  /// Draws a star shape with the given size and paint.
  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final radius = size / 2;
    final innerRadius = radius * 0.4;

    for (int i = 0; i < 10; i++) {
      final angle = (i * pi) / 5 - pi / 2; // Start from top
      final r = i % 2 == 0 ? radius : innerRadius;
      final x = r * cos(angle);
      final y = r * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  /// Draws a heart shape with the given size and paint.
  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final scale = size / 16; // Scale factor for heart shape

    // Heart shape coordinates (scaled)
    path.moveTo(0, 4 * scale);
    path.cubicTo(-8 * scale, -4 * scale, -8 * scale, 4 * scale, 0, 8 * scale);
    path.cubicTo(8 * scale, 4 * scale, 8 * scale, -4 * scale, 0, 4 * scale);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    // Always repaint for continuous time-based animation
    return true;
  }
}
