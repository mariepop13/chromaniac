import 'package:flutter/material.dart';
import 'package:reorderable_grid/reorderable_grid.dart';
import 'package:chromaniac/features/color_palette/presentation/color_tile_widget.dart';

class HomeContent extends StatelessWidget {
  final List<Color> palette;
  final Function(Color) onRemoveColor;
  final Function(Color, Color) onEditColor;
  final Function(List<Color>) onAddHarmonyColors;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = 2;
        final rowCount = (palette.length / columnCount).ceil();
        final width = constraints.maxWidth / columnCount;
        final height = constraints.maxHeight / rowCount;
        final aspectRatio = width / height;

        return ReorderableGridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
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
  }
}
