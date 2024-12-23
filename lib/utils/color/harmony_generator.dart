import 'package:flutter/material.dart';

enum HarmonyType {
  auto,
  monochromatic,
  analogous,
  complementary,
  splitComplementary,
  triadic,
  tetradic,
  square
}

class HarmonyGenerator {
  static List<Color> generateHarmony(Color baseColor, HarmonyType type) {
    switch (type) {
      case HarmonyType.auto:
        return _generateMonochromatic(baseColor);
      case HarmonyType.monochromatic:
        return _generateMonochromatic(baseColor);
      case HarmonyType.analogous:
        return _generateAnalogous(baseColor);
      case HarmonyType.complementary:
        return _generateComplementary(baseColor);
      case HarmonyType.splitComplementary:
        return _generateSplitComplementary(baseColor);
      case HarmonyType.triadic:
        return _generateTriadic(baseColor);
      case HarmonyType.tetradic:
        return _generateTetradic(baseColor);
      case HarmonyType.square:
        return _generateSquare(baseColor);
    }
  }

  static List<Color> _generateMonochromatic(Color color) {
    final HSLColor hslColor = HSLColor.fromColor(color);
    return [
      hslColor.withLightness((hslColor.lightness - 0.3).clamp(0.0, 1.0)).toColor(),
      hslColor.withLightness((hslColor.lightness - 0.15).clamp(0.0, 1.0)).toColor(),
      color,
      hslColor.withLightness((hslColor.lightness + 0.15).clamp(0.0, 1.0)).toColor(),
      hslColor.withLightness((hslColor.lightness + 0.3).clamp(0.0, 1.0)).toColor(),
    ];
  }

  static List<Color> _generateAnalogous(Color color) {
    final HSLColor hslColor = HSLColor.fromColor(color);
    return [
      hslColor.withHue((hslColor.hue - 30) % 360).toColor(),
      hslColor.withHue((hslColor.hue - 15) % 360).toColor(),
      color,
      hslColor.withHue((hslColor.hue + 15) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 30) % 360).toColor(),
    ];
  }

  static List<Color> _generateComplementary(Color color) {
    final HSLColor hslColor = HSLColor.fromColor(color);
    return [
      color,
      hslColor.withHue((hslColor.hue + 180) % 360).toColor(),
    ];
  }

  static List<Color> _generateSplitComplementary(Color color) {
    final HSLColor hslColor = HSLColor.fromColor(color);
    return [
      color,
      hslColor.withHue((hslColor.hue + 150) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 210) % 360).toColor(),
    ];
  }

  static List<Color> _generateTriadic(Color color) {
    final HSLColor hslColor = HSLColor.fromColor(color);
    return [
      color,
      hslColor.withHue((hslColor.hue + 120) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 240) % 360).toColor(),
    ];
  }

  static List<Color> _generateTetradic(Color color) {
    final HSLColor hslColor = HSLColor.fromColor(color);
    return [
      color,
      hslColor.withHue((hslColor.hue + 60) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 180) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 240) % 360).toColor(),
    ];
  }

  static List<Color> _generateSquare(Color color) {
    final HSLColor hslColor = HSLColor.fromColor(color);
    return [
      color,
      hslColor.withHue((hslColor.hue + 90) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 180) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 270) % 360).toColor(),
    ];
  }
}
