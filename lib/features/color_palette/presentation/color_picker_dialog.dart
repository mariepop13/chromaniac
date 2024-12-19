import 'package:flutter/material.dart';
import 'package:chromaniac/features/color_palette/presentation/color_picker_widget.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorSelected;
  final String title;
  final String cancelText;
  final String confirmText;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
    this.title = 'Select a color',
    this.cancelText = 'Cancel',
    this.confirmText = 'Apply',
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
  }

  void _updateSelectedColor(Color color) {
    setState(() {
      selectedColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorPickerWidget(
            currentColor: widget.initialColor,
            onColorSelected: _updateSelectedColor,
            useMaterialPicker: true,
          ),
          const SizedBox(height: 16),
          Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              color: selectedColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(widget.cancelText),
              ),
              TextButton(
                onPressed: () {
                  widget.onColorSelected(selectedColor);
                  Navigator.pop(context);
                },
                child: Text(widget.confirmText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
