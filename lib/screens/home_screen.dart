import 'dart:io';
import 'dart:math';
import 'package:chromaniac/features/color_palette/models/color_palette_type.dart';
import 'package:chromaniac/features/color_palette/utils/palette_generator_service.dart';
import 'package:chromaniac/features/color_palette/widgets/color_picker_widget.dart';
import 'package:chromaniac/features/color_palette/widgets/color_tile_widget.dart';
import 'package:chromaniac/utils/export_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:chromaniac/providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Color> _palette = [];
  Color _currentColor = Colors.blue;
  ColorPaletteType? selectedColorPaletteType = ColorPaletteType.auto;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _generatePaletteFromImage() async {
    if (_selectedImage == null) return;

    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      FileImage(_selectedImage!),
      maximumColorCount: 5,
    );

    setState(() {
      _palette.clear();
      _palette.addAll(paletteGenerator.colors);
    });
  }

  void _removeColorFromPalette(Color color) {
    if (_palette.contains(color)) {
      setState(() {
        _palette.remove(color);
      });
    }
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
      _palette.addAll(PaletteGeneratorService.generatePalette(
        selectedColorPaletteType ?? ColorPaletteType.auto,
        _generateRandomColor(),
      ));
    });
  }

  void _exportPalette(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await exportPalette(context, _palette, originBox: box);
  }

  void _clearPalette() {
    setState(() {
      _palette.clear();
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedImage != null)
              Image.file(
                _selectedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Expanded(child: _buildPaletteContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shuffle),
                    title: const Text('Generate Palette'),
                    onTap: () {
                      Navigator.pop(context);
                      _showPaletteOptionsDialog(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Add Color'),
                    onTap: () {
                      Navigator.pop(context);
                      _showColorPickerDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text('Import from Image'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickImage();
                      await _generatePaletteFromImage();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_download),
                    title: const Text('Export Palette'),
                    onTap: () {
                      Navigator.pop(context);
                      _exportPalette(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.clear),
                    title: const Text('Clear Palette'),
                    onTap: () {
                      Navigator.pop(context);
                      _clearPalette();
                    },
                  ),
                  ListTile(
                    leading: Icon(themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode),
                    title: Text(
                        themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode'),
                    onTap: () {
                      Navigator.pop(context);
                      themeProvider.toggleTheme(!themeProvider.isDarkMode);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.menu),
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
        if (_palette.isNotEmpty)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth / 2;
                final height =
                    constraints.maxHeight / (((_palette.length + 1) ~/ 2));
                return ReorderableGridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                  childAspectRatio: width / height,
                  children: _palette
                      .asMap()
                      .map((index, color) {
                        final hex =
                            '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                        return MapEntry(
                          index,
                          ColorTileWidget(
                            key: ValueKey(
                                '$hex-$index-${DateTime.now().millisecondsSinceEpoch}'),
                            color: color,
                            hex: hex,
                            onRemoveColor: _removeColorFromPalette,
                          ),
                        );
                      })
                      .values
                      .toList(),
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
            DropdownButton<ColorPaletteType>(
              value: selectedColorPaletteType,
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() => selectedColorPaletteType = newValue);
                }
              },
              items: ColorPaletteType.values.map((type) {
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
                child: Text('Add Color',
                    style: Theme.of(context).textTheme.titleLarge),
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
                    child: const Text('Done'),
                  ),
                  TextButton(
                    onPressed: () {
                      _addColorToPalette(previewColor);
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
