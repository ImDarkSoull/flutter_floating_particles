import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// A particle pre-rendered into an image, with any glow and blur baked in.
///
/// Every particle is drawn from the same sprite in a single
/// [Canvas.drawRawAtlas] call, scaled, rotated and tinted per particle, which
/// is much cheaper than drawing (and blurring) each particle separately.
class ParticleSprite {
  ParticleSprite._(this.image, this.contentExtent);

  /// The rendered sprite, including padding for glow and blur.
  final ui.Image image;

  /// Length in pixels of the particle's longest side within [image],
  /// excluding the padding. A particle of size `s` is drawn at a scale of
  /// `s / contentExtent`.
  final double contentExtent;

  /// Horizontal center of the particle within [image].
  double get anchorX => image.width / 2;

  /// Vertical center of the particle within [image].
  double get anchorY => image.height / 2;

  /// Draws [path] (normalized to a longest side of 1.0, centered on the
  /// origin) in white, [resolution] pixels across.
  factory ParticleSprite.fromPath(
    Path path, {
    required double resolution,
    double glowSigma = 0,
    double blurSigma = 0,
  }) {
    final bounds = path.getBounds();
    final contentSize = Size(
      max(1, bounds.width * resolution),
      max(1, bounds.height * resolution),
    );
    final matrix = Float64List(16)
      ..[0] = resolution
      ..[5] = resolution
      ..[10] = 1
      ..[15] = 1;

    return _render(contentSize, glowSigma, blurSigma, (canvas, content, paint) {
      final scaled = path.transform(matrix);
      canvas.drawPath(scaled.shift(content.center), paint);
    });
  }

  /// Draws [source] fitted into a [resolution]-pixel box, keeping its aspect
  /// ratio and colors.
  factory ParticleSprite.fromImage(
    ui.Image source, {
    required double resolution,
    double glowSigma = 0,
    double blurSigma = 0,
  }) {
    final width = source.width.toDouble();
    final height = source.height.toDouble();
    final scale = resolution / max(1, max(width, height));
    final contentSize = Size(max(1, width * scale), max(1, height * scale));

    return _render(contentSize, glowSigma, blurSigma, (canvas, content, paint) {
      canvas.drawImageRect(
        source,
        Rect.fromLTWH(0, 0, width, height),
        content,
        paint,
      );
    });
  }

  static ParticleSprite _render(
    Size contentSize,
    double glowSigma,
    double blurSigma,
    void Function(Canvas canvas, Rect content, Paint paint) draw,
  ) {
    // Room for the blur to fade out, plus a transparent border
    final padding = ((glowSigma + blurSigma) * 3).ceil() + _border + 1;
    final width = (contentSize.width + padding * 2).ceil();
    final height = (contentSize.height + padding * 2).ceil();
    final content = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: contentSize.width,
      height: contentSize.height,
    );

    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.medium;
    if (blurSigma > 0) {
      paint.imageFilter = ui.ImageFilter.blur(
        sigmaX: blurSigma,
        sigmaY: blurSigma,
      );
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Clear the sprite and keep a border that nothing is drawn into, so
    // sampling at the edges of each particle's quad only ever reads fully
    // transparent pixels.
    final bounds = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    canvas.drawRect(bounds, Paint()..blendMode = BlendMode.clear);
    canvas.clipRect(bounds.deflate(_border.toDouble()));
    if (glowSigma > 0) {
      // A soft halo behind the shape, which is then drawn sharp on top.
      // Drawn twice so the halo stays visible around small particles.
      final haloPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..filterQuality = FilterQuality.medium
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma)
        ..imageFilter = paint.imageFilter;
      draw(canvas, content, haloPaint);
      draw(canvas, content, haloPaint);
    }
    draw(canvas, content, paint);
    final picture = recorder.endRecording();
    try {
      return ParticleSprite._(
        picture.toImageSync(width, height),
        max(contentSize.width, contentSize.height),
      );
    } finally {
      picture.dispose();
    }
  }

  /// Width in pixels of the fully transparent border around every sprite.
  static const int _border = 2;

  /// Releases the sprite image.
  void dispose() => image.dispose();
}

/// Where one sprite sits within a [ParticleAtlas].
@immutable
class SpriteRegion {
  /// Creates a region.
  const SpriteRegion(this.rect, this.contentExtent);

  /// The sprite's bounds within the atlas image.
  final Rect rect;

  /// Length in pixels of the particle's longest side, excluding padding.
  final double contentExtent;

  /// Horizontal center of the sprite within its region.
  double get anchorX => rect.width / 2;

  /// Vertical center of the sprite within its region.
  double get anchorY => rect.height / 2;
}

/// Several sprites packed into one image, so particles with different shapes
/// or images can still be drawn in a single call.
///
/// The last region is always a plain circle, used for splashes.
class ParticleAtlas {
  ParticleAtlas._(this.image, this.regions);

  /// The packed image.
  final ui.Image image;

  /// One region per sprite, in the order they were given, then the circle.
  final List<SpriteRegion> regions;

  /// Number of sprites particles pick from (excluding the circle).
  int get variantCount => regions.length - 1;

  /// Index of the plain circle sprite.
  int get circleIndex => regions.length - 1;

  /// The sprite a particle with the given random [variant] (0.0 to 1.0)
  /// uses.
  int indexFor(double variant) =>
      (variant * variantCount).floor().clamp(0, variantCount - 1);

  /// Packs [sprites] (followed by [circle]) into rows no wider than
  /// [maxWidth] pixels. The sprites are disposed.
  factory ParticleAtlas.pack(
    List<ParticleSprite> sprites,
    ParticleSprite circle, {
    int maxWidth = 2048,
  }) {
    final all = [...sprites, circle];
    const gap = 2;
    final regions = <SpriteRegion>[];
    double x = 0;
    double y = 0;
    double rowHeight = 0;
    double width = 0;
    for (final sprite in all) {
      final w = sprite.image.width.toDouble();
      final h = sprite.image.height.toDouble();
      if (x > 0 && x + w > maxWidth) {
        x = 0;
        y += rowHeight + gap;
        rowHeight = 0;
      }
      regions.add(
        SpriteRegion(Rect.fromLTWH(x, y, w, h), sprite.contentExtent),
      );
      x += w + gap;
      rowHeight = max(rowHeight, h);
      width = max(width, x);
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();
    for (int i = 0; i < all.length; i++) {
      canvas.drawImage(all[i].image, regions[i].rect.topLeft, paint);
    }
    final picture = recorder.endRecording();
    try {
      return ParticleAtlas._(
        picture.toImageSync(
          max(1, width.ceil()),
          max(1, (y + rowHeight).ceil()),
        ),
        regions,
      );
    } finally {
      picture.dispose();
      for (final sprite in all) {
        sprite.dispose();
      }
    }
  }

  /// Releases the atlas image.
  void dispose() => image.dispose();
}
