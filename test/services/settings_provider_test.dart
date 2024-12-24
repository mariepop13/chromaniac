import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chromaniac/providers/settings_provider.dart';
import 'package:chromaniac/core/constants.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';

void main() {
  late SettingsProvider settingsProvider;
  late SharedPreferences prefs;

  setUpAll(() {
    AppLogger.enableTestMode();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    settingsProvider = SettingsProvider(prefs);
  });

  group('Grid Layout Tests', () {
    test('Initial grid columns should be 1', () {
      expect(settingsProvider.gridColumns, 1);
    });

    test('Default palette size should be AppConstants.defaultPaletteSize', () {
      expect(settingsProvider.defaultPaletteSize, AppConstants.defaultPaletteSize);
    });

    test('Grid columns should be (paletteSize/2).ceil() for default palette size', () {
      final expectedColumns = (AppConstants.defaultPaletteSize / 2).ceil();
      expect(settingsProvider.getMaxGridColumns(), expectedColumns);
    });

    test('Setting temporary palette size should adjust grid columns', () async {
      // Test with palette size 6
      await settingsProvider.setTemporaryPaletteSize(6);
      expect(settingsProvider.gridColumns, 3); // (6/2).ceil() = 3

      // Test with palette size 10
      await settingsProvider.setTemporaryPaletteSize(10);
      expect(settingsProvider.gridColumns, 5); // (10/2).ceil() = 5
    });

    test('Clearing temporary palette size should reset to default size columns', () async {
      // First set a temporary size
      await settingsProvider.setTemporaryPaletteSize(10);
      expect(settingsProvider.gridColumns, 5);

      // Then clear it and verify it returns to default
      await settingsProvider.clearTemporaryPaletteSize();
      final expectedColumns = (AppConstants.defaultPaletteSize / 2).ceil();
      expect(settingsProvider.gridColumns, expectedColumns);
    });

    test('Setting default palette size should adjust grid columns when no temporary size', () async {
      await settingsProvider.setDefaultPaletteSize(8);
      expect(settingsProvider.gridColumns, 4); // (8/2).ceil() = 4
    });

    test('Grid columns should not exceed max allowed for palette size', () async {
      // Try to set columns higher than allowed
      await settingsProvider.setGridColumns(10);
      
      // Should be clamped to (defaultPaletteSize/2).ceil()
      final maxAllowed = (settingsProvider.defaultPaletteSize / 2).ceil();
      expect(settingsProvider.gridColumns, maxAllowed);
    });

    test('Grid columns should not go below 1', () async {
      // Try to set columns below minimum
      await settingsProvider.setGridColumns(0);
      expect(settingsProvider.gridColumns, 1);
    });

    test('Temporary palette size should take precedence over default size', () async {
      // Set default size
      await settingsProvider.setDefaultPaletteSize(8);
      expect(settingsProvider.gridColumns, 4);

      // Set temporary size
      await settingsProvider.setTemporaryPaletteSize(6);
      expect(settingsProvider.gridColumns, 3);
    });

    test('adjustGridColumnsForPaletteSize should correct oversized columns', () async {
      // First set a large palette size and columns
      await settingsProvider.setTemporaryPaletteSize(10);
      expect(settingsProvider.gridColumns, 5);

      // Then set a smaller palette size
      await settingsProvider.setTemporaryPaletteSize(6);
      await settingsProvider.adjustGridColumnsForPaletteSize();
      expect(settingsProvider.gridColumns, 3);
    });
  });
} 