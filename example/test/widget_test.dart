import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('demo app switches presets and tabs', (tester) async {
    // A phone-sized screen, so every preset button is visible
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ParticleDemoApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Particle Effects'), findsOneWidget);
    expect(find.byType(ParticleEffects), findsWidgets);

    await tester.tap(find.text('Confetti'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Showing: Confetti'), findsOneWidget);

    await tester.tap(find.text('Interactive'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Celebrate'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}
