import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerWidget extends StatefulWidget {
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  const ColorPickerWidget({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
    required bool useMaterialPicker,
  });

  @override
  ColorPickerWidgetState createState() => ColorPickerWidgetState();
}

class ColorPickerWidgetState extends State<ColorPickerWidget> {
  bool showColorPicker = false;
  bool showMaterialPicker = false;
  bool showBlockPicker = false;
  bool showSlidePicker = false;
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.currentColor;
  }

  void _saveAndClosePicker() {
    setState(() {
      showColorPicker = false;
      showMaterialPicker = false;
      showBlockPicker = false;
      showSlidePicker = false;
    });
  }

  void _togglePicker(String pickerType) {
    setState(() {
      if (pickerType == 'color') {
        showColorPicker = !showColorPicker;
      } else if (pickerType == 'material') {
        showMaterialPicker = !showMaterialPicker;
      } else if (pickerType == 'block') {
        showBlockPicker = !showBlockPicker;
      } else if (pickerType == 'slide') {
        showSlidePicker = !showSlidePicker;
      }
      // Fermer les autres pickers
      if (pickerType != 'color') showColorPicker = false;
      if (pickerType != 'material') showMaterialPicker = false;
      if (pickerType != 'block') showBlockPicker = false;
      if (pickerType != 'slide') showSlidePicker = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPickerButton('Color Picker', Icons.colorize, 'color'),
          if (showColorPicker) _buildColorPicker(),
          _buildPickerButton('Material Picker', Icons.format_paint, 'material'),
          if (showMaterialPicker) _buildMaterialPicker(),
          _buildPickerButton('Block Picker', Icons.grid_on, 'block'),
          if (showBlockPicker) _buildBlockPicker(),
          _buildPickerButton('Slide Picker', Icons.slideshow, 'slide'),
          if (showSlidePicker) _buildSlidePicker(),
        ],
      ),
    );
  }

  Widget _buildColorPicker() => ColorPicker(
        pickerColor: selectedColor,
        onColorChanged: _updateColor,
        labelTypes: const [],
        pickerAreaHeightPercent: 0.8,
        enableAlpha: true,
      );

  Widget _buildMaterialPicker() => MaterialPicker(
        pickerColor: selectedColor,
        onColorChanged: _updateColor,
        enableLabel: true,
      );

  Widget _buildBlockPicker() => BlockPicker(
        pickerColor: selectedColor,
        onColorChanged: _updateColor,
      );

  Widget _buildSlidePicker() => SlidePicker(
        pickerColor: selectedColor,
        onColorChanged: _updateColor,
        enableAlpha: true,
        showParams: true,
        showIndicator: true,
      );

  void _updateColor(Color color) {
    setState(() => selectedColor = color);
    widget.onColorSelected(color);
  }

  Widget _buildPickerButton(String text, IconData icon, String type) {
    return ElevatedButton(
      onPressed: () => _togglePicker(type),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
