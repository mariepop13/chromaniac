import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:chromaniac/utils/export_palette.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:chromaniac/providers/theme_provider.dart';
import 'package:chromaniac/widgets/color_picker.dart';
import 'package:chromaniac/widgets/palette_generator.dart';
import 'package:chromaniac/widgets/color_tile.dart';
import 'package:reorderable_grid/reorderable_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Color> _palette = [];
  Color _currentColor = Colors.blue;
  PaletteType selectedPaletteType = PaletteType.auto;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _generateRandomPalette();
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
      _palette
          .addAll(generatePalette(selectedPaletteType, _generateRandomColor()));
    });
  }

  void _exportPalette(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await exportPalette(context, _palette, originBox: box);
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
            icon: const Icon(Icons.shuffle),
            onPressed: () => _showPaletteOptionsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showColorPickerDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: () async {
              await _pickImage();
              await _generatePaletteFromImage();
            },
          ),
          Builder(
            builder: (context) => IconButton(
              key: const Key('export_button'),
              icon: const Icon(Icons.file_download),
              onPressed: () => _exportPalette(context),
            ),
          ),
          IconButton(
            icon: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () =>
                themeProvider.toggleTheme(!themeProvider.isDarkMode),
          ),
        ],
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
                final height =
                    constraints.maxHeight / (((_palette.length + 1) ~/ 2));
                return ReorderableGridView.count(
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                  childAspectRatio: width / height,
                  children: _palette.map((color) {
                    final hex =
                        '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                    return ColorTile(
                      key: ValueKey('$hex-${color.value}'),
                      color: color,
                      hex: hex,
                      onRemoveColor: _removeColorFromPalette,
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
