import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:chromaniac/core/constants.dart';
import 'package:chromaniac/features/color_palette/domain/color_palette_type.dart';
import 'package:chromaniac/features/color_palette/domain/palette_generator_service.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';
import '../state/home_screen_state_notifier.dart';
import 'package:chromaniac/services/image_service.dart';
import 'package:chromaniac/services/database_service.dart';

class HomeScreenProvider extends ChangeNotifier {
  final HomeScreenStateNotifier _stateNotifier = HomeScreenStateNotifier();
  HomeScreenState get state => _stateNotifier.state;
  final DatabaseService _databaseService = DatabaseService();

  HomeScreenProvider() {
    AppLogger.d('HomeScreenProvider initialized');
  }

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

  void generateRandomPalette(BuildContext context) {
    final baseColor = _generateRandomColor();
    final colors = PaletteGeneratorService.generatePalette(
      context,
      state.selectedColorPaletteType ?? ColorPaletteType.auto,
      baseColor,
    );
    _stateNotifier.updatePalette(colors);
  }

  void updateColor(int index, Color newColor) {
    _stateNotifier.updateColorAtIndex(index, newColor);
    notifyListeners();
  }

  Color _generateRandomColor() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return Color.from(
      alpha: 1.0,
      red: ((timestamp >> 16) & 0xFF) / 255.0,
      green: ((timestamp >> 8) & 0xFF) / 255.0,
      blue: (timestamp & 0xFF) / 255.0,
    );
  }

  void setColorPaletteType(ColorPaletteType type) {
    _stateNotifier.setSelectedColorPaletteType(type);
  }

  void addColor(Color color) => _stateNotifier.addColor(color);
  void removeColor(Color color) => _stateNotifier.removeColor(color);
  void clearPalette() => _stateNotifier.clearPalette();
  void reorderPalette(int oldIndex, int newIndex) => 
      _stateNotifier.reorderPalette(oldIndex, newIndex);

  Future<void> toggleFavorite(Color color) async {
    try {
      final favorites = await _databaseService.getFavoriteColors();
      final colorInt = ((color.a * 255).round() << 24) |
                      ((color.r * 255).round() << 16) |
                      ((color.g * 255).round() << 8) |
                      (color.b * 255).round();
      final isFavorite = favorites.any((f) => 
        ((f.color.a * 255).round() << 24) |
        ((f.color.r * 255).round() << 16) |
        ((f.color.g * 255).round() << 8) |
        (f.color.b * 255).round() == colorInt
      );

      if (isFavorite) {
        final colorInt = ((color.a * 255).round() << 24) |
                        ((color.r * 255).round() << 16) |
                        ((color.g * 255).round() << 8) |
                        (color.b * 255).round();
        final favorite = favorites.firstWhere((f) => 
          ((f.color.a * 255).round() << 24) |
          ((f.color.r * 255).round() << 16) |
          ((f.color.g * 255).round() << 8) |
          (f.color.b * 255).round() == colorInt
        );
        await _databaseService.removeFavoriteColor(favorite.id);
      } else {
        await _databaseService.addFavoriteColor(color);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<bool> isFavoriteColor(Color color) async {
    try {
      final favorites = await _databaseService.getFavoriteColors();
      final colorInt = ((color.a * 255).round() << 24) |
                      ((color.r * 255).round() << 16) |
                      ((color.g * 255).round() << 8) |
                      (color.b * 255).round();
      return favorites.any((f) => 
        ((f.color.a * 255).round() << 24) |
        ((f.color.r * 255).round() << 16) |
        ((f.color.g * 255).round() << 8) |
        (f.color.b * 255).round() == colorInt
      );
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      return false;
    }
  }
}
