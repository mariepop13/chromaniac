import 'package:flutter/material.dart';

class HarmonyPreviewWidget extends StatelessWidget {
  final List<Color> colors;

  const HarmonyPreviewWidget({
    super.key,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: colors.map((color) {
          return Expanded(
            child: Container(
              color: color,
            ),
          );
        }).toList(),
      ),
    );
  }
}