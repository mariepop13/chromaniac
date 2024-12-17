import 'dart:io';
import 'dart:typed_data';
import 'package:chromaniac/utils/export_palette.dart';
import 'package:chromaniac/utils/read_swatches.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chromaniac/utils/read_swatches.dart' as read_swatches;

void main() {
  final sampleFilesDir = './test/sample';
  final sampleFiles = Directory(sampleFilesDir)
      .listSync()
      .whereType<File>()
      .map((file) => file.readAsBytesSync())
      .toList();
      
  final sampleSwatchesToCreate = [
    [
      'My palette',
      [
        [[255, 0, 0], 'rgb'],
        [[0, 255, 0], 'rgb'],
        [[0, 0, 255], 'rgb'],
      ],
    ],
  ];

  group('readSwatchesFile', () {
    test('reads the contents of .swatches files', () async {
      for (final sampleFile in sampleFiles) {
        final swatches = await readSwatchesFile(sampleFile);
        expect(swatches, isA<Map<String, dynamic>>());
        expect(swatches, contains('name'));
        expect(swatches['name'], isA<String>());
        expect(swatches, contains('colors'));
        expect(swatches['colors'], isA<List>());
        for (final color in swatches['colors']) {
          if (color == null) continue;
          expect(color, isA<List>());
          expect(color.length, 2);
          final colorValues = color[0];
          final colorSpace = color[1];
          expect(colorSpace, isA<String>());
          expect(colorSpace, isNotEmpty);
          expect(colorValues, isA<List>());
          expect(colorValues, isNotEmpty);
        }
      }
    });

    test('converts parsed colors', () async {
      for (final sampleFile in sampleFiles) {
        final swatches = await readSwatchesFile(sampleFile, space: 'rgb');
        for (final color in swatches['colors']) {
          if (color == null) continue;
          final colorValues = color[0];
          final colorSpace = color[1];
          expect(colorSpace, 'rgb');
          expect(colorValues.length, 3);
          for (final value in colorValues) {
            expect(value, inInclusiveRange(0, 255));
          }
        }
      }
    });

    test('throws an error if the color space is not supported', () async {
      try {
        await readSwatchesFile(Uint8List(0), space: 'notavalidcolorspace');
      } catch (error) {
        expect(error, isA<read_swatches.ProcreateSwatchesError>());
        expect(error.toString(), contains('Color space'));
      }
    });
  });

  group('createSwatchesFile', () {
    test('creates a new swatches file', () async {
      for (final swatch in sampleSwatchesToCreate) {
        final name = swatch[0];
        final colors = swatch[1];
        final swatchesFile = await createSwatchesFile(name as String, colors as List);
        final swatches = await readSwatchesFile(swatchesFile);
        expect(swatches['name'], name);
        expect(swatches['colors'].length, colors.length);
      }
    });

    test('saves a maximum of 30 colors', () async {
      final colors = List.generate(100, (_) => [[255, 255, 255], 'rgb']);
      expect(colors.length, 100);
      final swatchesFile = await createSwatchesFile('', colors);
      final swatches = await readSwatchesFile(swatchesFile);
      expect(swatches['colors'].length, 30);
    });

    test('exported file is readable by readSwatchesFile', () async {
      final colors = [
        [[255, 0, 0], 'rgb'],
        [[0, 255, 0], 'rgb'],
        [[0, 0, 255], 'rgb'],
      ];
      final swatchesFile = await createSwatchesFile('Test Palette', colors);
      final swatches = await readSwatchesFile(swatchesFile);
      expect(swatches['name'], 'Test Palette');
      expect(swatches['colors'].length, colors.length);
    });
  });
}