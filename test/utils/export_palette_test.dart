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
    test('Test createSwatchesContent format', () {
      final palette = [Colors.red, Colors.green, Colors.blue];
      final content = createSwatchesContent(palette);
      expect(content, isA<Uint8List>());
      expect(content.length, 3 * 4 + 12); // 3 colors * 4 bytes + 12 bytes metadata
    });

    test('Exported content is readable by readSwatchesFile', () async {
      final palette = [Colors.red, Colors.green, Colors.blue];
      final content = createSwatchesContent(palette);
      final swatches = await readSwatchesFile(content);
      expect(swatches['name'], isNotEmpty);
      expect(swatches['colors'].length, palette.length);
    });
  });
}