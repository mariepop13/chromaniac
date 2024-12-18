import 'package:chromaniac/utils/export_palette.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:chromaniac/providers/theme_provider.dart';
import 'package:chromaniac/widgets/color_picker.dart';
import 'package:chromaniac/widgets/palette_generator.dart';
import 'package:flutter/services.dart';
import 'package:reorderable_grid/reorderable_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class ColorTile extends StatelessWidget {
  final Color color;
  final String hex;

  const ColorTile({
    super.key,
    required this.color,
    required this.hex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = color.computeLuminance() < 0.5;
    return Material(
      color: color,
      child: InkWell(
        child: Center(
          child: Text(
            hex,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Color> _palette = [];
  Color _currentColor = Colors.blue;
  PaletteType selectedPaletteType = PaletteType.auto;

  @override
  void initState() {
    super.initState();
    _generateRandomPalette();
  }

  void _addColorToPalette(Color color) {
    setState(() {
      if (_palette.length < 5) {
        _palette.add(color);
      }
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

  void _swapColors(int oldIndex, int newIndex) {
    setState(() {
      final color = _palette.removeAt(oldIndex);
      _palette.insert(newIndex, color);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Chromaniac'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () => _showPaletteOptionsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showColorPickerDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => exportPalette(context, _palette),
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildPaletteContent(),
      ),
    );
  }

  Widget _buildPaletteContent() {
    if (_palette.isEmpty) {
      return const Center(
        child: Text('Generate a palette or add colors'),
      );
    }

    return Column(
      children: [
        if (_palette.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Generate a palette or add colors'),
          ),
        if (_palette.isNotEmpty)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth / 2;
                final height = constraints.maxHeight / (((_palette.length + 1) ~/ 2));
                return ReorderableGridView.count(
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                  childAspectRatio: width / height,
                  children: _palette.map((color) {
                    final hex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                    return ColorTile(
                      key: ValueKey('$hex-${color.value}'),
                      color: color,
                      hex: hex,
                    );
                  }).toList(),
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      final color = _palette.removeAt(oldIndex);
                      _palette.insert(newIndex, color);
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  void _showPaletteOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Palette Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<PaletteType>(
              value: selectedPaletteType,
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() => selectedPaletteType = newValue);
                }
              },
              items: PaletteType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateRandomPalette,
              child: const Text('Generate New Palette'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog() {
    Color previewColor = _currentColor;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Add Color', style: Theme.of(context).textTheme.titleLarge),
              ),
              Flexible(
                child: ColorPickerWidget(
                  currentColor: _currentColor,
                  onColorSelected: (color) {
                    setState(() => previewColor = color);
                    _updateCurrentColor(color);
                  },
                  useMaterialPicker: true,
                ),
              ),
              Container(
                height: 50,
                width: double.infinity,
                color: previewColor,
              ),
              OverflowBar(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      _addColorToPalette(previewColor);
                      Navigator.pop(context);
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
