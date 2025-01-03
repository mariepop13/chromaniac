import 'package:flutter/foundation.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';

class EnvironmentConfig {
  static Future<void> initialize() async {
    try {
      AppLogger.d('Initializing environment configuration');
      // No need to load .env file
      AppLogger.i('Environment configuration initialized');
    } catch (e) {
      AppLogger.e('Error during environment configuration: $e');
    }
  }

  static String get openRouterApiKey {
    // Use environment variable for web, fallback for other platforms
    const key = String.fromEnvironment('OPENROUTER_API_KEY', 
      defaultValue: 'default_key_if_not_set');
    
    if (key.isEmpty) {
      AppLogger.w('OPENROUTER_API_KEY not found');
      return '';
    }
    return key;
  }

  static String get emojiSetting {
    return const String.fromEnvironment('OCO_EMOJI', defaultValue: 'true');
  }

  static String get languageSetting {
    return const String.fromEnvironment('OCO_LANGUAGE', defaultValue: 'en');
  }

  static String get modelSetting {
    return const String.fromEnvironment('OCO_MODEL', defaultValue: 'gpt-4o-mini');
  }
}
