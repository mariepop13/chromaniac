import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:chromaniac/features/color_palette/domain/color_palette_type.dart';

class HomeScreenState {
  final List<Color> palette;
  final ColorPaletteType? selectedColorPaletteType;
  final File? selectedImage;
  final Uint8List? imageBytes;

  const HomeScreenState({
    required this.palette,
    this.selectedColorPaletteType = ColorPaletteType.auto,
    this.selectedImage,
    this.imageBytes,
  });

  HomeScreenState copyWith({
    List<Color>? palette,
    ColorPaletteType? selectedColorPaletteType,
    File? selectedImage,
    Uint8List? imageBytes,
  }) {
    return HomeScreenState(
      palette: palette ?? this.palette,
      selectedColorPaletteType: selectedColorPaletteType ?? this.selectedColorPaletteType,
      selectedImage: selectedImage ?? this.selectedImage,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }
}

class HomeScreenStateNotifier extends ChangeNotifier {
  HomeScreenState _state = HomeScreenState(palette: []);

  HomeScreenState get state => _state;

  void updatePalette(List<Color> palette) {
    _state = _state.copyWith(palette: palette);
    notifyListeners();
  }

  void setSelectedColorPaletteType(ColorPaletteType type) {
    _state = _state.copyWith(selectedColorPaletteType: type);
    notifyListeners();
  }

  void setSelectedImage(File? image, Uint8List? bytes) {
    _state = _state.copyWith(
      selectedImage: image,
      imageBytes: bytes,
    );
    notifyListeners();
  }

  void addColor(Color color) {
    final newPalette = List<Color>.from(_state.palette)..add(color);
    updatePalette(newPalette);
  }

  void removeColor(Color color) {
    final newPalette = List<Color>.from(_state.palette)..remove(color);
    updatePalette(newPalette);
  }

  void clearPalette() {
    updatePalette([]);
  }

  void reorderPalette(int oldIndex, int newIndex) {
    final newPalette = List<Color>.from(_state.palette);
    final color = newPalette.removeAt(oldIndex);
    newPalette.insert(newIndex, color);
    updatePalette(newPalette);
  }

  void updateColorAtIndex(int index, Color newColor) {
    if (index < 0 || index >= _state.palette.length) return;
    
    final newPalette = List<Color>.from(_state.palette);
    newPalette[index] = newColor;
    _state = _state.copyWith(palette: newPalette);
    notifyListeners();
  }
}
