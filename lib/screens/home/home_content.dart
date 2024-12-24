import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import '../../features/color_palette/domain/color_palette_type.dart';
import '../../features/color_palette/presentation/color_tile_widget.dart';
import '../../providers/settings_provider.dart';
import '../../utils/logger/app_logger.dart';

class HomeContent extends StatelessWidget {
  final List<Color> palette;
  final Function(Color) onRemoveColor;
  final Function(Color, Color) onEditColor;
  final Function(List<Color>, ColorPaletteType) onAddHarmonyColors;
  final Function(int, int) onReorder;

  const HomeContent({
    super.key,
    required this.palette,
    required this.onRemoveColor,
    required this.onEditColor,
    required this.onAddHarmonyColors,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    if (palette.isEmpty) {
      return const Center(
        child: Text('Generate a palette or add colors'),
      );
    }

    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final columnCount = settingsProvider.gridColumns;
        final rowCount = (palette.length / columnCount).ceil();

        AppLogger.d('HomeContent Grid Layout:');
        AppLogger.d('- Palette Size: ${palette.length}');
        AppLogger.d('- Column Count: $columnCount');
        AppLogger.d('- Row Count: $rowCount');

        return LayoutBuilder(
          builder: (context, constraints) {

            final gridWidth = constraints.maxWidth;
            final gridHeight = constraints.maxHeight;
            

            final cellWidth = gridWidth / columnCount;
            final cellHeight = gridHeight / rowCount;
            final aspectRatio = cellWidth / cellHeight;

            AppLogger.d('Grid Layout Constraints:');
            AppLogger.d('- Max Width: ${constraints.maxWidth}');
            AppLogger.d('- Max Height: ${constraints.maxHeight}');
            AppLogger.d('- Cell Width: $cellWidth');
            AppLogger.d('- Cell Height: $cellHeight');
            AppLogger.d('- Calculated Aspect Ratio: $aspectRatio');

            return ReorderableGridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
              ),
              itemCount: palette.length,
              itemBuilder: (context, index) {
                final color = palette[index];
                return ColorTileWidget(
                  key: ValueKey('${((color.a * 255).round() << 24) | ((color.r * 255).round() << 16) | ((color.g * 255).round() << 8) | (color.b * 255).round()}_$index'),
                  color: color,
                  hex: ((((color.r * 255).round() << 16) | ((color.g * 255).round() << 8) | (color.b * 255).round())).toRadixString(16).padLeft(6, '0'),
                  onRemoveColor: onRemoveColor,
                  onEditColor: (newColor) => onEditColor(color, newColor),
                  paletteSize: palette.length,
                  onAddHarmonyColors: onAddHarmonyColors,
                );
              },
              onReorder: onReorder,
            );
          },
        );
      },
    );
  }
}
