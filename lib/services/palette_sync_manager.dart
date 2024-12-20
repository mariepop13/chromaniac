import 'dart:async';
import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:flutter/foundation.dart';
import '../models/color_palette.dart';
import 'supabase_service.dart';
import 'database_service.dart';
import 'auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaletteSyncManager extends ChangeNotifier {
  static final PaletteSyncManager _instance = PaletteSyncManager._internal();
  final SupabaseService _supabaseService = SupabaseService();
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();

  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  factory PaletteSyncManager() {
    return _instance;
  }

  PaletteSyncManager._internal() {
    // Écouter les changements d'état d'authentification
    _authService.authStateChanges.listen((state) {
      if (state.event == AuthChangeEvent.signedIn) {
        startAutoSync();
      } else if (state.event == AuthChangeEvent.signedOut) {
        stopAutoSync();
      }
    });
  }

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  void startAutoSync() {
    // Synchroniser toutes les 5 minutes
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncPalettes();
    });
    
    // Synchroniser immédiatement au démarrage
    syncPalettes();
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> syncPalettes() async {
    if (_isSyncing) return;

    try {
      _isSyncing = true;
      notifyListeners();

      await _supabaseService.syncPalettes();
      
      _lastSyncTime = DateTime.now();
    } catch (e) {
      AppLogger.e('Error during palette synchronization: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> savePalette(ColorPalette palette) async {
    try {
      // Sauvegarder localement d'abord
      await _dbService.savePalette(palette);

      // Si l'utilisateur est connecté, synchroniser avec Supabase
      if (_authService.currentUser != null) {
        await _supabaseService.savePalette(palette);
        await _dbService.markAsSynced(palette.id);
      }
    } catch (e) {
      AppLogger.e('Error saving palette: $e');
      rethrow;
    }
  }

  Future<void> deletePalette(String id) async {
    try {
      // Supprimer localement d'abord
      await _dbService.deletePalette(id);

      // Si l'utilisateur est connecté, supprimer de Supabase
      if (_authService.currentUser != null) {
        await _supabaseService.deletePalette(id);
      }
    } catch (e) {
      AppLogger.e('Error deleting palette: $e');
      rethrow;
    }
  }

  Future<List<ColorPalette>> getPalettes() async {
    try {
      return await _dbService.getPalettes(
        userId: _authService.currentUser?.id,
      );
    } catch (e) {
      AppLogger.e('Error getting palettes: $e');
      rethrow;
    }
  }

  Future<List<ColorPalette>> searchPalettes(String query) async {
    try {
      if (_authService.currentUser != null) {
        // Rechercher dans Supabase si connecté
        return await _supabaseService.searchPalettes(query);
      } else {
        // Rechercher localement si hors ligne
        final palettes = await _dbService.getPalettes();
        return palettes
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    } catch (e) {
      AppLogger.e('Error searching palettes: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    stopAutoSync();
    super.dispose();
  }
}
