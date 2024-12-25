import 'package:flutter/foundation.dart';
import 'package:chromaniac/providers/settings_provider.dart';
import 'package:chromaniac/services/premium_service.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';

class DebugProvider extends ChangeNotifier {
  final SettingsProvider _settingsProvider;
  final PremiumService _premiumService;
  bool _isDebugEnabled = false;

  DebugProvider(this._settingsProvider, this._premiumService);

  bool get isDebugEnabled => _isDebugEnabled;

  void toggleDebug() {
    _isDebugEnabled = !_isDebugEnabled;
    
    if (_isDebugEnabled) {
      _settingsProvider.setIsPremiumStarLogoEnabled(true);
    } else {
      if (_settingsProvider.isPremiumStarLogoEnabled) {
        _settingsProvider.setIsPremiumStarLogoEnabled(false);
      }
    }
    
    notifyListeners();
  }

  void togglePremiumStatus() {
    AppLogger.d('Debug Mode: $_isDebugEnabled');
    AppLogger.d('Current Premium Status: ${_premiumService.isPremium}');

    if (_isDebugEnabled) {
      _premiumService.togglePremiumStatus();
      AppLogger.d('Toggled Premium Status: ${_premiumService.isPremium}');
    } else {
      _premiumService.unlockPremium();
      AppLogger.d('Unlocked Premium');
    }
    
    notifyListeners();
  }
}
