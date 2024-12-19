import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'services/premium_service.dart';
import 'screens/home_screen.dart';
import 'utils/config/environment_config.dart';
import 'providers/debug_provider.dart';
import 'utils/logger/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();
  await EnvironmentConfig.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PremiumService()),
        ChangeNotifierProvider(create: (_) => DebugProvider()),
      ],
      child: const ChromaniacApp(),
    ),
  );
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
