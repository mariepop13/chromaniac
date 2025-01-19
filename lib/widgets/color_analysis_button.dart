import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:chromaniac/utils/color/image_color_analyzer.dart';

class ColorAnalysisButton extends StatefulWidget {
  final Uint8List? imageBytes;
  final Function(ColorAnalysisResult) onAnalysisComplete;

  const ColorAnalysisButton({
    super.key,
    required this.imageBytes,
    required this.onAnalysisComplete,
  });

  @override
  State<ColorAnalysisButton> createState() => _ColorAnalysisButtonState();
}

class _ColorAnalysisButtonState extends State<ColorAnalysisButton> {
  void _performColorAnalysis() {
    if (widget.imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use Confirm Generation to analyze image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    widget.onAnalysisComplete(ColorAnalysisResult(colorAnalysis: []));
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _performColorAnalysis,
      icon: const Icon(Icons.palette_outlined),
      label: const Text('Smart Palette'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
      ),
    );
  }
}
