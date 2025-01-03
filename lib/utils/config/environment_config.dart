import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';

class EnvironmentConfig {
  static Future<void> initialize() async {
    try {
      AppLogger.d('Attempting to load .env file...');
      const envFile = ".env";
      await dotenv.load(fileName: envFile);
      AppLogger.i('Successfully loaded .env file');
    } catch (e) {
      AppLogger.e('Critical error loading .env file: $e');
      // Optionally, you can rethrow the error to prevent app startup
      // rethrow;
    }
  }

  static String get openRouterApiKey {
    final key = dotenv.env['OPENROUTER_API_KEY'];
    if (key == null || key.isEmpty) {
      AppLogger.w('OPENROUTER_API_KEY not found in environment variables');
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
