import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class EnvironmentConfig {
  static final Logger _logger = Logger();

  static Future<void> initialize() async {
    try {
      _logger.d('Attempting to load .env file...');
      const envFile = ".env";
      await dotenv.load(fileName: envFile);
      _logger.i('Successfully loaded .env file');
    } catch (e) {
      _logger.w('Error loading .env file: $e');
      // Continue execution even if .env file is missing
      // This allows the app to run in development without a .env file
    }
  }

  static String get openRouterApiKey {
    final key = dotenv.env['OPENROUTER_API_KEY'];
    if (key == null || key.isEmpty) {
      _logger.w('OPENROUTER_API_KEY not found in environment variables');
      return '';
    }
    return key;
  }
}
