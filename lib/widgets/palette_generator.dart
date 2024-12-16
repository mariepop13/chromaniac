import 'package:chromaniac/widgets/color_picker.dart';
import 'package:flutter/material.dart';
import 'dart:math';

List<Color> generatePalette(PaletteType type, Color color) {
  switch (type) {
    case PaletteType.monochromatic:
      return _generateMonochromaticPalette(color);
    case PaletteType.analogous:
      return _generateAnalogousPalette(color);
    case PaletteType.complementary:
      return _generateComplementaryPalette(color);
    case PaletteType.splitComplementary:
      return _generateSplitComplementaryPalette(color);
    case PaletteType.triadic:
      return _generateTriadicPalette(color);
    case PaletteType.tetradic:
      return _generateTetradicPalette(color);
    case PaletteType.square:
      return _generateSquarePalette(color);
    case PaletteType.auto:
    default:
      return _generateAutoPalette(color);
  }
}

List<Color> _generateMonochromaticPalette(Color color) {
  return [
    color,
    color.withOpacity(0.8),
    color.withOpacity(0.6),
    color.withOpacity(0.4),
    color.withOpacity(0.2),
  ];
}

List<Color> _generateAnalogousPalette(Color color) {
  final hslColor = HSLColor.fromColor(color);
  return [
    hslColor.withHue((hslColor.hue + 30) % 360).toColor(),
    hslColor.withHue((hslColor.hue + 15) % 360).toColor(),
    color,
    hslColor.withHue((hslColor.hue - 15) % 360).toColor(),
    hslColor.withHue((hslColor.hue - 30) % 360).toColor(),
  ];
}

List<Color> _generateComplementaryPalette(Color color) {
  final hslColor = HSLColor.fromColor(color);
  return [
    color,
    hslColor.withHue((hslColor.hue + 180) % 360).toColor(),
  ];
}

List<Color> _generateSplitComplementaryPalette(Color color) {
  final hslColor = HSLColor.fromColor(color);
  return [
    color,
    hslColor.withHue((hslColor.hue + 150) % 360).toColor(),
    hslColor.withHue((hslColor.hue + 210) % 360).toColor(),
  ];
}

List<Color> _generateTriadicPalette(Color color) {
  final hslColor = HSLColor.fromColor(color);
  return [
    color,
    hslColor.withHue((hslColor.hue + 120) % 360).toColor(),
    hslColor.withHue((hslColor.hue + 240) % 360).toColor(),
  ];
}

List<Color> _generateTetradicPalette(Color color) {
  final hslColor = HSLColor.fromColor(color);
  return [
    color,
    hslColor.withHue((hslColor.hue + 90) % 360).toColor(),
    hslColor.withHue((hslColor.hue + 180) % 360).toColor(),
    hslColor.withHue((hslColor.hue + 270) % 360).toColor(),
  ];
}

List<Color> _generateSquarePalette(Color color) {
  final hslColor = HSLColor.fromColor(color);
  return [
    color,
    hslColor.withHue((hslColor.hue + 90) % 360).toColor(),
    hslColor.withHue((hslColor.hue + 180) % 360).toColor(),
    hslColor.withHue((hslColor.hue + 270) % 360).toColor(),
  ];
}

List<Color> _generateAutoPalette(Color color) {
  final random = Random();
  return List.generate(5, (_) => Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0));
}
