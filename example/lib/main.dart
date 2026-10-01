import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import 'code_export.dart';
import 'themes/gallery.dart';

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
    ThemesGallery(),
    PresetsPage(),
    PlaygroundPage(),
    InteractivePage(),
    SourcesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Only the visible page animates
      body: IndexedStack(
        index: _tab,
        children: [
          for (int i = 0; i < _pages.length; i++)
            TickerMode(enabled: i == _tab, child: _pages[i]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.celebration), label: 'Themes'),
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
    ParticleEffectType.fireworks => const [
      Color(0xFF020111),
      Color(0xFF191970),
    ],
    ParticleEffectType.sakura => const [Color(0xFF6A4C93), Color(0xFFF8C8DC)],
    ParticleEffectType.network => const [Color(0xFF0F2027), Color(0xFF203A43)],
    ParticleEffectType.blizzard => const [Color(0xFF1E3C72), Color(0xFF2A5298)],
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
  /// The starting point: what the page opens with, or an imported config.
  /// The controls adjust it, and options they don't cover are kept.
  static const _defaults = ParticleConfig(
    particleType: ParticleType.star,
    particleCount: 60,
    maxSize: 10,
    enableGlow: true,
    enableRotation: true,
    gradientColors: [Color(0xFFFFC107), Color(0xFF00BCD4), Color(0xFFFF4081)],
  );

  ParticleConfig _base = _defaults;
  late ParticleType _type;
  late ParticleDirection _direction;
  late ParticleCoverage _coverage;
  late double _count;
  late double _speed;
  late double _wind;
  late double _maxSize;
  late double _edgeFade;
  late bool _glow;
  late bool _rotate;
  late bool _additive;
  late bool _depth;
  late bool _trail;
  late bool _connections;
  late bool _shrink;
  late bool _splash;
  late bool _mixed;
  late int _seed;

  @override
  void initState() {
    super.initState();
    _load(_defaults);
  }

  /// Sets the controls from [config].
  void _load(ParticleConfig config) {
    _base = config;
    // Custom widgets can't come from JSON
    _type = config.particleType == ParticleType.custom
        ? ParticleType.circle
        : config.particleType;
    _direction = config.direction;
    _coverage = config.particleCoverage;
    _count = config.particleCount.toDouble();
    _speed = config.velocityMultiplier;
    _wind = config.wind;
    _maxSize = config.maxSize;
    _edgeFade = config.edgeFade;
    _glow = config.enableGlow;
    _rotate = config.enableRotation;
    _additive = config.blendMode == BlendMode.plus;
    _depth = config.depthEffect > 0;
    _trail = config.trail != null;
    _connections = config.connections != null;
    _shrink = config.lifecycle != null;
    _splash = config.splash != null;
    _mixed = config.particleTypes != null;
    _seed = config.seed ?? 0;
  }

  ParticleConfig get _config {
    final base = _base;
    final json = base.toJson()
      ..addAll({
        'particleType': _type.name,
        'direction': _direction.name,
        'particleCoverage': _coverage.name,
        'particleCount': _count.round(),
        'minSize': identical(base, _defaults)
            ? max(1.0, _maxSize / 3)
            : min(base.minSize, _maxSize),
        'maxSize': _maxSize,
        'velocityMultiplier': _speed,
        'wind': _wind,
        'edgeFade': _edgeFade,
        'enableGlow': _glow,
        'enableRotation': _rotate,
        'blendMode': _additive
            ? BlendMode.plus.name
            : base.blendMode == BlendMode.plus
            ? BlendMode.srcOver.name
            : base.blendMode.name,
        'seed': _seed,
        'depthEffect': _depth
            ? (base.depthEffect > 0 ? base.depthEffect : 0.8)
            : 0.0,
      });
    // Toggles keep the imported options, or add sensible ones
    void toggle(String key, bool on, Object? fallback) {
      on ? json[key] ??= fallback : json.remove(key);
    }

    toggle('particleTypes', _mixed, const ['star', 'heart', 'sparkle']);
    toggle('trail', _trail, const ParticleTrail(length: 8).toJson());
    toggle('connections', _connections, const ParticleConnections().toJson());
    toggle('lifecycle', _shrink, ParticleLifecycle.shrink.toJson());
    toggle('splash', _splash, const ParticleSplash().toJson());
    return ParticleConfig.fromJson(json).copyWith(
      // Used when the type is ParticleType.path
      customPath: _lightningBolt,
    );
  }

  Future<void> _import() async {
    final config = await showModalBottomSheet<ParticleConfig>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ImportSheet(),
    );
    if (config == null || !mounted) return;
    setState(() => _load(config));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Config imported')));
  }

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
                          // Images only when an imported config has one
                          if (type != ParticleType.custom &&
                              (type != ParticleType.image ||
                                  _type == ParticleType.image))
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
                    for (final (label, value, set) in [
                      ('Mix shapes', _mixed, (bool v) => _mixed = v),
                      ('Depth', _depth, (bool v) => _depth = v),
                      ('Trail', _trail, (bool v) => _trail = v),
                      (
                        'Connections',
                        _connections,
                        (bool v) => _connections = v,
                      ),
                      ('Shrink over life', _shrink, (bool v) => _shrink = v),
                      ('Splash', _splash, (bool v) => _splash = v),
                    ])
                      FilterChip(
                        label: Text(label),
                        selected: value,
                        onSelected: (v) => setState(() => set(v)),
                      ),
                    ActionChip(
                      label: const Text('New layout (seed)'),
                      onPressed: () => setState(() => _seed++),
                    ),
                    if (!identical(_base, _defaults))
                      ActionChip(
                        avatar: const Icon(Icons.restart_alt, size: 18),
                        label: const Text('Reset'),
                        onPressed: () => setState(() => _load(_defaults)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => _showExport(context, _config),
                  icon: const Icon(Icons.code),
                  label: const Text('Export as Dart code or JSON'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _import,
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text('Import JSON'),
                ),
                const SizedBox(height: 16),
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
    double lower,
    double upper,
    void Function(double) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            // Widened for imported values outside the usual range
            min: min(lower, value),
            max: max(upper, value),
            onChanged: (v) => setState(() => onChanged(v)),
          ),
        ),
        SizedBox(width: 44, child: Text(value.toStringAsFixed(1))),
      ],
    );
  }
}

