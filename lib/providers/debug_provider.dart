import 'package:flutter/foundation.dart';

class DebugProvider extends ChangeNotifier {
  bool _isDebugEnabled = false;

  bool get isDebugEnabled => _isDebugEnabled;

  void toggleDebug() {
    _isDebugEnabled = !_isDebugEnabled;
    notifyListeners();
  }
}
