import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import '../../features/color_palette/domain/color_palette_type.dart';
import '../../features/color_palette/presentation/color_tile_widget.dart';
import '../../providers/settings_provider.dart';

class PaletteGridView extends StatefulWidget {
  final List<Color> palette;
  final Function(Color) onRemoveColor;
  final Function(Color, Color) onEditColor;
  final Function(List<Color>, ColorPaletteType) onAddHarmonyColors;
  final Function(int, int) onReorder;

  const PaletteGridView({
    super.key,
    required this.palette,
    required this.onRemoveColor,
    required this.onEditColor,
    required this.onAddHarmonyColors,
    required this.onReorder,
  });

  @override
  PaletteGridViewState createState() => PaletteGridViewState();
}

class PaletteGridViewState extends State<PaletteGridView> {
  @override
  Widget build(BuildContext context) {
    if (widget.palette.isEmpty) {
      return const Center(
        child: Text('Generate a palette or add colors'),
      );
    }

    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          settingsProvider.adjustGridColumnsForCurrentPaletteSize(widget.palette.length);
        });

        final columnCount = settingsProvider.gridColumns;
        final rowCount = (widget.palette.length / columnCount).ceil();

        return LayoutBuilder(
          builder: (context, constraints) {
            final gridWidth = constraints.maxWidth;
            final gridHeight = constraints.maxHeight;
            
            final cellWidth = gridWidth / columnCount;
            final cellHeight = gridHeight / rowCount;
            final aspectRatio = cellWidth / cellHeight;

            return ReorderableGridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
              ),
              itemCount: widget.palette.length,
              itemBuilder: (context, index) {
                final color = widget.palette[index];
                return ColorTileWidget(
                  key: ValueKey('${color.value}_$index'),
                  color: color,
                  hex: color.value.toRadixString(16).padLeft(6, '0'),
                  onRemoveColor: widget.onRemoveColor,
                  onEditColor: (newColor) => widget.onEditColor(color, newColor),
                  paletteSize: widget.palette.length,
                  onAddHarmonyColors: widget.onAddHarmonyColors,
                );
              },
              onReorder: widget.onReorder,
            );
          },
        );
      },
    );
  }
}
