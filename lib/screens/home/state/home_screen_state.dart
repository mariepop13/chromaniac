import 'dart:io';
import 'dart:math';
import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:chromaniac/core/constants.dart';
import 'package:chromaniac/features/color_palette/domain/color_palette_type.dart';
import 'package:chromaniac/features/color_palette/domain/palette_generator_service.dart';
import 'package:chromaniac/services/premium_service.dart';
import 'package:chromaniac/utils/dialog/dialog_utils.dart';
import '../home_screen.dart';

class HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Color> palette = [];
  ColorPaletteType? selectedColorPaletteType = ColorPaletteType.auto;
  File? selectedImage;
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    generateRandomPalette();
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          selectedImage = File(pickedFile.path);
          imageBytes = bytes;
        });
      }
    } catch (e) {
      AppLogger.e('Error picking image', error: e);
      if (mounted) {
        showSnackBar(context, 'Error picking image: $e');
      }
    }
  }

  Future<void> generatePaletteFromImage() async {
    if (selectedImage == null) return;

    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      FileImage(selectedImage!),
      maximumColorCount: AppConstants.defaultPaletteSize,
    );

    setState(() {
      palette.clear();
      palette.addAll(paletteGenerator.colors);
    });
  }

  void removeColorFromPalette(Color color) {
    if (palette.contains(color)) {
      setState(() {
        palette.remove(color);
      });
    }
  }

  void addColorToPalette(Color color) {
    setState(() {
      final maxColors = context.read<PremiumService>().isPremium 
          ? AppConstants.maxPaletteColors 
          : AppConstants.defaultPaletteSize;
          
      if (palette.length < maxColors) {
        palette.add(color);
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Palette Full'),
            content: Text(
              'You\'ve reached the maximum of ${AppConstants.defaultPaletteSize} colors. '
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
                  addColorToPalette(color);
                },
                child: const Text('Upgrade Now'),
              ),
            ],
          ),
        );
      }
    });
  }

  Color generateRandomColor() {
    final random = Random();
    return Color((random.nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
  }

  void generateRandomPalette() {
    setState(() {
      palette.clear();
      palette.addAll(PaletteGeneratorService.generatePalette(
        selectedColorPaletteType ?? ColorPaletteType.auto,
        generateRandomColor(),
      ));
    });
  }

  void clearPalette() {
    setState(() {
      palette.clear();
    });
  }

  void editColorInPalette(Color oldColor, Color newColor) {
    setState(() {
      final index = palette.indexOf(oldColor);
      if (index != -1) {
        palette[index] = newColor;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Container(); // Implemented in home_screen.dart
}
