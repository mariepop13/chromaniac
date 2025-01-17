import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:chromaniac/models/color_palette.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:chromaniac/features/color_palette/presentation/color_tile_widget.dart';
import 'package:chromaniac/services/database_service.dart';
import 'package:chromaniac/utils/color/export_palette.dart';

class PaletteDetailsScreen extends StatefulWidget {
  final ColorPalette palette;
  final Function(List<Color>)? onRestorePalette;

  const PaletteDetailsScreen({
    super.key,
    required this.palette,
    this.onRestorePalette,
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
    final colorInt = (color.alpha << 24) |
                    (color.red << 16) |
                    (color.green << 8) |
                    color.blue;
    return 'color_${colorInt}_$index';
  }

  String _getHexString(Color color) {
    final rgbInt = (color.red << 16) |
                  (color.green << 8) |
                  color.blue;
    return rgbInt.toRadixString(16).padLeft(6, '0');
  }

  void _restorePaletteToHome() {
    if (widget.onRestorePalette != null) {
      widget.onRestorePalette!(_colors);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored palette: ${_nameController.text}')),
      );
      
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoration not supported')),
      );
    }
  }

  Future<void> _sharePalette() async {
    if (kIsWeb || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing not supported on this platform')),
      );
      return;
    }

    try {
      final box = context.findRenderObject() as RenderBox?;
      await exportPalette(context, _colors, originBox: box);
    } catch (e) {
      AppLogger.e('Error sharing palette', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing palette: $e')),
      );
    }
  }

  void _showPaletteActionsMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: SingleChildScrollView(
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Palette Actions',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.save_outlined),
                        title: const Text('Save Palette'),
                        subtitle: const Text('Update the current palette details'),
                        onTap: () {
                          Navigator.pop(context);
                          _savePalette();
                        },
                      ),
                    ),
                    if (widget.onRestorePalette != null)
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.palette_outlined),
                          title: const Text('Apply to Home'),
                          subtitle: const Text('Use this palette in the main color grid'),
                          onTap: () {
                            Navigator.pop(context);
                            _restorePaletteToHome();
                          },
                        ),
                      ),
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.share_outlined),
                        title: const Text('Share Palette'),
                        subtitle: const Text('Export palette to other apps'),
                        onTap: () {
                          Navigator.pop(context);
                          _sharePalette();
                        },
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: const Text('Delete Palette'),
                        subtitle: const Text('Permanently remove this palette'),
                        onTap: () {
                          Navigator.pop(context);
                          _deletePalette();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deletePalette() async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Palette'),
        content: const Text('Are you sure you want to delete this palette?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await DatabaseService().deletePalette(widget.palette.id);
        
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Palette deleted')),
        );
      } catch (e) {
        AppLogger.e('Error deleting palette', error: e);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting palette')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Palette Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Palette Actions',
            onPressed: _showPaletteActionsMenu,
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return orientation == Orientation.portrait
            ? _buildPortraitLayout()
            : _buildLandscapeLayout();
        },
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildDetailsContent(),
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return SingleChildScrollView(
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
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
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
    );
  }

  List<Widget> _buildDetailsContent() {
    return [
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
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
