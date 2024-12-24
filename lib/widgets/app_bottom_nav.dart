import 'package:flutter/material.dart';
import 'package:chromaniac/utils/color/contrast_color.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = ContrastColorScheme.fromBottomNavTheme(Theme.of(context));

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.backgroundColor,
      selectedItemColor: colorScheme.foregroundColor,
      unselectedItemColor: colorScheme.inactiveForegroundColor,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.palette),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shuffle),
          label: 'Generate',
        ),
      ],
    );
  }
}
