import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// A full-screen theme page with a back button.
class ThemeScaffold extends StatelessWidget {
  const ThemeScaffold({super.key, required this.child, this.dark = true});

  final Widget child;

  /// Whether the page has a dark background (for the back button style).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          child,
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton.filledTonal(
                  tooltip: 'Back',
                  style: IconButton.styleFrom(
                    backgroundColor: (dark ? Colors.black : Colors.white)
                        .withValues(alpha: 0.3),
                    foregroundColor: dark ? Colors.white : Colors.black87,
                  ),
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A frosted glass panel.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.tint = Colors.white,
    this.radius = 28,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color tint;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tint.withValues(alpha: 0.18),
                tint.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(color: tint.withValues(alpha: 0.25)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Text filled with a gradient, with an optional glow.
class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    required this.style,
    this.glow,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final Gradient gradient;
  final TextStyle style;
  final Color? glow;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    // Centered so the text (and the gradient) are only as wide as the words
    return Center(
      child: ShaderMask(
        shaderCallback: gradient.createShader,
        child: Text(
          text,
          textAlign: textAlign,
          style: style.copyWith(
            color: Colors.white,
            shadows: glow == null
                ? null
                : [Shadow(color: glow!, blurRadius: 28)],
          ),
        ),
      ),
    );
  }
}

/// A glowing pill-shaped button. The glow sits outside the Material, whose
/// ink is clipped to the pill.
class FestiveButton extends StatelessWidget {
  const FestiveButton({
    super.key,
    required this.label,
    required this.gradient,
    required this.onPressed,
    this.glow = const Color(0xFFFFC107),
    this.textColor = const Color(0xFF3A2400),
  });

  final String label;
  final Gradient gradient;
  final VoidCallback onPressed;
  final Color glow;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(color: glow.withValues(alpha: 0.5), blurRadius: 30),
        ],
      ),
      child: Material(
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(gradient: gradient),
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small caption above a title, e.g. "✦ FESTIVAL OF LIGHTS ✦".
class Eyebrow extends StatelessWidget {
  const Eyebrow(
    this.text, {
    super.key,
    required this.color,
    this.letterSpacing = 3,
  });

  final String text;
  final Color color;

  /// Use 0 for scripts such as Devanagari, where spacing breaks up the
  /// connected letters.
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: 12,
        letterSpacing: letterSpacing,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Rebuilds every second, e.g. for countdowns.
class EverySecond extends StatefulWidget {
  const EverySecond({super.key, required this.builder});

  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<EverySecond> createState() => _EverySecondState();
}

class _EverySecondState extends State<EverySecond> {
  late final Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _now);
}

/// Days, hours, minutes and seconds until [target], as glass tiles.
class CountdownTiles extends StatelessWidget {
  const CountdownTiles({
    super.key,
    required this.remaining,
    this.tint = Colors.white,
  });

  final Duration remaining;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final parts = [
      (remaining.inDays, 'DAYS'),
      (remaining.inHours % 24, 'HOURS'),
      (remaining.inMinutes % 60, 'MINUTES'),
      (remaining.inSeconds % 60, 'SECONDS'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (value, label) in parts)
          Container(
            width: 72,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  tint.withValues(alpha: 0.16),
                  tint.withValues(alpha: 0.04),
                ],
              ),
              border: Border.all(color: tint.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  value.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Moves [child] across the screen from right to left on a gentle wave,
/// repeating every [period]. Give [trailKey] to a widget inside [child] to
/// have an emitter follow it.
class Flyer extends StatefulWidget {
  const Flyer({
    super.key,
    required this.child,
    required this.top,
    this.period = const Duration(seconds: 16),
    this.amplitude = 18,
    this.leftToRight = false,
  });

  final Widget child;
  final double top;
  final Duration period;
  final double amplitude;
  final bool leftToRight;

  @override
  State<Flyer> createState() => _FlyerState();
}

class _FlyerState extends State<Flyer> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final travel = width * 1.9;
        final x = widget.leftToRight
            ? -width * 0.6 + t * travel
            : width * 1.25 - t * travel;
        return Positioned(
          left: x,
          top: widget.top + sin(t * 2 * pi * 2) * widget.amplitude,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

/// Calls [action] [count] times, [gap] apart, while [isMounted] is true.
void staggered(
  int count,
  Duration gap,
  bool Function() isMounted,
  void Function(int index) action,
) {
  for (int i = 0; i < count; i++) {
    Future<void>.delayed(gap * i, () {
      if (isMounted()) action(i);
    });
  }
}

/// A footer line crediting the package.
class MadeWith extends StatelessWidget {
  const MadeWith({super.key, this.color = Colors.white70, this.hint});

  final Color color;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        32,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Text(
        [?hint, 'Made with flutter_floating_particles'].join('\n'),
        textAlign: TextAlign.center,
        style: TextStyle(height: 1.6, fontSize: 12, color: color),
      ),
    );
  }
}
