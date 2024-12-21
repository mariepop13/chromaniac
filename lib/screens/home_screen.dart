import 'dart:io';
import 'dart:math';
import 'package:chromaniac/models/color_palette.dart';
import 'package:flutter/foundation.dart';
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
import 'package:chromaniac/screens/favorites/favorites_screen.dart';
import '../core/constants.dart';
import '../services/premium_service.dart';
import '../providers/debug_provider.dart';
import '../utils/logger/app_logger.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import 'package:chromaniac/widgets/app_bottom_nav.dart';
import 'package:chromaniac/widgets/speed_dial_fab.dart';
import '../providers/settings_provider.dart';
import 'home/dialogs/palette_size_dialog.dart';

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
      AppLogger.e('Error picking image', error: e);
      if (mounted) {
        showSnackBar(context, 'Error picking image: $e');
      }
    }
  }

  Future<void> _generatePaletteFromImage() async {
    if (_selectedImage == null) return;

    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      FileImage(_selectedImage!),
      maximumColorCount: context.read<SettingsProvider>().defaultPaletteSize,
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
          : context.read<SettingsProvider>().defaultPaletteSize;
          
      if (_palette.length < maxColors) {
        _palette.add(color);
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Palette Full'),
            content: Text(
              'You\'ve reached the maximum of ${context.read<SettingsProvider>().defaultPaletteSize} colors. '
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
        context,
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

  void _showSavePaletteDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save Palette'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${_palette.length} colors selected'),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Palette Name',
                hintText: 'Enter a name for this palette',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                Navigator.pop(dialogContext, value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Pop the dialog first
              Navigator.pop(dialogContext);
              
              try {
                AppLogger.d('Saving palette with name: ${textController.text}');
                final now = DateTime.now();
                final colorPalette = ColorPalette(
                  id: const Uuid().v4(),
                  name: textController.text.isEmpty 
                    ? 'Palette ${now.toIso8601String()}'
                    : textController.text,
                  colors: List<Color>.from(_palette),
                  createdAt: now,
                  updatedAt: now,
                );
                
                AppLogger.d('Created palette object: ${colorPalette.name}');
                await DatabaseService().savePalette(colorPalette);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Palette saved successfully')),
                  );
                }
              } catch (e, stackTrace) {
                AppLogger.e('Error saving palette', error: e, stackTrace: stackTrace);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving palette: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (value) async {
            switch (value) {
              case 'theme':
                await Provider.of<ThemeProvider>(context, listen: false)
                    .toggleTheme(!Provider.of<ThemeProvider>(context, listen: false).isDarkMode);
                break;
              case 'settings':
                _showSettingsDialog(context);
                break;
            }
          },
          itemBuilder: (context) => [
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
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
          ],
        ),
        title: const Text('Chromaniac'),
        actions: [
          Consumer<PremiumService>(
            builder: (context, premiumService, _) => IconButton(
              onPressed: () => context.read<DebugProvider>().isDebugEnabled 
                ? premiumService.togglePremium()
                : premiumService.unlockPremium(),
              icon: Icon(
                premiumService.isPremium ? Icons.star : Icons.star_border,
                color: premiumService.isPremium ? Colors.amber : null,
              ),
            ),
          ),
          if (kDebugMode)
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
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedImage != null) ...[
              Stack(
                children: [
                  Image.file(
                    _selectedImage!,
                    height: AppConstants.colorPreviewHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: AppConstants.smallPadding,
                    right: AppConstants.smallPadding,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() {
                        _selectedImage = null;
                        _imageBytes = null;
                      }),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(AppConstants.defaultPadding),
                child: ColorAnalysisButton(
                  imageBytes: _imageBytes,
                  onAnalysisComplete: (result) {
                    setState(() {
                      if (context.read<DebugProvider>().isDebugEnabled) {
                        _palette.clear();
                      }
                      _palette.addAll(
                        result.colorAnalysis.map((colorData) {
                          final hexCode = colorData['hexCode'] as String;
                          final hex = hexCode.startsWith('#') ? hexCode.substring(1) : hexCode;
                          return Color(int.parse('FF$hex', radix: 16));
                        }),
                      );
                    });
                  },
                ),
              ),
            ],
            _buildPaletteContent(),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
              break;
            case 2:
              _generateRandomPalette();
              break;
          }
        },
      ),
      floatingActionButton: Consumer<DebugProvider>(
        builder: (context, debugProvider, child) => SpeedDialFab(
          onAddColor: _showColorPickerDialog,
          onImportImage: () async {
            await _pickImage();
            if (_selectedImage != null) {
              await _generatePaletteFromImage();
            }
          },
          onClearAll: _clearPalette,
          onSavePalette: _showSavePaletteDialog,
          onExportPalette: () => _exportPalette(context),
          isDebugEnabled: debugProvider.isDebugEnabled,
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

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / 2;
          final height = constraints.maxHeight / (((_palette.length + 1) ~/ 2));
          final aspectRatio = width / height;

          return ReorderableGridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            itemCount: _palette.length,
            itemBuilder: (context, index) {
              final color = _palette[index];
              return ColorTileWidget(
                key: ValueKey('${color.value}_$index'),
                color: color,
                hex: color.value.toRadixString(16).padLeft(8, '0').substring(2),
                onRemoveColor: _removeColorFromPalette,
                onEditColor: (newColor) => _editColorInPalette(color, newColor),
                paletteSize: _palette.length,
              );
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final color = _palette.removeAt(oldIndex);
                _palette.insert(newIndex, color);
              });
            },
          );
        },
      ),
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

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Default Palette Size'),
              subtitle: Text('${context.watch<SettingsProvider>().defaultPaletteSize} colors'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const PaletteSizeDialog(),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Default Palette Type'),
              subtitle: Text(selectedColorPaletteType?.toString().split('.').last ?? 'Auto'),
              onTap: () {
                Navigator.pop(context);
                _showPaletteOptionsDialog(context);
              },
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
  }
}
