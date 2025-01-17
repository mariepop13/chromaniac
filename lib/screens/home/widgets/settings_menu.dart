import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chromaniac/providers/theme_provider.dart';
import 'package:chromaniac/services/premium_service.dart';

class SettingsMenu extends StatelessWidget {
  final Function() onSettingsTap;
  final Function() onThemeTap;

  const SettingsMenu({
    super.key,
    required this.onSettingsTap,
    required this.onThemeTap,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Consumer<PremiumService>(
        builder: (context, premiumService, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.more_vert),
            if (premiumService.isPremium)
              const Icon(Icons.star, color: Colors.amber, size: 16),
          ],
        ),
      ),
      onSelected: (value) async {
        switch (value) {
          case 'settings':
            onSettingsTap();
            break;
          case 'theme':
            onThemeTap();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'theme',
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => Row(
              children: [
                Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                const SizedBox(width: 8),
                Text(themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
