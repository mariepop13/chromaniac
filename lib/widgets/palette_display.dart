import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
          ],
        ),
      ),
    );
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
    Color pickerColor = Colors.white;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: hexController,
            decoration: const InputDecoration(
              labelText: 'Enter Hex Color',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: ElevatedButton(
            onPressed: () => onHexColorAdded(hexController.text),
            child: const Text('Add Hex Color'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Pick a color'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (color) {
                          pickerColor = color;
                        },
                      ),
                    ),
                    actions: <Widget>[
                      ElevatedButton(
                        child: const Text('Add Color'),
                        onPressed: () {
                          onHexColorAdded(pickerColor.value.toRadixString(16));
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text('Pick Color'),
          ),
        ),
      ],
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
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: palette.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onColorRemoved(index),
              child: Container(
                width: 60,
                decoration: BoxDecoration(
                  color: palette[index],
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
        },
      ),
    );
  }
}
