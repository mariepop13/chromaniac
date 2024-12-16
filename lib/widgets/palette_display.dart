import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class PaletteDisplay extends StatelessWidget {
  final List<Color> palette;
  final Function(int) onColorRemoved;
  final Function(String) onHexColorAdded;

  const PaletteDisplay({
    super.key,
    required this.palette,
    required this.onColorRemoved,
    required this.onHexColorAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Title(),
            Padding(padding: const EdgeInsets.only(top: 12)),
            _ColorInputSection(onHexColorAdded: onHexColorAdded),
            Padding(padding: const EdgeInsets.only(top: 12)),
            _PaletteList(palette: palette, onColorRemoved: onColorRemoved),
            Padding(padding: const EdgeInsets.only(top: 12)),
            ElevatedButton(
              onPressed: () => _exportPalette(context),
              child: const Text('Export as Procreate Palette'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportPalette(BuildContext context) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export not supported on web')),
      );
      return;
    }

    final procreatePalette = _convertToProcreatePalette(palette);

    String? outputPath;
    try {
      outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Palette',
        fileName: 'palette.swatches',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      return;
    }

    if (outputPath != null) {
      final file = File(outputPath);
      final content = procreatePalette.join('\n');
      await file.writeAsString(content);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Palette exported: ${file.path}')),
      );
    }
  }

  List<String> _convertToProcreatePalette(List<Color> palette) {
    return palette.map((color) {
      return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    }).toList();
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Your Palette',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}

class _ColorInputSection extends StatelessWidget {
  final Function(String) onHexColorAdded;

  const _ColorInputSection({
    required this.onHexColorAdded,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController hexController = TextEditingController();

    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: hexController,
            decoration: const InputDecoration(
              labelText: 'Enter Hex Color',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
            ),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => onHexColorAdded(hexController.text),
            child: const Text('Add Hex Color'),
          ),
        ],
      ),
    );
  }
}

class _PaletteList extends StatelessWidget {
  final List<Color> palette;
  final Function(int) onColorRemoved;

  const _PaletteList({
    required this.palette,
    required this.onColorRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: palette.asMap().entries.map((entry) {
          int index = entry.key;
          Color color = entry.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onColorRemoved(index),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.close,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
