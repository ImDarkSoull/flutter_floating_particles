import 'dart:math';

import 'package:flutter/material.dart';

/// Shapes and backdrops shared by several theme pages.

/// A bird in flight, for use as `ParticleType.path`.
final Path birdPath = Path()
  ..moveTo(-1, 0)
  ..quadraticBezierTo(-0.5, -0.55, 0, -0.05)
  ..quadraticBezierTo(0.5, -0.55, 1, 0)
  ..quadraticBezierTo(0.5, -0.3, 0, 0.1)
  ..quadraticBezierTo(-0.5, -0.3, -1, 0)
  ..close();

/// A bat silhouette, for use as `ParticleType.path`.
final Path batPath = () {
  const wing = [
    (0.08, -0.35),
    (0.13, -0.12),
    (1.0, -0.22),
    (0.78, 0.12),
    (0.52, 0.14),
    (0.26, 0.2),
    (0.08, 0.32),
    (0.0, 0.4),
  ];
  final path = Path()..moveTo(0, -0.15);
  for (final (x, y) in wing) {
    path.lineTo(x, y);
  }
  for (final (x, y) in wing.reversed.skip(1)) {
    path.lineTo(-x, y);
  }
  return path..close();
}();

/// A city skyline with lit windows, in two rows of buildings.
class CitySkylinePainter extends CustomPainter {
  const CitySkylinePainter({
    this.far = const Color(0xFF16203F),
    this.near = const Color(0xFF0A1128),
    this.window = const Color(0xFFFFE082),
    this.seed = 7,
  });

  final Color far;
  final Color near;
  final Color window;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(seed);
    final w = size.width;
    final h = size.height;

    void row(double minHeight, double maxHeight, Color color, bool windows) {
      double x = -10;
      while (x < w) {
        final bw = 26 + random.nextDouble() * 40;
        final bh = minHeight + random.nextDouble() * (maxHeight - minHeight);
        canvas.drawRect(
          Rect.fromLTWH(x, h - bh, bw, bh),
          Paint()..color = color,
        );
        if (random.nextDouble() < 0.25) {
          canvas.drawRect(
            Rect.fromLTWH(x + bw / 2 - 1.5, h - bh - 18, 3, 18),
            Paint()..color = color,
          );
        }
        if (windows) {
          for (double wy = h - bh + 8; wy < h - 6; wy += 11) {
            for (double wx = x + 5; wx < x + bw - 6; wx += 9) {
              if (random.nextDouble() < 0.4) {
                canvas.drawRect(
                  Rect.fromLTWH(wx, wy, 4, 5),
                  Paint()
                    ..color = window.withValues(
                      alpha: 0.35 + random.nextDouble() * 0.5,
                    ),
                );
              }
            }
          }
        }
        x += bw + 2;
      }
    }

    row(h * 0.45, h * 0.95, far, false);
    row(h * 0.25, h * 0.7, near, true);
  }

  @override
  bool shouldRepaint(CitySkylinePainter oldDelegate) => false;
}

/// Positions of [key]'s widget in [ancestor]'s coordinates, or null.
Rect? rectOf(GlobalKey key, BuildContext ancestor) {
  final box = key.currentContext?.findRenderObject();
  final page = ancestor.findRenderObject();
  if (box is! RenderBox || page is! RenderBox || !box.hasSize) return null;
  final topLeft = box.localToGlobal(Offset.zero, ancestor: page);
  return topLeft & box.size;
}
