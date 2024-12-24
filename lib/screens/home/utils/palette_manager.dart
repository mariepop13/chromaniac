import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../services/premium_service.dart';
import '../../../providers/settings_provider.dart';
import '../../../features/color_palette/domain/color_palette_type.dart';
import '../../../features/color_palette/domain/palette_generator_service.dart';

class PaletteManager {
  static void showPaletteLimitDialog(BuildContext context, VoidCallback onGenerateRandomPalette) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Palette Full'),
        content: Text(
          'You\'ve reached the maximum of ${context.read<SettingsProvider>().defaultPaletteSize} colors. '
          'Upgrade to premium to add up to ${AppConstants.maxPaletteColors} colors!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<PremiumService>().unlockPremium();
              onGenerateRandomPalette();
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  static void addColorsToPalette(
    BuildContext context,
    List<Color> colors,
    List<Color> currentPalette,
    Function(List<Color>) onColorsAdded,
  ) {
    final maxColors = context.read<PremiumService>().isPremium
        ? AppConstants.maxPaletteColors
        : context.read<SettingsProvider>().defaultPaletteSize;
    
    final remainingSpace = maxColors - currentPalette.length;
    
    if (remainingSpace > 0) {
      final colorsToAdd = colors.take(remainingSpace).toList();
      onColorsAdded(colorsToAdd);
      
      if (colors.length > remainingSpace) {
        showPaletteLimitDialog(context, () {});
      }
    } else {
      showPaletteLimitDialog(context, () {});
    }
  }

  static void applyHarmonyColors(
    BuildContext context,
    List<Color> colors,
    Function(List<Color>) onColorsApplied,
  ) {
    final maxColors = context.read<PremiumService>().isPremium
        ? AppConstants.maxPaletteColors
        : context.read<SettingsProvider>().defaultPaletteSize;
    
    if (colors.length > maxColors) {
      showPaletteLimitDialog(context, () {});
      colors = colors.take(maxColors).toList();
    }
    
    onColorsApplied(colors);
  }

  static Color generateRandomColor() {
    final random = Random();
    return Color.fromRGBO(
      (random.nextDouble() * 255).round(),
      (random.nextDouble() * 255).round(),
      (random.nextDouble() * 255).round(),
      1.0,
    );
  }

  static List<Color> generateRandomPalette(
    BuildContext context,
    ColorPaletteType? selectedType,
  ) {
    return PaletteGeneratorService.generatePalette(
      context,
      selectedType ?? ColorPaletteType.auto,
      generateRandomColor(),
    );
  }

  static bool isValidHexColor(String hexColor) {
    final hexRegExp = RegExp(r'^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');
    return hexRegExp.hasMatch(hexColor);
  }
}