import 'package:flutter/material.dart';

class PickerButtons extends StatelessWidget {
  final Function(String) togglePicker;
  final bool showColorPicker;
  final bool showMaterialPicker;
  final bool showBlockPicker;
  final bool showSlidePicker;
  final Color currentColor;
  final ValueChanged<Color> onColorSelected;

  const PickerButtons({super.key, 
    required this.togglePicker,
    required this.showColorPicker,
    required this.showMaterialPicker,
    required this.showBlockPicker,
    required this.showSlidePicker,
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              togglePicker('color');
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
              togglePicker('material');
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
              togglePicker('block');
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
              togglePicker('slide');
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
    );
  }
}
