import 'package:flutter/material.dart';
import '../screens/theme_spinner_dialog.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final BuildContext context;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.context,
  });

  void _showThemeSpinner() {
    showDialog(
      context: context,
      builder: (context) => const ThemeWheel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 2) {
          _showThemeSpinner();
        } else {
          onTap(index);
        }
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.shuffle),
          label: 'Random',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.palette_outlined),
          activeIcon: const Icon(Icons.palette),
          label: 'Theme',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          label: 'Favorites',
        ),
      ],
    );
  }
}
