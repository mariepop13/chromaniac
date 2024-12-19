import 'package:chromaniac/features/color_palette/presentation/color_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chromaniac/utils/dialog/dialog_utils.dart';

class ColorTileWidget extends StatelessWidget {
  final Color color;
  final String hex;
  final Function(Color) onRemoveColor;
  final Function(Color) onEditColor;

  const ColorTileWidget({
    super.key,
    required this.color,
    required this.hex,
    required this.onRemoveColor,
    required this.onEditColor,
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
                hex,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTapUp: (TapUpDetails details) {
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
                      PopupMenuItem(
                        child: const Text('Copy Hex'),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: hex));
                          showCopySnackBar(context, hex);
                        },
                      ),
                      PopupMenuItem(
                        child: const Text('Remove'),
                        onTap: () => onRemoveColor(color),
                      ),
                    ],
                  );
                },
                child: Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.white : Colors.black,
                  size: 30,
                ),
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
      ),
    );
  }
}
