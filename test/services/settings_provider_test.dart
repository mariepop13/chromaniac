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

      await settingsProvider.setTemporaryPaletteSize(6);
      expect(settingsProvider.gridColumns, 3);


      await settingsProvider.setTemporaryPaletteSize(10);
      expect(settingsProvider.gridColumns, 5);
    });

    test('Clearing temporary palette size should reset to default size columns', () async {

      await settingsProvider.setTemporaryPaletteSize(10);
      expect(settingsProvider.gridColumns, 5);


      await settingsProvider.clearTemporaryPaletteSize();
      final expectedColumns = (AppConstants.defaultPaletteSize / 2).ceil();
      expect(settingsProvider.gridColumns, expectedColumns);
    });

    test('Setting default palette size should adjust grid columns when no temporary size', () async {
      await settingsProvider.setDefaultPaletteSize(8);
      expect(settingsProvider.gridColumns, 4);
    });

    test('Grid columns should not exceed max allowed for palette size', () async {

      await settingsProvider.setGridColumns(10);
      

      final maxAllowed = (settingsProvider.defaultPaletteSize / 2).ceil();
      expect(settingsProvider.gridColumns, maxAllowed);
    });

    test('Grid columns should not go below 1', () async {

      await settingsProvider.setGridColumns(0);
      expect(settingsProvider.gridColumns, 1);
    });

    test('Temporary palette size should take precedence over default size', () async {

      await settingsProvider.setDefaultPaletteSize(8);
      expect(settingsProvider.gridColumns, 4);


      await settingsProvider.setTemporaryPaletteSize(6);
      expect(settingsProvider.gridColumns, 3);
    });

    test('adjustGridColumnsForPaletteSize should correct oversized columns', () async {

      await settingsProvider.setTemporaryPaletteSize(10);
      expect(settingsProvider.gridColumns, 5);


      await settingsProvider.setTemporaryPaletteSize(6);
      await settingsProvider.adjustGridColumnsForPaletteSize();
      expect(settingsProvider.gridColumns, 3);
    });
  });
} 