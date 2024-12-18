import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorTile extends StatelessWidget {
  final Color color;
  final String hex;
  final Function(Color) onRemoveColor;

  const ColorTile({
    super.key,
    required this.color,
    required this.hex,
    required this.onRemoveColor,
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
                        child: Text('Copy Hex'),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: hex));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied $hex to clipboard!')),
                          );
                        },
                      ),
                      PopupMenuItem(
                        child: Text('Remove Color'),
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
}
