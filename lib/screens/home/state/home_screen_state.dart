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
import 'package:chromaniac/screens/home_screen.dart';
import 'package:chromaniac/services/database_service.dart';
import 'package:uuid/uuid.dart';

class HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Color> palette = [];
  ColorPaletteType? selectedColorPaletteType = ColorPaletteType.auto;
  File? selectedImage;
  Uint8List? imageBytes;

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
    return Color.from(
      alpha: 1.0,
      red: random.nextDouble(),
      green: random.nextDouble(),
      blue: random.nextDouble(),
    );
  }

  void generateRandomPalette(BuildContext context) {
    setState(() {
      palette.clear();
      palette.addAll(PaletteGeneratorService.generatePalette(
        context,
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

  Future<void> addToFavorites([String? name]) async {
    try {
      final now = DateTime.now();
      AppLogger.d('Creating new palette with ${palette.length} colors');
      
      final colorPalette = ColorPalette(
        id: const Uuid().v4(),
        name: name ?? 'Palette ${now.toIso8601String()}',
        colors: List<Color>.from(palette), // Create a new list to avoid reference issues
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
