import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

import '../utils/logger/app_logger.dart';

class SupabaseConfig {
  static String get url {
    return const String.fromEnvironment('SUPABASE_URL');
  }

  static String get anonKey {
    return const String.fromEnvironment('SUPABASE_ANON_KEY');
  }

  // Redirect URL for OAuth providers
  static const String redirectUrl = 'io.supabase.chromaniac://login-callback';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        debug: kDebugMode, // Enable debug logging in debug mode
      );

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
