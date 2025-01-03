import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Configure web-specific input handling
    WebConfig.configureWebInputHandling();
    
    await AppLogger.init();
    await EnvironmentConfig.initialize();
    await SupabaseConfig.initialize();
    
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService();
    
    runApp(
      MultiProvider(
        providers: [
          Provider<AuthService>.value(value: authService),
          ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
          ChangeNotifierProvider(create: (_) => PremiumService()),
          ChangeNotifierProvider(create: (context) => SettingsProvider(prefs)),
          ChangeNotifierProvider(
            create: (context) => DebugProvider(
              Provider.of<SettingsProvider>(context, listen: false),
              Provider.of<PremiumService>(context, listen: false)
            ),
          ),
        ],
        child: const ChromaniacApp(),
      ),
    );
  } catch (e) {
    AppLogger.e('Error during initialization: $e');
  }
}

class ChromaniacApp extends StatelessWidget {
  const ChromaniacApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Chromaniac',
      theme: themeProvider.themeData,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
