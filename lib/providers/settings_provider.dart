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
    
    // Always update and notify
    await _prefs.setInt(gridColumnsKey, validColumns);
    notifyListeners();
  }

  int? _temporaryPaletteSize;

  Future<void> setTemporaryPaletteSize(int size) async {
    AppLogger.d('Setting Temporary Palette Size - Start:');
    AppLogger.d('- Requested Size: $size');
    AppLogger.d('- Current Temporary Size: $_temporaryPaletteSize');
    
    // Validate the size
    if (size < AppConstants.minPaletteColors || size > AppConstants.maxPaletteColors) {
      AppLogger.e('Invalid temporary palette size: $size');
      return;
    }
    
    // Always update temporary palette size
    _temporaryPaletteSize = size;
    
    // Always recalculate and set grid columns based on new palette size
    final optimalColumns = calculateOptimalColumns(size);
    
    AppLogger.d('Grid Column Calculation:');
    AppLogger.d('- Optimal Columns: $optimalColumns');
    AppLogger.d('- Current Grid Columns: $gridColumns');
    
    // Force update grid columns
    await setGridColumns(optimalColumns);
    
    AppLogger.d('Setting Temporary Palette Size - Complete');
    
    // Ensure listeners are notified
    notifyListeners();
  }

  Future<void> clearTemporaryPaletteSize() async {
    AppLogger.d('Clearing temporary palette size');
    
    // Always reset temporary palette size
    _temporaryPaletteSize = null;
    
    // Reset to optimal columns based on default palette size
    final optimalColumns = calculateOptimalColumns(defaultPaletteSize);
    
    AppLogger.d('Resetting grid columns:');
    AppLogger.d('- Default Palette Size: $defaultPaletteSize');
    AppLogger.d('- Optimal Columns: $optimalColumns');
    
    // Force update grid columns
    await setGridColumns(optimalColumns);
    
    // Ensure listeners are notified of the state change
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
    
    // Dynamically calculate max columns based on current palette size
    int maxColumns = calculateOptimalColumns(currentSize);
    AppLogger.d('Using max columns: $maxColumns');
    return maxColumns;
  }

  int getGridColumnsForPaletteSize(int paletteSize) {
    return (paletteSize / 2).ceil();
  }

  Future<void> adjustGridColumnsForPaletteSize() async {
    int currentSize = getCurrentPaletteSize();
    int optimalColumns = getGridColumnsForPaletteSize(currentSize);
    int maxColumns = getMaxGridColumns();
    int currentGridColumns = gridColumns;
    
    AppLogger.d('Grid Columns Update Diagnostic:');
    AppLogger.d('- Current Palette Size: $currentSize');
    AppLogger.d('- Optimal Columns: $optimalColumns');
    AppLogger.d('- Max Columns: $maxColumns');
    AppLogger.d('- Current Grid Columns: $currentGridColumns');
    
    // Ensure columns are within the valid range
    int columnsToSet = optimalColumns.clamp(1, maxColumns);
    
    // Only update if columns have actually changed
    if (columnsToSet != currentGridColumns) {
      AppLogger.d('Updating grid columns: $currentGridColumns -> $columnsToSet');
      await setGridColumns(columnsToSet);
    } else {
      AppLogger.d('No grid column update needed');
    }
  }

  int validateGridColumns(int columns) {
    int currentSize = getCurrentPaletteSize();
    int maxColumns = calculateOptimalColumns(currentSize);
    
    AppLogger.d('Validating grid columns: current size = $currentSize, max columns = $maxColumns');
    
    return columns.clamp(1, maxColumns);
  }

  int calculateOptimalColumns(int paletteSize) {
    // Special handling for very small palettes
    if (paletteSize <= 2) return 1;
    if (paletteSize <= 4) return 2;
    
    // For larger palettes, use the standard calculation
    return (paletteSize / 2).ceil().clamp(1, paletteSize);
  }

  bool isUsingTemporaryPalette() {
    bool isTemporary = _temporaryPaletteSize != null;
    AppLogger.d('Checking temporary palette status: $isTemporary');
    return isTemporary;
  }
}
