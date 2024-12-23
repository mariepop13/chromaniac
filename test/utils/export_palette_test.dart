import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:chromaniac/utils/color/read_swatches.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chromaniac/utils/color/export_palette.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String> getTemporaryPath() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = MockPathProviderPlatform();

  group('ExportPalette', () {
    final standardTestPalette = [
      Color.from(alpha: 1.0, red: 1.0, green: 0.0, blue: 0.0), // Red
      Color.from(alpha: 1.0, red: 0.0, green: 1.0, blue: 0.0), // Green
      Color.from(alpha: 1.0, red: 0.0, green: 0.0, blue: 1.0), // Blue
    ];

    group('CreateSwatchesContent', () {
      test('ExportPalette_CreateSwatches_ShouldGenerateValidSwatchFileWithHSVValues', () async {
        final content = createSwatchesContent(standardTestPalette);
        final swatchData = await readSwatchesFile(content);

        expect(swatchData['name'], equals('Palette'));
        expect(swatchData['colors'], hasLength(standardTestPalette.length));

        for (var i = 0; i < standardTestPalette.length; i++) {
          final color = HSVColor.fromColor(standardTestPalette[i]);
          final exportedColor = swatchData['colors'][i][0];
          final colorSpace = swatchData['colors'][i][1];
          
          expect(exportedColor[0], equals(color.hue));
          expect(exportedColor[1], equals(color.saturation * 100));
          expect(exportedColor[2], equals(color.value * 100));
          expect(colorSpace, equals('hsv'));
        }
      });

      test('ExportPalette_CreateSwatches_ShouldCreateValidZipArchiveWithJSON', () {
        final content = createSwatchesContent(standardTestPalette);
        final decoder = ZipDecoder();
        final archive = decoder.decodeBytes(content);

        expect(archive.length, equals(1));
        expect(archive.first.name, equals('Swatches.json'));

        final jsonContent = utf8.decode(archive.first.content);
        final data = jsonDecode(jsonContent) as List<dynamic>;
        
        expect(data.length, equals(1));
        expect(data[0]['name'], equals('Palette'));
        expect(data[0]['swatches'].length, equals(standardTestPalette.length));
      });

      test('ExportPalette_CreateSwatches_ShouldHandleEmptyPaletteCorrectly', () {
        final content = createSwatchesContent([]);
        final decoder = ZipDecoder();
        final archive = decoder.decodeBytes(content);
        
        final jsonContent = utf8.decode(archive.first.content);
        final data = jsonDecode(jsonContent) as List<dynamic>;

        expect(data.length, equals(1));
        expect(data[0]['name'], equals('Palette'));
        expect(data[0]['swatches'], isEmpty);
      });
    });
  });
}
