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

  // New method to get current grid columns
  int get gridColumns {
    // Always return the saved value, or 1 if not set
    return _prefs.getInt(gridColumnsKey) ?? 1;
  }

  // New method to set grid columns
  Future<void> setGridColumns(int columns) async {
    // Ensure columns is a positive integer
    int maxAllowedColumns = getMaxGridColumns();
    AppLogger.d('Max allowed columns: $maxAllowedColumns');
    AppLogger.d('Attempting to set columns: $columns');

    int validColumns = columns.clamp(1, maxAllowedColumns);
    AppLogger.d('Validated columns: $validColumns');
    
    await _prefs.setInt(gridColumnsKey, validColumns);
    notifyListeners();
  }

  // Method to get max columns based on current palette size
  int getMaxGridColumns() {
    int defaultSize = defaultPaletteSize;
    int maxColumns = (defaultSize / 2).ceil();
    
    AppLogger.d('Calculating max grid columns for palette size: $defaultSize');
    AppLogger.d('Max columns calculation: $defaultSize ÷ 2 = $maxColumns');
    
    // Ensure max columns is between 1 and 4
    //maxColumns = maxColumns.clamp(1, 4);
    
    AppLogger.d('Final max columns after clamping: $maxColumns');
    return maxColumns;
  }

  // Calculate optimal columns based on palette size (for future use)
  int calculateOptimalColumns(int paletteSize) {
    if (paletteSize <= 4) return 2;  // 2x2 grid
    if (paletteSize <= 6) return 3;  // 2x3 or 3x2 grid
    if (paletteSize <= 9) return 3;  // 3x3 grid
    return 4;  // 4x3 or 3x4 grid
  }
}
