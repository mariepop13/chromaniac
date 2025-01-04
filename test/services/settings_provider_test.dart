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

  group('Grid Layout and Palette Size Tests', () {
    test('Initial grid columns should be 1 for default palette size', () {
      expect(settingsProvider.gridColumns, 1);
    });

    test('Initial default palette size should be AppConstants.defaultPaletteSize', () {
      expect(settingsProvider.defaultPaletteSize, AppConstants.defaultPaletteSize);
    });

    test('Grid columns calculation for default palette size', () {
      final expectedColumns = (AppConstants.defaultPaletteSize / 2).ceil();
      expect(settingsProvider.getMaxGridColumns(), expectedColumns);
    });

    test('Setting temporary palette size should adjust grid columns', () async {
      await settingsProvider.setTemporaryPaletteSize(6);
      expect(settingsProvider.gridColumns, 1);

      await settingsProvider.setTemporaryPaletteSize(10);
      expect(settingsProvider.gridColumns, 1);
    });

    test('Clearing temporary palette size should reset to default size columns', () async {
      await settingsProvider.setTemporaryPaletteSize(10);
      expect(settingsProvider.gridColumns, 1);

      await settingsProvider.clearTemporaryPaletteSize();
      final expectedColumns = (AppConstants.defaultPaletteSize / 2).ceil();
      expect(settingsProvider.gridColumns, expectedColumns);
    });

    test('Setting default palette size should adjust grid columns', () async {
      await settingsProvider.setDefaultPaletteSize(8);
      expect(settingsProvider.gridColumns, 4);
    });

    test('Special case for palette size 3 should set grid columns to 2', () async {
      await settingsProvider.setDefaultPaletteSize(3);
      expect(settingsProvider.gridColumns, 2);
    });

    test('Grid columns should not exceed max allowed for palette size', () async {
      await settingsProvider.setDefaultPaletteSize(8);
      await settingsProvider.setGridColumns(10);
      final maxAllowed = 8;
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
      expect(settingsProvider.gridColumns, 4);
    });

    test('adjustGridColumnsForPaletteSize should correct oversized columns', () async {
      await settingsProvider.setTemporaryPaletteSize(10);
      expect(settingsProvider.gridColumns, 1);

      await settingsProvider.setTemporaryPaletteSize(6);
      await settingsProvider.adjustGridColumnsForPaletteSize();
      expect(settingsProvider.gridColumns, 3);
    });

    test('getCurrentPaletteSize should return temporary size if set', () async {
      await settingsProvider.setTemporaryPaletteSize(7);
      expect(settingsProvider.getCurrentPaletteSize(), 7);
    });

    test('getCurrentPaletteSize should return default size if no temporary size', () {
      expect(settingsProvider.getCurrentPaletteSize(), AppConstants.defaultPaletteSize);
    });
  });

  group('Premium Settings Tests', () {
    test('Initial premium status should be false', () {
      expect(settingsProvider.isPremiumEnabled, false);
    });

    test('Setting premium status should work', () async {
      await settingsProvider.setIsPremiumEnabled(true);
      expect(settingsProvider.isPremiumEnabled, true);
    });

    test('Setting default palette size should respect premium limits', () async {
      await settingsProvider.setIsPremiumEnabled(false);
      
      expect(() async => await settingsProvider.setDefaultPaletteSize(AppConstants.maxPaletteColors + 1), 
        throwsA(isA<RangeError>()));
    });
  });
} 