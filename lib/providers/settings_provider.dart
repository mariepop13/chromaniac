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

  Future<void> setTemporaryPaletteSize(int size) async {
    AppLogger.d('Setting Temporary Palette Size - Start:');
    AppLogger.d('- Requested Size: $size');
    AppLogger.d('- Current Temporary Size: $_temporaryPaletteSize');
    

    if (size < AppConstants.minPaletteColors || size > AppConstants.maxPaletteColors) {
      AppLogger.e('Invalid temporary palette size: $size');
      return;
    }
    

    _temporaryPaletteSize = size;
    

    final optimalColumns = calculateOptimalColumns(size);
    
    AppLogger.d('Grid Column Calculation:');
    AppLogger.d('- Optimal Columns: $optimalColumns');
    AppLogger.d('- Current Grid Columns: $gridColumns');
    

    await setGridColumns(optimalColumns);
    
    AppLogger.d('Setting Temporary Palette Size - Complete');
    

    notifyListeners();
  }

  Future<void> clearTemporaryPaletteSize() async {
    AppLogger.d('Clearing temporary palette size');
    

    _temporaryPaletteSize = null;
    

    final optimalColumns = calculateOptimalColumns(defaultPaletteSize);
    
    AppLogger.d('Resetting grid columns:');
    AppLogger.d('- Default Palette Size: $defaultPaletteSize');
    AppLogger.d('- Optimal Columns: $optimalColumns');
    

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
    

    int columnsToSet = optimalColumns.clamp(1, maxColumns);
    

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

    if (paletteSize <= 2) return 1;
    if (paletteSize <= 4) return 2;
    

    return (paletteSize / 2).ceil().clamp(1, paletteSize);
  }

  bool isUsingTemporaryPalette() {
    bool isTemporary = _temporaryPaletteSize != null;
    AppLogger.d('Checking temporary palette status: $isTemporary');
    return isTemporary;
  }

  Future<void> regenerateGridColumnsForDefaultPaletteSize() async {
    int currentDefaultSize = defaultPaletteSize;
    

    if (_temporaryPaletteSize == null) {
      final optimalColumns = calculateOptimalColumns(currentDefaultSize);
      
      AppLogger.d('Regenerating grid columns for default palette size:');
      AppLogger.d('- Default Palette Size: $currentDefaultSize');
      AppLogger.d('- Optimal Columns: $optimalColumns');
      
      await setGridColumns(optimalColumns);
    } else {
      AppLogger.d('Skipping grid columns regeneration due to active temporary palette size');
    }
  }
}
