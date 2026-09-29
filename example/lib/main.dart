import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

void main() {
  runApp(const ParticleDemoApp());
}

class ParticleDemoApp extends StatelessWidget {
  const ParticleDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Particle Effects Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const DemoHome(),
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  int _tab = 0;

  static const _pages = [
    PresetsPage(),
    PlaygroundPage(),
    InteractivePage(),
    SourcesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_awesome),
            label: 'Presets',
          ),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Playground'),
          NavigationDestination(
            icon: Icon(Icons.touch_app),
            label: 'Interactive',
          ),
          NavigationDestination(icon: Icon(Icons.image), label: 'Sources'),
        ],
      ),
    );
  }
}

/// Background gradient used behind each preset.
List<Color> _backgroundFor(ParticleEffectType type) {
  return switch (type) {
    ParticleEffectType.snow => const [Color(0xFF0F2027), Color(0xFF2C5364)],
    ParticleEffectType.rain => const [Color(0xFF34495E), Color(0xFF2C3E50)],
    ParticleEffectType.fireAshes => const [
      Color(0xFF2F1B14),
      Color(0xFF8B0000),
    ],
    ParticleEffectType.bubbles => const [Color(0xFF006994), Color(0xFF004B6B)],
    ParticleEffectType.stars => const [Color(0xFF0F0F23), Color(0xFF1A1A2E)],
    ParticleEffectType.hearts => const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    ParticleEffectType.confetti => const [Color(0xFF667DB6), Color(0xFF0082C8)],
    ParticleEffectType.fallingLeaves => const [
      Color(0xFF8B4513),
      Color(0xFF654321),
    ],
    ParticleEffectType.fireflies => const [
      Color(0xFF0B1D0F),
      Color(0xFF1E3A24),
    ],
    ParticleEffectType.starfield => const [
      Color(0xFF000000),
      Color(0xFF0B0B1E),
    ],
  };
}

String _label(String camelCase) {
  final words = camelCase.replaceAllMapped(
    RegExp('([A-Z])'),
    (m) => ' ${m[1]}',
  );
  return words[0].toUpperCase() + words.substring(1);
}

Widget _gradient(List<Color> colors, Widget child) => DecoratedBox(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    ),
  ),
  child: SizedBox.expand(child: child),
);

// ---------------------------------------------------------------------------
// Presets: every built-in effect, with enable and layer toggles
// ---------------------------------------------------------------------------

class PresetsPage extends StatefulWidget {
  const PresetsPage({super.key});

  @override
  State<PresetsPage> createState() => _PresetsPageState();
}

class _PresetsPageState extends State<PresetsPage> {
  ParticleEffectType _effect = ParticleEffectType.snow;
  bool _enabled = true;
  bool _behind = false;

