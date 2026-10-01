import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';
import 'package:flutter_floating_particles/src/rendering/particle_shapes.dart';
import 'package:flutter_floating_particles/src/rendering/particle_sprite.dart';
import 'package:flutter_floating_particles/src/rendering/particle_system.dart';
import 'package:flutter_test/flutter_test.dart';

void _paint(ParticleSystem system, [Size size = const Size(400, 800)]) {
  final recorder = ui.PictureRecorder();
  system.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}

void main() {
  group('ParticleShapes', () {
    test('built-in shapes are normalized to a longest side of 1', () {
      for (final type in ParticleType.values) {
        final path = ParticleShapes.forType(type);
        if (path == null) continue;
        final bounds = path.getBounds();
        expect(
          max(bounds.width, bounds.height),
          closeTo(1.0, 0.01),
          reason: '$type',
        );
        expect(bounds.center.dx, closeTo(0, 0.01), reason: '$type');
        expect(bounds.center.dy, closeTo(0, 0.01), reason: '$type');
      }
    });

    test('normalize fits any path', () {
      final path = ParticleShapes.normalize(
        Path()..addRect(const Rect.fromLTWH(100, 50, 40, 20)),
      );
      final bounds = path.getBounds();

      expect(bounds.width, closeTo(1.0, 1e-9));
      expect(bounds.height, closeTo(0.5, 1e-9));
      expect(bounds.center, equals(Offset.zero));
    });
  });

  group('ParticleSprite', () {
    test('includes padding for glow', () {
      final plain = ParticleSprite.fromPath(
        ParticleShapes.circle,
        resolution: 32,
      );
      final glowing = ParticleSprite.fromPath(
        ParticleShapes.circle,
        resolution: 32,
        glowSigma: 4,
      );

      expect(plain.contentExtent, equals(32));
      expect(glowing.contentExtent, equals(32));
      expect(glowing.image.width, greaterThan(plain.image.width));

      plain.dispose();
      glowing.dispose();
    });
  });

  group('ParticleSystem', () {
    late ParticleSystem system;

    setUp(() {
      system = ParticleSystem(config: const ParticleConfig(particleCount: 0))
        ..atlas = ParticleAtlas.pack([
          ParticleSprite.fromPath(ParticleShapes.circle, resolution: 16),
        ], ParticleSprite.fromPath(ParticleShapes.circle, resolution: 16));
    });

    tearDown(() {
      system.atlas?.dispose();
      system.dispose();
    });

    test('bursts wait for a size, then live for their lifespan', () {
      system.addBurst(
        const BurstRequest(count: 12, lifespan: Duration(seconds: 1)),
      );
      expect(system.hasBursts, isTrue);

      // No size yet, so the burst stays pending
      system.advance(0.016);
      expect(system.burstParticleCount, equals(0));

      _paint(system);
      expect(system.burstParticleCount, equals(12));

      for (int i = 0; i < 20; i++) {
        system.advance(0.1);
      }
      expect(system.burstParticleCount, equals(0));
      expect(system.hasBursts, isFalse);
    });

    test('burst particle count is capped', () {
      system.addBurst(
        const BurstRequest(count: ParticleSystem.maxBurstParticles + 100),
      );
      _paint(system);

      expect(
        system.burstParticleCount,
        equals(ParticleSystem.maxBurstParticles),
      );
    });

    test('cycles follow the animation duration', () {
      system.config = const ParticleConfig(
        animationDuration: Duration(seconds: 2),
      );
      system.advance(3);

      expect(system.cycles, closeTo(1.5, 1e-9));
    });

    test('paints many particles with interaction without errors', () {
      system.config = const ParticleConfig(particleCount: 500, wind: -0.4);
      system.particles = List.generate(
        500,
        (i) => ParticleData.generate(i, system.config),
      );
      system.interaction = ParticleInteraction.attract;
      system.pointer = const Offset(200, 400);

      for (int i = 0; i < 5; i++) {
        system.advance(0.5);
        _paint(system);
      }
    });

    test('notifies listeners when advanced', () {
      int notifications = 0;
      system.addListener(() => notifications++);

      system.advance(0.016);
      system.markNeedsPaint();

      expect(notifications, equals(2));
    });
  });
}
