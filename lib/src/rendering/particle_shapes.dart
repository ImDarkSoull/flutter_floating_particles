import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../models/particle_type.dart';

/// Built-in particle shapes, each normalized so that its longest side is 1.0
/// and it is centered on the origin.
abstract final class ParticleShapes {
  /// A circle.
  static final Path circle = Path()
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 0.5));

  /// A square.
  static final Path square = Path()
    ..addRect(Rect.fromCenter(center: Offset.zero, width: 1, height: 1));

  /// A five-pointed star.
  static final Path star = normalize(_star());

  /// A heart.
  static final Path heart = normalize(_heart());

  /// A leaf.
  static final Path leaf = normalize(_leaf());

  /// A thin vertical capsule; rotated to follow the direction of motion.
  static final Path streak = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 0.12, height: 1),
        const Radius.circular(0.06),
      ),
    );

  /// The normalized path for a built-in [type], or null for types that are
  /// not drawn from a built-in shape.
  static Path? forType(ParticleType type) => switch (type) {
    ParticleType.circle => circle,
    ParticleType.square => square,
    ParticleType.star => star,
    ParticleType.heart => heart,
    ParticleType.leaf => leaf,
    ParticleType.streak => streak,
    ParticleType.path || ParticleType.image || ParticleType.custom => null,
  };

  /// Scales [path] so its longest side is 1.0 and centers it on the origin.
  static Path normalize(Path path) {
    final bounds = path.getBounds();
    final extent = max(bounds.width, bounds.height);
    if (extent <= 0 || !extent.isFinite) return circle;
    final scale = 1 / extent;
    final matrix = Float64List(16)
      ..[0] = scale
      ..[5] = scale
      ..[10] = 1
      ..[15] = 1
      ..[12] = -bounds.center.dx * scale
      ..[13] = -bounds.center.dy * scale;
    return path.transform(matrix);
  }

  static Path _star() {
    final path = Path();
    const double innerRadius = 0.4;
    for (int i = 0; i < 10; i++) {
      final angle = (i * pi) / 5 - pi / 2;
      final r = i.isEven ? 1.0 : innerRadius;
      final point = Offset(r * cos(angle), r * sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  static Path _heart() {
    return Path()
      ..moveTo(0.5, 0.3)
      ..cubicTo(0.5, 0.27, 0.45, 0.15, 0.25, 0.15)
      ..cubicTo(0.0, 0.15, 0.0, 0.4, 0.0, 0.4)
      ..cubicTo(0.0, 0.55, 0.1, 0.7, 0.5, 0.95)
      ..cubicTo(0.9, 0.7, 1.0, 0.55, 1.0, 0.4)
      ..cubicTo(1.0, 0.4, 1.0, 0.15, 0.75, 0.15)
      ..cubicTo(0.6, 0.15, 0.5, 0.27, 0.5, 0.3)
      ..close();
  }

  static Path _leaf() {
    return Path()
      ..moveTo(0, -10)
      ..cubicTo(-10, -5, -10, 5, 0, 10)
      ..cubicTo(10, 5, 10, -5, 0, -10)
      ..close();
  }
}
