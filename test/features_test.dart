import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';
import 'package:flutter_floating_particles/src/rendering/particle_shapes.dart';
import 'package:flutter_floating_particles/src/rendering/particle_sprite.dart';
import 'package:flutter_floating_particles/src/rendering/particle_system.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home) =>
    MaterialApp(debugShowCheckedModeBanner: false, home: home);

const _size = Size(400, 800);

ParticleSystem _system(ParticleConfig config) {
  final system = ParticleSystem(config: config)
    ..particles = List.generate(
      config.particleCount,
      (i) => ParticleData.generate(i, config),
    )
    ..atlas = ParticleAtlas.pack([
      ParticleSprite.fromPath(ParticleShapes.circle, resolution: 16),
    ], ParticleSprite.fromPath(ParticleShapes.circle, resolution: 16));
  addTearDown(() {
    system.atlas?.dispose();
    system.dispose();
  });
  return system;
}

void _paint(ParticleSystem system, [Size size = _size]) {
  final recorder = ui.PictureRecorder();
  system.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}

/// Advances [seconds] in 1/60 s frames, painting each frame.
void _run(ParticleSystem system, double seconds) {
  _paint(system);
  for (double t = 0; t < seconds; t += 1 / 60) {
    system.advance(1 / 60);
    _paint(system);
  }
}

