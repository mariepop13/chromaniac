import 'dart:typed_data';
import 'dart:ui';
import 'package:chromaniac/utils/color/export_palette.dart';
import 'package:chromaniac/utils/color/read_swatches.dart';
import 'package:flutter/material.dart' show HSVColor;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadSwatches', () {
    final standardTestPalette = [
      Color.fromRGBO(255, 0, 0, 1.0),
      Color.fromRGBO(0, 255, 0, 1.0),
      Color.fromRGBO(0, 0, 255, 1.0),
    ];

    group('ReadSwatchesFile', () {
      test('ReadSwatches_ShouldReadValidSwatchFileAndReturnCorrectHSVValues', () async {
        final content = createSwatchesContent(standardTestPalette);
        final result = await readSwatchesFile(content);

        expect(result['name'], equals('Palette'));
        expect(result['colors'], hasLength(standardTestPalette.length));
        
        for (var i = 0; i < standardTestPalette.length; i++) {
          final color = HSVColor.fromColor(standardTestPalette[i]);
          final exportedColor = result['colors'][i][0];
          final colorSpace = result['colors'][i][1];
          
          expect(exportedColor[0], equals(color.hue));
          expect(exportedColor[1], equals(color.saturation * 100));
          expect(exportedColor[2], equals(color.value * 100));
          expect(colorSpace, equals('hsv'));
        }
      });

      test('ReadSwatches_ShouldThrowErrorForUnsupportedColorSpace', () async {
        expect(
          () => readSwatchesFile(Uint8List(0), space: 'invalidspace'),
          throwsA(isA<ProcreateSwatchesError>().having(
            (e) => e.toString(),
            'message',
            contains('Color space invalidspace is not supported'),
          )),
        );
      });

      test('ReadSwatches_ShouldThrowErrorForInvalidFileFormat', () async {
        expect(
          () => readSwatchesFile(Uint8List(0)),
          throwsA(isA<ProcreateSwatchesError>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid .swatches file'),
          )),
        );
      });

      test('ReadSwatches_ShouldThrowErrorForCorruptedFileContent', () async {
        final corruptedContent = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 0x05]);

        expect(
          () => readSwatchesFile(corruptedContent),
          throwsA(isA<ProcreateSwatchesError>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid .swatches file'),
          )),
        );
      });

      test('ReadSwatches_ShouldHandleEmptyPaletteCorrectly', () async {
        final content = createSwatchesContent([]);
        final result = await readSwatchesFile(content);

        expect(result['name'], equals('Palette'));
        expect(result['colors'], isEmpty);
      });

      test('ReadSwatches_ShouldConvertColorsToRGBFormatWhenSpecified', () async {
        final content = createSwatchesContent(standardTestPalette);
        final result = await readSwatchesFile(content, space: 'rgb');

        expect(result['colors'], hasLength(standardTestPalette.length));
        for (var i = 0; i < standardTestPalette.length; i++) {
          final originalColor = standardTestPalette[i];
          final exportedColor = result['colors'][i][0];
          final colorSpace = result['colors'][i][1];
          
          expect(exportedColor[0], equals(originalColor.red));
          expect(exportedColor[1], equals(originalColor.green));
          expect(exportedColor[2], equals(originalColor.blue));
          expect(colorSpace, equals('rgb'));
        }
      });
    });
  });
}
