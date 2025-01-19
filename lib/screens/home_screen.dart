import 'package:chromaniac/widgets/color_analysis_button.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'home/widgets/app_bar_actions.dart';
import 'home/widgets/settings_menu.dart';
import 'home/widgets/image_preview.dart';
import 'home/state/home_screen_state.dart';
import 'home/utils/palette_manager.dart';
import 'home/utils/image_handler.dart';
import 'package:chromaniac/providers/theme_provider.dart';
import 'dart:math' show max;
import '../../screens/home/palette_grid_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chromaniac/screens/auth/login_screen.dart';
import 'package:chromaniac/services/auth_service.dart';
import 'package:chromaniac/core/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _state = HomeScreenState();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _generateRandomPalette();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _currentUser = authService.currentUser;
    });
  }

  void _showLoginScreen() async {
    final result = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LoginScreen()));

    if (result == true) {
      _checkCurrentUser();
    }
  }

  void _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    _checkCurrentUser();
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
    try {
      final result = await ImageHandler.pickImage(context);
      AppLogger.d(
          'Image pick result: file=${result?.$1}, bytes=${result?.$2?.length}');

      if (!mounted) return;

      if (result != null) {
        final (file, bytes) = result;
        if (bytes != null) {
          setState(() {
            _state.selectedImage = kIsWeb ? null : file;
            _state.imageBytes = bytes;
            AppLogger.d(
                'Image set: selectedImage=${_state.selectedImage}, imageBytes=${_state.imageBytes?.length}');
          });

          final colors = await ImageHandler.generatePaletteFromImage(
              context,
              kIsWeb ? bytes : file!,
              context.read<SettingsProvider>().defaultPaletteSize);
          AppLogger.d('Generated colors: $colors');

          if (!mounted) return;

          setState(() {
            _state.clearPalette();
            _state.addColors(
                colors.map((paletteColor) => paletteColor.color).toList());
          });
        } else {
          AppLogger.w('Image bytes are null');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to process image. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        AppLogger.w('No image selected');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error in image pick process',
          error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: SingleChildScrollView(
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.palette, color: Colors.blue),
                        title: const Text('Palette Size'),
                        subtitle: Text(
                          '${context.read<SettingsProvider>().defaultPaletteSize} colors',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => PaletteSizeDialog(
                              onSave: (size) {
                                context
                                    .read<SettingsProvider>()
                                    .setDefaultPaletteSize(size,
                                        onPaletteTruncate: (newSize) {
                                  setState(() {
                                    _state.truncatePaletteToSize(newSize);
                                  });
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading:
                            const Icon(Icons.color_lens, color: Colors.green),
                        title: const Text('Color Harmony'),
                        subtitle: Text(
                          _state.selectedColorPaletteType
                                  ?.toString()
                                  .split('.')
                                  .last ??
                              'Auto',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          showPaletteOptionsDialog(
                            context,
                            _state.selectedColorPaletteType,
                            (type) => setState(
                                () => _state.selectedColorPaletteType = type),
                            (colors) => setState(() {
                              _state.clearPalette();
                              _state.addColors(colors);
                            }),
                          );
                        },
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading:
                            const Icon(Icons.grid_view, color: Colors.purple),
                        title: const Text('Grid Layout'),
                        subtitle: Consumer<SettingsProvider>(
                          builder: (context, settingsProvider, _) {
                            final currentColumns = settingsProvider.gridColumns;
                            final maxColumns = settingsProvider
                                .calculateOptimalColumns(_state.palette.length);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$currentColumns columns',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Slider(
                                  value: currentColumns.toDouble(),
                                  min: 1,
                                  max: max(currentColumns, maxColumns)
                                      .toDouble(),
                                  divisions: max(currentColumns, maxColumns) > 1
                                      ? max(currentColumns, maxColumns) - 1
                                      : null,
                                  label: currentColumns.toString(),
                                  onChanged: (double value) {
                                    final columns = value.round();
                                    settingsProvider.setGridColumns(columns);
                                    setState(() {});
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, Orientation orientation) {
    AppLogger.d(
        'Building content: orientation=$orientation, selectedImage=${_state.selectedImage}, imageBytes=${_state.imageBytes != null}');

    if (orientation == Orientation.portrait || _state.selectedImage == null) {
      return Stack(
        children: [
          PaletteGridView(
            palette: _state.palette,
            onRemoveColor: (color) => setState(() => _state.removeColor(color)),
            onEditColor: (oldColor, newColor) =>
                setState(() => _state.updateColor(oldColor, newColor)),
            onAddHarmonyColors: (colors, paletteType) =>
                PaletteManager.applyHarmonyColors(
              context,
              colors,
              (newColors) => setState(() {
                _state.clearPalette();
                _state.addColors(newColors);
              }),
              paletteType,
            ),
            onReorder: (oldIndex, newIndex) =>
                setState(() => _state.reorderColors(oldIndex, newIndex)),
          ),
          if (_state.imageBytes != null)
            Positioned(
              bottom: 16,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => ImagePreviewDialog.show(
                      context,
                      image: _state.selectedImage,
                      imageBytes: _state.imageBytes!,
                      onAnalysisComplete: _handleAnalysisComplete,
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.25,
                      height: MediaQuery.of(context).size.height * 0.25,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.memory(
                                _state.imageBytes!,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _state.selectedImage!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ColorAnalysisButton(
                    imageBytes: _state.imageBytes,
                    onAnalysisComplete: _handleAnalysisComplete,
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: PaletteGridView(
            palette: _state.palette,
            onRemoveColor: (color) => setState(() => _state.removeColor(color)),
            onEditColor: (oldColor, newColor) =>
                setState(() => _state.updateColor(oldColor, newColor)),
            onAddHarmonyColors: (colors, paletteType) =>
                PaletteManager.applyHarmonyColors(
              context,
              colors,
              (newColors) => setState(() {
                _state.clearPalette();
                _state.addColors(newColors);
              }),
              paletteType,
            ),
            onReorder: (oldIndex, newIndex) =>
                setState(() => _state.reorderColors(oldIndex, newIndex)),
          ),
        ),
      ],
    );
  }

  void _handleAnalysisComplete(ColorAnalysisResult result) {
    // If result is empty, it means Smart Palette button was pressed
    if (result.colorAnalysis.isEmpty) {
      // Simply show the theme input dialog without any analysis
      _showThemeInputDialog();
    } else {
      // If result is not empty, use it directly
      _showThemeInputDialog();
    }
  }

  void _showThemeInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController themeController = TextEditingController();
        final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

        return AlertDialog(
          title: const Text('Enter Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<String?>(
                valueListenable: errorNotifier,
                builder: (context, errorText, child) {
                  return TextField(
                    controller: themeController,
                    decoration: InputDecoration(
                      hintText: 'e.g., pastel, noel, summer',
                      errorText: errorText,
                      helperText:
                          'Choose a theme to generate your color palette',
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final String theme = themeController.text.trim();

                if (theme.isEmpty) {
                  // Set more descriptive error message if theme is empty
                  errorNotifier.value =
                      'Please enter a theme for color generation\n'
                      'Examples: pastel, noel, summer, vintage, modern';
                } else {
                  // Clear any previous error
                  errorNotifier.value = null;

                  // Close the dialog
                  Navigator.of(context).pop();

                  // Initiate color analysis with theme
                  _initiateColorAnalysisWithTheme(theme);
                }
              },
              child: const Text('Confirm Generation'),
            ),
          ],
        );
      },
    );
  }

  void _initiateColorAnalysisWithTheme(String theme) {
    // Ensure image bytes are available
    if (_state.imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No image selected. Please pick an image first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Use ImageColorAnalyzer with theme
    final analyzer = ImageColorAnalyzer();

    // Perform color analysis with theme
    analyzer
        .analyzeColoringImageWithTheme(
      _state.imageBytes!,
      theme,
    )
        .then((themedResult) {
      // Show analysis dialog with the themed result
      _showAnalysisDialog(themedResult);

      setState(() {
        _state.clearPalette();
        final colors =
            ImageHandler.processColorAnalysis(themedResult.colorAnalysis);
        _state.addColors(colors);
        AppLogger.d('Generated palette for theme: $theme');
      });
    }).catchError((e, stackTrace) {
      AppLogger.e('Error processing themed color analysis',
          error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error generating palette. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _showAnalysisDialog(ColorAnalysisResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.dialogBorderRadius),
          ),
          child: OrientationBuilder(
            builder: (context, orientation) {
              final isLandscape = orientation == Orientation.landscape;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxDialogHeight = isLandscape
                      ? MediaQuery.of(context).size.height * 0.8
                      : constraints.maxHeight - 100;
                  final maxDialogWidth = isLandscape
                      ? MediaQuery.of(context).size.width * 0.8
                      : constraints.maxWidth;

                  return Container(
                    width: maxDialogWidth,
                    constraints: BoxConstraints(
                      maxHeight: maxDialogHeight,
                    ),
                    padding: const EdgeInsets.all(AppConstants.dialogPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Palette Results',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingMedium),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: result.colorAnalysis.map((analysis) {
                                final color = Color(int.parse(
                                  analysis['hexCode']!.replaceAll('#', '0xFF'),
                                ));
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppConstants.spacingSmall,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: AppConstants.colorPreviewSize,
                                        height: AppConstants.colorPreviewSize,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(
                                            AppConstants
                                                .colorPreviewBorderRadius,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                          width: AppConstants.spacingMedium),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              analysis['object']!,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(analysis['colorName']!),
                                          ],
                                        ),
                                      ),
                                      Text(analysis['hexCode']!),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    return AppBottomNav(
      context: context,
      currentIndex: 1,
      onTap: (index) {
        switch (index) {
          case 0:
            _generateRandomPalette();
            break;
          case 1:
            break;
          case 2:
            // Theme spinner is now handled directly in the bottom nav
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FavoritesScreen(
                  onRestorePalette: (colors) {
                    setState(() {
                      _state.clearPalette();
                      _state.addColors(colors);
                    });
                  },
                ),
              ),
            );
            break;
          case 4:
            _showSettingsDialog(context);
            break;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: SettingsMenu(
          onSettingsTap: () => _showSettingsDialog(context),
          onThemeTap: () {
            Provider.of<ThemeProvider>(context, listen: false).toggleTheme(
                !Provider.of<ThemeProvider>(context, listen: false).isDarkMode);
          },
        ),
        title: const Text('Chromaniac'),
        actions: [
          AppBarActions(
            onSettingsTap: () => _showSettingsDialog(context),
            onFavoritesTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FavoritesScreen())),
          ),
          if (_currentUser == null)
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Login',
              onPressed: _showLoginScreen,
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              tooltip: 'Account',
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout, color: Colors.red),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Logout (${_currentUser?.email ?? ""})',
                          style: const TextStyle(color: Colors.red),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) =>
              _buildContent(context, orientation),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
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
