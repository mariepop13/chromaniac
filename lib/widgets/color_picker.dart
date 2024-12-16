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

  void _togglePicker(String pickerType) {
    setState(() {
      showColorPicker = pickerType == 'color';
      showMaterialPicker = pickerType == 'material';
      showBlockPicker = pickerType == 'block';
      showSlidePicker = pickerType == 'slide';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  _togglePicker('color');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.color_lens),
                    SizedBox(width: 8),
                    Expanded(child: Text('Select a Color')),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  _togglePicker('material');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.palette),
                    SizedBox(width: 8),
                    Expanded(child: Text('Material Picker')),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  _togglePicker('block');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_on),
                    SizedBox(width: 8),
                    Expanded(child: Text('Block Picker')),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  _togglePicker('slide');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.slideshow),
                    SizedBox(width: 8),
                    Expanded(child: Text('Slide Picker')),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (showColorPicker)
          Flexible(
            fit: FlexFit.loose,
            child: ColorPicker(
              pickerColor: widget.currentColor,
              onColorChanged: widget.onColorSelected,
              labelTypes: [],
              pickerAreaHeightPercent: 0.8,
              enableAlpha: true,
              displayThumbColor: true,
              pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(10.0)),
            ),
          ),
        if (showMaterialPicker)
          Flexible(
            fit: FlexFit.loose,
            child: MaterialPicker(
              pickerColor: widget.currentColor,
              onColorChanged: widget.onColorSelected,
              enableLabel: true,
            ),
          ),
        if (showBlockPicker)
          Flexible(
            fit: FlexFit.loose,
            child: BlockPicker(
              pickerColor: widget.currentColor,
              onColorChanged: widget.onColorSelected,
            ),
          ),
        if (showSlidePicker)
          Flexible(
            fit: FlexFit.loose,
            child: SlidePicker(
              pickerColor: widget.currentColor,
              onColorChanged: widget.onColorSelected,
              enableAlpha: true,
              showParams: true,
              showIndicator: true,
              labelTypes: [],
            ),
          ),
      ],
    );
  }
}