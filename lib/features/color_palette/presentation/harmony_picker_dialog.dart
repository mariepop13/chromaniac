import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/color/harmony_generator.dart';
import '../domain/color_palette_type.dart';
import '../../../providers/settings_provider.dart';

class HarmonyPickerDialog extends StatefulWidget {
  final Color baseColor;
  final Function(List<Color>, ColorPaletteType) onHarmonySelected;
  final bool showAutoOption;
  final int currentPaletteSize;

  const HarmonyPickerDialog({
    super.key,
    required this.baseColor,
    required this.onHarmonySelected,
    this.showAutoOption = true,
    required this.currentPaletteSize,
  });

  @override
  State<HarmonyPickerDialog> createState() => _HarmonyPickerDialogState();
}

class _HarmonyPickerDialogState extends State<HarmonyPickerDialog> {
  late HarmonyType selectedHarmony;
  late List<Color> previewColors;

  @override
  void initState() {
    super.initState();
    selectedHarmony = widget.showAutoOption ? HarmonyType.auto : HarmonyType.monochromatic;
    _updatePreview(selectedHarmony);
  }

  void _updatePreview(HarmonyType type) {
    setState(() {
      selectedHarmony = type;
      final paletteType = _harmonyTypeToColorPaletteType(type);
      final defaultSize = context.read<SettingsProvider>().defaultPaletteSize;
      
      AppLogger.d('Selected harmony type: $type');
      AppLogger.d('Palette type: $paletteType');
      AppLogger.d('Default size: $defaultSize');
      
      final colors = HarmonyGenerator.generateHarmony(widget.baseColor, type);
      AppLogger.d('Generated colors length: ${colors.length}');
      AppLogger.d('Generated colors: $colors');
      
      if (type == HarmonyType.splitComplementary ||
          type == HarmonyType.triadic ||
          type == HarmonyType.tetradic ||
          type == HarmonyType.square) {
        AppLogger.d('Special mode detected, using all colors');
        previewColors = colors;
      } else {
        AppLogger.d('Normal mode, taking $defaultSize colors');
        previewColors = colors.take(defaultSize).toList();
      }
      AppLogger.d('Final preview colors length: ${previewColors.length}');
      AppLogger.d('Final preview colors: $previewColors');
    });
  }

  ColorPaletteType _harmonyTypeToColorPaletteType(HarmonyType type) {
    return ColorPaletteType.values.firstWhere(
      (paletteType) => paletteType.toString().split('.').last == type.toString().split('.').last,
      orElse: () => ColorPaletteType.monochromatic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Color Harmony'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<HarmonyType>(
            value: selectedHarmony,
            onChanged: (HarmonyType? value) {
              if (value != null) {
                _updatePreview(value);
              }
            },
            items: HarmonyType.values.where((type) => 
              widget.showAutoOption || type != HarmonyType.auto
            ).map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.toString().split('.').last),
              );
            }).toList(),
          ),
          if (selectedHarmony != HarmonyType.auto) ...[
            const SizedBox(height: 16),
            Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: previewColors.map((color) {
                  return Expanded(
                    child: Container(
                      color: color,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onHarmonySelected(
              previewColors,
              _harmonyTypeToColorPaletteType(selectedHarmony),
            );
            Navigator.pop(context);
          },
          child: const Text('Apply Harmony'),
        ),
      ],
    );
  }
}
