import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/color_palette.dart';
import 'database_service.dart';
import 'auth_service.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  late final SupabaseClient _supabase;
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  factory CloudSyncService() {
    return _instance;
  }

  CloudSyncService._internal() {
    _supabase = Supabase.instance.client;
  }

  Future<void> syncPalettes() async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;


      final unsyncedPalettes = await _dbService.getUnsyncedPalettes();
      for (var palette in unsyncedPalettes) {
        await _supabase
            .from('palettes')
            .upsert({
              ...palette.toMap(),
              'user_id': user.id,
              'updated_at': DateTime.now().toIso8601String(),
            });
        await _dbService.markAsSynced(palette.id);
      }


      final response = await _supabase
          .from('palettes')
          .select()
          .eq('user_id', user.id)
          .order('updated_at', ascending: false);

      for (var item in response) {
        final palette = ColorPalette.fromMap(item);
        await _dbService.savePalette(palette);
      }
    } catch (e) {
      AppLogger.e('Error syncing palettes: $e');
      rethrow;
    }
  }

  Future<void> savePalette(ColorPalette palette) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final paletteData = {
        ...palette.toMap(),
        'user_id': user.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('palettes')
          .upsert(paletteData);
      
      await _dbService.savePalette(palette);
      await _dbService.markAsSynced(palette.id);
    } catch (e) {
      AppLogger.e('Error saving palette: $e');

      await _dbService.savePalette(palette);
      rethrow;
    }
  }

  Future<void> deletePalette(String id) async {
    try {
      await _supabase
          .from('palettes')
          .delete()
          .eq('id', id);
      
      await _dbService.deletePalette(id);
    } catch (e) {
      AppLogger.e('Error deleting palette: $e');
      rethrow;
    }
  }

  Future<List<ColorPalette>> searchPalettes(String query) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('palettes')
          .select()
          .eq('user_id', user.id)
          .ilike('name', '%$query%')
          .order('updated_at', ascending: false);

      return response.map((item) => ColorPalette.fromMap(item)).toList();
    } catch (e) {
      AppLogger.e('Error searching palettes: $e');
      rethrow;
    }
  }
}