void main() {
  group('JSON', () {
    // Compared as JSON: Material swatches like Colors.orange never equal a
    // plain Color with the same value
    Map<String, Object?> roundTrip(ParticleConfig config) {
      final json = jsonDecode(jsonEncode(config.toJson()));
      return ParticleConfig.fromJson(json as Map<String, Object?>).toJson();
    }

    test('every preset survives a round trip', () {
      for (final type in ParticleEffectType.values) {
        expect(
          roundTrip(type.config),
          equals(jsonDecode(jsonEncode(type.config.toJson()))),
          reason: type.name,
        );
      }
    });

    test('nested options and network images round trip', () {
      const config = ParticleConfig(
        particleType: ParticleType.image,
        images: [NetworkImage('https://a.com/x.png'), AssetImage('a.png')],
        lifecycle: ParticleLifecycle.ember,
        trail: ParticleTrail(length: 3),
        splash: ParticleSplash(color: Color(0xFF2196F3)),
        connections: ParticleConnections(maxDistance: 50),
        emitters: [ParticleEmitter.smoke],
        seed: 7,
        maxParticles: 300,
      );
      final json = jsonDecode(jsonEncode(config.toJson()));
      expect(
        ParticleConfig.fromJson(json as Map<String, Object?>),
        equals(config),
      );
    });

    test('missing fields fall back to defaults', () {
      expect(ParticleConfig.fromJson(const {}), equals(const ParticleConfig()));
    });

    test('wrong types fall back to defaults', () {
      final config = ParticleConfig.fromJson(const {
        'particleType': 'blob',
        'particleCount': '50',
        'enableGlow': 'yes',
        'imagePath': 42,
        'gradientColors': [0xFFFF0000, 'blue', null],
        'lifecycle': 'grow',
        'emitters': [
          {'alignment': 'center', 'extent': ['a', 1], 'fireworks': 1},
          'not an emitter',
        ],
      });
      expect(config.particleType, ParticleType.circle);
      expect(config.particleCount, const ParticleConfig().particleCount);
      expect(config.enableGlow, isFalse);
      expect(config.imagePath, isNull);
      expect(config.gradientColors, [const Color(0xFFFF0000)]);
      expect(config.lifecycle, isNull);
      expect(config.emitters, hasLength(1));
      expect(config.emitters!.single.alignment, Alignment.bottomCenter);
      expect(config.emitters!.single.fireworks, isFalse);
    });

    test('out-of-range values are clamped', () {
      final config = ParticleConfig.fromJson(const {
        'particleCount': -5,
        'minSize': 0,
        'maxSize': -3,
        'minOpacity': 0.9,
        'maxOpacity': 2,
        'edgeFade': 3,
        'depthEffect': -1,
        'animationDurationMs': 0,
        'splash': {'size': -1, 'minSpeed': 200, 'maxSpeed': 10},
        'emitters': [
          {'rate': -2, 'minSpeed': 50, 'maxSpeed': 5, 'lifespanMs': -1},
        ],
      });
      expect(config.particleCount, 0);
      expect(config.minSize, greaterThan(0));
      expect(config.maxSize, config.minSize);
      expect(config.maxOpacity, 1);
      expect(config.minOpacity, 0.9);
      expect(config.edgeFade, 0.5);
      expect(config.depthEffect, 0);
      expect(config.animationDuration, const Duration(milliseconds: 1));
      expect(config.splash!.size, greaterThan(0));
      expect(config.splash!.maxSpeed, 200);
      final emitter = config.emitters!.single;
      expect(emitter.rate, 0);
      expect(emitter.maxSpeed, 50);
      expect(emitter.lifespan, Duration.zero);
    });
  });

  group('ParticleLifecycle', () {
    test('interpolates scale, opacity and colors', () {
      const lifecycle = ParticleLifecycle(
        startScale: 1,
        endScale: 0,
        endOpacity: 0.5,
        colors: [Color(0xFF000000), Color(0xFFFFFFFF)],
      );

      expect(lifecycle.scaleAt(0.25), closeTo(0.75, 1e-9));
      expect(lifecycle.opacityAt(1), closeTo(0.5, 1e-9));
      expect(lifecycle.colorAt(0), equals(const Color(0xFF000000)));
      expect(lifecycle.colorAt(1), equals(const Color(0xFFFFFFFF)));
      expect(const ParticleLifecycle().colorAt(0.5), isNull);
    });
  });

  group('ParticleAtlas', () {
    test('packs sprites and adds a circle', () {
      final atlas = ParticleAtlas.pack([
        for (final type in [ParticleType.star, ParticleType.snowflake])
          ParticleSprite.fromPath(
            ParticleShapes.forType(type)!,
            resolution: 32,
          ),
      ], ParticleSprite.fromPath(ParticleShapes.circle, resolution: 16));
      addTearDown(atlas.dispose);

      expect(atlas.regions, hasLength(3));
      expect(atlas.variantCount, equals(2));
      expect(atlas.circleIndex, equals(2));
      expect(atlas.indexFor(0.0), equals(0));
      expect(atlas.indexFor(0.99), equals(1));
      // Regions don't overlap
      expect(atlas.regions[0].rect.overlaps(atlas.regions[1].rect), isFalse);
    });
  });

  group('ParticleSystem features', () {
    test('emitters spawn particles at their rate', () {
      final system = _system(
        const ParticleConfig(
          particleCount: 0,
          emitters: [ParticleEmitter(rate: 30, lifespan: Duration(seconds: 5))],
        ),
      );
      _run(system, 1.0);

      expect(system.burstParticleCount, inInclusiveRange(28, 31));
    });

    test('fireworks shells explode into sparks', () {
      final system = _system(const ParticleConfig(particleCount: 0));
      system.addFireworks(const FireworksRequest(shells: 2, sparkCount: 30));
      _paint(system);
      expect(system.burstParticleCount, equals(2));

      _run(system, 2.5);
      expect(system.burstParticleCount, greaterThan(2));
    });

    test('splashes appear when rain reaches the bottom', () {
      final system = _system(
        const ParticleConfig(
          particleCount: 40,
          animationDuration: Duration(seconds: 1),
          splash: ParticleSplash(lifespan: Duration(seconds: 1)),
        ),
      );
      var sawSplash = false;
      _paint(system);
      for (int i = 0; i < 180 && !sawSplash; i++) {
        system.advance(1 / 60);
        _paint(system);
        sawSplash = system.burstParticleCount > 0;
      }
      expect(sawSplash, isTrue);
    });

    test('falling particles settle on colliders', () {
      final system = _system(
        const ParticleConfig(
          particleCount: 80,
          animationDuration: Duration(seconds: 2),
        ),
      )..colliderRects = [const Rect.fromLTWH(0, 400, 400, 100)];
      _run(system, 3);

      expect(system.burstParticleCount, greaterThan(0));
    });

    test('popAt pops a drawn particle', () {
      const config = ParticleConfig(
        particleCount: 1,
        direction: ParticleDirection.none,
        driftAmplitude: 0,
        seed: 3,
      );
      final system = _system(config);
      _paint(system);
      final particle = system.particles.first;
      final position = Offset(
        particle.initialX * _size.width,
        particle.initialY * _size.height,
      );

      expect(system.particleAt(position), isNotNull);
      final popped = system.popAt(position);
      expect(popped, isNotNull);
      expect(popped!.isBurstParticle, isFalse);
      // The pop burst replaces the particle
      expect(system.burstParticleCount, greaterThan(0));
      _paint(system);
      expect(system.particleAt(position)?.isBurstParticle ?? true, isTrue);
    });

    test('popped wandering particles come back after a cycle', () {
      const config = ParticleConfig(
        particleCount: 1,
        direction: ParticleDirection.none,
        driftAmplitude: 0,
        animationDuration: Duration(seconds: 2),
        seed: 3,
      );
      final system = _system(config);
      _paint(system);
      final particle = system.particles.first;
      final position = Offset(
        particle.initialX * _size.width,
        particle.initialY * _size.height,
      );

      system.popAt(position);
      _run(system, 1);
      // Only the pop burst, which has faded by now, was near the particle
      expect(system.particleAt(position), isNull);

      _run(system, 1.5);
      expect(system.particleAt(position)?.isBurstParticle, isFalse);
    });

    test('maxParticles caps extra particles', () {
      final system = _system(
        const ParticleConfig(particleCount: 10, maxParticles: 30),
      );
      system.addBurst(const BurstRequest(count: 100));
      _paint(system);

      expect(system.burstParticleCount, equals(20));
    });

    test('reset clears bursts and time', () {
      final system = _system(const ParticleConfig(particleCount: 5));
      system.addBurst(const BurstRequest(count: 10));
      _run(system, 0.5);
      system.reset();

      expect(system.seconds, equals(0));
      expect(system.burstParticleCount, equals(0));
    });

    test('connections, trails, depth and parallax paint without errors', () {
      final system =
          _system(
              const ParticleConfig(
                particleCount: 120,
                direction: ParticleDirection.none,
                connections: ParticleConnections(),
                trail: ParticleTrail(),
                depthEffect: 1,
                lifecycle: ParticleLifecycle.ember,
              ),
            )
            ..pointer = const Offset(200, 400)
            ..parallax = const Offset(0, 350);
      system.emitAt(const Offset(100, 100), 20);
      _run(system, 1);
    });
  });

  group('Widget features', () {
    testWidgets('timeScale speeds up the animation', (tester) async {
      final controller = ParticleController(timeScale: 2);
      addTearDown(controller.dispose);
      int cycles = 0;

      await tester.pumpWidget(
        _app(
          ParticleEffects(
            controller: controller,
            config: const ParticleConfig(
              animationDuration: Duration(milliseconds: 100),
            ),
            onAnimationComplete: () => cycles++,
          ),
        ),
      );
      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // 250ms at double speed = 5 cycles
      expect(cycles, equals(5));
      controller.seek(Duration.zero);
      controller.reset();
    });

    testWidgets('fireworks, explode, confetti and burstFromKey emit', (
      tester,
    ) async {
      final controller = ParticleController();
      addTearDown(controller.dispose);
      final buttonKey = GlobalKey();

      await tester.pumpWidget(
        _app(
          ParticleEffects(
            controller: controller,
            config: const ParticleConfig(particleCount: 0),
            child: Center(child: SizedBox(key: buttonKey, width: 50)),
          ),
        ),
      );

      controller
        ..fireworks(shells: 2)
        ..explode(count: 10)
        ..confettiCannon(count: 5)
        ..burstFromKey(buttonKey, count: 7);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(controller.burstParticleCount, equals(2 + 10 + 5 + 5 + 7));
    });

    testWidgets('onParticleTap and popOnTap', (tester) async {
      const config = ParticleConfig(
        particleCount: 1,
        direction: ParticleDirection.none,
        driftAmplitude: 0,
        seed: 3,
      );
      final particle = ParticleData.generate(0, config);
      final tapped = <ParticleTapDetails>[];

      await tester.pumpWidget(
        _app(
          ParticleEffects(
            config: config,
            interaction: ParticleInteraction.pop,
            onParticleTap: tapped.add,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      final size = tester.getSize(find.byType(ParticleEffects));
      await tester.tapAt(
        Offset(particle.initialX * size.width, particle.initialY * size.height),
      );
      await tester.pump();

      expect(tapped, hasLength(1));
    });

    testWidgets('dragging paints particles', (tester) async {
      final controller = ParticleController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          ParticleEffects(
            controller: controller,
            config: const ParticleConfig(particleCount: 0),
            interaction: ParticleInteraction.paint,
          ),
        ),
      );

      await tester.dragFrom(const Offset(100, 100), const Offset(200, 0));
      await tester.pump(const Duration(milliseconds: 16));

      expect(controller.burstParticleCount, greaterThan(0));
    });

    testWidgets('particles settle on collider widgets', (tester) async {
      final controller = ParticleController();
      addTearDown(controller.dispose);
      final cardKey = GlobalKey();

      await tester.pumpWidget(
        _app(
          ParticleEffects(
            controller: controller,
            config: const ParticleConfig(
              particleCount: 80,
              animationDuration: Duration(seconds: 2),
            ),
            colliders: [cardKey],
            child: Align(
              alignment: const Alignment(0, 0.3),
              child: SizedBox(key: cardKey, width: 600, height: 120),
            ),
          ),
        ),
      );
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(controller.burstParticleCount, greaterThan(0));
    });

    testWidgets('emitters can follow a widget', (tester) async {
      final controller = ParticleController();
      addTearDown(controller.dispose);
      final key = GlobalKey();

      await tester.pumpWidget(
        _app(
          ParticleEffects(
            controller: controller,
            config: ParticleConfig(
              particleCount: 0,
              emitters: [ParticleEmitter(followKey: key, rate: 60)],
            ),
            child: Center(child: SizedBox(key: key, width: 20, height: 20)),
          ),
        ),
      );
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(controller.burstParticleCount, greaterThan(0));
    });

    testWidgets('parallax, adaptive quality and new shapes build', (
      tester,
    ) async {
      final parallax = ValueNotifier(Offset.zero);
      addTearDown(parallax.dispose);

      await tester.pumpWidget(
        _app(
          ParticleEffects(
            parallax: parallax,
            adaptiveQuality: true,
            config: const ParticleConfig(
              particleTypes: [
                ParticleType.snowflake,
                ParticleType.sparkle,
                ParticleType.petal,
                ParticleType.raindrop,
                ParticleType.ring,
                ParticleType.triangle,
                ParticleType.diamond,
              ],
              depthEffect: 0.8,
            ),
          ),
        ),
      );
      parallax.value = const Offset(0, 500);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.takeException(), isNull);
    });

    testWidgets('ScrollParallax follows a scroll controller', (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      final parallax = ScrollParallax(scrollController);
      addTearDown(parallax.dispose);

      await tester.pumpWidget(
        _app(
          ListView(
            controller: scrollController,
            children: const [SizedBox(height: 3000)],
          ),
        ),
      );
      scrollController.jumpTo(250);

      expect(parallax.value, equals(const Offset(0, 250)));
    });

    testWidgets('mouse hover feeds connections', (tester) async {
      await tester.pumpWidget(
        _app(const ParticleEffects(config: ParticleConfig.network)),
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: const Offset(200, 200));
      await gesture.moveTo(const Offset(220, 220));
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.takeException(), isNull);
    });
  });
}
