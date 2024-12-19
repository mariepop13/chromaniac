import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:chromaniac/core/constants.dart';
import 'package:chromaniac/features/color_palette/domain/color_palette_type.dart';
import 'package:chromaniac/features/color_palette/domain/palette_generator_service.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';
import '../state/home_screen_state_notifier.dart';
import 'package:chromaniac/services/image_service.dart'; // Added import statement

class HomeScreenProvider extends ChangeNotifier {
  final HomeScreenStateNotifier _stateNotifier;

  HomeScreenProvider() : _stateNotifier = HomeScreenStateNotifier() {
    AppLogger.d('HomeScreenProvider initialized');
  }

  HomeScreenState get state => _stateNotifier.state;

  Future<void> pickImage(BuildContext context) async {
    final imageService = ImageService();
    final (image, bytes) = await imageService.pickImage(context);
    if (image != null && bytes != null) {
      _stateNotifier.setSelectedImage(image, bytes);
    }
  }

  Future<void> generatePaletteFromImage() async {
    if (state.selectedImage == null) {
      AppLogger.w('Cannot generate palette: no image selected');
      return;
    }

    try {
      AppLogger.d('Generating palette from image: ${state.selectedImage!.path}');
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        FileImage(state.selectedImage!),
        maximumColorCount: AppConstants.defaultPaletteSize,
      );

      AppLogger.i('Palette generated successfully with ${paletteGenerator.colors.length} colors');
      _stateNotifier.updatePalette(paletteGenerator.colors.toList());
    } catch (e, stackTrace) {
      AppLogger.e('Error generating palette from image', error: e, stackTrace: stackTrace);
    }
  }

  void generateRandomPalette() {
    final baseColor = _generateRandomColor();
    final colors = PaletteGeneratorService.generatePalette(
      state.selectedColorPaletteType ?? ColorPaletteType.auto,
      baseColor,
    );
    _stateNotifier.updatePalette(colors);
  }

  Color _generateRandomColor() {
    return Color((DateTime.now().millisecondsSinceEpoch & 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  void setColorPaletteType(ColorPaletteType type) {
    _stateNotifier.setSelectedColorPaletteType(type);
  }

  void addColor(Color color) => _stateNotifier.addColor(color);
  void removeColor(Color color) => _stateNotifier.removeColor(color);
  void clearPalette() => _stateNotifier.clearPalette();
  void reorderPalette(int oldIndex, int newIndex) => 
      _stateNotifier.reorderPalette(oldIndex, newIndex);
}
