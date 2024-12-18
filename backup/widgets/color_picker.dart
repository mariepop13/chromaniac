import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

enum ColorPaletteType {
  auto,
  monochromatic,
  analogous,
  complementary,
  splitComplementary,
  triadic,
  tetradic,
  square,
}

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
  late Color selectedColor = widget.currentColor;

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
        if (showColorPicker) {
          _saveAndClosePicker();
        } else {
          _saveAndClosePicker();
          showColorPicker = true;
        }
      } else if (pickerType == 'material') {
        if (showMaterialPicker) {
          _saveAndClosePicker();
        } else {
          _saveAndClosePicker();
          showMaterialPicker = true;
        }
      } else if (pickerType == 'block') {
        if (showBlockPicker) {
          _saveAndClosePicker();
        } else {
          _saveAndClosePicker();
          showBlockPicker = true;
        }
      } else if (pickerType == 'slide') {
        if (showSlidePicker) {
          _saveAndClosePicker();
        } else {
          _saveAndClosePicker();
          showSlidePicker = true;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = theme.buttonTheme.colorScheme?.primary ?? Colors.blue;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildPickerButton('Color Picker', Icons.colorize, 'color',
              buttonColor, textColor),
            if (showColorPicker) buildColorPicker(),
            buildPickerButton('Material Picker', Icons.format_paint, 'material',
              buttonColor, textColor),
            if (showMaterialPicker)
              SizedBox(
                height: 240,
                child: buildMaterialPicker(),
              ),
            buildPickerButton(
                'Block Picker', Icons.grid_on, 'block', buttonColor, textColor),
            if (showBlockPicker) buildBlockPicker(),
            buildPickerButton('Slide Picker', Icons.slideshow, 'slide',
                buttonColor, textColor),
            if (showSlidePicker) buildSlidePicker(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget buildColorPicker() => ColorPicker(
        pickerColor: selectedColor,
        onColorChanged: updateColor,
        labelTypes: const [],
        pickerAreaHeightPercent: 0.8,
        enableAlpha: true,
        displayThumbColor: true,
        pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10)),
      );

  Widget buildMaterialPicker() => Material(
        child: MaterialPicker(
          pickerColor: selectedColor,
          onColorChanged: updateColor,
          enableLabel: true,
        ),
      );

  Widget buildBlockPicker() => BlockPicker(
        pickerColor: selectedColor,
        onColorChanged: updateColor,
      );

  Widget buildSlidePicker() => SlidePicker(
        pickerColor: selectedColor,
        onColorChanged: updateColor,
        enableAlpha: true,
        showParams: true,
        showIndicator: true,
        labelTypes: const [],
      );

  @override
  void didUpdateWidget(ColorPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    selectedColor = widget.currentColor;
  }

  void updateColor(Color color) {
    setState(() {
      selectedColor = color;
    });
    widget.onColorSelected(color);
  }

  Widget buildPickerButton(String text, IconData icon, String type,
      Color buttonColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () => _togglePicker(type),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: TextStyle(color: textColor))),
          ],
        ),
      ),
    );
  }
}
