import 'package:flutter/material.dart';
import 'package:chromaniac/core/constants.dart';
import 'package:chromaniac/features/color_palette/domain/color_palette_type.dart';

class PaletteOptionsDialog extends StatelessWidget {
  final ColorPaletteType? selectedType;
  final Function(ColorPaletteType?) onTypeChanged;
  final VoidCallback onGenerate;

  const PaletteOptionsDialog({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Palette Options'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<ColorPaletteType>(
            value: selectedType,
            onChanged: onTypeChanged,
            items: ColorPaletteType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.toString().split('.').last),
              );
            }).toList(),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          ElevatedButton(
            onPressed: onGenerate,
            child: const Text('Generate New Palette'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
