import 'package:flutter/material.dart';
import 'package:chromaniac/models/favorite_color.dart';
import 'package:chromaniac/services/database_service.dart';
import 'package:chromaniac/features/color_palette/presentation/color_tile_widget.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<FavoriteColor>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    _favoritesFuture = DatabaseService().getFavoriteColors();
  }

  void _removeFavorite(FavoriteColor favorite) async {
    await DatabaseService().removeFavoriteColor(favorite.id);
    setState(() {
      _loadFavorites();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Color removed from favorites')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Colors'),
      ),
      body: FutureBuilder<List<FavoriteColor>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const Center(
              child: Text('No favorite colors yet'),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              return ColorTileWidget(
                color: favorite.color,
                hex: favorite.color.value.toRadixString(16).padLeft(8, '0').substring(2),
                onRemoveColor: (_) => _removeFavorite(favorite),
                onEditColor: (_) {},
                paletteSize: 1,
                isFavorite: true,
                onFavoriteColor: (_) => _removeFavorite(favorite),
              );
            },
          );
        },
      ),
    );
  }
}