/// Shows [config] as Dart code and JSON, ready to copy.
void _showExport(BuildContext context, ParticleConfig config) {
  final dart = configToDart(config);
  final json = const JsonEncoder.withIndent('  ').convert(config.toJson());
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DefaultTabController(
      length: 2,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Dart'),
                Tab(text: 'JSON'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  for (final code in [dart, json])
                    Stack(
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            code,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: IconButton.filledTonal(
                            tooltip: 'Copy',
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied')),
                              );
                            },
                          ),
                        ),
                      ],
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

/// Paste JSON from the export sheet (or anywhere else) to load it.
class _ImportSheet extends StatefulWidget {
  const _ImportSheet();

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text case final text?) {
      setState(() {
        _text.text = text;
        _error = null;
      });
    }
  }

  void _submit() {
    try {
      final json = jsonDecode(_text.text);
      if (json is! Map<String, Object?>) {
        setState(() => _error = 'Expected a JSON object: { ... }');
        return;
      }
      Navigator.of(context).pop(ParticleConfig.fromJson(json));
    } on FormatException catch (error) {
      setState(() => _error = 'Not valid JSON: ${error.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Import JSON', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Paste a config exported from here or made with '
            'ParticleConfig.toJson(). Missing options use their defaults.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            minLines: 6,
            maxLines: 12,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: '{\n  "particleType": "snowflake",\n  ...\n}',
              errorText: _error,
              errorMaxLines: 3,
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste),
                label: const Text('Paste'),
              ),
              const Spacer(),
              FilledButton(onPressed: _submit, child: const Text('Import')),
            ],
          ),
        ],
      ),
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
  final _fireworks = ParticleController();
  ParticleInteraction _interaction = ParticleInteraction.repel;

  static const _modes = {
    'Repel': ParticleInteraction.repel,
    'Attract': ParticleInteraction.attract,
    'Tap burst': ParticleInteraction.tapToBurst,
    'Pop': ParticleInteraction.pop,
    'Paint': ParticleInteraction.paint,
  };

  @override
  void dispose() {
    _ambient.dispose();
    _confetti.dispose();
    _fireworks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _gradient(
      const [Color(0xFF1F1C2C), Color(0xFF3A3560)],
      // Stacked effects: fireworks at the back, interactive fireflies in the
      // middle, confetti bursts on top. Bursts use burst-only configs
      // (particleCount: 0).
      ParticleEffects(
        controller: _fireworks,
        layer: ParticleLayer.background,
        config: ParticleConfig.fireworks.copyWith(emitters: const []),
        child: ParticleEffects(
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
                      'Move, tap or drag on the screen',
                      style: TextStyle(fontSize: 22),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final MapEntry(key: label, value: mode)
                            in _modes.entries)
                          ChoiceChip(
                            label: Text(label),
                            selected: _interaction == mode,
                            onSelected: (_) =>
                                setState(() => _interaction = mode),
                          ),
                      ],
                    ),
                    const Spacer(),
                    ListenableBuilder(
                      listenable: _ambient,
                      builder: (context, _) => Row(
                        children: [
                          const Text('Speed'),
                          Expanded(
                            child: Slider(
                              value: _ambient.timeScale,
                              min: 0,
                              max: 3,
                              onChanged: (v) => _ambient.timeScale = v,
                            ),
                          ),
                          Text('${_ambient.timeScale.toStringAsFixed(1)}x'),
                        ],
                      ),
                    ),
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
                              _ambient.isPaused
                                  ? Icons.play_arrow
                                  : Icons.pause,
                            ),
                            label: Text(_ambient.isPaused ? 'Resume' : 'Pause'),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _ambient.reset,
                          icon: const Icon(Icons.replay),
                          label: const Text('Reset'),
                        ),
                        FilledButton.icon(
                          onPressed: () => _confetti.confettiCannon(),
                          icon: const Icon(Icons.celebration),
                          label: const Text('Confetti'),
                        ),
                        FilledButton.icon(
                          onPressed: () => _confetti.explode(count: 80),
                          icon: const Icon(Icons.flare),
                          label: const Text('Explode'),
                        ),
                        FilledButton.icon(
                          onPressed: () => _fireworks.fireworks(shells: 4),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Fireworks'),
                        ),
                      ],
                    ),
                  ],
                ),
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
