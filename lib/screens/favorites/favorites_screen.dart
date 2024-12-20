import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chromaniac/models/color_palette.dart';
import 'package:chromaniac/services/database_service.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:chromaniac/screens/favorites/palette_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:chromaniac/providers/debug_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<ColorPalette>> _palettesFuture;

  @override
  void initState() {
    super.initState();
    _loadPalettes();
  }

  void _loadPalettes() {
    _palettesFuture = DatabaseService().getPalettes();
  }

  void _removePalette(ColorPalette palette) async {
    try {
      await DatabaseService().deletePalette(palette.id);
      setState(() {
        _loadPalettes();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Palette removed from favorites')),
      );
    } catch (e) {
      AppLogger.e('Error removing palette', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error removing palette')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Palettes'),
        actions: [
          if (kDebugMode && context.watch<DebugProvider>().isDebugEnabled)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                try {
                  AppLogger.d('Resetting database');
                  await DatabaseService().resetDatabase();
                  if (mounted) {
                    setState(() {
                      _loadPalettes();
                    });
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Database reset successfully')),
                    );
                  }
                } catch (e) {
                  AppLogger.e('Error resetting database', error: e);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error resetting database')),
                    );
                  }
                }
              },
              tooltip: 'Reset Database (Debug)',
            ),
        ],
      ),
      body: FutureBuilder<List<ColorPalette>>(
        future: _palettesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final palettes = snapshot.data ?? [];
          if (palettes.isEmpty) {
            return const Center(
              child: Text('No saved palettes yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: palettes.length,
            itemBuilder: (context, index) {
              final palette = palettes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaletteDetailsScreen(palette: palette),
                      ),
                    );
                    
                    if (updated == true && mounted) {
                      setState(() {
                        _loadPalettes();
                      });
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    palette.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created ${_formatDate(palette.createdAt)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removePalette(palette),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 60,
                        child: Row(
                          children: palette.colors.map((color) {
                            return Expanded(
                              child: Container(
                                color: color,
                                height: double.infinity,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
