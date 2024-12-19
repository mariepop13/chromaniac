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
    final debugEnabled = Provider.of<DebugProvider>(context, listen: false).isDebugEnabled;

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
        _buildMenuItem('generate', Icons.shuffle, 'Generate Palette'),
        _buildMenuItem('add', Icons.add, 'Add Color'),
        _buildMenuItem('import', Icons.image, 'Import from Image'),
        _buildMenuItem('export', Icons.file_download, 'Export Palette'),
        if (debugEnabled) _buildMenuItem('clear', Icons.clear, 'Clear Palette'),
        _buildThemeMenuItem(context),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildThemeMenuItem(BuildContext context) {
    return PopupMenuItem(
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
    );
  }
}
