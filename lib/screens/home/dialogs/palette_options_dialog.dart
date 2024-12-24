import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chromaniac/features/color_palette/domain/color_palette_type.dart';
import 'package:chromaniac/features/color_palette/presentation/harmony_preview_widget.dart';
import 'package:chromaniac/utils/color/harmony_generator.dart';
import '../../../core/constants.dart';

void showPaletteOptionsDialog(
  BuildContext context,
  ColorPaletteType? selectedColorPaletteType,
  Function(ColorPaletteType) onTypeChanged,
  Function(List<Color>) onColorsApplied,
) {
  Color previewBaseColor = _generateRandomColor();
  List<Color> previewColors = [];

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        HarmonyType selectedHarmonyType = HarmonyType.values.firstWhere(
          (type) => type.toString().split('.').last == selectedColorPaletteType.toString().split('.').last,
          orElse: () => HarmonyType.monochromatic,
        );
        previewColors = HarmonyGenerator.generateHarmony(previewBaseColor, selectedHarmonyType);

        return AlertDialog(
          title: const Text('Palette Generator'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose a palette type to preview and generate color combinations.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              DropdownButton<ColorPaletteType>(
                value: selectedColorPaletteType,
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      onTypeChanged(newValue);
                      previewBaseColor = _generateRandomColor();
                    });
                  }
                },
                items: ColorPaletteType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
              ),
              if (selectedColorPaletteType != ColorPaletteType.auto) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                HarmonyPreviewWidget(colors: previewColors),
                const SizedBox(height: AppConstants.defaultPadding),
              ],
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 8,
                children: [
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            previewBaseColor = _generateRandomColor();
                          });
                        },
                        child: const Text('Preview New Colors'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          onColorsApplied(previewColors);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Colors applied to palette'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Text('Apply to Palette'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    ),
  );
}

Color _generateRandomColor() {
  final random = Random();
  return Color.fromRGBO(
    (random.nextDouble() * 255).round(),
    (random.nextDouble() * 255).round(),
    (random.nextDouble() * 255).round(),
    1.0,
  );
}
