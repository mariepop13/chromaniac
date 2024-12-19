import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chromaniac/providers/debug_provider.dart';
import 'package:chromaniac/providers/theme_provider.dart';

class PaletteMenu extends StatelessWidget {
  final VoidCallback onGenerate;
  final VoidCallback onAdd;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onClear;

  const PaletteMenu({
    super.key,
    required this.onGenerate,
    required this.onAdd,
    required this.onImport,
    required this.onExport,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu),
      onSelected: (value) async {
        switch (value) {
          case 'generate':
            onGenerate();
            break;
          case 'add':
            onAdd();
            break;
          case 'import':
            onImport();
            break;
          case 'export':
            onExport();
            break;
          case 'clear':
            onClear();
            break;
          case 'theme':
            Provider.of<ThemeProvider>(context, listen: false)
                .toggleTheme(!Provider.of<ThemeProvider>(context, listen: false).isDarkMode);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'generate',
          child: Row(
            children: [
              Icon(Icons.shuffle),
              SizedBox(width: 8),
              Text('Generate Palette'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'add',
          child: Row(
            children: [
              Icon(Icons.add),
              SizedBox(width: 8),
              Text('Add Color'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'import',
          child: Row(
            children: [
              Icon(Icons.image),
              SizedBox(width: 8),
              Text('Import from Image'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.file_download),
              SizedBox(width: 8),
              Text('Export Palette'),
            ],
          ),
        ),
        if (Provider.of<DebugProvider>(context, listen: false).isDebugEnabled)
          const PopupMenuItem(
            value: 'clear',
            child: Row(
              children: [
                Icon(Icons.clear),
                SizedBox(width: 8),
                Text('Clear Palette'),
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
                Text(themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
