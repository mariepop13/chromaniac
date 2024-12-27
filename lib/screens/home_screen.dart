import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chromaniac/features/color_palette/presentation/color_picker_dialog.dart';
import 'package:chromaniac/utils/color/export_palette.dart';
import 'package:chromaniac/utils/color/image_color_analyzer.dart';
import 'package:chromaniac/screens/favorites/favorites_screen.dart';
import 'package:chromaniac/widgets/app_bottom_nav.dart';
import 'package:chromaniac/widgets/speed_dial_fab.dart';
import '../providers/debug_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/logger/app_logger.dart';
import 'home/dialogs/palette_size_dialog.dart';
import 'home/dialogs/palette_options_dialog.dart';
import 'home/dialogs/save_palette_dialog.dart';
import 'home/home_content.dart';
import 'home/widgets/app_bar_actions.dart';
import 'home/widgets/settings_menu.dart';
import 'home/widgets/image_preview.dart';
import 'home/state/home_screen_state.dart';
import 'home/utils/palette_manager.dart';
import 'home/utils/image_handler.dart';
import 'package:chromaniac/providers/theme_provider.dart';

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

  void _generateRandomPalette() {
    setState(() {
      _state.clearPalette();
      _state.addColors(PaletteManager.generateRandomPalette(
        context,
        _state.selectedColorPaletteType,
      ));
    });
  }

  Future<void> _handleImagePick() async {
    final result = await ImageHandler.pickImage(context);
    if (!mounted) return;
    
    if (result != null) {
      final (file, bytes) = result;
      if (file != null && bytes != null) {
        setState(() {
          _state.selectedImage = file;
          _state.imageBytes = bytes;
        });
        
        final colors = await ImageHandler.generatePaletteFromImage(context, file);
        if (!mounted) return;
        
        setState(() {
          _state.clearPalette();
          _state.addColors(colors);
        });
      }
    }
  }

  void _showSettingsDialog(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) {
        int currentColumns = settingsProvider.gridColumns;
        int maxColumns = settingsProvider.calculateOptimalColumns(
          settingsProvider.getCurrentPaletteSize()
        );
        currentColumns = currentColumns.clamp(1, maxColumns);

        return AlertDialog(
          title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customize your Chromaniac experience',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 1,
                child: ListTile(
                  leading: const Icon(Icons.palette, color: Colors.blue),
                  title: const Text('Palette Size'),
                  subtitle: Text(
                    '${settingsProvider.defaultPaletteSize} colors',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => PaletteSizeDialog(
                        onSave: (size) {
                          settingsProvider.setDefaultPaletteSize(
                            size, 
                            onPaletteTruncate: (newSize) {
                              setState(() {
                                _state.truncatePaletteToSize(newSize);
                              });
                            }
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                child: ListTile(
                  leading: const Icon(Icons.color_lens, color: Colors.green),
                  title: const Text('Color Harmony'),
                  subtitle: Text(
                    _state.selectedColorPaletteType?.toString().split('.').last ?? 'Auto',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    showPaletteOptionsDialog(
                      context,
                      _state.selectedColorPaletteType,
                      (type) => setState(() => _state.selectedColorPaletteType = type),
                      (colors) => setState(() {
                        _state.clearPalette();
                        _state.addColors(colors);
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 1,
                child: ListTile(
                  leading: const Icon(Icons.grid_view, color: Colors.purple),
                  title: const Text('Grid Layout'),
                  subtitle: Text(
                    '$currentColumns columns',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (context, dialogSetState) {
                          return AlertDialog(
                            title: const Text('Grid Layout', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Adjust the number of columns to optimize your color grid view',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Number of Columns:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      currentColumns.toString(),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: currentColumns.toDouble(),
                                  min: 1,
                                  max: maxColumns.toDouble(),
                                  divisions: maxColumns > 1 ? maxColumns - 1 : null,
                                  label: currentColumns.toString(),
                                  onChanged: (double value) {
                                    currentColumns = value.round();
                                    settingsProvider.setGridColumns(currentColumns);
                                    dialogSetState(() {});
                                    setState(() {});
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Optimal columns based on current palette size (${settingsProvider.getCurrentPaletteSize()} colors)',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, Orientation orientation) {
    if (orientation == Orientation.portrait || _state.selectedImage == null) {
      return Column(
        children: [
          if (_state.selectedImage != null)
            ImagePreview(
              image: _state.selectedImage!,
              imageBytes: _state.imageBytes!,
              onAnalysisComplete: _handleAnalysisComplete,
            ),
          Expanded(
            child: HomeContent(
              palette: _state.palette,
              onRemoveColor: (color) => setState(() => _state.removeColor(color)),
              onEditColor: (oldColor, newColor) => setState(() => _state.updateColor(oldColor, newColor)),
              onAddHarmonyColors: (colors, paletteType) => PaletteManager.applyHarmonyColors(
                context,
                colors,
                (newColors) => setState(() {
                  _state.clearPalette();
                  _state.addColors(newColors);
                }),
                paletteType,
              ),
              onReorder: (oldIndex, newIndex) => setState(() => _state.reorderColors(oldIndex, newIndex)),
            ),
          ),
        ],
      );
    }


    return Row(
      children: [
        Expanded(
          flex: 1,
          child: ImagePreview(
            image: _state.selectedImage!,
            imageBytes: _state.imageBytes!,
            onAnalysisComplete: _handleAnalysisComplete,
          ),
        ),
        Expanded(
          flex: 1,
          child: HomeContent(
            palette: _state.palette,
            onRemoveColor: (color) => setState(() => _state.removeColor(color)),
            onEditColor: (oldColor, newColor) => setState(() => _state.updateColor(oldColor, newColor)),
            onAddHarmonyColors: (colors, paletteType) => PaletteManager.applyHarmonyColors(
              context,
              colors,
              (newColors) => setState(() {
                _state.clearPalette();
                _state.addColors(newColors);
              }),
              paletteType,
            ),
            onReorder: (oldIndex, newIndex) => setState(() => _state.reorderColors(oldIndex, newIndex)),
          ),
        ),
      ],
    );
  }

  void _handleAnalysisComplete(ColorAnalysisResult result) {
    try {
      setState(() {
        _state.clearPalette();
        final colors = ImageHandler.processColorAnalysis(result.colorAnalysis);
        _state.addColors(colors);
      });
    } catch (e, stackTrace) {
      AppLogger.e('Error processing color analysis', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error processing colors. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: SettingsMenu(
          onSettingsTap: () => _showSettingsDialog(context),
          onThemeTap: () {
            Provider.of<ThemeProvider>(context, listen: false)
                .toggleTheme(!Provider.of<ThemeProvider>(context, listen: false).isDarkMode);
          },
        ),
        title: const Text('Chromaniac'),
        actions: const [AppBarActions()],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) => _buildContent(context, orientation),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
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
          onAddColor: () => showDialog(
            context: context,
            builder: (context) => ColorPickerDialog(
              initialColor: Colors.blue,
              onColorSelected: (color) => PaletteManager.addColorsToPalette(
                context,
                [color],
                _state.palette,
                (colors) => setState(() => _state.addColors(colors)),
              ),
              currentPaletteSize: _state.palette.length,
            ),
          ),
          onImportImage: _handleImagePick,
          onClearAll: () => setState(() => _state.clearPalette()),
          onSavePalette: () => showSavePaletteDialog(context, _state.palette),
          onExportPalette: () async {
            final box = context.findRenderObject() as RenderBox?;
            await exportPalette(context, _state.palette, originBox: box);
          },
          isDebugEnabled: debugProvider.isDebugEnabled,
        ),
      ),
    );
  }
}
