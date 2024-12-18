import 'dart:math';
import 'package:flutter/material.dart';
import '../models/color_palette_type.dart';

class PaletteGeneratorService {
  static List<Color> generatePalette(ColorPaletteType type, Color color) {
    switch (type) {
      case ColorPaletteType.monochromatic:
        return _generateMonochromaticPalette(color);
      case ColorPaletteType.analogous:
        return _generateAnalogousPalette(color);
      case ColorPaletteType.complementary:
        return _generateComplementaryPalette(color);
      case ColorPaletteType.splitComplementary:
        return _generateSplitComplementaryPalette(color);
      case ColorPaletteType.triadic:
        return _generateTriadicPalette(color);
      case ColorPaletteType.tetradic:
        return _generateTetradicPalette(color);
      case ColorPaletteType.square:
        return _generateSquarePalette(color);
      case ColorPaletteType.auto:
      default:
        return _generateAutoPalette(color);
    }
  }

  static List<Color> _generateMonochromaticPalette(Color color) {
    return [
      color,
      color.withOpacity(0.8),
      color.withOpacity(0.6),
      color.withOpacity(0.4),
      color.withOpacity(0.2),
    ];
  }

  static List<Color> _generateAnalogousPalette(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return [
      hslColor.withHue((hslColor.hue + 30) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 15) % 360).toColor(),
      color,
      hslColor.withHue((hslColor.hue - 15) % 360).toColor(),
      hslColor.withHue((hslColor.hue - 30) % 360).toColor(),
    ];
  }

  static List<Color> _generateComplementaryPalette(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return [
      color,
      hslColor.withHue((hslColor.hue + 180) % 360).toColor(),
    ];
  }

  static List<Color> _generateSplitComplementaryPalette(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return [
      color,
      hslColor.withHue((hslColor.hue + 150) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 210) % 360).toColor(),
    ];
  }

  static List<Color> _generateTriadicPalette(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return [
      color,
      hslColor.withHue((hslColor.hue + 120) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 240) % 360).toColor(),
    ];
  }

  static List<Color> _generateTetradicPalette(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return [
      color,
      hslColor.withHue((hslColor.hue + 90) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 180) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 270) % 360).toColor(),
    ];
  }

  static List<Color> _generateSquarePalette(Color color) {
    final hslColor = HSLColor.fromColor(color);
    return [
      color,
      hslColor.withHue((hslColor.hue + 90) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 180) % 360).toColor(),
      hslColor.withHue((hslColor.hue + 270) % 360).toColor(),
    ];
  }

  static List<Color> _generateAutoPalette(Color color) {
    final random = Random();
    return List.generate(
      5,
      (_) => Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
    );
  }
}
