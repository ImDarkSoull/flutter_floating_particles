import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpFrames(WidgetTester tester, [int count = 10]) async {
    for (int i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Scrolls [text] fully on screen and taps it.
  Future<void> tapOnScreen(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await pumpFrames(tester);
  }

  Future<void> openTheme(WidgetTester tester, String title) async {
    await tester.scrollUntilVisible(
      find.text(title),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(title));
    await tester.pump();
    await tester.tap(find.text(title));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await pumpFrames(tester);
  }

  Future<void> goBack(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  void phoneScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  testWidgets('every themed page opens and reacts', (tester) async {
    phoneScreen(tester);
    await tester.pumpWidget(const ParticleDemoApp());
    await pumpFrames(tester, 2);
    expect(find.text('Themes'), findsWidgets);

    await openTheme(tester, 'Dashain');
    // Layered lettering draws the text more than once
    expect(find.text('Happy\nDashain'), findsWidgets);
    await tapOnScreen(tester, '🙏  Receive tika');
    await goBack(tester);

    await openTheme(tester, 'Christmas');
    expect(find.text('Merry\nChristmas'), findsOneWidget);
    await tapOnScreen(tester, 'Tap the tree ✨');
    await tapOnScreen(tester, '🎆  Celebrate');
    await goBack(tester);

    await openTheme(tester, 'Diwali');
    await tapOnScreen(tester, '🪔  Blow out');
    await tapOnScreen(tester, '🎆  Fireworks');
    await pumpFrames(tester, 20);
    await goBack(tester);

    await openTheme(tester, "New Year's Eve");
    expect(find.text('Happy New Year'), findsOneWidget);
    await tapOnScreen(tester, '💪  Health');
    await goBack(tester);

    await openTheme(tester, 'Halloween');
    expect(find.text('Happy\nHalloween'), findsOneWidget);
    await goBack(tester);

    await openTheme(tester, "Valentine's Day");
    await tapOnScreen(tester, '💘  Send love');
    await goBack(tester);

    await openTheme(tester, 'Holi');
    // Layered lettering draws the text more than once
    expect(find.text('Happy\nHoli'), findsWidgets);
    await tester.tapAt(const Offset(180, 400));
    await pumpFrames(tester);
    await goBack(tester);

    await openTheme(tester, 'Lunar New Year');
    await tapOnScreen(tester, '🧨  Light firecrackers');
    await pumpFrames(tester, 20);
    await goBack(tester);

    // Weather and superhero pages
    for (final title in [
      'Rainy Day',
      'Thunderstorm',
      'Snowy Mountains',
      'Sunny Beach',
      'Autumn Forest',
      'Cosmic Force',
      'Night Watch',
      'Lightspeed',
      'Tech Suit',
      'Arcane',
    ]) {
      await openTheme(tester, title);
      await tester.tapAt(const Offset(200, 500));
      await pumpFrames(tester);
      expect(tester.takeException(), isNull, reason: title);
      await goBack(tester);
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('the other tabs work', (tester) async {
    phoneScreen(tester);
    await tester.pumpWidget(const ParticleDemoApp());
    await pumpFrames(tester, 2);

    // Presets
    await tester.tap(find.text('Presets'));
    await pumpFrames(tester, 2);
    await tester.tap(find.text('Confetti'));
    await pumpFrames(tester, 2);
    expect(find.text('Showing: Confetti'), findsOneWidget);

    // Playground export
    await tester.tap(find.text('Playground'));
    await pumpFrames(tester, 2);
    await tester.scrollUntilVisible(
      find.text('Export as Dart code or JSON'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Export as Dart code or JSON'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('ParticleConfig('), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 500));

    // Playground import: bad JSON shows an error, good JSON loads
    await tester.scrollUntilVisible(
      find.text('Import JSON'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Import JSON'));
    // One frame to start the sheet's animation, then let it finish
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField), '{ not json');
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pump();
    expect(find.textContaining('Not valid JSON'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      '{"particleType": "snowflake", "particleCount": 700, '
      '"direction": "bottomToTop", "trail": {"length": 4}}',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Config imported'), findsOneWidget);
    // Dismiss the snack bar so it doesn't cover the controls
    ScaffoldMessenger.of(
      tester.element(find.text('Config imported')),
    ).removeCurrentSnackBar();
    // And let the import sheet finish closing
    await tester.pump(const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(
      find.text('Snowflake'),
      -200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('700.0'), findsOneWidget);

    // Interactive
    await tester.tap(find.text('Interactive'));
    await pumpFrames(tester, 2);
    await tester.tap(find.text('Fireworks'));
    await pumpFrames(tester, 2);

    expect(find.byType(ParticleEffects), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
