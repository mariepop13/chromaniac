import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chromaniac/models/color_palette.dart';
import 'package:chromaniac/services/database_service.dart';
import 'package:chromaniac/services/auth_service.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:chromaniac/screens/favorites/palette_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:chromaniac/providers/debug_provider.dart';
import 'package:chromaniac/screens/auth/login_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final Function(List<Color>)? onRestorePalette;

  const FavoritesScreen({
    super.key,
    this.onRestorePalette,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<ColorPalette>> _palettesFuture;
  final _authService = AuthService();
  bool _hasShownAuthDialog = false;

  @override
  void initState() {
    super.initState();
    _palettesFuture = Future.value([]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAuthentication();
  }

  void _checkAuthentication() {
    // Check if user is authenticated and dialog hasn't been shown
    if (_authService.currentUser == null && !_hasShownAuthDialog) {
      // Prevent multiple dialog showings
      _hasShownAuthDialog = true;

      // Use a post-frame callback to show dialog after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAuthenticationDialog();
      });
    } else if (_authService.currentUser != null) {
      // Load palettes for authenticated user
      setState(() {
        _palettesFuture = DatabaseService().getPalettes();
      });
    }
  }

  void _showAuthenticationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text('Please log in to view your saved palettes.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).pop(); // Close favorites screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Navigate to login screen
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  void _removePalette(ColorPalette palette) async {
    try {
      await DatabaseService().deletePalette(palette.id);
      setState(() {
        _palettesFuture = DatabaseService().getPalettes();
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

  void _restorePaletteToHome(List<Color> colors) {
    if (widget.onRestorePalette != null) {
      widget.onRestorePalette!(colors);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Palette restored to home')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoration not supported')),
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
                      _palettesFuture = DatabaseService().getPalettes();
                    });
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Database reset successfully')),
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
                        builder: (context) => PaletteDetailsScreen(
                          palette: palette,
                          onRestorePalette: _restorePaletteToHome,
                        ),
                      ),
                    );

                    if (updated == true && mounted) {
                      setState(() {
                        _palettesFuture = DatabaseService().getPalettes();
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
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created ${_formatDate(palette.createdAt)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
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

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
