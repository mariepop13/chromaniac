import 'package:flutter/material.dart';
import 'package:chromaniac/widgets/export_palette.dart';

class PaletteDisplay extends StatelessWidget {
  final List<Color> palette;
  final ValueChanged<int> onColorRemoved;

  const PaletteDisplay({
    Key? key,
    required this.palette,
    required this.onColorRemoved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Your Palette',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: palette.asMap().entries.map((entry) {
            int index = entry.key;
            Color color = entry.value;
            return Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  color: color,
                ),
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    onTap: () => onColorRemoved(index),
                    child: Container(
                      color: Colors.black54,
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            exportPalette(context, palette);
          },
          child: Text('Export Palette'),
        ),
      ],
    );
  }
}
