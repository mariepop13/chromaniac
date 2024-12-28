import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../utils/logger/app_logger.dart';

class SettingsProvider extends ChangeNotifier {
  static const String defaultPaletteSizeKey = 'defaultPaletteSize';
  static const String gridColumnsKey = 'gridColumns';
  static const String gridColumnsPaletteSizeThreeKey = 'gridColumnsPaletteSizeThree';
  static const String isPremiumEnabledKey = 'isPremiumEnabled';
  static const String isPremiumStarLogoEnabledKey = 'isPremiumStarLogoEnabled';
  static const String maxPremiumPaletteColorsKey = 'maxPremiumPaletteColors';

  final SharedPreferences _prefs;

  SettingsProvider(this._prefs) {
    if (_prefs.getInt(gridColumnsPaletteSizeThreeKey) == null) {
      _prefs.setInt(gridColumnsPaletteSizeThreeKey, 2);
    }
  }

  int get defaultPaletteSize =>
      _prefs.getInt(defaultPaletteSizeKey) ?? AppConstants.defaultPaletteSize;

  Future<void> setDefaultPaletteSize(int size, {Function(int)? onPaletteTruncate}) async {
    if (!isPremiumEnabled && size > maxPremiumPaletteColors) {
      throw RangeError('Non-premium users are limited to $maxPremiumPaletteColors colors');
    }
    
    await _prefs.setInt(defaultPaletteSizeKey, size);
    
    if (size == 3) {
      await setGridColumns(2);
    } else {
      await regenerateGridColumnsForDefaultPaletteSize();
    }
    
    if (onPaletteTruncate != null) {
      onPaletteTruncate(size);
    }
    
    notifyListeners();
  }

  int get gridColumns {
    if (defaultPaletteSize == 3) {
      return _prefs.getInt(gridColumnsPaletteSizeThreeKey) ?? 2;
    }
    return _prefs.getInt(gridColumnsKey) ?? 1;
  }

  Future<void> setGridColumns(int columns) async {
    int validColumns = validateGridColumns(columns);
    
    AppLogger.d('Setting grid columns: requested = $columns, validated = $validColumns');
    AppLogger.d('Current palette size: ${getCurrentPaletteSize()}');
    
    if (getCurrentPaletteSize() == 3 && validColumns > 2) {
      AppLogger.d('Preventing column change for palette size 3');
      validColumns = 2;
    }

    if (defaultPaletteSize == 3) {
      await _prefs.setInt(gridColumnsPaletteSizeThreeKey, validColumns);
    } else {
      await _prefs.setInt(gridColumnsKey, validColumns);
    }
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
    return (paletteSize / 2).ceil().clamp(1, paletteSize);
  }

  bool isUsingTemporaryPalette() {
    bool isTemporary = _temporaryPaletteSize != null;
    AppLogger.d('Checking temporary palette status: $isTemporary');
    return isTemporary;
  }

  Future<void> regenerateGridColumnsForDefaultPaletteSize() async {
    int currentDefaultSize = defaultPaletteSize;
    int currentGridColumns = gridColumns;
    
    AppLogger.d('Regenerating grid columns for default palette size:');
    AppLogger.d('- Default Palette Size: $currentDefaultSize');
    AppLogger.d('- Current Grid Columns: $currentGridColumns');
    
    if (_temporaryPaletteSize == null) {
      final optimalColumns = calculateOptimalColumns(currentDefaultSize);
      
      AppLogger.d('- Optimal Columns: $optimalColumns');
      
      await setGridColumns(optimalColumns);
    } else {
      AppLogger.d('Skipping grid columns regeneration due to active temporary palette size');
    }
  }

  bool get isPremiumEnabled => _prefs.getBool(isPremiumEnabledKey) ?? false;

  Future<void> setIsPremiumEnabled(bool enabled) async {
    await _prefs.setBool(isPremiumEnabledKey, enabled);
    notifyListeners();
  }

  bool get isPremiumStarLogoEnabled => _prefs.getBool(isPremiumStarLogoEnabledKey) ?? false;

  Future<void> setIsPremiumStarLogoEnabled(bool enabled) async {
    await _prefs.setBool(isPremiumStarLogoEnabledKey, enabled);
    notifyListeners();
  }

  int get maxPremiumPaletteColors => _prefs.getInt(maxPremiumPaletteColorsKey) ?? AppConstants.maxPaletteColors;

  Future<void> setMaxPremiumPaletteColors(int maxColors) async {
    if (maxColors < AppConstants.minPaletteColors || maxColors > AppConstants.maxPaletteColors) {
      throw RangeError('Premium palette size must be between ${AppConstants.minPaletteColors} and ${AppConstants.maxPaletteColors}');
    }
    
    await _prefs.setInt(maxPremiumPaletteColorsKey, maxColors);
    notifyListeners();
  }

  Future<void> adjustGridColumnsForCurrentPaletteSize(int currentPaletteSize) async {
    if (currentPaletteSize < AppConstants.minPaletteColors || 
        currentPaletteSize > AppConstants.maxPaletteColors) {
      AppLogger.d('Invalid palette size: $currentPaletteSize');
      return;
    }

    _temporaryPaletteSize = currentPaletteSize;
    await adjustGridColumnsForPaletteSize();
    _temporaryPaletteSize = null;
  }
}
