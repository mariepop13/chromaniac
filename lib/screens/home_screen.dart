import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';// Add this line
import 'package:chromaniac/features/color_palette/domain/color_palette_type.dart';
import 'package:chromaniac/features/color_palette/domain/palette_generator_service.dart';
import 'package:chromaniac/features/color_palette/presentation/color_tile_widget.dart';
import 'package:chromaniac/utils/color/export_palette.dart';
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
import '../providers/debug_provider.dart';
import '../utils/logger/app_logger.dart'; // Import AppLogger

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
    _generateRandomPalette();
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
      AppLogger.e('Error picking image', error: e); // Replaced print with AppLogger
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
        final isPremium = context.read<PremiumService>().isPremium;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Palette Full'),
            content: Text(
              isPremium
                ? 'You have reached the maximum of ${AppConstants.maxPaletteColors} colors in your palette.'
                : 'You have reached the maximum of ${AppConstants.defaultPaletteSize} colors. '
                  'Upgrade to premium to add up to ${AppConstants.maxPaletteColors} colors!'
            ),
            actions: [
              if (!isPremium) ...[
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
              ] else
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
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
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Chromaniac'),
        actions: [
          Consumer<PremiumService>(
            builder: (context, premiumService, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<DebugProvider>(
                  builder: (context, debugProvider, _) => IconButton(
                    onPressed: () => debugProvider.isDebugEnabled 
                      ? premiumService.togglePremium()
                      : premiumService.unlockPremium(),
                    icon: Icon(
                      premiumService.isPremium ? Icons.star : Icons.star_border,
                      color: premiumService.isPremium ? Colors.amber : null,
                    ),
                  ),
                ),
                Consumer<DebugProvider>(
                  builder: (context, debugProvider, _) => IconButton(
                    onPressed: () {
                      debugProvider.toggleDebug();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(debugProvider.isDebugEnabled ? 'Debug mode enabled' : 'Debug mode disabled'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: Icon(
                      debugProvider.isDebugEnabled ? Icons.bug_report : Icons.bug_report_outlined,
                      color: debugProvider.isDebugEnabled ? Colors.red : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) async {
              switch (value) {
                case 'generate':
                  _showPaletteOptionsDialog(context);
                  break;
                case 'add':
                  _showColorPickerDialog();
                  break;
                case 'import':
                  await _pickImage();
                  await _generatePaletteFromImage();
                  break;
                case 'export':
                  _exportPalette(context);
                  break;
                case 'clear':
                  _clearPalette();
                  break;
                case 'theme':
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme(!Provider.of<ThemeProvider>(context, listen: false).isDarkMode);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'generate',
                child: Row(
                  children: [
                    Icon(Icons.shuffle),
                    SizedBox(width: 8),
                    Text('Generate Palette'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Add Color'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.image),
                    SizedBox(width: 8),
                    Text('Import from Image'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export Palette'),
                  ],
                ),
              ),
              if (Provider.of<DebugProvider>(context, listen: false).isDebugEnabled)
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear),
                      SizedBox(width: 8),
                      Text('Clear Palette'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'theme',
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) => Row(
                    children: [
                      Icon(themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode),
                      const SizedBox(width: 8),
                      Text(themeProvider.isDarkMode
                          ? 'Dark Mode'
                          : 'Light Mode'),
                    ],
                  ),
                ),
              ),
            ],
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
