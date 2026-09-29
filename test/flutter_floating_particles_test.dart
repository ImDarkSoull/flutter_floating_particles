import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    });

    test('ParticleConfig.snow preset', () {
      const config = ParticleConfig.snow;

      expect(config.particleType, equals(ParticleType.circle));
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
  });

  group('ParticleEffects Widget Tests', () {
    testWidgets('ParticleEffects creates widget tree correctly', (
      tester,
    ) async {
      const testChild = Text('Test Child');

      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ParticleEffects(config: ParticleConfig.snow, child: testChild),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(Stack), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
    });

    testWidgets('ParticleEffects respects isEnabled property', (tester) async {
      const testChild = Text('Test Child');

      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ParticleEffects(
            config: ParticleConfig.snow,
            isEnabled: false,
            child: testChild,
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(CustomPaint), findsNothing);
    });

    testWidgets('ParticleEffects updates when config changes', (tester) async {
      const testChild = Text('Test Child');

      // Start with snow config
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ParticleEffects(config: ParticleConfig.snow, child: testChild),
        ),
      );

      expect(find.byType(CustomPaint), findsOneWidget);

      // Change to fire ashes config
      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ParticleEffects(
            config: ParticleConfig.fireAshes,
            child: testChild,
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });

  group('Regression Tests', () {
    tearDown(ParticleEffects.clearImageCache);

    test('ParticleConfig equality includes gradientColors', () {
      const config1 = ParticleConfig(gradientColors: [Colors.red]);
      const config2 = ParticleConfig(gradientColors: [Colors.red]);
      const config3 = ParticleConfig(gradientColors: [Colors.blue]);

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1, isNot(equals(config3)));
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

    testWidgets('a failed image load is not retried every frame', (
      tester,
    ) async {
      int loadAttempts = 0;
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (message) async {
          loadAttempts++;
          return null; // Asset not found
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'flutter/assets',
          null,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ParticleEffects(
            config: ParticleConfig(
              particleType: ParticleType.image,
              imagePath: 'assets/missing.png',
            ),
            child: SizedBox(),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(loadAttempts, equals(1));
    });

    testWidgets('disposing while an image loads does not throw', (
      tester,
    ) async {
      final completer = Completer<ByteData?>();
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (message) => completer.future,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'flutter/assets',
          null,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ParticleEffects(
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

    testWidgets('onAnimationComplete fires after a cycle', (tester) async {
      int completedCycles = 0;

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: ParticleEffects(
            config: const ParticleConfig(
              animationDuration: Duration(milliseconds: 50),
            ),
            onAnimationComplete: () => completedCycles++,
            child: const SizedBox(),
          ),
        ),
      );

      expect(completedCycles, equals(0));

      // Cycles are timed with the wall clock, so let real time pass
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(completedCycles, equals(1));
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

      final imageA = ParticlePainter.getCustomWidgetImage(widgetA, 10);
      final imageB = ParticlePainter.getCustomWidgetImage(widgetB, 10);

      expect(imageA, isNotNull);
      expect(imageB, isNotNull);
      expect(identical(imageA, imageB), isFalse);
    });
  });

  group('Enum Tests', () {
    test('ParticleType enum values', () {
      expect(ParticleType.values.length, equals(7));
      expect(ParticleType.values, contains(ParticleType.circle));
      expect(ParticleType.values, contains(ParticleType.square));
      expect(ParticleType.values, contains(ParticleType.star));
      expect(ParticleType.values, contains(ParticleType.heart));
      expect(ParticleType.values, contains(ParticleType.leaf));
      expect(ParticleType.values, contains(ParticleType.image));
      expect(ParticleType.values, contains(ParticleType.custom));
    });

    test('ParticleDirection enum values', () {
      expect(ParticleDirection.values.length, equals(5));
      expect(ParticleDirection.values, contains(ParticleDirection.topToBottom));
      expect(ParticleDirection.values, contains(ParticleDirection.bottomToTop));
      expect(ParticleDirection.values, contains(ParticleDirection.leftToRight));
      expect(ParticleDirection.values, contains(ParticleDirection.rightToLeft));
      expect(ParticleDirection.values, contains(ParticleDirection.diagonal));
    });

    test('ParticleEffectType enum values', () {
      expect(ParticleEffectType.values.length, equals(8));
      expect(ParticleEffectType.values, contains(ParticleEffectType.snow));
      expect(ParticleEffectType.values, contains(ParticleEffectType.rain));
      expect(ParticleEffectType.values, contains(ParticleEffectType.fireAshes));
      expect(ParticleEffectType.values, contains(ParticleEffectType.bubbles));
    });
  });
}
