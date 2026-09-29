import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
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

  /// Unused. The painter lays out particles using the size passed to [paint].
  @Deprecated('Unused. The painter uses the size passed to paint().')
  final Size screenSize;

  /// Start time for time-based animation
  final DateTime startTime;

  /// Maximum number of custom widget snapshots kept in memory.
  static const int _maxCustomWidgetCacheSize = 32;

  /// Cache for loaded images
  static final Map<String, ui.Image> _imageCache = {};

  /// In-flight image loads, so concurrent callers share a single request
  static final Map<String, Future<void>> _pendingImages = {};

  /// Images that failed to load. They are not retried from [paint], only
  /// when explicitly requested via [preloadImage].
  static final Set<String> _failedImages = {};

  /// Cache for custom widget images, keyed by widget instance.
  ///
  /// Widgets use identity equality, so a `const` widget (or a widget instance
  /// that is reused across rebuilds) is rendered only once.
  static final Map<Widget, ui.Image> _customWidgetCache = {};

  /// In-flight custom widget renders
  static final Map<Widget, Future<void>> _pendingCustomWidgets = {};

  /// Custom widgets that failed to render
  static final Set<Widget> _failedCustomWidgets = {};

  ParticlePainter({
    required this.particles,
    required this.animation,
    required this.config,
    @Deprecated('Unused. The painter uses the size passed to paint().')
    this.screenSize = Size.zero,
    required this.startTime,
  });

  // Reusable objects to avoid GC pressure
  final Paint _paint = Paint();
  static final Path _starPath = _createStarPath();

  static Path _createStarPath() {
    final path = Path();
    // Create a star of radius 1.0 centered at 0,0
    const double radius = 1.0;
    const double innerRadius = 0.4; // relative to radius

    for (int i = 0; i < 10; i++) {
      final angle = (i * pi) / 5 - pi / 2;
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
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Preload image if needed
    final imagePath = config.imagePath;
    if (config.particleType == ParticleType.image &&
        imagePath != null &&
        !_imageCache.containsKey(imagePath) &&
        !_pendingImages.containsKey(imagePath) &&
        !_failedImages.contains(imagePath)) {
      _loadImage(imagePath);
    }

    // Render the custom widget outside of the paint phase if needed
    final customParticle = config.customParticle;
    if (config.particleType == ParticleType.custom &&
        customParticle != null &&
        !_customWidgetCache.containsKey(customParticle) &&
        !_pendingCustomWidgets.containsKey(customParticle) &&
        !_failedCustomWidgets.contains(customParticle)) {
      final renderSize = config.maxSize;
      scheduleMicrotask(() => preloadCustomWidget(customParticle, renderSize));
    }

    // Elapsed animation cycles. Kept unwrapped so rotation, drift and
    // opacity stay continuous instead of snapping at cycle boundaries.
    final durationMs = config.animationDuration.inMilliseconds;
    final elapsedMs =
        DateTime.now().difference(startTime).inMicroseconds / 1000.0;
    final cycles = durationMs > 0 ? elapsedMs / durationMs : 0.0;

    // Filters are the same for every particle, so create them once per frame
    _paint.style = PaintingStyle.fill;
    _paint.maskFilter = config.enableGlow
        ? MaskFilter.blur(BlurStyle.normal, config.glowRadius)
        : null;
    _paint.imageFilter = config.enableBlur
        ? ui.ImageFilter.blur(
            sigmaX: config.blurSigma,
            sigmaY: config.blurSigma,
          )
        : null;

    // Draw each particle
    for (final particle in particles) {
      _drawParticle(canvas, size, particle, cycles);
    }
  }

  /// Loads an image from assets or network and caches it
  static Future<void> _loadImage(String imagePath) {
    final pending = _pendingImages[imagePath];
    if (pending != null) return pending;

    final future = _decodeImage(imagePath)
        .then((image) {
          _imageCache.remove(imagePath)?.dispose();
          _imageCache[imagePath] = image;
          _failedImages.remove(imagePath);
        })
        .catchError((Object e) {
          _failedImages.add(imagePath);
          debugPrint('Error loading image $imagePath: $e');
        })
        // Block body: returning the removed future would make this future
        // wait on itself.
        .whenComplete(() {
          _pendingImages.remove(imagePath);
        });

    _pendingImages[imagePath] = future;
    return future;
  }

  /// Fetches and decodes an image from assets or network.
  static Future<ui.Image> _decodeImage(String imagePath) async {
    final bool isNetwork = imagePath.toLowerCase().startsWith('http');
    final bool isSvg = imagePath.toLowerCase().endsWith('.svg');
    Uint8List bytes;

    if (isNetwork) {
      final response = await http.get(Uri.parse(imagePath));
      if (response.statusCode == 200) {
        bytes = response.bodyBytes;
      } else {
        throw Exception('Failed to load network image: ${response.statusCode}');
      }
    } else {
      final ByteData data = await rootBundle.load(imagePath);
      bytes = data.buffer.asUint8List();
    }

    if (isSvg) {
      // Render the SVG to a ui.Image whose longest side is svgSize. Particles
      // scale it down when drawing.
      const double svgSize = 200.0;
      final PictureInfo pictureInfo = await vg.loadPicture(
        SvgStringLoader(utf8.decode(bytes, allowMalformed: true)),
        null,
        clipViewbox: false,
      );

      try {
        final Size svgBounds = pictureInfo.size;
        final bool hasBounds = svgBounds.width > 0 && svgBounds.height > 0;
        final double scale = hasBounds
            ? svgSize / max(svgBounds.width, svgBounds.height)
            : 1.0;
        final int width = hasBounds
            ? max(1, (svgBounds.width * scale).round())
            : svgSize.toInt();
        final int height = hasBounds
            ? max(1, (svgBounds.height * scale).round())
            : svgSize.toInt();

        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        canvas.scale(scale, scale);
        canvas.drawPicture(pictureInfo.picture);
        final ui.Picture picture = recorder.endRecording();
        try {
          return await picture.toImage(width, height);
        } finally {
          picture.dispose();
        }
      } finally {
        pictureInfo.picture.dispose();
      }
    }

    // Raster image
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    try {
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      return frameInfo.image;
    } finally {
      codec.dispose();
    }
  }

  /// Renders a custom widget to an image and caches it
  static Future<void> _loadCustomWidget(Widget widget, double size) {
    final pending = _pendingCustomWidgets[widget];
    if (pending != null) return pending;

    final future = _widgetToImage(widget, size)
        .then((image) {
          _customWidgetCache.remove(widget)?.dispose();
          _customWidgetCache[widget] = image;
          _failedCustomWidgets.remove(widget);

          // Evict the oldest snapshots so the cache cannot grow unbounded
          while (_customWidgetCache.length > _maxCustomWidgetCacheSize) {
            final oldest = _customWidgetCache.keys.first;
            _customWidgetCache.remove(oldest)?.dispose();
          }
        })
        .catchError((Object e) {
          _failedCustomWidgets.add(widget);
          debugPrint('Error converting widget to image: $e');
        })
        // Block body: returning the removed future would make this future
        // wait on itself.
        .whenComplete(() {
          _pendingCustomWidgets.remove(widget);
        });

    _pendingCustomWidgets[widget] = future;
    return future;
  }

  /// Converts a Flutter widget to ui.Image at the device pixel ratio
  static Future<ui.Image> _widgetToImage(Widget widget, double size) async {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final repaintBoundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration.fromView(view),
    );

    final pipelineOwner = PipelineOwner();
    final focusManager = FocusManager();
    final buildOwner = BuildOwner(focusManager: focusManager);

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: MediaQuery(
        data: MediaQueryData.fromView(view),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: size, height: size, child: widget),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    try {
      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();

      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      return await repaintBoundary.toImage(pixelRatio: view.devicePixelRatio);
    } finally {
      // Tear down the offscreen tree so its elements, render objects and
      // layers are released.
      RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
      ).attachToRenderTree(buildOwner, rootElement);
      buildOwner.finalizeTree();
      pipelineOwner.rootNode = null;
      pipelineOwner.dispose();
      renderView.dispose();
      focusManager.dispose();
    }
  }

  /// Preloads an image (call this from your widget to preload images).
  ///
  /// An image that previously failed to load is retried.
  static Future<void> preloadImage(String imagePath) async {
    if (!_imageCache.containsKey(imagePath)) {
      _failedImages.remove(imagePath);
      await _loadImage(imagePath);
    }
  }

  /// Preloads a custom widget (call this to preload custom widgets).
  ///
  /// The widget is rendered once in a [size] x [size] box and scaled to each
  /// particle's size when drawn. A widget that previously failed is retried.
  static Future<void> preloadCustomWidget(Widget widget, double size) async {
    if (!_customWidgetCache.containsKey(widget)) {
      _failedCustomWidgets.remove(widget);
      await _loadCustomWidget(widget, size);
    }
  }

  /// Gets the cached image for a custom widget.
  ///
  /// [size] is ignored; each widget is cached once regardless of size.
  static ui.Image? getCustomWidgetImage(Widget widget, double size) {
    return _customWidgetCache[widget];
  }

  /// Checks if a custom widget is loading.
  ///
  /// [size] is ignored; each widget is cached once regardless of size.
  static bool isCustomWidgetLoading(Widget widget, double size) {
    return _pendingCustomWidgets.containsKey(widget);
  }

  /// Clears and disposes the image cache (useful for memory management)
  static void clearImageCache() {
    for (final image in _imageCache.values) {
      image.dispose();
    }
    for (final image in _customWidgetCache.values) {
      image.dispose();
    }
    _imageCache.clear();
    _failedImages.clear();
    _customWidgetCache.clear();
    _failedCustomWidgets.clear();
  }

  /// Draws a single particle at its current animation position.
  void _drawParticle(
    Canvas canvas,
    Size size,
    ParticleData particle,
    double cycles,
  ) {
    // Phase offset as a fraction of a cycle
    final phase = particle.animationOffset / (2 * pi);
    final speed = particle.velocity * config.velocityMultiplier;
    // Unwrapped distance travelled, in path lengths
    final travelled = cycles * speed + phase;
    // Position along the path, 0.0 (entering) to 1.0 (leaving)
    final progress = travelled % 1.0;

    final position = _calculatePosition(size, particle, progress);
    final opacity = _calculateOpacity(particle, cycles, progress);

    // Skip drawing if particle is completely transparent
    if (opacity <= 0.0) {
      return;
    }

    _paint.color = particle.color.withValues(alpha: opacity);

    canvas.save();
    canvas.translate(position.dx, position.dy);

    if (config.enableRotation) {
      canvas.rotate(
        cycles * 2 * pi * particle.rotationSpeed + particle.animationOffset,
      );
    }

    _drawParticleShape(canvas, particle, _paint);

    canvas.restore();
  }

  /// Calculates the current position of a particle.
  ///
  /// Particles enter from just outside the edge and travel across
  /// [ParticleData.screenOccupancy] of the screen. With full coverage they
  /// leave past the opposite edge, so the wrap back to the start is never
  /// visible; with partial coverage they fade out instead (see
  /// [_calculateOpacity]).
  Offset _calculatePosition(Size size, ParticleData particle, double progress) {
    // Distance outside the edge where particles start and end, so they are
    // fully hidden when they wrap around
    final margin =
        particle.size + (config.enableGlow ? config.glowRadius * 2 : 0) + 2;
    final coverage = particle.screenOccupancy;
    final exitMargin = coverage >= 1.0 ? margin : 0.0;
    // Drift uses whole sine periods per path so it matches at the wrap
    final wave = progress * 2 * pi + particle.animationOffset;

    double x, y;

    switch (config.direction) {
      case ParticleDirection.topToBottom:
        final travel = margin + size.height * coverage + exitMargin;
        x = particle.initialX * size.width + 30 * sin(wave);
        y = -margin + progress * travel;
        break;

      case ParticleDirection.bottomToTop:
        final travel = margin + size.height * coverage + exitMargin;
        x = particle.initialX * size.width + 20 * sin(2 * wave);
        y = size.height + margin - progress * travel;
        break;

      case ParticleDirection.leftToRight:
        final travel = margin + size.width * coverage + exitMargin;
        x = -margin + progress * travel;
        y = particle.initialY * size.height + 15 * cos(wave);
        break;

      case ParticleDirection.rightToLeft:
        final travel = margin + size.width * coverage + exitMargin;
        x = size.width + margin - progress * travel;
        y = particle.initialY * size.height + 15 * cos(wave);
        break;

      case ParticleDirection.diagonal:
        // Start points are spread along a line through the top-left corner
        // so that particles moving at 45° cover the whole screen.
        final travel = margin + size.height * coverage + exitMargin;
        final startX = particle.initialX * (size.width + size.height) -
            size.height;
        x = startX + progress * travel;
        y = -margin + progress * travel;
        break;
    }

    return Offset(x, y);
  }

  /// Calculates the current opacity of a particle.
  double _calculateOpacity(
    ParticleData particle,
    double cycles,
    double progress,
  ) {
    double opacity;

    if (!config.enableOpacityAnimation) {
      opacity = config.maxOpacity;
    } else {
      final phase = particle.animationOffset / (2 * pi);
      // Smooth opacity animation using a sine wave
      opacity =
          config.minOpacity +
          (config.maxOpacity - config.minOpacity) *
              (0.5 +
                  0.5 *
                      sin((cycles + phase) * 4 * pi + particle.animationOffset));
    }

    // With partial coverage particles stop mid-screen, so fade them out over
    // the last part of their path instead of letting them vanish.
    if (particle.screenOccupancy < 1.0) {
      const fadeStart = 0.8;
      if (progress > fadeStart) {
        opacity *= (1.0 - progress) / (1.0 - fadeStart);
      }
    }

    return opacity.clamp(0.0, 1.0);
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

      case ParticleType.leaf:
        _drawLeaf(canvas, particle.size, paint);
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
    final customParticle = config.customParticle;
    final image = customParticle == null
        ? null
        : _customWidgetCache[customParticle];

    if (image == null) {
      // No widget provided, or not rendered yet: show a circle placeholder
      canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      return;
    }

    // Create destination rectangle centered at origin
    final destRect = Rect.fromCenter(
      center: Offset.zero,
      width: particle.size,
      height: particle.size,
    );

    // Source rectangle (entire image)
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

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

  /// Draws a star shape using pre-calculated path
  void _drawStar(Canvas canvas, double size, Paint paint) {
    canvas.save();
    // Scale the unit star path (which has radius 1.0 => diameter 2.0)
    // We want valid size. so scale by size/2
    final scale = size / 2.0;
    canvas.scale(scale, scale);
    canvas.drawPath(_starPath, paint);
    canvas.restore();
  }

  /// Draws a heart shape with the given size and paint.
  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final scale = size / 16; // Scale factor for heart shape

    // Heart shape coordinates (scaled)
    path.moveTo(0, 4 * scale);
    path.cubicTo(-8 * scale, -4 * scale, -8 * scale, 4 * scale, 0, 8 * scale);
    path.cubicTo(8 * scale, 4 * scale, 8 * scale, -4 * scale, 0, 4 * scale);

    path.close();
    canvas.drawPath(path, paint);
  }

  /// Draws a leaf shape with the given size and paint.
  void _drawLeaf(Canvas canvas, double size, Paint paint) {
    final path = Path();
    final scale = size / 20; // Scale factor based on typical leaf path

    // Draw a simple leaf shape
    path.moveTo(0, -10 * scale);
    // Left curve
    path.cubicTo(
      -10 * scale,
      -5 * scale,
      -10 * scale,
      5 * scale,
      0,
      10 * scale,
    );
    // Right curve
    path.cubicTo(10 * scale, 5 * scale, 10 * scale, -5 * scale, 0, -10 * scale);

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    // Always repaint for continuous time-based animation
    return true;
  }
}
