import 'dart:math';

import 'package:flutter/painting.dart';

/// JSON helpers shared by the configuration classes.
///
/// The readers never throw: values of the wrong type read as null, so
/// hand-edited or partial JSON falls back to the defaults.

/// Encodes [color] as a 32-bit ARGB integer.
int colorToJson(Color color) => color.toARGB32();

/// Decodes a color written by [colorToJson].
Color? readColor(Object? value) => value is int ? Color(value) : null;

/// Decodes a list of colors written by [colorToJson].
List<Color>? readColors(Object? value) {
  if (value is! List) return null;
  return [
    for (final item in value)
      if (item is int) Color(item),
  ];
}

/// Reads a number as a double.
double? readDouble(Object? value) => value is num ? value.toDouble() : null;

/// Reads a number as an int.
int? readInt(Object? value) => value is num ? value.toInt() : null;

/// Reads a bool.
bool? readBool(Object? value) => value is bool ? value : null;

/// Reads a string.
String? readString(Object? value) => value is String ? value : null;

/// Reads a number clamped to [lower] and [upper].
double? readDoubleIn(
  Object? value,
  double lower, [
  double upper = double.infinity,
]) => readDouble(value)?.clamp(lower, upper);

/// Reads a number greater than zero, or null otherwise.
double? readPositive(Object? value) {
  final number = readDouble(value);
  return number != null && number > 0 ? number : null;
}

/// Reads a count, clamped to zero or more.
int? readCount(Object? value) {
  final number = readInt(value);
  return number == null ? null : max(0, number);
}

/// Reads a duration in milliseconds, clamped to [minMs] or more.
Duration? readMs(Object? value, [int minMs = 0]) {
  final ms = readInt(value);
  return ms == null ? null : Duration(milliseconds: max(minMs, ms));
}

/// Reads an enum value by name, falling back to [fallback].
T readEnum<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

/// Encodes an [Offset] or [Alignment]-like pair.
List<double> pairToJson(double x, double y) => [x, y];

/// Reads a pair written by [pairToJson].
(double, double)? readPair(Object? value) {
  if (value is! List || value.length != 2) return null;
  final [x, y] = value;
  if (x is! num || y is! num) return null;
  return (x.toDouble(), y.toDouble());
}

/// Whether two nullable lists have equal elements.
bool listEqualsNullable<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Encodes an [ImageProvider] when it is an [AssetImage] or [NetworkImage].
Object? imageToJson(ImageProvider? image) {
  if (image is AssetImage) return {'asset': image.assetName};
  if (image is NetworkImage) return {'url': image.url};
  return null;
}

/// Decodes an image written by [imageToJson].
ImageProvider? readImage(Object? value) {
  if (value is! Map) return null;
  final asset = value['asset'];
  if (asset is String) return AssetImage(asset);
  final url = value['url'];
  if (url is String) return NetworkImage(url);
  return null;
}
