import 'package:chromaniac/utils/export_palette.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/theme_provider.dart';
import '../widgets/color_picker.dart';
import '../widgets/palette_generator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Color> _palette = [];
  Color _currentColor = Colors.blue;
  PaletteType selectedPaletteType = PaletteType.auto;

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


  Color _generateRandomColor() {
    final random = Random();
    return Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  void _generateRandomPalette() {
    setState(() {
      _palette.clear();
      _palette.addAll(generatePalette(selectedPaletteType, _generateRandomColor()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chromaniac - Color Palette Creator'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              themeProvider.toggleTheme(!themeProvider.isDarkMode);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _palette.asMap().entries.map((entry) {
                    int index = entry.key;
                    Color color = entry.value;
                    bool isDarkColor = color.computeLuminance() < 0.5;
                    return Container(
                      height: 50,
                      width: double.infinity,
                      color: color,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.close, color: isDarkColor ? Colors.white : Colors.black),
                            onPressed: () {
                              _removeColorFromPalette(index);
                            },
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
                                  style: TextStyle(
                                    color: isDarkColor ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ColorPickerWidget(
                  currentColor: _currentColor,
                  onColorSelected: _updateCurrentColor,
                ),
              ),
              Container(
                height: 100,
                width: double.infinity,
                color: _currentColor, // Utilisez _currentColor ici
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
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _generateRandomPalette,
                        child: const Text('Generate Random Palette'),
                      ),
                    ),
                    SizedBox(width: 16),
                    DropdownButton<PaletteType>(
                      value: selectedPaletteType,
                      onChanged: (PaletteType? newValue) {
                        setState(() {
                          selectedPaletteType = newValue!;
                        });
                      },
                      items: PaletteType.values.map((PaletteType type) {
                        return DropdownMenuItem<PaletteType>(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    exportPalette(context, _palette);
                  },
                  child: const Text('Export'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
