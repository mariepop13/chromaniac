import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/logger/app_logger.dart';
import '../../../utils/dialog/dialog_utils.dart';

class ImageHandler {
  static Future<(File?, Uint8List?)?> pickImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        return (File(pickedFile.path), bytes);
      }
      return null;
    } catch (e) {
      AppLogger.e('Error picking image', error: e);
      if (context.mounted) {
        showSnackBar(context, 'Error picking image: $e');
      }
      return null;
    }
  }

  static Future<List<Color>> generatePaletteFromImage(
    BuildContext context,
    File imageFile,
  ) async {
    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      FileImage(imageFile),
      maximumColorCount: context.read<SettingsProvider>().defaultPaletteSize,
    );

    return paletteGenerator.colors.toList();
  }

  static List<Color> processColorAnalysis(List<Map<String, dynamic>> colorAnalysis) {
    return colorAnalysis.map((colorData) {
      try {
        final hexCode = colorData['hexCode'] as String;
        if (!_isValidHexColor(hexCode)) {
          AppLogger.w('Invalid hex color: $hexCode');
          return Colors.grey;
        }
        final hex = hexCode.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (e) {
        AppLogger.e('Error parsing color: $colorData', error: e);
        return Colors.grey;
      }
    }).toList();
  }

  static bool _isValidHexColor(String hexColor) {
    final hexRegExp = RegExp(r'^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');
    return hexRegExp.hasMatch(hexColor);
  }
}