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

  void setTemporaryPaletteSize(int size) {
    AppLogger.d('Setting temporary palette size: $size');
    _temporaryPaletteSize = size;
    notifyListeners();
  }

  void clearTemporaryPaletteSize() {
    AppLogger.d('Clearing temporary palette size');
    _temporaryPaletteSize = null;
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
    
    if (_temporaryPaletteSize != null) {
      int maxColumns = (_temporaryPaletteSize! / 2).ceil();
      if (_temporaryPaletteSize! <= 2) maxColumns = 1;
      
      AppLogger.d('Using temporary size for max columns: $maxColumns');
      return maxColumns;
    }
    
    int maxColumns = (currentSize / 2).ceil();
    if (currentSize <= 2) maxColumns = 1;
    
    AppLogger.d('Using default size for max columns: $maxColumns');
    return maxColumns;
  }

  int getGridColumnsForPaletteSize(int paletteSize) {
    AppLogger.d('Getting grid columns for palette size: $paletteSize');
    
    if (paletteSize <= 2) return 1;
    if (paletteSize <= 4) return 2;
    if (paletteSize <= 6) return 3;
    
    return 4;
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
    int maxColumns = getMaxGridColumns();
    
    AppLogger.d('Validating grid columns: current size = $currentSize, max columns = $maxColumns');
    
    if (_temporaryPaletteSize != null && _temporaryPaletteSize != defaultPaletteSize) {
      maxColumns = (_temporaryPaletteSize! / 2).ceil();
      AppLogger.d('Temporary palette size detected. Calculating max columns from temporary size: $maxColumns');
    }
    
    return columns.clamp(1, maxColumns);
  }

  int calculateOptimalColumns(int paletteSize) {
    if (paletteSize <= 4) return 2;
    if (paletteSize <= 6) return 3;
    if (paletteSize <= 9) return 3;
    return 4;
  }

  bool isUsingTemporaryPalette() {
    return _temporaryPaletteSize != null;
  }
}
