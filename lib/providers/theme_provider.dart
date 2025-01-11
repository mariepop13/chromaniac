import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class ThemeProvider with ChangeNotifier {
  static const String themeKey = 'isDarkMode';
  final SharedPreferences _prefs;
  late bool _isDarkMode;

  ThemeProvider(this._prefs) {
    _isDarkMode = _prefs.getBool(themeKey) ?? false;
  }

  bool get isDarkMode => _isDarkMode;

  ThemeData get themeData => _isDarkMode ? _darkTheme : _lightTheme;

  Future<void> toggleTheme(bool isDarkMode) async {
    _isDarkMode = isDarkMode;
    await _prefs.setBool(themeKey, isDarkMode);
    notifyListeners();
  }

  static final TextTheme _baseTextTheme = TextTheme(
    displayLarge: GoogleFonts.quicksand(
        fontSize: ThemeConstants.displayLargeSize, fontWeight: FontWeight.w600),
    displayMedium: GoogleFonts.quicksand(
        fontSize: ThemeConstants.displayMediumSize,
        fontWeight: FontWeight.w600),
    displaySmall: GoogleFonts.quicksand(
        fontSize: ThemeConstants.displaySmallSize, fontWeight: FontWeight.w600),
    headlineLarge: GoogleFonts.quicksand(
        fontSize: ThemeConstants.headlineLargeSize,
        fontWeight: FontWeight.w700),
    headlineMedium: GoogleFonts.quicksand(
        fontSize: ThemeConstants.headlineMediumSize,
        fontWeight: FontWeight.w700),
    headlineSmall: GoogleFonts.quicksand(
        fontSize: ThemeConstants.headlineSmallSize,
        fontWeight: FontWeight.w700),
    titleLarge: GoogleFonts.dmSans(
        fontSize: ThemeConstants.titleLargeSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15),
    titleMedium: GoogleFonts.dmSans(
        fontSize: ThemeConstants.titleMediumSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15),
    titleSmall: GoogleFonts.dmSans(
        fontSize: ThemeConstants.titleSmallSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1),
    bodyLarge: GoogleFonts.dmSans(
        fontSize: ThemeConstants.bodyLargeSize,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5),
    bodyMedium: GoogleFonts.dmSans(
        fontSize: ThemeConstants.bodyMediumSize,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25),
    bodySmall: GoogleFonts.dmSans(
        fontSize: ThemeConstants.bodySmallSize,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4),
    labelLarge: GoogleFonts.dmSans(
        fontSize: ThemeConstants.labelLargeSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25),
    labelMedium: GoogleFonts.dmSans(
        fontSize: ThemeConstants.labelMediumSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.0),
    labelSmall: GoogleFonts.dmSans(
        fontSize: ThemeConstants.labelSmallSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5),
  );

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: _baseTextTheme,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF6B4EE8),
      secondary: const Color(0xFF9C8AFF),
      tertiary: const Color(0xFFFF8FB1),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF2D2B3F),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: ThemeConstants.defaultElevation,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.defaultBorderRadius)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6B4EE8),
        foregroundColor: Colors.white,
        elevation: ThemeConstants.defaultElevation,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ThemeConstants.defaultBorderRadius)),
      ),
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: _baseTextTheme,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF9C8AFF),
      secondary: const Color(0xFF6B4EE8),
      tertiary: const Color(0xFFFF8FB1),
      surface: const Color(0xFF1E1B2E),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1E1B2E),
      elevation: ThemeConstants.defaultElevation,
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(ThemeConstants.defaultBorderRadius)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF9C8AFF),
        foregroundColor: Colors.white,
        elevation: ThemeConstants.defaultElevation,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ThemeConstants.defaultBorderRadius)),
      ),
    ),
  );
}
