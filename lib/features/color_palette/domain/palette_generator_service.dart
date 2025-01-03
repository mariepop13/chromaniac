import 'dart:math';
import 'package:chromaniac/features/color_palette/domain/color_palette_type.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';

class PaletteGeneratorService {
  static List<Color> generatePalette(
      BuildContext context, ColorPaletteType type, Color color) {
    final defaultSize = context.read<SettingsProvider>().defaultPaletteSize;

    switch (type) {
      case ColorPaletteType.monochromatic:
        return _generateMonochromaticPalette(color, defaultSize);
      case ColorPaletteType.analogous:
        return _generateAnalogousPalette(color, defaultSize);
      case ColorPaletteType.complementary:
        return _generateComplementaryPalette(color, defaultSize);
      case ColorPaletteType.splitComplementary:
        return [
          color,
          _getHueShifted(color, 150),
          _getHueShifted(color, 210),
        ];
      case ColorPaletteType.triadic:
        return [
          color,
          _getHueShifted(color, 120),
          _getHueShifted(color, 240),
        ];
      case ColorPaletteType.tetradic:
        return [
          color,
          _getHueShifted(color, 60),
          _getHueShifted(color, 180),
          _getHueShifted(color, 240),
        ];
      case ColorPaletteType.square:
        return [
          color,
          _getHueShifted(color, 90),
          _getHueShifted(color, 180),
          _getHueShifted(color, 270),
        ];
      case ColorPaletteType.auto:
        return _generateAutoPalette(null, defaultSize);
    }
  }

  static Color _getHueShifted(Color color, double shift) {
    final hslColor = HSLColor.fromColor(color);
    return hslColor.withHue((hslColor.hue + shift) % 360).toColor();
  }

  static List<Color> _generateMonochromaticPalette(Color color, int size) {
    final baseColors = [
      color,
      Color.fromRGBO(color.red, color.green, color.blue, 0.75),
      Color.fromRGBO(color.red, color.green, color.blue, 0.5),
      Color.fromRGBO(color.red, color.green, color.blue, 0.25),
    ];
    return _interpolateColors(baseColors, size);
  }

  static List<Color> _generateAnalogousPalette(Color color, int size) {
    final baseColors = [
      _getHueShifted(color, -30),
      color,
      _getHueShifted(color, 30),
    ];
    return _interpolateColors(baseColors, size);
  }

  static List<Color> _generateComplementaryPalette(Color color, int size) {
    if (size < 2) return [color];

    final hslColor = HSLColor.fromColor(color);
    final complement = hslColor.withHue((hslColor.hue + 180) % 360).toColor();

    if (size == 2) return [color, complement];

    final List<Color> palette = [];
    final step = 1.0 / ((size - 2) ~/ 2 + 1);

    for (var i = 0; i < (size - 1) ~/ 2; i++) {
      palette.add(Color.lerp(color, complement, step * (i + 1))!);
    }

    palette.add(color);
    palette.add(complement);

    for (var i = 0; i < size ~/ 2 - 1; i++) {
      palette.add(Color.lerp(complement, color, step * (i + 1))!);
    }

    return palette;
  }

  static List<Color> _generateAutoPalette(Color? color, int size) {
    final random = Random();
    return List.generate(
      size,
      (_) => Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        1.0,
      ),
    );
  }

  static List<Color> _interpolateColors(
      List<Color> baseColors, int targetSize) {
    if (targetSize <= baseColors.length) {
      return baseColors.take(targetSize).toList();
    }

    final List<Color> result = [];
    final segmentSize =
        (targetSize - baseColors.length) ~/ (baseColors.length - 1);
    final remainder =
        (targetSize - baseColors.length) % (baseColors.length - 1);

    for (var i = 0; i < baseColors.length - 1; i++) {
      result.add(baseColors[i]);

      final extraColors = segmentSize + (i < remainder ? 1 : 0);
      if (extraColors > 0) {
        final step = 1.0 / (extraColors + 1);
        for (var j = 0; j < extraColors; j++) {
          result.add(
              Color.lerp(baseColors[i], baseColors[i + 1], step * (j + 1))!);
        }
      }
    }

    result.add(baseColors.last);
    return result;
  }
}
