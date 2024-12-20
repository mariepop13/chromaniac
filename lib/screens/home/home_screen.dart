import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chromaniac/core/constants.dart';
import 'package:chromaniac/providers/debug_provider.dart';
import 'package:chromaniac/services/premium_service.dart';
import 'package:chromaniac/features/color_palette/presentation/color_picker_dialog.dart';
import 'package:chromaniac/utils/color/export_palette.dart';
import 'package:chromaniac/screens/favorites/favorites_screen.dart';
import 'widgets/palette_content.dart';
import 'widgets/image_preview.dart';
import 'widgets/palette_menu.dart';
import 'dialogs/palette_options_dialog.dart';
import 'providers/home_screen_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeScreenProvider(),
      child: const HomeScreenView(),
    );
  }
}

class HomeScreenView extends StatelessWidget {
  const HomeScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeScreenProvider>();
    final state = provider.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chromaniac'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
            tooltip: 'Favorite Colors',
          ),
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
          PaletteMenu(
            onGenerate: () => showDialog(
              context: context,
              builder: (context) => PaletteOptionsDialog(
                selectedType: state.selectedColorPaletteType,
                onTypeChanged: (newValue) {
                  if (newValue != null) {
                    provider.setColorPaletteType(newValue);
                  }
                },
                onGenerate: provider.generateRandomPalette,
              ),
            ),
            onAdd: () => showDialog(
              context: context,
              builder: (context) => ColorPickerDialog(
                initialColor: Colors.blue,
                onColorSelected: provider.addColor,
                currentPaletteSize: state.palette.length,
              ),
            ),
            onImport: () async {
              await provider.pickImage(context);
              if (state.selectedImage != null) {
                await provider.generatePaletteFromImage();
              }
            },
            onExport: () async {
              final box = context.findRenderObject() as RenderBox?;
              await exportPalette(context, state.palette, originBox: box);
            },
            onClear: provider.clearPalette,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.selectedImage != null && state.imageBytes != null) 
              ImagePreview(
                image: state.selectedImage!,
                imageBytes: state.imageBytes!,
                onAnalysisComplete: (result) {
                  provider.clearPalette();
                  for (final colorInfo in result.colorAnalysis) {
                    final hexCode = colorInfo['hexCode']!;
                    final value = int.parse(hexCode.substring(1), radix: 16);
                    provider.addColor(Color(value | 0xFF000000));
                  }
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
                          ...result.colorAnalysis.map((colorInfo) => 
                            Padding(
                              padding: EdgeInsets.only(bottom: AppConstants.tinyPadding),
                              child: Text('• ${colorInfo['object']} - ${colorInfo['colorName']} (${colorInfo['hexCode']})'),
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
            Expanded(
              child: PaletteContent(
                palette: state.palette,
                onRemoveColor: provider.removeColor,
                onEditColor: (oldColor, newColor) {
                  provider.removeColor(oldColor);
                  provider.addColor(newColor);
                },
                onReorder: provider.reorderPalette,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
