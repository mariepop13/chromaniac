import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/color_palette.dart';
import 'database_service.dart';
import '../config/supabase_config.dart';
import 'package:logger/logger.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final DatabaseService _dbService = DatabaseService();
  final logger = Logger();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  SupabaseClient get _supabase => SupabaseConfig.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      logger.e('Error signing up: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      logger.e('Error signing in: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      logger.e('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> syncPalettes() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Upload local changes
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

      // Download remote changes
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
      logger.e('Error syncing palettes: $e');
      rethrow;
    }
  }

  Future<void> savePalette(ColorPalette palette) async {
    try {
      final user = _supabase.auth.currentUser;
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
      logger.e('Error saving palette: $e');
      // Save locally if offline
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
      logger.e('Error deleting palette: $e');
      rethrow;
    }
  }

  Future<List<ColorPalette>> searchPalettes(String query) async {
    try {
      final user = _supabase.auth.currentUser;
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
      logger.e('Error searching palettes: $e');
      rethrow;
    }
  }
}
