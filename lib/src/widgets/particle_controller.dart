part of 'particle_effects_widget.dart';

/// Controls one or more [ParticleEffects] widgets: pause, resume, slow down,
/// seek and reset the animation, or emit bursts, confetti and fireworks.
///
/// ```dart
/// final controller = ParticleController();
///
/// ParticleEffects(
///   controller: controller,
///   config: ParticleConfig.confetti.copyWith(particleCount: 0),
///   child: ...,
/// );
///
/// // Later, e.g. when the user completes a task:
/// controller.confettiCannon();
/// ```
///
/// Dispose the controller when it is no longer needed.
class ParticleController extends ChangeNotifier {
  /// Creates a controller, optionally starting [paused].
  ParticleController({bool paused = false, double timeScale = 1.0})
    : _isPaused = paused,
      _timeScale = timeScale;

  bool _isPaused;
  double _timeScale;
  final Set<_ParticleEffectsState> _states = {};

  /// Whether the animation is paused. Paused particles stay visible.
  bool get isPaused => _isPaused;

  /// Whether the controller is attached to at least one [ParticleEffects].
  bool get isAttached => _states.isNotEmpty;

  /// Speed of time: 1.0 is normal, 0.5 is slow motion, 2.0 is double speed.
  double get timeScale => _timeScale;

  set timeScale(double value) {
    assert(value >= 0);
    if (value == _timeScale) return;
    _timeScale = value;
    notifyListeners();
  }

  /// Number of live burst, emitted and firework particles across all
  /// attached effects.
  int get burstParticleCount =>
      _states.fold(0, (sum, state) => sum + state._system.burstParticleCount);

  /// Freezes the animation in place.
  void pause() {
    if (_isPaused) return;
    _isPaused = true;
    notifyListeners();
  }

  /// Continues a paused animation.
  void resume() {
    if (!_isPaused) return;
    _isPaused = false;
    notifyListeners();
  }

  /// Pauses if running, resumes if paused.
  void toggle() => _isPaused ? resume() : pause();

  /// Jumps the continuous particles to [position] in the animation.
  void seek(Duration position) {
    for (final state in _states) {
      state._system
        ..seconds = position.inMicroseconds / 1e6
        ..markNeedsPaint();
    }
  }

  /// Restarts the animation and removes all burst particles.
  void reset() {
    for (final state in _states) {
      state._system.reset();
      state._reportedCycles = 0;
    }
  }

  /// Emits [count] particles that fly out and fall under gravity, using the
  /// shape, colors and sizes of the effect's [ParticleConfig].
  ///
  /// The burst starts at [position] (in the effect's local coordinates) or,
  /// if that is null, at [alignment] within the effect. Particles are
  /// launched in a cone [spread] radians wide around [angle] (0 is right,
  /// -pi/2 is up) at between [minSpeed] and [maxSpeed] logical pixels per
  /// second, pulled down by [gravity] (pixels per second squared), slowed
  /// by [drag] (fraction of speed lost per second), and fade out within
  /// [lifespan].
  ///
  /// Bursts work alongside the continuous particles; set
  /// [ParticleConfig.particleCount] to 0 for a burst-only effect. Bursts are
  /// ignored while the effect is disabled or reduced motion is on.
  void burst({
    Offset? position,
    Alignment alignment = Alignment.center,
    int count = 40,
    double angle = -pi / 2,
    double spread = 2 * pi,
    double minSpeed = 150,
    double maxSpeed = 450,
    double gravity = 600,
    double drag = 0.5,
    Duration lifespan = const Duration(seconds: 3),
  }) {
    assert(count >= 0);
    assert(minSpeed >= 0 && maxSpeed >= minSpeed);
    assert(drag >= 0);
    final request = BurstRequest(
      position: position,
      alignment: alignment,
      count: count,
      angle: angle,
      spread: spread,
      minSpeed: minSpeed,
      maxSpeed: maxSpeed,
      gravity: gravity,
      drag: drag,
      lifespan: lifespan,
    );
    for (final state in _states.toList()) {
      state._burst(request);
    }
  }

  /// Bursts particles out of the widget with [key] (e.g. a button), with
  /// the same options as [burst]. Does nothing if the widget isn't shown.
  void burstFromKey(
    GlobalKey key, {
    int count = 40,
    double angle = -pi / 2,
    double spread = 2 * pi,
    double minSpeed = 150,
    double maxSpeed = 450,
    double gravity = 600,
    double drag = 0.5,
    Duration lifespan = const Duration(seconds: 3),
  }) {
    for (final state in _states.toList()) {
      final rect = state._rectOf(key);
      if (rect == null) continue;
      state._burst(
        BurstRequest(
          position: rect.center,
          count: count,
          angle: angle,
          spread: spread,
          minSpeed: minSpeed,
          maxSpeed: maxSpeed,
          gravity: gravity,
          drag: drag,
          lifespan: lifespan,
        ),
      );
    }
  }

  /// An explosion of [count] particles in every direction from [position]
  /// or [alignment].
  void explode({
    Offset? position,
    Alignment alignment = Alignment.center,
    int count = 60,
    double speed = 450,
  }) {
    burst(
      position: position,
      alignment: alignment,
      count: count,
      minSpeed: speed * 0.3,
      maxSpeed: speed,
      gravity: 300,
      drag: 1.0,
      lifespan: const Duration(seconds: 2),
    );
  }

  /// Confetti cannons firing up and inwards from the bottom corners.
  void confettiCannon({int count = 60, bool left = true, bool right = true}) {
    const spread = pi / 6;
    if (left) {
      burst(
        alignment: Alignment.bottomLeft,
        angle: -pi / 3,
        spread: spread,
        count: count,
        minSpeed: 600,
        maxSpeed: 1100,
      );
    }
    if (right) {
      burst(
        alignment: Alignment.bottomRight,
        angle: -2 * pi / 3,
        spread: spread,
        count: count,
        minSpeed: 600,
        maxSpeed: 1100,
      );
    }
  }

  /// Launches [shells] firework shells from the bottom edge that rise and
  /// explode into [sparks] sparks each. Looks best with
  /// [ParticleConfig.fireworks] or another glowing, additive config.
  void fireworks({int shells = 3, int sparks = 70}) {
    assert(shells >= 0 && sparks >= 0);
    final request = FireworksRequest(shells: shells, sparkCount: sparks);
    for (final state in _states.toList()) {
      state._fireworks(request);
    }
  }

  /// Removes all burst particles immediately.
  void clearBursts() {
    for (final state in _states) {
      state._system.clearBursts();
    }
  }

  void _attach(_ParticleEffectsState state) {
    if (_states.add(state)) addListener(state._onControllerChanged);
  }

  void _detach(_ParticleEffectsState state) {
    if (_states.remove(state)) removeListener(state._onControllerChanged);
  }
}
