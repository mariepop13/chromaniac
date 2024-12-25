import 'package:flutter/foundation.dart';

class PremiumService extends ChangeNotifier {
  bool _isPremium = true;

  bool get isPremium => _isPremium;


  Future<void> unlockPremium() async {
    _isPremium = true;
    notifyListeners();
  }

  Future<void> restorePurchases() async {
    _isPremium = true;
    notifyListeners();
  }


  void togglePremiumStatus() {
    _isPremium = !_isPremium;
    notifyListeners();
  }

  int getMaxPaletteSize() {
    return _isPremium ? 10 : 5;
  }
}
