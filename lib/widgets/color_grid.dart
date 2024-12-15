import 'package:flutter/material.dart';

class ColorGrid extends StatelessWidget {
  final Color currentColor;
  final Function(Color) onColorSelected;

  const ColorGrid({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          OrientationBuilder(
            builder: (context, orientation) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: const _Title(),
                    ),
                    _ColorGridView(
                      currentColor: currentColor,
                      onColorSelected: onColorSelected,
                      orientation: orientation,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Select a Color',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}

class _ColorGridView extends StatelessWidget {
  final Color currentColor;
  final Function(Color) onColorSelected;
  final Orientation orientation;

  const _ColorGridView({
    required this.currentColor,
    required this.onColorSelected,
    required this.orientation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = orientation == Orientation.portrait ? 6 : 10;
        final itemCount = Colors.primaries.length;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              final color = Colors.primaries[index];
              return GestureDetector(
                onTap: () => onColorSelected(color),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: currentColor == color ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
