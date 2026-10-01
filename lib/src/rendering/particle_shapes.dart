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

  /// A six-armed snowflake with branches.
  static final Path snowflake = normalize(_snowflake());

  /// A four-pointed sparkle with curved sides.
  static final Path sparkle = normalize(
    Path()
      ..moveTo(0, -1)
      ..quadraticBezierTo(0.12, -0.12, 1, 0)
      ..quadraticBezierTo(0.12, 0.12, 0, 1)
      ..quadraticBezierTo(-0.12, 0.12, -1, 0)
      ..quadraticBezierTo(-0.12, -0.12, 0, -1)
      ..close(),
  );

  /// A flower petal with a notch at the tip.
  static final Path petal = normalize(
    Path()
      ..moveTo(0, 1)
      ..cubicTo(-0.75, 0.55, -0.6, -0.6, -0.16, -1)
      ..lineTo(0, -0.82)
      ..lineTo(0.16, -1)
      ..cubicTo(0.6, -0.6, 0.75, 0.55, 0, 1)
      ..close(),
  );

  /// A teardrop, pointed at the top.
  static final Path raindrop = normalize(
    Path()
      ..moveTo(0, -1)
      ..cubicTo(0.2, -0.5, 0.6, -0.1, 0.6, 0.3)
      ..cubicTo(0.6, 0.65, 0.3, 0.9, 0, 0.9)
      ..cubicTo(-0.3, 0.9, -0.6, 0.65, -0.6, 0.3)
      ..cubicTo(-0.6, -0.1, -0.2, -0.5, 0, -1)
      ..close(),
  );

  /// A hollow ring.
  static final Path ring = Path()
    ..fillType = PathFillType.evenOdd
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 0.5))
    ..addOval(Rect.fromCircle(center: Offset.zero, radius: 0.36));

  /// An upward-pointing triangle.
  static final Path triangle = normalize(
    Path()
      ..moveTo(0, -1)
      ..lineTo(0.866, 0.5)
      ..lineTo(-0.866, 0.5)
      ..close(),
  );

  /// A diamond.
  static final Path diamond = normalize(
    Path()
      ..moveTo(0, -1)
      ..lineTo(0.62, 0)
      ..lineTo(0, 1)
      ..lineTo(-0.62, 0)
      ..close(),
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
    ParticleType.snowflake => snowflake,
    ParticleType.sparkle => sparkle,
    ParticleType.petal => petal,
    ParticleType.raindrop => raindrop,
    ParticleType.ring => ring,
    ParticleType.triangle => triangle,
    ParticleType.diamond => diamond,
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

  static Path _snowflake() {
    final path = Path();
    // Every bar is added with the same winding, so overlaps stay filled
    void bar(Offset from, Offset to, double halfWidth) {
      final direction = to - from;
      final length = direction.distance;
      final normal = Offset(-direction.dy, direction.dx) / length * halfWidth;
      path
        ..moveTo(from.dx + normal.dx, from.dy + normal.dy)
        ..lineTo(to.dx + normal.dx, to.dy + normal.dy)
        ..lineTo(to.dx - normal.dx, to.dy - normal.dy)
        ..lineTo(from.dx - normal.dx, from.dy - normal.dy)
        ..close();
    }

    Offset polar(double radius, double angle) =>
        Offset(radius * cos(angle), radius * sin(angle));

    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3 - pi / 2;
      bar(Offset.zero, polar(1, angle), 0.07);
      for (final at in const [0.45, 0.72]) {
        final base = polar(at, angle);
        final length = at == 0.45 ? 0.32 : 0.22;
        bar(base, base + polar(length, angle - pi / 4), 0.055);
        bar(base, base + polar(length, angle + pi / 4), 0.055);
      }
    }
    return path;
  }

  static Path _leaf() {
    return Path()
      ..moveTo(0, -10)
      ..cubicTo(-10, -5, -10, 5, 0, 10)
      ..cubicTo(10, 5, 10, -5, 0, -10)
      ..close();
  }
}
