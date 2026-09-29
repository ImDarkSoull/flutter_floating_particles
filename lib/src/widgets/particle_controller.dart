part of 'particle_effects_widget.dart';

/// Controls one or more [ParticleEffects] widgets: pause and resume the
/// animation, or emit one-shot bursts of particles.
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
/// controller.burst(alignment: Alignment.bottomCenter, spread: pi / 3);
/// ```
///
/// Dispose the controller when it is no longer needed.
class ParticleController extends ChangeNotifier {
  /// Creates a controller, optionally starting [paused].
  ParticleController({bool paused = false}) : _isPaused = paused;

  bool _isPaused;
  final Set<_ParticleEffectsState> _states = {};

  /// Whether the animation is paused. Paused particles stay visible.
  bool get isPaused => _isPaused;

  /// Whether the controller is attached to at least one [ParticleEffects].
  bool get isAttached => _states.isNotEmpty;

  /// Number of live burst particles across all attached effects.
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
