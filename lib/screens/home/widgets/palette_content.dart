import 'package:chromaniac/screens/home/providers/home_screen_provider.dart';
import 'package:flutter/material.dart';
import 'package:chromaniac/features/color_palette/presentation/color_tile_widget.dart';
import 'package:provider/provider.dart';

class PaletteContent extends StatelessWidget {
  const PaletteContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeScreenProvider>(
      builder: (context, provider, _) {
        if (provider.state.palette.isEmpty) {
          return const Center(
            child: Text('Generate a palette or add colors'),
          );
        }

        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          onReorder: provider.reorderPalette,
          itemCount: provider.state.palette.length,
          itemBuilder: (context, index) {
            final color = provider.state.palette[index];
            final colorInt = ((color.a * 255).round() << 24) |
                           ((color.r * 255).round() << 16) |
                           ((color.g * 255).round() << 8) |
                           (color.b * 255).round();
            
            return FutureBuilder<bool>(
              key: ValueKey('color_$colorInt'),
              future: provider.isFavoriteColor(color),
              builder: (context, snapshot) {

                final hexString = ((((color.r * 255).round() << 16) |
                                  ((color.g * 255).round() << 8) |
                                  (color.b * 255).round()))
                                  .toRadixString(16)
                                  .padLeft(6, '0');
                
                return ColorTileWidget(
                  color: color,
                  hex: hexString,
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
