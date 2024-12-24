import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants.dart';
import '../../../utils/dialog/dialog_utils.dart';
import '../domain/color_palette_type.dart';
import 'color_picker_dialog.dart';
import 'harmony_picker_dialog.dart';

class ColorTileWidget extends StatelessWidget {
  final Color color;
  final String hex;
  final Function(Color) onRemoveColor;
  final Function(Color) onEditColor;
  final Function(List<Color>, ColorPaletteType)? onAddHarmonyColors;
  final int paletteSize;
  final Function(Color)? onFavoriteColor;
  final bool isFavorite;

  const ColorTileWidget({
    super.key,
    required this.color,
    required this.hex,
    required this.onRemoveColor,
    required this.onEditColor,
    this.onAddHarmonyColors,
    required this.paletteSize,
    this.onFavoriteColor,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = color.computeLuminance() < 0.5;
    return Material(
      color: color,
      child: InkWell(
        child: Stack(
          children: [
            Center(
              child: Text(
                hex.toUpperCase(),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Row(
                children: [
                  if (onFavoriteColor != null)
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => onFavoriteColor?.call(color),
                      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      final RenderBox renderBox = context.findRenderObject() as RenderBox;
                      final Offset localPosition = renderBox.localToGlobal(Offset.zero);
                      final Size tileSize = renderBox.size;
                      
                      showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(
                          localPosition.dx,
                          localPosition.dy,
                          localPosition.dx + tileSize.width,
                          localPosition.dy + tileSize.height,
                        ),
                        items: [
                          PopupMenuItem(
                            child: const Text('Edit Color'),
                            onTap: () => showDelayedDialog(context, 
                              (ctx) => _showColorPickerDialog(ctx, color)),
                          ),
                          if (onAddHarmonyColors != null)
                            PopupMenuItem(
                              child: const Text('Apply Harmony'),
                              onTap: () => showDelayedDialog(context,
                                (ctx) => _showHarmonyPickerDialog(ctx)),
                            ),
                          PopupMenuItem(
                            child: const Text('Copy Hex'),
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: hex));
                              showCopySnackBar(context, hex);
                            },
                          ),
                          if (paletteSize > AppConstants.minPaletteColors)
                            PopupMenuItem(
                              child: const Text('Remove'),
                              onTap: () => onRemoveColor(color),
                            ),
                        ],
                      );
                    },
                    tooltip: 'More options',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context, Color initialColor) {
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: initialColor,
        onColorSelected: onEditColor,
        currentPaletteSize: paletteSize,
        isEditing: true,
      ),
    );
  }

  void _showHarmonyPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => HarmonyPickerDialog(
        baseColor: color,
        onHarmonySelected: onAddHarmonyColors!,
        showAutoOption: false,
        currentPaletteSize: paletteSize,
      ),
    );
  }
}
