import 'dart:ui';

import 'package:chromaniac/models/favorite_color.dart';
import 'package:sqflite/sqflite.dart';
import 'package:chromaniac/models/color_palette.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  final logger = Logger();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = '${await getDatabasesPath()}/color_palettes.db';
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE palettes ADD COLUMN ai_output TEXT;
        ALTER TABLE palettes ADD COLUMN description TEXT;
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE favorites(
          id TEXT PRIMARY KEY,
          color INTEGER NOT NULL,
          user_id TEXT,
          created_at TEXT NOT NULL,
          name TEXT,
          is_sync INTEGER DEFAULT 0
        )
      ''');
    }
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE palettes(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        colors TEXT NOT NULL,
        user_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_sync INTEGER DEFAULT 0,
        ai_output TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites(
        id TEXT PRIMARY KEY,
        color INTEGER NOT NULL,
        user_id TEXT,
        created_at TEXT NOT NULL,
        name TEXT,
        is_sync INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> savePalette(ColorPalette palette) async {
    try {
      final db = await database;
      await db.insert(
        'palettes',
        palette.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      logger.e('Error saving palette: $e');
      rethrow;
    }
  }

  Future<List<ColorPalette>> getPalettes({String? userId}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'palettes',
        where: userId != null ? 'user_id = ?' : null,
        whereArgs: userId != null ? [userId] : null,
      );

      return List.generate(maps.length, (i) => ColorPalette.fromMap(maps[i]));
    } catch (e) {
      logger.e('Error getting palettes: $e');
      rethrow;
    }
  }

  Future<List<ColorPalette>> getUnsyncedPalettes() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'palettes',
        where: 'is_sync = ?',
        whereArgs: [0],
      );

      return List.generate(maps.length, (i) => ColorPalette.fromMap(maps[i]));
    } catch (e) {
      logger.e('Error getting unsynced palettes: $e');
      rethrow;
    }
  }

  Future<void> markAsSynced(String id) async {
    try {
      final db = await database;
      await db.update(
        'palettes',
        {'is_sync': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      logger.e('Error marking palette as synced: $e');
      rethrow;
    }
  }

  Future<void> deletePalette(String id) async {
    try {
      final db = await database;
      await db.delete(
        'palettes',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      logger.e('Error deleting palette: $e');
      rethrow;
    }
  }

  Future<void> addFavoriteColor(Color color, {String? name, String? userId}) async {
    try {
      final db = await database;
      final id = const Uuid().v4();
      await db.insert(
        'favorites',
        {
          'id': id,
          'color': color.value,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
          'name': name,
          'is_sync': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      logger.i('Color added to favorites successfully');
    } catch (e) {
      logger.e('Error adding color to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFavoriteColor(String id) async {
    try {
      final db = await database;
      await db.delete(
        'favorites',
        where: 'id = ?',
        whereArgs: [id],
      );
      logger.i('Color removed from favorites successfully');
    } catch (e) {
      logger.e('Error removing color from favorites: $e');
      rethrow;
    }
  }

  Future<List<FavoriteColor>> getFavoriteColors({String? userId}) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'favorites',
        where: userId != null ? 'user_id = ?' : null,
        whereArgs: userId != null ? [userId] : null,
        orderBy: 'created_at DESC',
      );
      return List.generate(maps.length, (i) => FavoriteColor.fromMap(maps[i]));
    } catch (e) {
      logger.e('Error getting favorite colors: $e');
      rethrow;
    }
  }
}
