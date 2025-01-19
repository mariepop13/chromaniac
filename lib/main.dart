import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'services/premium_service.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'utils/config/environment_config.dart';
import 'providers/debug_provider.dart';
import 'utils/logger/app_logger.dart';
import 'config/supabase_config.dart';
import 'utils/web_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  WebConfig.configureWebInputHandling();
  await AppLogger.init();
  await EnvironmentConfig.initialize();
  await SupabaseConfig.initialize();

  final prefs = await SharedPreferences.getInstance();
  final authService = AuthService();

  runApp(
    ProviderScope(
      child: legacy_provider.MultiProvider(
        providers: [
          legacy_provider.Provider<AuthService>.value(value: authService),
          legacy_provider.ChangeNotifierProvider(
              create: (_) => ThemeProvider(prefs)),
          legacy_provider.ChangeNotifierProvider(
              create: (_) => PremiumService()),
          legacy_provider.ChangeNotifierProvider(
              create: (context) => SettingsProvider(prefs)),
          legacy_provider.ChangeNotifierProvider(
            create: (context) => DebugProvider(
              legacy_provider.Provider.of<SettingsProvider>(context,
                  listen: false),
              legacy_provider.Provider.of<PremiumService>(context,
                  listen: false),
            ),
          ),
        ],
        child: const ChromaniacApp(),
      ),
    ),
  );
}

class ChromaniacApp extends ConsumerWidget {
  const ChromaniacApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = legacy_provider.Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Chromaniac',
      theme: themeProvider.themeData,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
