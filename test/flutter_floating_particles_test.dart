import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';
import 'package:flutter_floating_particles/src/rendering/particle_image_cache.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home) =>
    MaterialApp(debugShowCheckedModeBanner: false, home: home);

/// Number of scheduled frame callbacks, i.e. whether a ticker is running.
int _tickers(WidgetTester tester) => tester.binding.transientCallbackCount;

void _mockAssets(
  WidgetTester tester,
  Future<ByteData?>? Function(ByteData? message) handler,
) {
  tester.binding.defaultBinaryMessenger.setMockMessageHandler(
    'flutter/assets',
    handler,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      null,
    ),
  );
}

void main() {
  tearDown(ParticleEffects.clearImageCache);

  group('ParticleConfig Tests', () {
    test('ParticleConfig default values', () {
      const config = ParticleConfig();

      expect(config.particleType, equals(ParticleType.circle));
      expect(config.direction, equals(ParticleDirection.topToBottom));
      expect(config.particleCount, equals(50));
      expect(config.minSize, equals(2.0));
      expect(config.maxSize, equals(6.0));
      expect(config.animationDuration, equals(const Duration(seconds: 10)));
      expect(config.enableGlow, equals(false));
      expect(config.enableRotation, equals(false));
      expect(config.wind, equals(0.0));
      expect(config.blendMode, equals(BlendMode.srcOver));
    });

    test('ParticleConfig.snow preset', () {
      const config = ParticleConfig.snow;

      expect(config.particleType, equals(ParticleType.snowflake));
      expect(config.direction, equals(ParticleDirection.topToBottom));
      expect(config.particleCount, equals(100));
      expect(config.particleColor, equals(Colors.white));
      expect(config.enableGlow, equals(true));
    });

    test('ParticleConfig.fireAshes preset', () {
      const config = ParticleConfig.fireAshes;

      expect(config.particleType, equals(ParticleType.circle));
      expect(config.direction, equals(ParticleDirection.bottomToTop));
      expect(config.particleCount, equals(30));
      expect(config.enableGlow, equals(true));
      expect(config.gradientColors, isNotNull);
      expect(config.gradientColors!.length, greaterThan(0));
    });

    test('ParticleConfig equality', () {
      const config1 = ParticleConfig(
        particleCount: 100,
        minSize: 2.0,
        maxSize: 8.0,
      );

      const config2 = ParticleConfig(
        particleCount: 100,
        minSize: 2.0,
        maxSize: 8.0,
      );

      const config3 = ParticleConfig(
        particleCount: 50,
        minSize: 2.0,
        maxSize: 8.0,
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('ParticleConfig equality includes gradientColors', () {
      const config1 = ParticleConfig(gradientColors: [Colors.red]);
      const config2 = ParticleConfig(gradientColors: [Colors.red]);
      const config3 = ParticleConfig(gradientColors: [Colors.blue]);

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1, isNot(equals(config3)));
    });

    test('copyWith replaces only the given fields', () {
      final config = ParticleConfig.snow.copyWith(particleCount: 7, wind: 0.5);

      expect(config.particleCount, equals(7));
      expect(config.wind, equals(0.5));
      expect(config.particleColor, equals(ParticleConfig.snow.particleColor));
      expect(config.direction, equals(ParticleConfig.snow.direction));
      expect(ParticleConfig.snow.copyWith(), equals(ParticleConfig.snow));
    });

    test('ParticleEffectType maps to its preset', () {
      expect(ParticleEffectType.snow.config, equals(ParticleConfig.snow));
      expect(ParticleEffectType.rain.config, equals(ParticleConfig.rain));
      expect(
        ParticleEffectType.starfield.config,
        equals(ParticleConfig.starfield),
      );
      for (final type in ParticleEffectType.values) {
        expect(type.config, isA<ParticleConfig>());
      }
    });

    test('ParticleCoverage fractions', () {
      expect(ParticleCoverage.quarter.fraction, equals(0.25));
      expect(ParticleCoverage.full.fraction, equals(1.0));
    });
  });

  group('ParticleData Tests', () {
    test('ParticleData generation with default config', () {
      const config = ParticleConfig();
      final particle = ParticleData.generate(0, config);

      expect(particle.initialX, isA<double>());
      expect(particle.initialY, isA<double>());
      expect(particle.size, greaterThanOrEqualTo(config.minSize));
      expect(particle.size, lessThanOrEqualTo(config.maxSize));
      expect(particle.velocity, isA<double>());
      expect(particle.rotationSpeed, isA<double>());
      expect(particle.animationOffset, isA<double>());
      expect(particle.color, isA<Color>());
    });

    test('ParticleData generation with specific color', () {
      const config = ParticleConfig(particleColor: Colors.red);
      final particle = ParticleData.generate(0, config);

      expect(particle.color, equals(Colors.red));
    });

    test('ParticleData generation with gradient colors', () {
      const config = ParticleConfig(
        gradientColors: [Colors.red, Colors.blue, Colors.green],
      );
      final particle = ParticleData.generate(0, config);

      expect([Colors.red, Colors.blue, Colors.green], contains(particle.color));
    });

    test('ParticleData consistent generation with same seed', () {
      const config = ParticleConfig();
      final particle1 = ParticleData.generate(42, config);
      final particle2 = ParticleData.generate(42, config);

      expect(particle1.initialX, equals(particle2.initialX));
      expect(particle1.initialY, equals(particle2.initialY));
      expect(particle1.size, equals(particle2.size));
      expect(particle1.velocity, equals(particle2.velocity));
    });

    test('config seed changes the layout deterministically', () {
      final a = ParticleData.generate(3, const ParticleConfig(seed: 1));
      final b = ParticleData.generate(3, const ParticleConfig(seed: 1));
      final c = ParticleData.generate(3, const ParticleConfig(seed: 2));

      expect(a.initialX, equals(b.initialX));
      expect(a.initialX, isNot(equals(c.initialX)));
    });

    test('enableSizeVariation: false gives every particle maxSize', () {
      const config = ParticleConfig(
        minSize: 2.0,
        maxSize: 9.0,
        enableSizeVariation: false,
      );

      for (int i = 0; i < 20; i++) {
        expect(ParticleData.generate(i, config).size, equals(9.0));
      }
    });
  });

  group('ParticleEffects Widget Tests', () {
    testWidgets('ParticleEffects creates widget tree correctly', (
      tester,
    ) async {
      const testChild = Text('Test Child');

      await tester.pumpWidget(
        _app(
          const ParticleEffects(config: ParticleConfig.snow, child: testChild),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(Stack), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('ParticleEffects respects isEnabled property', (tester) async {
      const testChild = Text('Test Child');

      await tester.pumpWidget(
        _app(
          const ParticleEffects(
            config: ParticleConfig.snow,
            isEnabled: false,
            child: testChild,
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(CustomPaint), findsNothing);
      expect(_tickers(tester), equals(0));
    });

    testWidgets('ParticleEffects updates when config changes', (tester) async {
      const testChild = Text('Test Child');

      // Start with snow config
      await tester.pumpWidget(
        _app(
          const ParticleEffects(config: ParticleConfig.snow, child: testChild),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);

      // Change to fire ashes config
      await tester.pumpWidget(
        _app(
          const ParticleEffects(
            config: ParticleConfig.fireAshes,
            child: testChild,
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('works without a child', (tester) async {
      await tester.pumpWidget(
        _app(const ParticleEffects(config: ParticleConfig.stars)),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(CustomPaint), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every particle type and direction paints', (tester) async {
      final types = ParticleType.values.where(
        (t) => t != ParticleType.image && t != ParticleType.custom,
      );
      for (final type in types) {
        for (final direction in ParticleDirection.values) {
          await tester.pumpWidget(
            _app(
              ParticleEffects(
                config: ParticleConfig(
                  particleType: type,
                  direction: direction,
                  customPath: Path()..addOval(const Rect.fromLTWH(0, 0, 4, 2)),
                  particleCoverage: ParticleCoverage.half,
                  enableGlow: true,
                  enableBlur: true,
                  enableRotation: true,
                  wind: 0.3,
                  edgeFade: 0.2,
                  gradientColors: const [Colors.red, Colors.blue],
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('child state survives layer and isEnabled changes', (
      tester,
    ) async {
      Widget build(ParticleLayer layer, bool enabled) => _app(
        Material(
          child: ParticleEffects(
            layer: layer,
            isEnabled: enabled,
            child: const TextField(),
          ),
        ),
      );

      await tester.pumpWidget(build(ParticleLayer.foreground, true));
      await tester.enterText(find.byType(TextField), 'kept');

      await tester.pumpWidget(build(ParticleLayer.background, true));
      await tester.pumpWidget(build(ParticleLayer.background, false));
      await tester.pumpWidget(build(ParticleLayer.foreground, true));

      expect(find.text('kept'), findsOneWidget);
    });

    testWidgets('onAnimationComplete fires once per cycle', (tester) async {
      int completedCycles = 0;

      await tester.pumpWidget(
        _app(
          ParticleEffects(
            config: const ParticleConfig(
              animationDuration: Duration(milliseconds: 100),
            ),
            onAnimationComplete: () => completedCycles++,
          ),
        ),
      );

      await tester.pump();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // 250ms of animation = 2 full cycles
      expect(completedCycles, equals(2));
    });

    testWidgets('reduced motion freezes particles', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _app(const ParticleEffects(config: ParticleConfig.snow)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byType(CustomPaint), findsOneWidget);
      expect(_tickers(tester), equals(0));
    });

    testWidgets('respectReduceMotion: false keeps animating', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _app(
            const ParticleEffects(
              config: ParticleConfig.snow,
              respectReduceMotion: false,
            ),
          ),
        ),
      );

      expect(_tickers(tester), greaterThan(0));
    });
  });

  group('ParticleController Tests', () {
    testWidgets('pause and resume stop and restart the animation', (
      tester,
    ) async {
      final controller = ParticleController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          ParticleEffects(controller: controller, config: ParticleConfig.snow),
        ),
      );
      expect(controller.isAttached, isTrue);
      expect(_tickers(tester), greaterThan(0));

      controller.pause();
      await tester.pump();
      expect(controller.isPaused, isTrue);
      expect(_tickers(tester), equals(0));

      controller.toggle();
      await tester.pump();
      expect(controller.isPaused, isFalse);
      expect(_tickers(tester), greaterThan(0));

      await tester.pumpWidget(_app(const SizedBox()));
      expect(controller.isAttached, isFalse);
    });

    testWidgets('burst-only effect ticks only while particles are alive', (
      tester,
    ) async {
      final controller = ParticleController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          ParticleEffects(
            controller: controller,
            config: ParticleConfig.confetti.copyWith(particleCount: 0),
          ),
        ),
      );
      expect(_tickers(tester), equals(0));

      controller.burst(count: 25, lifespan: const Duration(milliseconds: 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(controller.burstParticleCount, equals(25));
      expect(_tickers(tester), greaterThan(0));

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(controller.burstParticleCount, equals(0));
      expect(_tickers(tester), equals(0));
    });

    testWidgets('clearBursts removes burst particles', (tester) async {
      final controller = ParticleController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          ParticleEffects(
            controller: controller,
            config: const ParticleConfig(particleCount: 0),
          ),
        ),
      );

      controller.burst(count: 10);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(controller.burstParticleCount, equals(10));

      controller.clearBursts();
      expect(controller.burstParticleCount, equals(0));
    });

    testWidgets('tap to burst emits particles at the tap', (tester) async {
      await tester.pumpWidget(
        _app(
          const ParticleEffects(
            config: ParticleConfig(particleCount: 0),
            interaction: ParticleInteraction.tapToBurst,
            child: SizedBox.expand(),
          ),
        ),
      );
      expect(_tickers(tester), equals(0));

      await tester.tapAt(const Offset(100, 100));
      await tester.pump();
      expect(_tickers(tester), greaterThan(0));
    });

    testWidgets('interaction does not block taps on the child', (tester) async {
      int taps = 0;
      await tester.pumpWidget(
        _app(
          ParticleEffects(
            interaction: ParticleInteraction.repel,
            child: Center(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap'));
      expect(taps, equals(1));
    });
  });

  group('Image Tests', () {
    testWidgets('a failed image load is not retried every frame', (
      tester,
    ) async {
      int loadAttempts = 0;
      _mockAssets(tester, (message) async {
        loadAttempts++;
        return null; // Asset not found
      });

      await tester.pumpWidget(
        _app(
          const ParticleEffects(
            config: ParticleConfig(
              particleType: ParticleType.image,
              imagePath: 'assets/missing.png',
            ),
            child: SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 16));
      final attemptsAfterFirstFrame = loadAttempts;
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(loadAttempts, equals(attemptsAfterFirstFrame));
    });

    testWidgets('disposing while an image loads does not throw', (
      tester,
    ) async {
      final completer = Completer<ByteData?>();
      _mockAssets(tester, (message) => completer.future);

      await tester.pumpWidget(
        _app(
          const ParticleEffects(
            config: ParticleConfig(
              particleType: ParticleType.image,
              imagePath: 'assets/slow.png',
            ),
            loadingWidget: Text('Loading'),
            child: SizedBox(),
          ),
        ),
      );

      expect(find.text('Loading'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      completer.complete(null);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('ImageProvider particles load and hide the loading widget', (
      tester,
    ) async {
      final bytes = (await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 4, 4),
          Paint()..color = Colors.red,
        );
        final picture = recorder.endRecording();
        final image = picture.toImageSync(4, 4);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        picture.dispose();
        return data!.buffer.asUint8List();
      }))!;

      await tester.pumpWidget(
        _app(
          ParticleEffects(
            config: ParticleConfig(
              particleType: ParticleType.image,
              image: MemoryImage(bytes),
            ),
            loadingWidget: const Text('Loading'),
          ),
        ),
      );
      expect(find.text('Loading'), findsOneWidget);

      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();

      expect(find.text('Loading'), findsNothing);
      expect(_tickers(tester), greaterThan(0));
    });

    testWidgets('different custom widgets of the same type are cached apart', (
      tester,
    ) async {
      const widgetA = ColoredBox(color: Colors.red);
      const widgetB = ColoredBox(color: Colors.blue);

      await tester.runAsync(() async {
        await ParticleEffects.preloadCustomWidget(widgetA, 10);
        await ParticleEffects.preloadCustomWidget(widgetB, 10);
      });

      final imageA = ParticleImageCache.debugPeek(widgetA);
      final imageB = ParticleImageCache.debugPeek(widgetB);

      expect(imageA, isNotNull);
      expect(imageB, isNotNull);
      expect(identical(imageA, imageB), isFalse);
    });

    test('image path detection', () {
      expect(ParticleImageCache.isNetworkPath('https://a.com/x.png'), isTrue);
      expect(ParticleImageCache.isNetworkPath('assets/x.png'), isFalse);
      expect(ParticleImageCache.isSvgPath('assets/x.svg'), isTrue);
      expect(ParticleImageCache.isSvgPath('https://a.com/x.SVG?v=2'), isTrue);
      expect(ParticleImageCache.isSvgPath('assets/x.png'), isFalse);
      expect(
        ParticleImageCache.providerForPath('https://a.com/x.png'),
        isA<NetworkImage>(),
      );
      expect(
        ParticleImageCache.providerForPath('assets/x.png'),
        isA<AssetImage>(),
      );
    });
  });

  group('Enum Tests', () {
    test('ParticleType enum values', () {
      expect(ParticleType.values.length, equals(16));
      expect(ParticleType.values, contains(ParticleType.circle));
      expect(ParticleType.values, contains(ParticleType.square));
      expect(ParticleType.values, contains(ParticleType.star));
      expect(ParticleType.values, contains(ParticleType.heart));
      expect(ParticleType.values, contains(ParticleType.leaf));
      expect(ParticleType.values, contains(ParticleType.streak));
      expect(ParticleType.values, contains(ParticleType.path));
      expect(ParticleType.values, contains(ParticleType.image));
      expect(ParticleType.values, contains(ParticleType.custom));
    });

    test('ParticleDirection enum values', () {
      expect(ParticleDirection.values.length, equals(7));
      expect(ParticleDirection.values, contains(ParticleDirection.topToBottom));
      expect(ParticleDirection.values, contains(ParticleDirection.bottomToTop));
      expect(ParticleDirection.values, contains(ParticleDirection.leftToRight));
      expect(ParticleDirection.values, contains(ParticleDirection.rightToLeft));
      expect(ParticleDirection.values, contains(ParticleDirection.diagonal));
      expect(ParticleDirection.values, contains(ParticleDirection.none));
      expect(ParticleDirection.values, contains(ParticleDirection.radial));
    });

    test('ParticleEffectType enum values', () {
      expect(ParticleEffectType.values.length, equals(14));
      expect(ParticleEffectType.values, contains(ParticleEffectType.snow));
      expect(ParticleEffectType.values, contains(ParticleEffectType.rain));
      expect(ParticleEffectType.values, contains(ParticleEffectType.fireAshes));
      expect(ParticleEffectType.values, contains(ParticleEffectType.bubbles));
    });
  });
}
