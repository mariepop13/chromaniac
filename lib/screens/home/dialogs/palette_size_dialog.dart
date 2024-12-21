import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants.dart';
import '../../../providers/settings_provider.dart';

class PaletteSizeDialog extends StatefulWidget {
  const PaletteSizeDialog({super.key});

  @override
  State<PaletteSizeDialog> createState() => _PaletteSizeDialogState();
}

class _PaletteSizeDialogState extends State<PaletteSizeDialog> {
  late int selectedSize;

  @override
  void initState() {
    super.initState();
    selectedSize = context.read<SettingsProvider>().defaultPaletteSize;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Default Palette Size'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: selectedSize.toDouble(),
            min: AppConstants.minPaletteColors.toDouble(),
            max: AppConstants.maxPaletteColors.toDouble(),
            divisions: AppConstants.maxPaletteColors - AppConstants.minPaletteColors,
            label: selectedSize.toString(),
            onChanged: (value) {
              setState(() {
                selectedSize = value.round();
              });
            },
          ),
          Text(
            '$selectedSize colors',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            context.read<SettingsProvider>().setDefaultPaletteSize(selectedSize);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
