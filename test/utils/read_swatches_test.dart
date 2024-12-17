import 'dart:io';
import 'dart:typed_data';
import 'package:chromaniac/utils/export_palette.dart' as export_palette;
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
}
