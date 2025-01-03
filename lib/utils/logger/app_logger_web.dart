import 'package:flutter/foundation.dart';

Future<void> initializePlatformLogger() async {
  // No-op for web, as file system operations are not supported
  debugPrint('🌐 Initializing logger for web platform');
} 