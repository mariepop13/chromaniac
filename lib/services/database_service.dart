import 'package:chromaniac/models/color_palette.dart';
import 'package:chromaniac/models/favorite_color.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  final _supabase = Supabase.instance.client;
  final _uuid = Uuid();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<List<ColorPalette>> getPalettes({String? userId}) async {
    try {
      AppLogger.d('Fetching palettes from Supabase');
      
      // If no user is provided, use the current authenticated user
      final currentUser = _supabase.auth.currentUser;
      userId ??= currentUser?.id;

      if (userId == null) {
        AppLogger.w('No user ID provided for palette retrieval');
        return [];
      }

      final response = await _supabase
          .from('palettes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final palettes = response
          .map((item) => ColorPalette.fromMap(item))
          .toList();

      AppLogger.d('Retrieved ${palettes.length} palettes');
      return palettes;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching palettes from Supabase', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Future<ColorPalette> savePalette(ColorPalette palette) async {
    try {
      AppLogger.d('Saving palette to Supabase: ${palette.name}');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to save a palette');
      }

      // Prepare palette data for Supabase
      final paletteData = palette.toMap();
      paletteData['user_id'] = currentUser.id;
      
      // If no ID exists, generate a new one
      if (paletteData['id'] == null) {
        paletteData['id'] = _uuid.v4();
      }

      // Upsert the palette
      final response = await _supabase
          .from('palettes')
          .upsert(paletteData)
          .select()
          .single();

      // Convert the response back to a ColorPalette
      final savedPalette = ColorPalette.fromMap(response);

      AppLogger.d('Successfully saved palette: ${savedPalette.name}');
      return savedPalette;
    } catch (e, stackTrace) {
      AppLogger.e('Error saving palette to Supabase', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Future<void> deletePalette(String paletteId) async {
    try {
      AppLogger.d('Deleting palette: $paletteId');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to delete a palette');
      }

      await _supabase
          .from('palettes')
          .delete()
          .eq('id', paletteId)
          .eq('user_id', currentUser.id);

      AppLogger.d('Successfully deleted palette: $paletteId');
    } catch (e, stackTrace) {
      AppLogger.e('Error deleting palette from Supabase', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Future<List<ColorPalette>> searchPalettes(String query) async {
    try {
      AppLogger.d('Searching palettes with query: $query');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to search palettes');
      }

      final response = await _supabase
          .from('palettes')
          .select()
          .eq('user_id', currentUser.id)
          .ilike('name', '%$query%')
          .order('created_at', ascending: false);

      final palettes = response
          .map((item) => ColorPalette.fromMap(item))
          .toList();

      AppLogger.d('Found ${palettes.length} palettes matching the query');
      return palettes;
    } catch (e, stackTrace) {
      AppLogger.e('Error searching palettes in Supabase', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Future<List<FavoriteColor>> getFavoriteColors() async {
    try {
      AppLogger.d('Fetching favorite colors from Supabase');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to get favorite colors');
      }

      final response = await _supabase
          .from('favorite_colors')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      final favoriteColors = response
          .map((item) => FavoriteColor.fromMap(item))
          .toList();

      AppLogger.d('Retrieved ${favoriteColors.length} favorite colors');
      return favoriteColors;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching favorite colors from Supabase', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Future<FavoriteColor> addFavoriteColor(Color color) async {
    try {
      AppLogger.d('Adding favorite color to Supabase');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to add a favorite color');
      }

      final favoriteColor = FavoriteColor(
        id: _uuid.v4(),
        color: color,
        userId: currentUser.id,
        createdAt: DateTime.now(),
        isSync: true
      );

      final response = await _supabase
          .from('favorite_colors')
          .upsert(favoriteColor.toMap())
          .select()
          .single();

      final savedFavoriteColor = FavoriteColor.fromMap(response);

      AppLogger.d('Successfully added favorite color');
      return savedFavoriteColor;
    } catch (e, stackTrace) {
      AppLogger.e('Error adding favorite color to Supabase', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Future<void> removeFavoriteColor(String favoriteColorId) async {
    try {
      AppLogger.d('Removing favorite color: $favoriteColorId');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to remove a favorite color');
      }

      await _supabase
          .from('favorite_colors')
          .delete()
          .eq('id', favoriteColorId)
          .eq('user_id', currentUser.id);

      AppLogger.d('Successfully removed favorite color');
    } catch (e, stackTrace) {
      AppLogger.e('Error removing favorite color from Supabase', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Future<List<ColorPalette>> getUnsyncedPalettes() async {
    try {
      AppLogger.d('Fetching unsynced palettes');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to get unsynced palettes');
      }

      final response = await _supabase
          .from('palettes')
          .select()
          .eq('user_id', currentUser.id)
          .eq('is_sync', false)
          .order('created_at', ascending: false);

      final palettes = response
          .map((item) => ColorPalette.fromMap(item))
          .toList();

      AppLogger.d('Retrieved ${palettes.length} unsynced palettes');
      return palettes;
    } catch (e, stackTrace) {
      AppLogger.e('Error fetching unsynced palettes', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Future<void> markAsSynced(String paletteId) async {
    try {
      AppLogger.d('Marking palette as synced: $paletteId');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to mark palette as synced');
      }

      await _supabase
          .from('palettes')
          .update({'is_sync': true})
          .eq('id', paletteId)
          .eq('user_id', currentUser.id);

      AppLogger.d('Successfully marked palette as synced');
    } catch (e, stackTrace) {
      AppLogger.e('Error marking palette as synced', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }

  Future<void> resetDatabase() async {
    try {
      AppLogger.d('Resetting database');
      
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to reset database');
      }

      // Delete all palettes for the current user
      await _supabase
          .from('palettes')
          .delete()
          .eq('user_id', currentUser.id);

      // Delete all favorite colors for the current user
      await _supabase
          .from('favorite_colors')
          .delete()
          .eq('user_id', currentUser.id);

      AppLogger.d('Successfully reset database for user');
    } catch (e, stackTrace) {
      AppLogger.e('Error resetting database', 
        error: e, 
        stackTrace: stackTrace
      );
      rethrow;
    }
  }
}
