import 'package:flutter/material.dart';
import 'package:chromaniac/models/color_palette.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:chromaniac/features/color_palette/presentation/color_tile_widget.dart';
import 'package:chromaniac/services/database_service.dart';

class PaletteDetailsScreen extends StatefulWidget {
  final ColorPalette palette;

  const PaletteDetailsScreen({
    super.key,
    required this.palette,
  });

  @override
  State<PaletteDetailsScreen> createState() => _PaletteDetailsScreenState();
}

class _PaletteDetailsScreenState extends State<PaletteDetailsScreen> {
  late TextEditingController _nameController;
  late List<Color> _colors;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.palette.name);
    _colors = List.from(widget.palette.colors);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _savePalette() async {
    try {
      final updatedPalette = ColorPalette(
        id: widget.palette.id,
        name: _nameController.text,
        colors: _colors,
        createdAt: widget.palette.createdAt,
        updatedAt: DateTime.now(),
        isSync: false,
      );

      await DatabaseService().savePalette(updatedPalette);
      
      if (!mounted) return;
      Navigator.pop(context, true);
      
    } catch (e) {
      AppLogger.e('Error saving palette', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving palette')),
      );
    }
  }

  void _removeColor(int index) {
    setState(() {
      _colors.removeAt(index);
    });
  }

  void _editColor(int index, Color newColor) {
    setState(() {
      _colors[index] = newColor;
    });
  }

  String _getColorKey(Color color, int index) {
    final colorInt = ((color.a * 255).round() << 24) |
                    ((color.r * 255).round() << 16) |
                    ((color.g * 255).round() << 8) |
                    (color.b * 255).round();
    return 'color_${colorInt}_$index';
  }

  String _getHexString(Color color) {
    final rgbInt = ((color.r * 255).round() << 16) |
                  ((color.g * 255).round() << 8) |
                  (color.b * 255).round();
    return rgbInt.toRadixString(16).padLeft(6, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Palette Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePalette,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Palette Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Colors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
              ),
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final color = _colors[index];
                return ColorTileWidget(
                  key: ValueKey(_getColorKey(color, index)),
                  color: color,
                  hex: _getHexString(color),
                  onRemoveColor: (_) => _removeColor(index),
                  onEditColor: (newColor) => _editColor(index, newColor),
                  paletteSize: _colors.length,
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Created: ${_formatDate(widget.palette.createdAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: ${_formatDate(widget.palette.updatedAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
