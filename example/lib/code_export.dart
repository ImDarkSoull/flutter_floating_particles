import 'dart:convert';

import 'package:flutter_floating_particles/flutter_floating_particles.dart';

/// Turns a [ParticleConfig] into the Dart code that creates it, listing
/// only the fields that differ from the defaults.
///
/// Built on [ParticleConfig.toJson], so fields that can't be serialized
/// (custom widgets and paths) are left out.
String configToDart(ParticleConfig config) {
  final json = config.toJson();
  final defaults = const ParticleConfig().toJson();
  final fields = <String>[];
  json.forEach((key, value) {
    if (jsonEncode(defaults[key]) == jsonEncode(value)) return;
    fields.add(_field(key, value));
  });
  if (fields.isEmpty) return 'const ParticleConfig()';
  return 'const ParticleConfig(\n${fields.map((f) => '  $f,').join('\n')}\n)';
}

String _field(String key, Object? value) {
  switch (key) {
    case 'particleType':
      return 'particleType: ParticleType.$value';
    case 'direction':
      return 'direction: ParticleDirection.$value';
    case 'particleCoverage':
      return 'particleCoverage: ParticleCoverage.$value';
    case 'blendMode':
      return 'blendMode: BlendMode.$value';
    case 'animationDurationMs':
      return 'animationDuration: Duration(milliseconds: $value)';
    case 'particleColor':
      return 'particleColor: ${_color(value)}';
    case 'gradientColors':
      return 'gradientColors: ${_colors(value)}';
    case 'particleTypes':
      final types = (value as List).map((t) => 'ParticleType.$t');
      return 'particleTypes: [${types.join(', ')}]';
    case 'lifecycle':
      return 'lifecycle: ${_object('ParticleLifecycle', value)}';
    case 'trail':
      return 'trail: ${_object('ParticleTrail', value)}';
    case 'splash':
      return 'splash: ${_object('ParticleSplash', value)}';
    case 'connections':
      return 'connections: ${_object('ParticleConnections', value)}';
    case 'emitters':
      final emitters = (value as List).map(
        (e) => _object('ParticleEmitter', e),
      );
      return 'emitters: [${emitters.join(', ')}]';
    case 'image':
      return 'image: ${_image(value)}';
    case 'images':
      return 'images: [${(value as List).map(_image).join(', ')}]';
    default:
      return '$key: ${_literal(value)}';
  }
}

/// A nested options class, e.g. `ParticleTrail(length: 6)`.
String _object(String className, Object? value) {
  final map = value as Map<String, Object?>;
  final args = <String>[];
  map.forEach((key, v) {
    switch (key) {
      case 'spacingMs':
        args.add('spacing: Duration(milliseconds: $v)');
      case 'lifespanMs':
        args.add('lifespan: Duration(milliseconds: $v)');
      case 'color':
        args.add('color: ${_color(v)}');
      case 'colors':
        args.add('colors: ${_colors(v)}');
      case 'alignment':
        final pair = v as List;
        args.add('alignment: Alignment(${pair[0]}, ${pair[1]})');
      case 'position':
        final pair = v as List;
        args.add('position: Offset(${pair[0]}, ${pair[1]})');
      case 'extent':
        final pair = v as List;
        args.add('extent: Size(${pair[0]}, ${pair[1]})');
      default:
        args.add('$key: ${_literal(v)}');
    }
  });
  return '$className(${args.join(', ')})';
}

String _image(Object? value) {
  final map = value as Map;
  if (map['asset'] != null) return "AssetImage('${map['asset']}')";
  return "NetworkImage('${map['url']}')";
}

String _color(Object? value) =>
    'Color(0x${(value as int).toRadixString(16).padLeft(8, '0').toUpperCase()})';

String _colors(Object? value) => '[${(value as List).map(_color).join(', ')}]';

String _literal(Object? value) {
  if (value is String) return "'$value'";
  if (value is double) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(1)
        : double.parse(value.toStringAsFixed(3)).toString();
  }
  return '$value';
}
