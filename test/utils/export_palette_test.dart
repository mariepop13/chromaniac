import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:chromaniac/utils/read_swatches.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chromaniac/utils/export_palette.dart';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class MockBuildContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

  group('Export Palette Output Format Tests', () {
    test('creates swatches content in correct format', () {
      final palette = [Colors.red, Colors.green, Colors.blue];
      final content = createSwatchesContent(palette);
      expect(content, isA<Uint8List>());
      expect(content.length, 3 * 4 + 12); // 3 colors * 4 bytes + 12 bytes metadata
    });

    test('exported content is readable by readSwatchesFile', () async {
      final palette = [Colors.red, Colors.green, Colors.blue];
      final content = createSwatchesContent(palette);
      final swatches = await readSwatchesFile(content);
      expect(swatches['name'], isNotEmpty);
      expect(swatches['colors'].length, palette.length);
    });
  });

  group('Color Conversion Tests', () {
    test('preserves color information correctly', () {
      final palette = [
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
      ];
      
      final content = createSwatchesContent(palette);
      final decoder = ZipDecoder();
      final archive = decoder.decodeBytes(content);
      final jsonContent = utf8.decode(archive.first.content);
      final data = jsonDecode(jsonContent) as List<dynamic>;
      final swatches = data[0]['swatches'] as List<dynamic>;

      final redSwatch = swatches[0];
      expect(redSwatch['hue'], closeTo(0.0, 0.001));
      expect(redSwatch['saturation'], equals(1.0));
      expect(redSwatch['brightness'], equals(1.0));

      final greenSwatch = swatches[1];
      expect(greenSwatch['hue'], closeTo(0.333, 0.001));
      expect(greenSwatch['saturation'], equals(1.0));
      expect(greenSwatch['brightness'], equals(1.0));

      final blueSwatch = swatches[2];
      expect(blueSwatch['hue'], closeTo(0.667, 0.001));
      expect(blueSwatch['saturation'], equals(1.0));
      expect(blueSwatch['brightness'], equals(1.0));
    });
  });
}