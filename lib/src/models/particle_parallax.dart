import 'package:flutter/widgets.dart';

/// Feeds a [ScrollController]'s offset to `ParticleEffects.parallax`, so
/// particles drift with the page as it scrolls.
///
/// ```dart
/// late final parallax = ScrollParallax(scrollController);
///
/// ParticleEffects(parallax: parallax, config: ..., child: ListView(
///   controller: scrollController, ...
/// ));
///
/// // In dispose():
/// parallax.dispose();
/// ```
///
/// For device tilt, feed accelerometer readings (e.g. from the
/// `sensors_plus` package) into a `ValueNotifier<Offset>` instead.
class ScrollParallax extends ValueNotifier<Offset> {
  /// Tracks [controller] along [axis].
  ScrollParallax(this.controller, {this.axis = Axis.vertical})
    : super(Offset.zero) {
    controller.addListener(_update);
    _update();
  }

  /// The scroll controller being tracked.
  final ScrollController controller;

  /// The scroll direction that moves particles.
  final Axis axis;

  void _update() {
    if (!controller.hasClients) return;
    final offset = controller.offset;
    value = axis == Axis.vertical ? Offset(0, offset) : Offset(offset, 0);
  }

  @override
  void dispose() {
    controller.removeListener(_update);
    super.dispose();
  }
}
