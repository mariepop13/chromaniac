import 'package:flutter/material.dart';

Color getContrastColor(Color backgroundColor) {
  return backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
}

class ContrastColorScheme {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color inactiveForegroundColor;

  ContrastColorScheme({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.inactiveForegroundColor,
  });

  factory ContrastColorScheme.fromBackground(Color backgroundColor) {
    final foregroundColor = getContrastColor(backgroundColor);
    return ContrastColorScheme(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      inactiveForegroundColor: foregroundColor.withAlpha(153),
    );
  }

  factory ContrastColorScheme.fromTheme(ThemeData theme) {
    final backgroundColor = theme.colorScheme.primary;
    return ContrastColorScheme.fromBackground(backgroundColor);
  }

  factory ContrastColorScheme.fromBottomNavTheme(ThemeData theme) {
    final backgroundColor = theme.bottomNavigationBarTheme.backgroundColor ??
        theme.colorScheme.surface;
    return ContrastColorScheme.fromBackground(backgroundColor);
  }
}
