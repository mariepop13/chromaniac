import 'dart:io';
import 'dart:typed_data';
import 'package:chromaniac/utils/color/export_palette.dart' as export_palette;
import 'package:chromaniac/utils/color/export_palette.dart';
import 'package:chromaniac/utils/color/read_swatches.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chromaniac/utils/color/read_swatches.dart' as read_swatches;

void main() {
  final sampleFilesDir = './test/sample';
  Directory(sampleFilesDir)
      .listSync()
      .whereType<File>()
      .map((file) => file.readAsBytesSync())
      .toList();

  final sampleSwatchesToCreate = [
    [
      'My palette',
      [
        [
          [255.0, 0.0, 0.0],
          'rgb'
        ],
        [
          [0.0, 255.0, 0.0],
          'rgb'
        ],
        [
          [0.0, 0.0, 255.0],
          'rgb'
        ],
      ],
    ],
  ];

  group('readSwatchesFile', () {
    test('throws an error for unsupported color space', () async {
      try {
        await readSwatchesFile(Uint8List(0), space: 'notavalidcolorspace');
      } catch (error) {
        expect(error, isA<read_swatches.ProcreateSwatchesError>());
        expect(error.toString(), contains('Color space'));
      }
    });

    test('throws an error for invalid .swatches file', () async {
      try {
        await readSwatchesFile(Uint8List(0));
      } catch (error) {
        expect(error, isA<read_swatches.ProcreateSwatchesError>());
        expect(error.toString(), contains('Invalid .swatches file.'));
      }
    });
  });

  group('createSwatchesFile', () {
    test('creates a new swatches file', () async {
      for (final swatch in sampleSwatchesToCreate) {
        final name = swatch[0];
        final List<List<dynamic>> colors =
            (swatch[1] as List).cast<List<dynamic>>();
        final swatchesFile = await createSwatchesFile(name as String, colors);
        final swatches = await readSwatchesFile(swatchesFile);
        expect(swatches['name'], name);
        expect(swatches['colors'].length, colors.length);
      }
    });

    test('saves a maximum of 30 colors', () async {
      final colors = List.generate(
          100,
          (_) => [
                [255, 255, 255],
                'rgb'
              ]);
      expect(colors.length, 100);
      final swatchesFile = await createSwatchesFile('', colors);
      final swatches = await readSwatchesFile(swatchesFile);
      expect(swatches['colors'].length, 30);
    });

    test('throws an error for invalid color format', () async {
      try {
        final colors = [
          [
            [255, 0, 0],
            'invalid'
          ],
        ];
        await createSwatchesFile('Invalid Palette', colors);
        fail('Should throw ProcreateSwatchesError');
      } on export_palette.ProcreateSwatchesError catch (error) {
        expect(error.toString(), contains('is not supported'));
      }
    });

    test('exported file is readable by readSwatchesFile', () async {
      final colors = [
        [
          [255, 0, 0],
          'rgb'
        ],
        [
          [0, 255, 0],
          'rgb'
        ],
        [
          [0, 0, 255],
          'rgb'
        ],
      ];
      final swatchesFile = await createSwatchesFile('Test Palette', colors);
      final swatches = await readSwatchesFile(swatchesFile);
      expect(swatches['name'], 'Test Palette');
      expect(swatches['colors'].length, colors.length);
    });
  });

  group('Sample swatches files', () {
    final Map<String, String> sampleFileNames = {
      'Modern_&_Fresh.swatches': 'Modern & Fresh',
      'mypalette.swatches': 'Jakaś Sałatkowa Bonanza ',
      'Pantone_2019.swatches': 'Pantone 2019',
      'Retro_&_Vintage.swatches': 'Retro & Vintage',
    };

    sampleFileNames.forEach((fileName, expectedName) {
      test('Testing $fileName', () async {
        final file = File('$sampleFilesDir/$fileName');
        final data = file.readAsBytesSync();

        final swatchesHsv = await readSwatchesFile(data, space: 'hsv');
        expect(swatchesHsv['name'], expectedName);
        expect(swatchesHsv['colors'], isNotEmpty);
        expect(swatchesHsv['colors'].first[1], equals('hsv'));

        for (final color in swatchesHsv['colors']) {
          expect(color[0], hasLength(3));
          expect(color[1], equals('hsv'));
          expect(color[0][0], inInclusiveRange(0, 360));
          expect(color[0][1], inInclusiveRange(0, 100));
          expect(color[0][2], inInclusiveRange(0, 100));
        }

        final swatchesRgb = await readSwatchesFile(data, space: 'rgb');
        expect(swatchesRgb['name'], expectedName);
        expect(swatchesRgb['colors'], isNotEmpty);
        expect(swatchesRgb['colors'].first[1], equals('rgb'));

        for (final color in swatchesRgb['colors']) {
          expect(color[0], hasLength(3));
          expect(color[1], equals('rgb'));
          expect(color[0][0], inInclusiveRange(0, 255));
          expect(color[0][1], inInclusiveRange(0, 255));
          expect(color[0][2], inInclusiveRange(0, 255));
        }
      });
    });
  });
}
