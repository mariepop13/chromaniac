import 'package:flutter/material.dart';
import 'package:chromaniac/services/auth_service.dart';
import 'package:chromaniac/screens/theme_spinner_dialog.dart';

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
    final isAuthenticated = AuthService().currentUser != null;

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
        BottomNavigationBarItem(
          icon: const Icon(Icons.shuffle),
          label: 'Random',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.palette_outlined),
          activeIcon: const Icon(Icons.palette),
          label: 'Theme',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            alignment: Alignment.topRight,
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.favorite_border),
              if (!isAuthenticated)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Icon(
                    Icons.star,
                    color: Colors.amber.shade700,
                    size: 24,
                  ),
                ),
            ],
          ),
          label: 'Favorites',
        ),
      ],
    );
  }
}
