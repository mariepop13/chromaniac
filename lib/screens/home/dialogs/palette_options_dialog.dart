import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chromaniac/features/color_palette/domain/color_palette_type.dart';
import 'package:chromaniac/features/color_palette/presentation/harmony_preview_widget.dart';
import 'package:chromaniac/utils/color/harmony_generator.dart';
import 'package:chromaniac/features/color_palette/domain/palette_generator_service.dart';
import '../../../core/constants.dart';
import '../../../providers/settings_provider.dart';

void showPaletteOptionsDialog(
  BuildContext context,
  ColorPaletteType? selectedColorPaletteType,
  Function(ColorPaletteType) onTypeChanged,
  Function(List<Color>) onColorsApplied,
) {
  Color previewBaseColor = _generateRandomColor();
  List<Color> previewColors = [];
  ColorPaletteType currentType = selectedColorPaletteType ?? ColorPaletteType.auto;
  final defaultPaletteSize = Provider.of<SettingsProvider>(context, listen: false).defaultPaletteSize;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        HarmonyType.values.firstWhere(
          (type) => type.toString().split('.').last == currentType.toString().split('.').last,
          orElse: () => HarmonyType.monochromatic,
        );
        previewColors = currentType == ColorPaletteType.auto
            ? PaletteGeneratorService.generatePalette(
                context, 
                ColorPaletteType.auto, 
                _generateRandomColor()
              )
            : HarmonyGenerator.generateHarmony(previewBaseColor, 
                HarmonyType.values.firstWhere(
                  (type) => type.toString().split('.').last == currentType.toString().split('.').last,
                  orElse: () => HarmonyType.monochromatic,
                ))
                .take(defaultPaletteSize)
                .toList();

        return AlertDialog(
          title: const Text('Palette Generator'),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose a palette type to preview and generate color combinations.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<ColorPaletteType>(
                      value: currentType,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      elevation: 16,
                      underline: Container(
                        height: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            currentType = newValue;
                            onTypeChanged(newValue);
                            previewBaseColor = _generateRandomColor();
                            previewColors = currentType == ColorPaletteType.auto
                                ? PaletteGeneratorService.generatePalette(
                                    context, 
                                    ColorPaletteType.auto, 
                                    _generateRandomColor()
                                  )
                                : HarmonyGenerator.generateHarmony(previewBaseColor, 
                                    HarmonyType.values.firstWhere(
                                      (type) => type.toString().split('.').last == currentType.toString().split('.').last,
                                      orElse: () => HarmonyType.monochromatic,
                                    ))
                                    .take(defaultPaletteSize)
                                    .toList();
                          });
                        }
                      },
                      items: ColorPaletteType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              type.toString().split('.').last,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (currentType != ColorPaletteType.auto) ...[
                      const SizedBox(height: AppConstants.defaultPadding),
                      HarmonyPreviewWidget(colors: previewColors),
                      const SizedBox(height: AppConstants.defaultPadding),
                    ] else ...[
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
              ),
            ),
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
