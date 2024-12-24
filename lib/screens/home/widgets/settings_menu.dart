import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chromaniac/providers/theme_provider.dart';
import 'package:chromaniac/providers/settings_provider.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';

class SettingsMenu extends StatelessWidget {
  final Function() onSettingsTap;

  const SettingsMenu({
    super.key,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu),
      onSelected: (value) async {
        switch (value) {
          case 'theme':
            await Provider.of<ThemeProvider>(context, listen: false)
                .toggleTheme(!Provider.of<ThemeProvider>(context, listen: false).isDarkMode);
            break;
          case 'settings':
            onSettingsTap();
            break;
          case 'grid_layout':
            _showGridLayoutDialog(context);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'theme',
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => Row(
              children: [
                Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                const SizedBox(width: 8),
                Text(themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode'),
              ],
            ),
          ),
        ),
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
        const PopupMenuItem(
          value: 'grid_layout',
          child: Row(
            children: [
              Icon(Icons.grid_view),
              SizedBox(width: 8),
              Text('Grid Layout'),
            ],
          ),
        ),
      ],
    );
  }

  void _showGridLayoutDialog(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    final currentPaletteSize = settingsProvider.getCurrentPaletteSize();
    final defaultPaletteSize = settingsProvider.defaultPaletteSize;
    
    final paletteSize = currentPaletteSize == 3 ? defaultPaletteSize : currentPaletteSize;
    
    final optimalColumns = settingsProvider.calculateOptimalColumns(paletteSize);
    
    settingsProvider.clearTemporaryPaletteSize();
    
    settingsProvider.setGridColumns(optimalColumns);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Consumer<SettingsProvider>(
            builder: (context, settingsProvider, _) {
              int currentColumns = settingsProvider.gridColumns;
              int maxColumns = settingsProvider.calculateOptimalColumns(currentPaletteSize);

              // Ensure currentColumns is within the valid range
              currentColumns = currentColumns.clamp(1, maxColumns);

              AppLogger.d('Grid Layout Dialog - Current Palette Size: $currentPaletteSize');
              AppLogger.d('Grid Layout Dialog - Default Palette Size: $defaultPaletteSize');
              AppLogger.d('Grid Layout Dialog - Appropriate Palette Size: $paletteSize');
              AppLogger.d('Grid Layout Dialog - Max Columns: $maxColumns');
              AppLogger.d('Grid Layout Dialog - Current Columns: $currentColumns');
              AppLogger.d('Grid Layout Dialog - Optimal Columns: $optimalColumns');

              return AlertDialog(
                title: const Text('Grid Layout'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Number of Columns: $currentColumns'),
                    Slider(
                      value: currentColumns.toDouble(),
                      min: 1,
                      max: maxColumns.toDouble(),
                      divisions: maxColumns > 1 ? maxColumns - 1 : null,
                      label: currentColumns.toString(),
                      onChanged: (double value) {
                        int newColumns = value.round();
                        AppLogger.d('Dialog - Max columns: $maxColumns');
                        AppLogger.d('Dialog - Attempting to set columns: $newColumns');
                        
                        settingsProvider.setGridColumns(newColumns);
                        
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentPaletteSize == 3 
                        ? 'Adjust columns based on default palette size ($defaultPaletteSize colors)'
                        : 'Adjust columns based on current palette size ($currentPaletteSize colors)',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save'),
                  ),
                ],
              );
            }
          );
        },
      ),
    );
  }
}
