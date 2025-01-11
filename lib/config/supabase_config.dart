import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../utils/logger/app_logger.dart';

class SupabaseConfig {
  static String get url {
    // Use dotenv for runtime environment loading
    final envUrl = dotenv.env['SUPABASE_URL'];
    if (envUrl == null || envUrl.isEmpty) {
      AppLogger.e('SUPABASE_URL not found in environment');
      throw Exception('Supabase URL is not configured');
    }
    return envUrl;
  }

  static String get anonKey {
    // Use dotenv for runtime environment loading
    final envKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (envKey == null || envKey.isEmpty) {
      AppLogger.e('SUPABASE_ANON_KEY not found in environment');
      throw Exception('Supabase Anon Key is not configured');
    }
    return envKey;
  }

  // Redirect URL for OAuth providers
  static const String redirectUrl = 'io.supabase.chromaniac://login-callback';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      // Load environment variables before initialization
      await dotenv.load(fileName: '.env');

      WidgetsFlutterBinding.ensureInitialized();

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        debug: kDebugMode, // Enable debug logging in debug mode
      );

      AppLogger.d('Supabase initialized successfully');

      // Handle deep links for mobile platforms
      if (!kIsWeb) {
        await _setupDeepLinkHandling();
      }
    } catch (e) {
      AppLogger.e('Error initializing Supabase: $e');
      rethrow;
    }
  }

  static Future<void> _setupDeepLinkHandling() async {
    try {
      final appLinks = AppLinks();
      // Handle incoming links
      appLinks.uriLinkStream.listen((uri) {
        // Handle deep link
        AppLogger.d('Received deep link: $uri');
      }, onError: (err) {
        AppLogger.e('Deep link error: $err');
      });
    } catch (e) {
      AppLogger.e('Error setting up deep link handling: $e');
    }
  }
}
