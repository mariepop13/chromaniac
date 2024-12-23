import 'dart:io';
import 'dart:math';
import 'package:chromaniac/models/color_palette.dart';
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
import 'package:chromaniac/services/database_service.dart';
import 'package:uuid/uuid.dart';

class HomeScreenState {
  List<Color> palette = [];
  ColorPaletteType? selectedColorPaletteType = ColorPaletteType.auto;
  File? selectedImage;
  Uint8List? imageBytes;
  
  void clearImage() {
    selectedImage = null;
    imageBytes = null;
  }
  
  void clearPalette() {
    palette.clear();
  }
  
  void addColors(List<Color> colors) {
    palette.addAll(colors);
  }
  
  void removeColor(Color color) {
    palette.remove(color);
  }
  
  void reorderColors(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final color = palette.removeAt(oldIndex);
    palette.insert(newIndex, color);
  }
  
  void updateColor(Color oldColor, Color newColor) {
    final index = palette.indexOf(oldColor);
    if (index != -1) {
      palette[index] = newColor;
    }
  }
}

class HomeScreenStateWidget extends StatefulWidget {
  const HomeScreenStateWidget({super.key});

  @override
  State<HomeScreenStateWidget> createState() => HomeScreenStateWidgetState();
}

class HomeScreenStateWidgetState extends State<HomeScreenStateWidget> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final HomeScreenState homeScreenState = HomeScreenState();

  @override
  void initState() {
    super.initState();
    generateRandomPalette(context);
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          homeScreenState.selectedImage = File(pickedFile.path);
          homeScreenState.imageBytes = bytes;
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
    if (homeScreenState.selectedImage == null) return;

    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      FileImage(homeScreenState.selectedImage!),
      maximumColorCount: AppConstants.defaultPaletteSize,
    );

    setState(() {
      homeScreenState.clearPalette();
      homeScreenState.addColors(paletteGenerator.colors.toList());
    });
  }

  void removeColorFromPalette(Color color) {
    if (homeScreenState.palette.contains(color)) {
      setState(() {
        homeScreenState.removeColor(color);
      });
    }
  }

  void addColorToPalette(Color color) {
    setState(() {
      final maxColors = context.read<PremiumService>().isPremium 
          ? AppConstants.maxPaletteColors 
          : AppConstants.defaultPaletteSize;
          
      if (homeScreenState.palette.length < maxColors) {
        homeScreenState.addColors([color]);
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
    return Color.from(
      alpha: 1.0,
      red: random.nextDouble(),
      green: random.nextDouble(),
      blue: random.nextDouble(),
    );
  }

  void generateRandomPalette(BuildContext context) {
    setState(() {
      homeScreenState.clearPalette();
      homeScreenState.addColors(PaletteGeneratorService.generatePalette(
        context,
        homeScreenState.selectedColorPaletteType ?? ColorPaletteType.auto,
        generateRandomColor(),
      ));
    });
  }

  void clearPalette() {
    setState(() {
      homeScreenState.clearPalette();
    });
  }

  void editColorInPalette(Color oldColor, Color newColor) {
    setState(() {
      homeScreenState.updateColor(oldColor, newColor);
    });
  }

  Future<void> addToFavorites([String? name]) async {
    try {
      final now = DateTime.now();
      AppLogger.d('Creating new palette with ${homeScreenState.palette.length} colors');
      
      final colorPalette = ColorPalette(
        id: const Uuid().v4(),
        name: name ?? 'Palette ${now.toIso8601String()}',
        colors: List<Color>.from(homeScreenState.palette), // Create a new list to avoid reference issues
        createdAt: now,
        updatedAt: now,
      );
      
      AppLogger.d('Saving palette: ${colorPalette.name}');
      AppLogger.d('Colors: ${colorPalette.colors.map((c) => 
        ((((c.r * 255).round() << 16) | 
          ((c.g * 255).round() << 8) | 
          (c.b * 255).round())).toRadixString(16).padLeft(6, '0')
      ).join(', ')}');
      
      await DatabaseService().savePalette(colorPalette);
      
      if (mounted) {
        showSnackBar(context, 'Palette saved successfully');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error saving palette', error: e, stackTrace: stackTrace);
      if (mounted) {
        showSnackBar(context, 'Error saving palette: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Container(); // Implemented in home_screen.dart
}
