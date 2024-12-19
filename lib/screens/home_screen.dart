import 'dart:io';
import 'dart:math';
import 'package:chromaniac/features/color_palette/domain/color_palette_type.dart';
import 'package:chromaniac/features/color_palette/domain/palette_generator_service.dart';
import 'package:chromaniac/features/color_palette/presentation/color_tile_widget.dart';
import 'package:chromaniac/utils/color/export_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:chromaniac/providers/theme_provider.dart';
import 'package:chromaniac/features/color_palette/presentation/color_picker_dialog.dart';
import 'package:chromaniac/utils/dialog/dialog_utils.dart';
import 'package:chromaniac/widgets/color_analysis_button.dart';
import '../core/constants.dart';
import '../services/premium_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Color> _palette = [];
  ColorPaletteType? selectedColorPaletteType = ColorPaletteType.auto;
  File? _selectedImage;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
      if (mounted) {
        showSnackBar(context, 'Error picking image: $e');
      }
    }
  }

  Future<void> _generatePaletteFromImage() async {
    if (_selectedImage == null) return;

    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      FileImage(_selectedImage!),
      maximumColorCount: AppConstants.defaultPaletteSize,
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
      final maxColors = context.read<PremiumService>().isPremium 
          ? AppConstants.maxPaletteColors 
          : AppConstants.defaultPaletteSize;
          
      if (_palette.length < maxColors) {
        _palette.add(color);
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Palette Full'),
            content: Text(
              'You\'ve reached the maximum of ${AppConstants.defaultPaletteSize} colors. '
              'Upgrade to premium to add up to ${AppConstants.maxPaletteColors} colors!'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Maybe Later'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await context.read<PremiumService>().unlockPremium();
                  // Try adding the color again after premium is unlocked
                  _addColorToPalette(color);
                },
                child: const Text('Upgrade Now'),
              ),
            ],
          ),
        );
      }
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
        actions: [
          Consumer<PremiumService>(
            builder: (context, premiumService, _) => premiumService.isPremium
              ? const Icon(Icons.star, color: Colors.amber)
              : TextButton.icon(
                  onPressed: () => premiumService.unlockPremium(),
                  icon: const Icon(Icons.star_border),
                  label: const Text('Premium'),
                ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: EdgeInsets.all(AppConstants.defaultPadding),
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
            icon: const Icon(Icons.menu),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedImage != null) ...[
              Image.file(
                _selectedImage!,
                height: AppConstants.colorPreviewHeight,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: ColorAnalysisButton(
                  imageBytes: _imageBytes,
                  onAnalysisComplete: (result) {
                    setState(() {
                      _palette.clear();
                      for (final colorHex in result.colors) {
                        if (colorHex.startsWith('#')) {
                          final value = int.parse(colorHex.substring(1), radix: 16);
                          _palette.add(Color(value | 0xFF000000));
                        }
                      }
                    });
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Color Analysis Results'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Suggested Colors:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: AppConstants.smallPadding),
                            ...result.contextDescriptions.map((desc) => 
                              Padding(
                                padding: EdgeInsets.only(bottom: AppConstants.tinyPadding),
                                child: Text('• $desc'),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            Expanded(child: _buildPaletteContent()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Container(
              padding: EdgeInsets.all(AppConstants.defaultPadding),
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
                  crossAxisCount: AppConstants.gridColumnCount,
                  crossAxisSpacing: AppConstants.gridSpacing,
                  mainAxisSpacing: AppConstants.gridSpacing,
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
                            onEditColor: (newColor) => _editColorInPalette(
                                color, newColor), paletteSize: _palette.length, // Ajout du callback
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
            const SizedBox(height: AppConstants.defaultPadding),
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

  void _editColorInPalette(Color oldColor, Color newColor) {
    setState(() {
      final index = _palette.indexOf(oldColor);
      if (index != -1) {
        _palette[index] = newColor;
      }
    });
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: Colors.blue,
        onColorSelected: _addColorToPalette,
        currentPaletteSize: _palette.length,
      ),
    );
  }
}
