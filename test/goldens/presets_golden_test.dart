@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders every preset after a fixed amount of time, to catch visual
/// regressions such as rendering artifacts around particles.
void main() {
  for (final type in ParticleEffectType.values) {
    testWidgets('${type.name} preset', (tester) async {
      tester.view.physicalSize = const Size(300, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            child: ColoredBox(
              color: const Color(0xFF101828),
              // A fixed seed keeps bursts and emitters deterministic
              child: ParticleEffects(config: type.config.copyWith(seed: 1)),
            ),
          ),
        ),
      );
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('images/${type.name}.png'),
      );
    });
  }
}
