import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chromaniac/utils/color/image_color_analyzer.dart';
import 'package:chromaniac/services/openrouter_service.dart';
import 'package:chromaniac/utils/logger.dart';
import 'package:logger/logger.dart';

void main() {
  late ImageColorAnalyzer analyzer;
  late OpenRouterService service;
  final logger = Logger();

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
    AppLogger.init();
    service = OpenRouterService(client: http.Client());
    analyzer = ImageColorAnalyzer(service: service);
  });

  group('OpenRouter Integration Tests', () {
    test('analyzeColoringImage performs successful API integration', () async {
      // Arrange
      final File imageFile = File('test/sample/gaming_cats.PNG');
      final imageBytes = await imageFile.readAsBytes();

      // Act
      final result = await analyzer.analyzeColoringImage(imageBytes);

      // Assert and Log
      expect(result, isNotNull);
      expect(result.colors, isNotEmpty);
      expect(result.contextDescriptions, isNotEmpty);

      // Log results for manual verification
      logger.i('Colors found: ${result.colors}');
      logger.i('Descriptions: ${result.contextDescriptions}');
    });
  });
}