  @override
  Widget build(BuildContext context) {
    return _gradient(
      _backgroundFor(_effect),
      ParticleEffects(
        config: _effect.config,
        isEnabled: _enabled,
        layer: _behind ? ParticleLayer.background : ParticleLayer.foreground,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Particle Effects',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Text('Showing: ${_label(_effect.name)}'),
              SwitchListTile(
                title: const Text('Enable effects'),
                value: _enabled,
                onChanged: (value) => setState(() => _enabled = value),
              ),
              SwitchListTile(
                title: const Text('Paint behind the content'),
                subtitle: const Text('ParticleLayer.background'),
                value: _behind,
                onChanged: (value) => setState(() => _behind = value),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.8,
                  children: [
                    for (final effect in ParticleEffectType.values)
                      FilledButton.tonal(
                        onPressed: () => setState(() => _effect = effect),
                        style: FilledButton.styleFrom(
                          backgroundColor: effect == _effect
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withValues(alpha: 0.15),
                        ),
                        child: Text(_label(effect.name)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Playground: tweak every option live
// ---------------------------------------------------------------------------

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  ParticleType _type = ParticleType.star;
  ParticleDirection _direction = ParticleDirection.topToBottom;
  ParticleCoverage _coverage = ParticleCoverage.full;
  double _count = 60;
  double _speed = 1;
  double _wind = 0;
  double _maxSize = 10;
  double _edgeFade = 0;
  bool _glow = true;
  bool _rotate = true;
  bool _additive = false;
  int _seed = 0;

  ParticleConfig get _config => ParticleConfig(
    particleType: _type,
    direction: _direction,
    particleCoverage: _coverage,
    particleCount: _count.round(),
    minSize: max(1, _maxSize / 3),
    maxSize: _maxSize,
    velocityMultiplier: _speed,
    wind: _wind,
    edgeFade: _edgeFade,
    enableGlow: _glow,
    enableRotation: _rotate,
    blendMode: _additive ? BlendMode.plus : BlendMode.srcOver,
    seed: _seed,
    gradientColors: const [Colors.amber, Colors.cyan, Colors.pinkAccent],
    // Used when the type is ParticleType.path
    customPath: _lightningBolt,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: _gradient(const [
              Color(0xFF141E30),
              Color(0xFF243B55),
            ], ParticleEffects(config: _config)),
          ),
          SizedBox(
            height: 300,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Wrap(
                  spacing: 12,
                  children: [
                    DropdownButton<ParticleType>(
                      value: _type,
                      items: [
                        for (final type in ParticleType.values)
                          if (type != ParticleType.image &&
                              type != ParticleType.custom)
                            DropdownMenuItem(
                              value: type,
                              child: Text(_label(type.name)),
                            ),
                      ],
                      onChanged: (value) => setState(() => _type = value!),
                    ),
                    DropdownButton<ParticleDirection>(
                      value: _direction,
                      items: [
                        for (final direction in ParticleDirection.values)
                          DropdownMenuItem(
                            value: direction,
                            child: Text(_label(direction.name)),
                          ),
                      ],
                      onChanged: (value) => setState(() => _direction = value!),
                    ),
                    DropdownButton<ParticleCoverage>(
                      value: _coverage,
                      items: [
                        for (final coverage in ParticleCoverage.values)
                          DropdownMenuItem(
                            value: coverage,
                            child: Text('Coverage ${_label(coverage.name)}'),
                          ),
                      ],
                      onChanged: (value) => setState(() => _coverage = value!),
                    ),
                  ],
                ),
                _slider('Count', _count, 0, 500, (v) => _count = v),
                _slider('Speed', _speed, 0.1, 3, (v) => _speed = v),
                _slider('Wind', _wind, -1, 1, (v) => _wind = v),
                _slider('Max size', _maxSize, 2, 40, (v) => _maxSize = v),
                _slider('Edge fade', _edgeFade, 0, 0.5, (v) => _edgeFade = v),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Glow'),
                      selected: _glow,
                      onSelected: (v) => setState(() => _glow = v),
                    ),
                    FilterChip(
                      label: const Text('Rotate'),
                      selected: _rotate,
                      onSelected: (v) => setState(() => _rotate = v),
                    ),
                    FilterChip(
                      label: const Text('Additive blend'),
                      selected: _additive,
                      onSelected: (v) => setState(() => _additive = v),
                    ),
                    ActionChip(
                      label: const Text('New layout (seed)'),
                      onPressed: () => setState(() => _seed++),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    void Function(double) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (v) => setState(() => onChanged(v)),
          ),
        ),
        SizedBox(width: 44, child: Text(value.toStringAsFixed(1))),
      ],
    );
  }
}

/// A custom shape for [ParticleType.path]; any coordinates work.
final Path _lightningBolt = Path()
  ..moveTo(14, 0)
  ..lineTo(2, 14)
  ..lineTo(10, 14)
  ..lineTo(6, 24)
  ..lineTo(18, 9)
  ..lineTo(10, 9)
  ..close();

// ---------------------------------------------------------------------------
// Interactive: controller, bursts and pointer interaction
// ---------------------------------------------------------------------------

class InteractivePage extends StatefulWidget {
  const InteractivePage({super.key});

  @override
  State<InteractivePage> createState() => _InteractivePageState();
}

class _InteractivePageState extends State<InteractivePage> {
  final _ambient = ParticleController();
  final _confetti = ParticleController();
  ParticleInteraction _interaction = ParticleInteraction.repel;

  @override
  void dispose() {
    _ambient.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _celebrate() {
    // Two cannons firing up and inwards from the bottom corners
    _confetti
      ..burst(
        alignment: Alignment.bottomLeft,
        angle: -pi / 3,
        spread: pi / 6,
        count: 60,
        minSpeed: 600,
        maxSpeed: 1100,
      )
      ..burst(
        alignment: Alignment.bottomRight,
        angle: -2 * pi / 3,
        spread: pi / 6,
        count: 60,
        minSpeed: 600,
        maxSpeed: 1100,
      );
  }

  @override
  Widget build(BuildContext context) {
    return _gradient(
      const [Color(0xFF1F1C2C), Color(0xFF3A3560)],
      // Two stacked effects: interactive fireflies behind, confetti bursts on
      // top. Bursts use a burst-only config (particleCount: 0).
      ParticleEffects(
        controller: _confetti,
        config: ParticleConfig.confetti.copyWith(particleCount: 0),
        child: ParticleEffects(
          controller: _ambient,
          config: ParticleConfig.fireflies.copyWith(particleCount: 80),
          interaction: _interaction,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Move or tap on the screen',
                    style: TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ParticleInteraction>(
                    segments: const [
                      ButtonSegment(
                        value: ParticleInteraction.repel,
                        label: Text('Repel'),
                      ),
                      ButtonSegment(
                        value: ParticleInteraction.attract,
                        label: Text('Attract'),
                      ),
                      ButtonSegment(
                        value: ParticleInteraction.tapToBurst,
                        label: Text('Tap burst'),
                      ),
                    ],
                    selected: {_interaction},
                    onSelectionChanged: (value) =>
                        setState(() => _interaction = value.first),
                  ),
                  const Spacer(),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ListenableBuilder(
                        listenable: _ambient,
                        builder: (context, _) => FilledButton.icon(
                          onPressed: _ambient.toggle,
                          icon: Icon(
                            _ambient.isPaused ? Icons.play_arrow : Icons.pause,
                          ),
                          label: Text(_ambient.isPaused ? 'Resume' : 'Pause'),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _celebrate,
                        icon: const Icon(Icons.celebration),
                        label: const Text('Celebrate'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _confetti.burst(count: 80),
                        icon: const Icon(Icons.flare),
                        label: const Text('Explode'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sources: images, SVG, ImageProvider, widgets and paths
// ---------------------------------------------------------------------------

class SourcesPage extends StatefulWidget {
  const SourcesPage({super.key});

  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
  static final _sources = <String, ParticleConfig>{
    'Asset PNG': const ParticleConfig(
      particleType: ParticleType.image,
      imagePath: 'assets/icon_flutter.png',
      particleCount: 30,
      minSize: 12,
      maxSize: 28,
      enableRotation: true,
      velocityMultiplier: 0.6,
    ),
    'Network PNG': const ParticleConfig(
      particleType: ParticleType.image,
      imagePath: 'https://img.icons8.com/fluency/48/filled-like--v1.png',
      particleCount: 30,
      minSize: 12,
      maxSize: 24,
      velocityMultiplier: 0.6,
    ),
    'Asset SVG': const ParticleConfig(
      particleType: ParticleType.image,
      imagePath: 'assets/heart.svg',
      direction: ParticleDirection.bottomToTop,
      particleCount: 30,
      minSize: 10,
      maxSize: 26,
      velocityMultiplier: 0.5,
    ),
    'ImageProvider + tint': const ParticleConfig(
      particleType: ParticleType.image,
      image: AssetImage('assets/icon_flutter.png'),
      gradientColors: [Colors.amber, Colors.lightGreenAccent, Colors.cyan],
      particleCount: 40,
      minSize: 10,
      maxSize: 22,
      enableRotation: true,
    ),
    'Custom widget': const ParticleConfig(
      particleType: ParticleType.custom,
      customParticle: Icon(Icons.ac_unit, color: Colors.white),
      particleCount: 40,
      minSize: 10,
      maxSize: 30,
      enableRotation: true,
      velocityMultiplier: 0.5,
    ),
    'Custom path': ParticleConfig(
      particleType: ParticleType.path,
      customPath: _lightningBolt,
      particleColor: Colors.yellowAccent,
      enableGlow: true,
      particleCount: 30,
      minSize: 10,
      maxSize: 24,
      direction: ParticleDirection.diagonal,
    ),
  };

  String _selected = _sources.keys.first;

  @override
  Widget build(BuildContext context) {
    return _gradient(
      const [Color(0xFF16222A), Color(0xFF3A6073)],
      ParticleEffects(
        config: _sources[_selected]!,
        loadingWidget: const CircularProgressIndicator(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in _sources.keys)
                  ChoiceChip(
                    label: Text(name),
                    selected: name == _selected,
                    onSelected: (_) => setState(() => _selected = name),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
