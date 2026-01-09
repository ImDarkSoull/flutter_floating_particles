import 'package:flutter/material.dart';
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

  group('Enum Tests', () {
    test('ParticleType enum values', () {
      expect(ParticleType.values.length, equals(6));
      expect(ParticleType.values, contains(ParticleType.circle));
      expect(ParticleType.values, contains(ParticleType.square));
      expect(ParticleType.values, contains(ParticleType.star));
      expect(ParticleType.values, contains(ParticleType.heart));
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
