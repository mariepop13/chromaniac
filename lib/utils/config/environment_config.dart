import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static Future<void> initialize() async {
    try {
      AppLogger.d('Initializing environment configuration');
      // Load .env file
      await dotenv.load(fileName: '.env');
      AppLogger.i('Environment configuration initialized');
    } catch (e) {
      AppLogger.e('Error during environment configuration: $e');
    }
  }

  static String get openRouterApiKey {
    final key = dotenv.env['OPENROUTER_API_KEY'] ?? '';

    if (key.isEmpty) {
      AppLogger.w('OPENROUTER_API_KEY not found');
      return '';
    }
    return key;
  }

  static String get emojiSetting {
    return dotenv.env['OCO_EMOJI'] ?? 'true';
  }

  static String get languageSetting {
    return dotenv.env['OCO_LANGUAGE'] ?? 'en';
  }

  static String get modelSetting {
    return dotenv.env['OCO_MODEL'] ?? 'gpt-4o-mini';
  }
}
