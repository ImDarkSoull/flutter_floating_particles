import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

import '../xmas_page.dart';
import 'arcane_page.dart';
import 'autumn_page.dart';
import 'beach_page.dart';
import 'common.dart';
import 'cosmic_page.dart';
import 'dashain_page.dart';
import 'diwali_page.dart';
import 'halloween_page.dart';
import 'holi_page.dart';
import 'lightspeed_page.dart';
import 'lunar_new_year_page.dart';
import 'new_year_page.dart';
import 'rainy_page.dart';
import 'scenery.dart';
import 'snowy_page.dart';
import 'storm_page.dart';
import 'tech_page.dart';
import 'valentine_page.dart';
import 'vigilante_page.dart';

/// A showcase theme: a card in the gallery and the page it opens.
class _Theme {
  const _Theme({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.colors,
    required this.preview,
    required this.page,
    this.dark = true,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> colors;
  final ParticleConfig preview;
  final WidgetBuilder page;
  final bool dark;
}

final _festivals = <_Theme>[
  _Theme(
    title: 'Dashain',
    subtitle: 'Kites, tika & jamara',
    emoji: '🪁',
    colors: const [Color(0xFF2F80D1), Color(0xFFFFE7C2)],
    dark: false,
    preview: const ParticleConfig(
      particleType: ParticleType.petal,
      particleCount: 16,
      minSize: 5,
      maxSize: 9,
      gradientColors: [Color(0xFFFF9800), Color(0xFFFFC107)],
      enableRotation: true,
      velocityMultiplier: 0.5,
      wind: 0.3,
    ),
    page: (_) => const DashainPage(),
  ),
  _Theme(
    title: 'Christmas',
    subtitle: 'Snow, sleigh & gifts',
    emoji: '🎄',
    colors: const [Color(0xFF0E1638), Color(0xFF3A2456)],
    preview: ParticleConfig.snow.copyWith(particleCount: 30, maxSize: 9),
    page: (_) => const ThemeScaffold(child: XmasPage()),
  ),
  _Theme(
    title: 'Diwali',
    subtitle: 'Diyas & sky lanterns',
    emoji: '🪔',
    colors: const [Color(0xFF2A0839), Color(0xFF6B1E2A)],
    preview: const ParticleConfig(
      direction: ParticleDirection.bottomToTop,
      particleCount: 20,
      minSize: 2,
      maxSize: 5,
      gradientColors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
      enableGlow: true,
      glowRadius: 3,
      blendMode: BlendMode.plus,
      velocityMultiplier: 0.4,
    ),
    page: (_) => const DiwaliPage(),
  ),
  _Theme(
    title: "New Year's Eve",
    subtitle: 'Countdown & fireworks',
    emoji: '🎆',
    colors: const [Color(0xFF01020D), Color(0xFF1C2F5E)],
    preview: ParticleConfig.fireworks.copyWith(
      emitters: const [
        ParticleEmitter(
          extent: Size(10000, 0),
          rate: 0.6,
          fireworks: true,
          sparkCount: 30,
        ),
      ],
    ),
    page: (_) => const NewYearPage(),
  ),
  _Theme(
    title: 'Halloween',
    subtitle: 'Bats, fog & ghosts',
    emoji: '🎃',
    colors: const [Color(0xFF1E0B2F), Color(0xFF3B1242)],
    preview: const ParticleConfig(
      particleType: ParticleType.custom,
      customParticle: Text('👻', style: TextStyle(fontSize: 30)),
      direction: ParticleDirection.none,
      particleCount: 4,
      minSize: 18,
      maxSize: 26,
      driftAmplitude: 30,
      velocityMultiplier: 0.4,
    ),
    page: (_) => const HalloweenPage(),
  ),
  _Theme(
    title: "Valentine's Day",
    subtitle: 'Hearts & rose petals',
    emoji: '💘',
    colors: const [Color(0xFF4A0E3B), Color(0xFFC2185B)],
    preview: ParticleConfig.hearts.copyWith(particleCount: 12, maxSize: 12),
    page: (_) => const ValentinePage(),
  ),
  _Theme(
    title: 'Holi',
    subtitle: 'The festival of colours',
    emoji: '🎨',
    colors: const [Color(0xFFFFF8EE), Color(0xFFFFD6E8)],
    dark: false,
    preview: const ParticleConfig(
      direction: ParticleDirection.none,
      particleCount: 14,
      minSize: 14,
      maxSize: 30,
      gradientColors: [
        Color(0xFFE91E63),
        Color(0xFFFFC107),
        Color(0xFF00C853),
        Color(0xFF2979FF),
      ],
      enableBlur: true,
      blurSigma: 4,
      maxOpacity: 0.6,
      driftAmplitude: 20,
    ),
    page: (_) => const HoliPage(),
  ),
  _Theme(
    title: 'Lunar New Year',
    subtitle: 'Lanterns, dragon & coins',
    emoji: '🏮',
    colors: const [Color(0xFF3D0404), Color(0xFFC62828)],
    preview: const ParticleConfig(
      particleTypes: [ParticleType.circle, ParticleType.sparkle],
      particleCount: 18,
      minSize: 3,
      maxSize: 7,
      gradientColors: [Color(0xFFFFD54F), Color(0xFFFFE082)],
      enableGlow: true,
      glowRadius: 2,
      velocityMultiplier: 0.5,
    ),
    page: (_) => const LunarNewYearPage(),
  ),
];

final _weather = <_Theme>[
  _Theme(
    title: 'Rainy Day',
    subtitle: 'Drops on the window & chai',
    emoji: '🌧️',
    colors: const [Color(0xFF3D4B5C), Color(0xFF5A4636)],
    preview: ParticleConfig.rain.copyWith(
      particleCount: 40,
      particleColor: const Color(0xFFCFE0F0),
    ),
    page: (_) => const RainyPage(),
  ),
  _Theme(
    title: 'Thunderstorm',
    subtitle: 'Tap to call down lightning',
    emoji: '⛈️',
    colors: const [Color(0xFF0B0F17), Color(0xFF2D3A4A)],
    preview: ParticleConfig.rain.copyWith(
      particleCount: 60,
      velocityMultiplier: 1.9,
      wind: 0.35,
      particleColor: const Color(0xFFB8CCE6),
    ),
    page: (_) => const StormPage(),
  ),
  _Theme(
    title: 'Snowy Mountains',
    subtitle: 'A cabin in the blizzard',
    emoji: '🏔️',
    colors: const [Color(0xFF141B33), Color(0xFF6B6F9E)],
    preview: ParticleConfig.blizzard.copyWith(particleCount: 40, maxSize: 9),
    page: (_) => const SnowyPage(),
  ),
  _Theme(
    title: 'Sunny Beach',
    subtitle: 'Waves, sand & seagulls',
    emoji: '🏖️',
    colors: const [Color(0xFF3FA9F5), Color(0xFFE9D2A8)],
    dark: false,
    preview: const ParticleConfig(
      particleType: ParticleType.sparkle,
      direction: ParticleDirection.none,
      particleCount: 14,
      minSize: 3,
      maxSize: 7,
      particleColor: Color(0xFFFFF8E1),
      enableGlow: true,
      glowRadius: 2,
      driftAmplitude: 20,
    ),
    page: (_) => const BeachPage(),
  ),
  _Theme(
    title: 'Autumn Forest',
    subtitle: 'Leaves, gusts & mushrooms',
    emoji: '🍂',
    colors: const [Color(0xFFE08A3C), Color(0xFF3E2415)],
    preview: ParticleConfig.fallingLeaves.copyWith(
      particleCount: 12,
      maxSize: 11,
    ),
    page: (_) => const AutumnPage(),
  ),
];

final _heroes = <_Theme>[
  _Theme(
    title: 'Cosmic Force',
    subtitle: 'Power blasts & runes',
    emoji: '🌌',
    colors: const [Color(0xFF05010F), Color(0xFF2A0E4A)],
    preview: const ParticleConfig(
      particleType: ParticleType.streak,
      direction: ParticleDirection.radial,
      particleCount: 30,
      minSize: 4,
      maxSize: 10,
      particleColor: Color(0xFFE1D5FF),
      velocityMultiplier: 0.8,
      animationDuration: Duration(seconds: 4),
      enableOpacityAnimation: false,
    ),
    page: (_) => const CosmicPage(),
  ),
  _Theme(
    title: 'Night Watch',
    subtitle: 'A caped guardian & bat swarm',
    emoji: '🦇',
    colors: const [Color(0xFF05080F), Color(0xFF4A3B34)],
    preview: ParticleConfig(
      particleType: ParticleType.path,
      customPath: batPath,
      direction: ParticleDirection.leftToRight,
      particleCount: 5,
      minSize: 10,
      maxSize: 18,
      particleColor: const Color(0xFF8FA3C7),
      velocityMultiplier: 0.6,
      enableOpacityAnimation: false,
      driftAmplitude: 20,
    ),
    page: (_) => const VigilantePage(),
  ),
  _Theme(
    title: 'Lightspeed',
    subtitle: 'Speed trails & slow-mo',
    emoji: '⚡',
    colors: const [Color(0xFF7A1C00), Color(0xFF0D0200)],
    preview: const ParticleConfig(
      particleType: ParticleType.streak,
      direction: ParticleDirection.radial,
      particleCount: 30,
      minSize: 6,
      maxSize: 16,
      gradientColors: [Color(0xFFFFD180), Color(0xFFFF6E40)],
      velocityMultiplier: 1.4,
      animationDuration: Duration(seconds: 4),
      blendMode: BlendMode.plus,
    ),
    page: (_) => const LightspeedPage(),
  ),
  _Theme(
    title: 'Tech Suit',
    subtitle: 'HUD & repulsors',
    emoji: '🤖',
    colors: const [Color(0xFF06243A), Color(0xFF020A14)],
    preview: ParticleConfig.network.copyWith(
      particleCount: 16,
      particleColor: const Color(0xFF80D8FF),
      connections: const ParticleConnections(
        maxDistance: 70,
        color: Color(0xFF40C4FF),
      ),
    ),
    page: (_) => const TechPage(),
  ),
  _Theme(
    title: 'Arcane',
    subtitle: 'Draw spells & open portals',
    emoji: '🔮',
    colors: const [Color(0xFF2A0E4A), Color(0xFF0B0418)],
    preview: const ParticleConfig(
      particleType: ParticleType.sparkle,
      direction: ParticleDirection.bottomToTop,
      particleCount: 16,
      minSize: 3,
      maxSize: 7,
      gradientColors: [Color(0xFFFFD54F), Color(0xFFE1BEE7)],
      enableGlow: true,
      glowRadius: 2,
      blendMode: BlendMode.plus,
    ),
    page: (_) => const ArcanePage(),
  ),
];

final _sections = [
  ('Festivals', _festivals),
  ('Weather & Moods', _weather),
  ('Superheroes', _heroes),
];

/// A gallery of complete themed pages built with the package.
class ThemesGallery extends StatelessWidget {
  const ThemesGallery({super.key});

  @override
  Widget build(BuildContext context) {
    // Pause the previews while a theme page is open on top
    return TickerMode(
      enabled: ModalRoute.isCurrentOf(context) ?? true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1025), Color(0xFF1B1440)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Themes',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete pages built with flutter_floating_particles',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            for (final (title, themes) in _sections) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.78,
                  children: [for (final theme in themes) _ThemeCard(theme)],
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard(this.theme);

  final _Theme theme;

  @override
  Widget build(BuildContext context) {
    final textColor = theme.dark ? Colors.white : const Color(0xFF3E2723);
    return Material(
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: theme.page)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: theme.colors,
            ),
          ),
          child: ParticleEffects(
            config: theme.preview,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(theme.emoji, style: const TextStyle(fontSize: 42)),
                  const SizedBox(height: 8),
                  Text(
                    theme.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    theme.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
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
