import 'dart:io';
import 'dart:math';
import 'package:chromaniac/models/color_palette.dart';
import 'package:chromaniac/features/color_palette/domain/color_palette_type.dart';
import 'package:chromaniac/features/color_palette/domain/palette_generator_service.dart';
import 'package:chromaniac/features/color_palette/presentation/harmony_preview_widget.dart';
import 'package:chromaniac/utils/color/harmony_generator.dart';
import 'package:chromaniac/utils/color/export_palette.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:chromaniac/features/color_palette/presentation/color_picker_dialog.dart';
import 'package:chromaniac/utils/dialog/dialog_utils.dart';
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
import 'package:chromaniac/screens/home/home_content.dart';
import 'package:chromaniac/screens/home/widgets/app_bar_actions.dart';
import 'package:chromaniac/screens/home/widgets/settings_menu.dart';
import 'package:chromaniac/screens/home/widgets/image_preview.dart';
import 'package:chromaniac/screens/home/state/home_screen_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _state = HomeScreenState();

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
          _state.selectedImage = File(pickedFile.path);
          _state.imageBytes = bytes;
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
    if (_state.selectedImage == null) return;

    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      FileImage(_state.selectedImage!),
      maximumColorCount: context.read<SettingsProvider>().defaultPaletteSize,
    );

    setState(() {
      _state.clearPalette();
      _state.addColors(paletteGenerator.colors.toList());
    });
  }


  void _addColorToPalette(Color color) {
    _addColorsToPalette([color]);
  }

  void _addColorsToPalette(List<Color> colors) {
    setState(() {
      final maxColors = context.read<PremiumService>().isPremium
          ? AppConstants.maxPaletteColors
          : context.read<SettingsProvider>().defaultPaletteSize;
      
      final remainingSpace = maxColors - _state.palette.length;
      
      if (remainingSpace > 0) {
        final colorsToAdd = colors.take(remainingSpace).toList();
        _state.addColors(colorsToAdd);
        
        if (colors.length > remainingSpace) {
          _showPaletteLimitDialog();
        }
      } else {
        _showPaletteLimitDialog();
      }
    });
  }

  void _showPaletteLimitDialog() {
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
              _generateRandomPalette();
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  bool isValidHexColor(String hexColor) {
    final hexRegExp = RegExp(r'^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');
    return hexRegExp.hasMatch(hexColor);
  }

  Color _generateRandomColor() {
    final random = Random();
    return Color.from(
      alpha: 1.0,
      red: random.nextDouble(),
      green: random.nextDouble(),
      blue: random.nextDouble(),
    );
  }

  void _generateRandomPalette() {
    setState(() {
      _state.clearPalette();
      _state.addColors(PaletteGeneratorService.generatePalette(
        context,
        _state.selectedColorPaletteType ?? ColorPaletteType.auto,
        _generateRandomColor(),
      ));
    });
  }

  void _exportPalette(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    await exportPalette(context, _state.palette, originBox: box);
  }

  void _clearPalette() {
    setState(() {
      _state.clearPalette();
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
            Text('${_state.palette.length} colors selected'),
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
                  colors: List<Color>.from(_state.palette),
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
        leading: SettingsMenu(onSettingsTap: () => _showSettingsDialog(context)),
        title: const Text('Chromaniac'),
        actions: const [AppBarActions()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_state.selectedImage != null)
              ImagePreview(
                image: _state.selectedImage!,
                imageBytes: _state.imageBytes!,
                onAnalysisComplete: (result) {
                  setState(() {
                    _state.clearPalette();
                    _state.addColors(
                      result.colorAnalysis.map((colorData) {
                        final hexCode = colorData['hexCode'] as String;
                        final hex = hexCode.startsWith('#') ? hexCode.substring(1) : hexCode;
                        return Color(int.parse('FF$hex', radix: 16));
                      }).toList(),
                    );
                  });
                },
              ),
            HomeContent(
              palette: _state.palette,
              onRemoveColor: (color) => setState(() => _state.removeColor(color)),
              onEditColor: (oldColor, newColor) => setState(() => _state.updateColor(oldColor, newColor)),
              onAddHarmonyColors: _addColorsToPalette,
              onReorder: (oldIndex, newIndex) => setState(() => _state.reorderColors(oldIndex, newIndex)),
            ),
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
            if (_state.selectedImage != null) {
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

  void _showPaletteOptionsDialog(BuildContext context) {
    Color previewBaseColor = _generateRandomColor();
    List<Color> previewColors = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          HarmonyType selectedHarmonyType = HarmonyType.values.firstWhere(
            (type) => type.toString().split('.').last == _state.selectedColorPaletteType.toString().split('.').last,
            orElse: () => HarmonyType.monochromatic,
          );
          previewColors = HarmonyGenerator.generateHarmony(previewBaseColor, selectedHarmonyType);

          return AlertDialog(
            title: const Text('Palette Options'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<ColorPaletteType>(
                  value: _state.selectedColorPaletteType,
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _state.selectedColorPaletteType = newValue;
                        previewBaseColor = _generateRandomColor();
                      });
                    }
                  },
                  items: ColorPaletteType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.toString().split('.').last),
                    );
                  }).toList(),
                ),
                if (_state.selectedColorPaletteType != ColorPaletteType.auto) ...[
                  const SizedBox(height: AppConstants.defaultPadding),
                  HarmonyPreviewWidget(colors: previewColors),
                  const SizedBox(height: AppConstants.defaultPadding),
                ],
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          previewBaseColor = _generateRandomColor();
                        });
                      },
                      child: const Text('New Colors'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _generateRandomPalette();
                      },
                      child: const Text('Generate'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: Colors.blue,
        onColorSelected: _addColorToPalette,
        currentPaletteSize: _state.palette.length,
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
              subtitle: Text(_state.selectedColorPaletteType?.toString().split('.').last ?? 'Auto'),
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
