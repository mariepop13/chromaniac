import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../utils/logger/app_logger.dart';

class SettingsProvider extends ChangeNotifier {
  static const String defaultPaletteSizeKey = 'defaultPaletteSize';
  static const String gridColumnsKey = 'gridColumns';

  final SharedPreferences _prefs;

  SettingsProvider(this._prefs);

  int get defaultPaletteSize =>
      _prefs.getInt(defaultPaletteSizeKey) ?? AppConstants.defaultPaletteSize;

  Future<void> setDefaultPaletteSize(int size) async {
    if (size < AppConstants.minPaletteColors || size > AppConstants.maxPaletteColors) {
      throw RangeError('Palette size must be between ${AppConstants.minPaletteColors} and ${AppConstants.maxPaletteColors}');
    }
    
    await _prefs.setInt(defaultPaletteSizeKey, size);
    
    // If not using temporary palette size, adjust grid columns based on new default size
    if (_temporaryPaletteSize == null) {
      final optimalColumns = (size / 2).ceil();
      await setGridColumns(optimalColumns);
    }
    
    notifyListeners();
  }

  int get gridColumns {
    return _prefs.getInt(gridColumnsKey) ?? 1;
  }

  Future<void> setGridColumns(int columns) async {
    int validColumns = validateGridColumns(columns);
    
    AppLogger.d('Setting grid columns: requested = $columns, validated = $validColumns');
    
    await _prefs.setInt(gridColumnsKey, validColumns);
    notifyListeners();
  }

  int? _temporaryPaletteSize;

  Future<void> setTemporaryPaletteSize(int size) async {
    AppLogger.d('Setting temporary palette size: $size');
    _temporaryPaletteSize = size;
    
    // Automatically adjust grid columns based on new palette size
    final optimalColumns = (size / 2).ceil();
    await setGridColumns(optimalColumns);
    
    notifyListeners();
  }

  Future<void> clearTemporaryPaletteSize() async {
    AppLogger.d('Clearing temporary palette size');
    _temporaryPaletteSize = null;
    
    // Reset to optimal columns based on default palette size
    final optimalColumns = (defaultPaletteSize / 2).ceil();
    await setGridColumns(optimalColumns);
    
    notifyListeners();
  }

  int getCurrentPaletteSize() {
    if (_temporaryPaletteSize != null) {
      AppLogger.d('Using temporary palette size: $_temporaryPaletteSize');
      return _temporaryPaletteSize!;
    }
    
    AppLogger.d('Using default palette size: $defaultPaletteSize');
    return defaultPaletteSize;
  }

  int getMaxGridColumns() {
    int currentSize = getCurrentPaletteSize();
    AppLogger.d('Calculating max grid columns for current palette size: $currentSize');
    
    int maxColumns = (currentSize / 2).ceil();
    AppLogger.d('Using max columns: $maxColumns');
    return maxColumns;
  }

  int getGridColumnsForPaletteSize(int paletteSize) {
    return (paletteSize / 2).ceil();
  }

  Future<void> adjustGridColumnsForPaletteSize() async {
    getCurrentPaletteSize();
    int maxColumns = getMaxGridColumns();
    
    if (gridColumns > maxColumns) {
      AppLogger.d('Adjusting grid columns from $gridColumns to $maxColumns');
      await setGridColumns(maxColumns);
    }
  }

  int validateGridColumns(int columns) {
    int currentSize = getCurrentPaletteSize();
    int maxColumns = (currentSize / 2).ceil();
    
    AppLogger.d('Validating grid columns: current size = $currentSize, max columns = $maxColumns');
    
    return columns.clamp(1, maxColumns);
  }

  int calculateOptimalColumns(int paletteSize) {
    return (paletteSize / 2).ceil();
  }

  bool isUsingTemporaryPalette() {
    return _temporaryPaletteSize != null;
  }
}
