import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class SettingsProvider extends ChangeNotifier {
  static const String defaultPaletteSizeKey = 'defaultPaletteSize';

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
}
