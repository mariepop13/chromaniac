import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class SpeedDialFab extends StatelessWidget {
  final VoidCallback onAddColor;
  final VoidCallback onGeneratePalette;
  final VoidCallback onImportImage;
  final VoidCallback onClearAll;
  final VoidCallback onSavePalette;
  final VoidCallback onExportPalette;
  final bool isDebugEnabled;

  const SpeedDialFab({
    super.key,
    required this.onAddColor,
    required this.onGeneratePalette,
    required this.onImportImage,
    required this.onClearAll,
    required this.onSavePalette,
    required this.onExportPalette,
    required this.isDebugEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 3,
      childPadding: const EdgeInsets.all(5),
      spaceBetweenChildren: 4,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.color_lens),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          label: 'Add Color',
          onTap: onAddColor,
        ),
        SpeedDialChild(
          child: const Icon(Icons.shuffle),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          label: 'Generate Palette',
          onTap: onGeneratePalette,
        ),
        SpeedDialChild(
          child: const Icon(Icons.image),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          label: 'Import Image',
          onTap: onImportImage,
        ),
        SpeedDialChild(
          child: const Icon(Icons.save),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          label: 'Save Palette',
          onTap: onSavePalette,
        ),
        SpeedDialChild(
          child: const Icon(Icons.file_download),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          label: 'Export Palette',
          onTap: onExportPalette,
        ),
        if (isDebugEnabled)
          SpeedDialChild(
            child: const Icon(Icons.clear_all),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            label: 'Clear All',
            onTap: onClearAll,
          ),
      ],
    );
  }
}
