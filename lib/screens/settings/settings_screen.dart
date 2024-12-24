import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chromaniac/providers/settings_provider.dart';
import 'package:chromaniac/core/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSettingTile(
                title: 'Default Palette Size',
                subtitle: 'Maximum number of colors in a palette',
                child: StatefulBuilder(
                  builder: (context, setState) => Slider(
                    value: settingsProvider.defaultPaletteSize.toDouble(),
                    min: AppConstants.minPaletteColors.toDouble(),
                    max: AppConstants.maxPaletteColors.toDouble(),
                    divisions: AppConstants.maxPaletteColors - AppConstants.minPaletteColors,
                    label: settingsProvider.defaultPaletteSize.toString(),
                    onChanged: (value) {
                      settingsProvider.setDefaultPaletteSize(value.round());
                      setState(() {});
                    },
                  ),
                ),
                trailing: Text(
                  '${settingsProvider.defaultPaletteSize} colors',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

              _buildSettingTile(
                title: 'Grid Layout',
                subtitle: 'Number of columns in color grid',
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Slider(
                          value: settingsProvider.gridColumns.toDouble(),
                          min: 1,
                          max: settingsProvider.getMaxGridColumns().toDouble(),
                          divisions: settingsProvider.getMaxGridColumns() - 1,
                          label: settingsProvider.gridColumns.toString(),
                          onChanged: (value) {
                            int newColumns = value.round();
                            settingsProvider.setGridColumns(newColumns);
                            setState(() {});
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Adjust columns based on default palette size (${settingsProvider.getCurrentPaletteSize()} colors)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                trailing: Text(
                  '${settingsProvider.gridColumns} columns',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: null,
      ),
    );
  }
} 