import 'package:flutter/material.dart';
import 'package:flutter_floating_particles/flutter_floating_particles.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Particle Effects Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ParticleDemo(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ParticleDemo extends StatefulWidget {
  const ParticleDemo({super.key});

  @override
  State<ParticleDemo> createState() => _ParticleDemoState();
}

class _ParticleDemoState extends State<ParticleDemo> {
  ParticleConfig currentConfig = ParticleConfig.snow;
  bool isEnabled = true;
  String currentEffectName = 'Snow';

  final List<EffectOption> effectOptions = [
    EffectOption(
      'Snow',
      ParticleConfig(
        particleType: ParticleType.circle,
        direction: ParticleDirection.topToBottom,
        particleCoverage: ParticleCoverage.half,
        particleCount: 70,
        minSize: 2.0,
        maxSize: 8.0,
        particleColor: Colors.white,
        enableGlow: true,
        glowRadius: 1.5,
        velocityMultiplier: 0.8,
        animationDuration: Duration(seconds: 15),
        minOpacity: 0.6,
        maxOpacity: 1.0,
      ),
    ),
    EffectOption(
      'Rain',
      ParticleConfig(
        particleType: ParticleType.circle,
        direction: ParticleDirection.topToBottom,
        particleCoverage: ParticleCoverage.quarter,
        particleCount: 100,
        minSize: 1.0,
        maxSize: 3.0,
        particleColor: Color(0xFF4A90E2),
        velocityMultiplier: 0.8,
        animationDuration: Duration(seconds: 10),
        minOpacity: 0.4,
        maxOpacity: 0.8,
        enableBlur: true,
        blurSigma: 0.3,
      ),
    ),
    EffectOption(
      'Fire Ashes',
      ParticleConfig(
        particleType: ParticleType.circle,
        direction: ParticleDirection.topToBottom, // Changed to falling
        particleCoverage: ParticleCoverage.semiFull,
        particleCount: 60,
        minSize: 1.0,
        maxSize: 4.0,
        particleColor: Colors.grey,
        enableGlow: false,
        glowRadius: 6.0,
        velocityMultiplier: 0.4, // Slower falling
        animationDuration: Duration(seconds: 18),
        minOpacity: 0.4,
        maxOpacity: 1.0,
      ),
    ),
    EffectOption(
      'Bubbles',
      ParticleConfig(
        particleType: ParticleType.image,
        direction: ParticleDirection.topToBottom, // Changed to falling
        particleCoverage: ParticleCoverage.semiHalf,
        particleCount: 40,
        minSize: 4.0,

        maxSize: 20.0,
        particleColor: Colors.black,
        minOpacity: 0.2,
        maxOpacity: 0.7,
        enableGlow: true,
        glowRadius: 2.0,
        velocityMultiplier: 0.3, // Very slow falling
        animationDuration: Duration(seconds: 25),
        enableBlur: true,
        blurSigma: 0.5,
      ),
    ),
    EffectOption(
      'Stars',
      ParticleConfig(
        particleType: ParticleType.star,
        direction: ParticleDirection.topToBottom, // Changed to falling
        particleCount: 40,
        minSize: 3.0,
        maxSize: 10.0,
        gradientColors: [Colors.white, Colors.yellow, Colors.lightBlue],
        enableGlow: false,
        glowRadius: 5.0,
        enableRotation: true,
        velocityMultiplier: 0.3,
        animationDuration: Duration(seconds: 25),
        minOpacity: 0.5,
        maxOpacity: 1.0,
      ),
    ),
    EffectOption(
      'Hearts',
      ParticleConfig(
        particleType: ParticleType.heart,
        direction: ParticleDirection.topToBottom, // Changed to falling
        particleCount: 25,
        minSize: 6.0,
        maxSize: 16.0,
        gradientColors: [Colors.pink, Colors.red, Colors.pinkAccent],
        enableGlow: true,
        glowRadius: 1.5,
        velocityMultiplier: 0.4,
        animationDuration: Duration(seconds: 20),
        minOpacity: 0.6,
        maxOpacity: 0.9,
      ),
    ),
    EffectOption(
      'Confetti',
      ParticleConfig(
        particleType: ParticleType.square,
        direction: ParticleDirection.topToBottom, // Already falling
        particleCount: 80,
        minSize: 4.0,
        maxSize: 8.0,
        gradientColors: [
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
        ],
        enableRotation: true,
        velocityMultiplier: 1.2,
        animationDuration: Duration(seconds: 10),
        minOpacity: 0.8,
        maxOpacity: 1.0,
      ),
    ),
    EffectOption(
      'Falling Leaves',
      ParticleConfig(
        particleType: ParticleType.star,
        direction: ParticleDirection.topToBottom, // Already falling
        particleCount: 30,
        minSize: 8.0,
        maxSize: 15.0,
        gradientColors: [
          Colors.orange,
          Colors.red,
          Colors.brown,
          Colors.yellow,
        ],
        enableRotation: true,
        velocityMultiplier: 0.6,
        animationDuration: Duration(seconds: 20),
        minOpacity: 0.7,
        maxOpacity: 1.0,
      ),
    ),
    EffectOption(
      'Flutter Image',
      ParticleConfig(
        particleType: ParticleType.image,
        direction: ParticleDirection.topToBottom, // Already falling
        particleCount: 30,
        imagePath: "assets/icon_flutter.png",
        minSize: 8.0,
        maxSize: 20.0,
        enableRotation: true,
        enableSizeVariation: false,
        velocityMultiplier: 0.6,
        animationDuration: Duration(seconds: 20),
        minOpacity: 0.7,
        maxOpacity: 1.0,
      ),
    ),
    EffectOption(
      'Custom Widget',
      ParticleConfig(
        particleType: ParticleType.custom,
        direction: ParticleDirection.topToBottom, // Already falling
        particleCount: 30,
        customParticle: Text("Flutter"),
        minSize: 8.0,
        maxSize: 150.0,
        enableRotation: true,
        velocityMultiplier: 0.6,
        animationDuration: Duration(seconds: 20),
        minOpacity: 0.7,
        maxOpacity: 1.0,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticleEffects(
        config: currentConfig,
        isEnabled: isEnabled,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _getBackgroundColors(),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Particle Effects',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Currently showing: $currentEffectName',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),

                // Enable/Disable toggle
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Enable Effects',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      SizedBox(width: 10),
                      Switch(
                        value: isEnabled,
                        onChanged: (value) {
                          setState(() {
                            isEnabled = value;
                          });
                        },
                        activeThumbColor: Colors.blue,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // Effect buttons
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: effectOptions.length,
                    itemBuilder: (context, index) {
                      final option = effectOptions[index];
                      final isSelected = currentEffectName == option.name;

                      return ElevatedButton(
                        onPressed: () {
                          setState(() {
                            currentConfig = option.config;
                            currentEffectName = option.name;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Colors.blue
                              : Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          elevation: isSelected ? 8 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          option.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getBackgroundColors() {
    switch (currentEffectName) {
      case 'Snow':
        return [
          Color(0xFF0F2027), // Deep bluish
          Color(0xFF203A43), // Dark cyan/blue
          Color(0xFF2C5364), // Icy blue
        ];
      case 'Rain':
        return [Color(0xFF34495E), Color(0xFF2C3E50)];
      case 'Fire Ashes':
        return [Color(0xFF8B0000), Color(0xFF2F1B14)];
      case 'Bubbles':
        return [Color(0xFF006994), Color(0xFF004B6B)];
      case 'Stars':
        return [Color(0xFF0F0F23), Color(0xFF1A1A2E)];
      case 'Hearts':
        return [Color(0xFF8E2DE2), Color(0xFF4A00E0)];
      case 'Confetti':
        return [Color(0xFF667db6), Color(0xFF0082c8)];
      case 'Falling Leaves':
        return [Color(0xFF8B4513), Color(0xFF654321)];
      default:
        return [Colors.black87, Colors.black54];
    }
  }
}

class EffectOption {
  final String name;
  final ParticleConfig config;

  EffectOption(this.name, this.config);
}
