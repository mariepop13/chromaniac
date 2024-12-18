import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

enum PaletteType {
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  _togglePicker('color');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.color_lens, color: textColor),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text('Select a Color',
                            style: TextStyle(color: textColor))),
                  ],
                ),
              ),
              if (showColorPicker)
                Flexible(
                  fit: FlexFit.loose,
                  child: ColorPicker(
                    pickerColor: selectedColor,
                    onColorChanged: (color) {
                      setState(() {
                        selectedColor = color;
                        widget.onColorSelected(color);
                      });
                    },
                    labelTypes: [],
                    pickerAreaHeightPercent: 0.8,
                    enableAlpha: true,
                    displayThumbColor: true,
                    pickerAreaBorderRadius:
                        const BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  _togglePicker('material');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.palette, color: textColor),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text('Material Picker',
                            style: TextStyle(color: textColor))),
                  ],
                ),
              ),
              if (showMaterialPicker)
                Flexible(
                  fit: FlexFit.loose,
                  child: MaterialPicker(
                    pickerColor: selectedColor,
                    onColorChanged: (color) {
                      setState(() {
                        selectedColor = color;
                        widget.onColorSelected(color);
                      });
                    },
                    enableLabel: true,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  _togglePicker('block');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_on, color: textColor),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text('Block Picker',
                            style: TextStyle(color: textColor))),
                  ],
                ),
              ),
              if (showBlockPicker)
                BlockPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) {
                    setState(() {
                      selectedColor = color;
                      widget.onColorSelected(color);
                    });
                  },
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  _togglePicker('slide');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.slideshow, color: textColor),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text('Slide Picker',
                            style: TextStyle(color: textColor))),
                  ],
                ),
              ),
              if (showSlidePicker)
                Flexible(
                  fit: FlexFit.loose,
                  child: SlidePicker(
                    pickerColor: selectedColor,
                    onColorChanged: (color) {
                      setState(() {
                        selectedColor = color;
                        widget.onColorSelected(color);
                      });
                    },
                    enableAlpha: true,
                    showParams: true,
                    showIndicator: true,
                    labelTypes: [],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
