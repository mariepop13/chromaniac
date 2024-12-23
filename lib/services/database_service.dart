import 'dart:io';
import 'dart:ui';
import 'dart:convert'; // Import json library

import 'package:chromaniac/models/favorite_color.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:chromaniac/models/color_palette.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:uuid/uuid.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> resetDatabase() async {
    try {
      AppLogger.d('Resetting database');
      final path = '${await getDatabasesPath()}/color_palettes.db';
      
      // Close existing connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      
      // Delete the database file
      await deleteDatabase(path);
      AppLogger.d('Deleted existing database');
      
      // Reinitialize the database
      _database = await _initDatabase();
      AppLogger.d('Reinitialized database');
    } catch (e, stackTrace) {
      AppLogger.e('Error resetting database', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      AppLogger.d('Initializing database');
      String path = '${await getDatabasesPath()}/color_palettes.db';
      AppLogger.d('Database path: $path');
      
      // Check if database exists
      bool exists = await databaseExists(path);
      AppLogger.d('Database exists: $exists');
      
      if (!exists) {
        AppLogger.d('Creating new database');
        try {
          await Directory(dirname(path)).create(recursive: true);
          AppLogger.d('Created directory structure');
        } catch (e) {
          AppLogger.w('Directory already exists: ${e.toString()}');
        }
      }
      
      return await openDatabase(
        path,
        version: 3,
        onCreate: _createDb,
        onUpgrade: _upgradeDb,
        onOpen: (db) async {
          AppLogger.d('Database opened');
          // Verify tables exist
          final tables = await db.query('sqlite_master', 
            where: 'type = ?', 
            whereArgs: ['table']
          );
          AppLogger.d('Existing tables: ${tables.map((t) => t['name']).join(', ')}');
        },
      );
    } catch (e, stackTrace) {
      AppLogger.e('Error initializing database', error: e, stackTrace: stackTrace);
      rethrow;
    }
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
    try {
      AppLogger.d('Creating database tables');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS palettes(
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

      AppLogger.d('Created palettes table');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorites(
          id TEXT PRIMARY KEY,
          color INTEGER NOT NULL,
          user_id TEXT,
          created_at TEXT NOT NULL,
          name TEXT,
          is_sync INTEGER DEFAULT 0
        )
      ''');
      
      AppLogger.d('Created favorites table');
    } catch (e, stackTrace) {
      AppLogger.e('Error creating database tables', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> savePalette(ColorPalette palette) async {
    try {
      AppLogger.d('Starting to save palette: ${palette.name}');
      final db = await database;
      
      final map = palette.toMap();
      final colors = map['colors'] as List<String>;
      map['colors'] = jsonEncode(colors);
      
      AppLogger.d('Palette data: $map');
      AppLogger.d('Encoded colors: ${map['colors']}');
      
      await db.insert(
        'palettes',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Verify the save
      final saved = await db.query(
        'palettes',
        where: 'id = ?',
        whereArgs: [palette.id],
      );
      
      if (saved.isEmpty) {
        throw Exception('Palette was not saved properly');
      }
      
      AppLogger.d('Successfully saved palette to database: ${saved.first}');
    } catch (e, stackTrace) {
      AppLogger.e('Error saving palette to database', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<ColorPalette>> getPalettes({String? userId}) async {
    try {
      AppLogger.d('Getting palettes from database');
      final db = await database;
      
      // First, check if the table exists
      final tables = await db.query('sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'palettes'],
      );
      
      if (tables.isEmpty) {
        AppLogger.e('Palettes table does not exist');
        await _createDb(db, 3);
        return [];
      }
      
      final List<Map<String, dynamic>> maps = await db.query(
        'palettes',
        where: userId != null ? 'user_id = ?' : null,
        whereArgs: userId != null ? [userId] : null,
      );

      AppLogger.d('Found ${maps.length} palettes');
      
      final palettes = <ColorPalette>[];
      
      for (var i = 0; i < maps.length; i++) {
        try {
          final map = Map<String, dynamic>.from(maps[i]);
          AppLogger.d('Processing palette ${i + 1}/${maps.length}: ${map['name']}');
          
          final colorStr = map['colors'] as String;
          AppLogger.d('Raw colors data: $colorStr');
          
          List<dynamic> colorsList;
          try {
            colorsList = jsonDecode(colorStr);
            AppLogger.d('Decoded colors: $colorsList');
          } catch (e) {
            AppLogger.w('JSON decode failed, trying comma-separated format');
            colorsList = colorStr.split(',').map((s) => s.trim()).toList();
            AppLogger.d('Split colors: $colorsList');
          }
          
          map['colors'] = colorsList;
          final palette = ColorPalette.fromMap(map);
          palettes.add(palette);
          AppLogger.d('Successfully processed palette: ${palette.name} with ${palette.colors.length} colors');
        } catch (e, stackTrace) {
          AppLogger.e('Error processing palette at index $i', error: e, stackTrace: stackTrace);
          // Continue processing other palettes
          continue;
        }
      }
      
      return palettes;
    } catch (e, stackTrace) {
      AppLogger.e('Error getting palettes from database', error: e, stackTrace: stackTrace);
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
      AppLogger.e('Error getting unsynced palettes', error: e);
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
      AppLogger.e('Error marking palette as synced', error: e);
      rethrow;
    }
  }

  Future<void> deletePalette(String id) async {
    try {
      AppLogger.d('Deleting palette with id: $id');
      final db = await database;
      
      final result = await db.delete(
        'palettes',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (result == 0) {
        AppLogger.w('No palette found with id: $id');
      } else {
        AppLogger.d('Successfully deleted palette');
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error deleting palette', error: e, stackTrace: stackTrace);
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
          'color': ((((color.a * 255).round() << 24) |
                    ((color.r * 255).round() << 16) |
                    ((color.g * 255).round() << 8) |
                    (color.b * 255).round())),
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
          'name': name,
          'is_sync': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.i('Color added to favorites successfully');
    } catch (e) {
      AppLogger.e('Error adding color to favorites', error: e);
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
      AppLogger.i('Color removed from favorites successfully');
    } catch (e) {
      AppLogger.e('Error removing color from favorites', error: e);
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
      AppLogger.e('Error getting favorite colors', error: e);
      rethrow;
    }
  }
}
