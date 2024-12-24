import 'package:flutter/foundation.dart';

class PremiumService extends ChangeNotifier {
  bool _isPremium = false;

  bool get isPremium => _isPremium;


  Future<void> unlockPremium() async {
    _isPremium = true;
  }

  Future<void> restorePurchases() async {
    _isPremium = true;
  }


  void togglePremiumStatus() {
    _isPremium = !_isPremium;
  }
}
