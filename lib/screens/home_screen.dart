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

    // Landscape layout with image on left and colors on right
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
        leading: SettingsMenu(onSettingsTap: () => _showSettingsDialog(context)),
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
