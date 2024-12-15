import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/color_grid.dart';
import 'package:logger/logger.dart';
import '../widgets/palette_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Color> _palette = [];
  Color _currentColor = Colors.blue;

  @override
  void initState() {
    super.initState();
  }

  void _addColorToPalette(Color color) {
    setState(() {
      if (_palette.length < 5) {
        _palette.add(color);
      }
    });
  }

  void _removeColorFromPalette(int index) {
    setState(() {
      _palette.removeAt(index);
    });
  }

  void _updateCurrentColor(Color color) {
    setState(() {
      _currentColor = color;
    });
  }

  bool isValidHexColor(String hexColor) {
    final hexRegExp = RegExp(r'^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');
    return hexRegExp.hasMatch(hexColor);
  }

  void _addHexColorToPalette(String hexColor) {
    if (!isValidHexColor(hexColor)) {
      Logger().e('Invalid hex color');
      return;
    }
    if (!hexColor.startsWith('#')) {
      hexColor = '#$hexColor';
    }
    setState(() {
      if (_palette.length < 5) {
        _palette.add(
            Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000));
      }
    });
  }

  Color _generateRandomColor() {
    final random = Random();
    return Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  void _generateRandomPalette() {
    setState(() {
      _palette.clear();
      for (int i = 0; i < 5; i++) {
        _palette.add(_generateRandomColor());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chromaniac - Color Palette Creator'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ColorGrid(
                  currentColor: _currentColor,
                  onColorSelected: _updateCurrentColor,
                ),
              ),
              Container(
                height: 100,
                width: double.infinity,
                color: _currentColor,
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      _addColorToPalette(_currentColor);
                    },
                    child: const Text('Add to Palette'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _generateRandomPalette,
                  child: const Text('Generate Random Palette'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: PaletteDisplay(
                  palette: _palette,
                  onColorRemoved: _removeColorFromPalette,
                  onHexColorAdded: _addHexColorToPalette,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
