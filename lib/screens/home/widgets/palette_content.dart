import 'package:chromaniac/screens/home/providers/home_screen_provider.dart';
import 'package:flutter/material.dart';
import 'package:chromaniac/features/color_palette/presentation/color_tile_widget.dart';
import 'package:provider/provider.dart';

class PaletteContent extends StatelessWidget {
  const PaletteContent({super.key, required palette, required void Function(Color color) onRemoveColor, required Null Function(dynamic oldColor, dynamic newColor) onEditColor, required void Function(int oldIndex, int newIndex) onReorder});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeScreenProvider>(
      builder: (context, provider, _) {
        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          onReorder: provider.reorderPalette,
          itemCount: provider.state.palette.length,
          itemBuilder: (context, index) {
            final color = provider.state.palette[index];
            return FutureBuilder<bool>(
              key: ValueKey(color.value),
              future: provider.isFavoriteColor(color),
              builder: (context, snapshot) {
                return ColorTileWidget(
                  color: color,
                  hex: color.value.toRadixString(16).padLeft(8, '0').substring(2),
                  onRemoveColor: (_) => provider.removeColor(color),
                  onEditColor: (newColor) => provider.updateColor(index, newColor),
                  paletteSize: provider.state.palette.length,
                  isFavorite: snapshot.data ?? false,
                  onFavoriteColor: provider.toggleFavorite,
                );
              },
            );
          },
        );
      },
    );
  }
}
