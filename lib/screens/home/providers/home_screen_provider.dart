import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:logger/logger.dart';
import 'package:chromaniac/core/constants.dart';
import 'package:chromaniac/features/color_palette/domain/color_palette_type.dart';
import 'package:chromaniac/features/color_palette/domain/palette_generator_service.dart';
import 'package:chromaniac/utils/dialog/dialog_utils.dart';
import '../state/home_screen_state_notifier.dart';

class HomeScreenProvider extends ChangeNotifier {
  final HomeScreenStateNotifier _stateNotifier;
  final Logger _logger = Logger();

  HomeScreenProvider() : _stateNotifier = HomeScreenStateNotifier();

  HomeScreenState get state => _stateNotifier.state;

  Future<void> pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        _stateNotifier.setSelectedImage(File(pickedFile.path), bytes);
      }
    } catch (e) {
      _logger.e('Error picking image: $e');
      if (context.mounted) {
        showSnackBar(context, 'Error picking image: $e');
      }
    }
  }

  Future<void> generatePaletteFromImage() async {
    if (state.selectedImage == null) return;

    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        FileImage(state.selectedImage!),
        maximumColorCount: AppConstants.defaultPaletteSize,
      );

      _stateNotifier.updatePalette(paletteGenerator.colors.toList());
    } catch (e) {
      _logger.e('Error generating palette from image: $e');
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