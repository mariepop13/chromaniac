import 'package:flutter_test/flutter_test.dart';
import 'package:chromaniac/services/database_service.dart';
import 'package:chromaniac/models/color_palette.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';
import 'package:chromaniac/utils/logger/app_logger.dart';

void main() {
  late DatabaseService databaseService;
  final uuid = Uuid();
  final dbPath = '.dart_tool/sqflite_common_ffi/databases/color_palettes.db';

  setUpAll(() async {

    await AppLogger.init();
    
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    

    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  setUp(() async {
    databaseService = DatabaseService();
    final database = await databaseService.database;
    await database.delete('palettes');
  });

  tearDownAll(() async {
    final database = await databaseService.database;
    await database.close();
  });

  group('DatabaseService Tests', () {
    test('should create database successfully', () async {
      final database = await databaseService.database;
      expect(database, isNotNull);
      expect(database.isOpen, isTrue);
    });

    test('should insert and retrieve a color palette', () async {
      final palette = ColorPalette(
        id: uuid.v4(),
        name: 'Test Palette',
        colors: [Colors.red, Colors.green, Colors.blue],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final database = await databaseService.database;
      final map = palette.toMap();
      map['colors'] = json.encode(map['colors']);
      await database.insert('palettes', map);
      
      final List<Map<String, dynamic>> maps = await database.query(
        'palettes',
        where: 'id = ?',
        whereArgs: [palette.id],
      );
      
      expect(maps.length, 1);
      expect(maps.first['name'], palette.name);

      final retrievedColors = json.decode(maps.first['colors'] as String) as List;
      expect(retrievedColors.length, palette.colors.length);
    });

    test('should update a color palette', () async {
      final palette = ColorPalette(
        id: uuid.v4(),
        name: 'Original Name',
        colors: [Colors.red],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final database = await databaseService.database;
      final map = palette.toMap();
      map['colors'] = json.encode(map['colors']);
      await database.insert('palettes', map);

      final updatedPalette = ColorPalette(
        id: palette.id,
        name: 'Updated Name',
        colors: [Colors.red, Colors.green],
        createdAt: palette.createdAt,
        updatedAt: DateTime.now(),
      );

      final updatedMap = updatedPalette.toMap();
      updatedMap['colors'] = json.encode(updatedMap['colors']);
      await database.update(
        'palettes',
        updatedMap,
        where: 'id = ?',
        whereArgs: [updatedPalette.id],
      );

      final List<Map<String, dynamic>> maps = await database.query(
        'palettes',
        where: 'id = ?',
        whereArgs: [palette.id],
      );
      
      expect(maps.first['name'], 'Updated Name');
      final retrievedColors = json.decode(maps.first['colors'] as String) as List;
      expect(retrievedColors.length, 2);
    });

    test('should delete a color palette', () async {
      final palette = ColorPalette(
        id: uuid.v4(),
        name: 'To Delete',
        colors: [Colors.red],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final database = await databaseService.database;
      final map = palette.toMap();
      map['colors'] = json.encode(map['colors']);
      await database.insert('palettes', map);
      
      await database.delete(
        'palettes',
        where: 'id = ?',
        whereArgs: [palette.id],
      );
      
      final List<Map<String, dynamic>> maps = await database.query(
        'palettes',
        where: 'id = ?',
        whereArgs: [palette.id],
      );
      
      expect(maps.isEmpty, true);
    });

    test('should get all palettes', () async {
      final palettes = [
        ColorPalette(
          id: uuid.v4(),
          name: 'Palette 1',
          colors: [Colors.red],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ColorPalette(
          id: uuid.v4(),
          name: 'Palette 2',
          colors: [Colors.green],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final database = await databaseService.database;
      for (final palette in palettes) {
        final map = palette.toMap();
        map['colors'] = json.encode(map['colors']);
        await database.insert('palettes', map);
      }

      final List<Map<String, dynamic>> maps = await database.query('palettes');
      expect(maps.length, palettes.length);
    });
  });
}
