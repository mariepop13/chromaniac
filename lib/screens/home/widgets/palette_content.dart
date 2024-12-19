import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:chromaniac/core/constants.dart';
import 'package:chromaniac/features/color_palette/presentation/color_tile_widget.dart';

class PaletteContent extends StatelessWidget {
  final List<Color> palette;
  final Function(Color) onRemoveColor;
  final Function(Color, Color) onEditColor;
  final Function(int, int) onReorder;

  const PaletteContent({
    super.key,
    required this.palette,
    required this.onRemoveColor,
    required this.onEditColor,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    if (palette.isEmpty) {
      return const Center(
        child: Text('Generate a palette or add colors'),
      );
    }

    return Column(
      children: [
        if (palette.isNotEmpty)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth / 2;
                final height = constraints.maxHeight / (((palette.length + 1) ~/ 2));
                return ReorderableGridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: AppConstants.gridColumnCount,
                  crossAxisSpacing: AppConstants.gridSpacing,
                  mainAxisSpacing: AppConstants.gridSpacing,
                  childAspectRatio: width / height,
                  onReorder: onReorder,
                  children: palette
                      .asMap()
                      .map((index, color) {
                        final hex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                        return MapEntry(
                          index,
                          ColorTileWidget(
                            key: ValueKey('$hex-$index-${DateTime.now().millisecondsSinceEpoch}'),
                            color: color,
                            hex: hex,
                            onRemoveColor: onRemoveColor,
                            onEditColor: (newColor) => onEditColor(color, newColor),
                            paletteSize: palette.length,
                          ),
                        );
                      })
                      .values
                      .toList(),
                );
              },
            ),
          ),
      ],
    );
  }
}
