import 'dart:async';
import 'dart:io';
import 'package:chromaniac/services/openrouter_service.dart';
import 'package:chromaniac/utils/color/image_color_analyzer.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ImageColorAnalyzer Integration', () {
    late ImageColorAnalyzer analyzer;
    late OpenRouterService service;
    late File testImage;

    setUpAll(() async {
      await dotenv.load(fileName: '.env');
      AppLogger.enableTestMode();
      await AppLogger.init();
      
      service = OpenRouterService(client: http.Client());
      analyzer = ImageColorAnalyzer(service: service);
      testImage = File('test/sample/gaming_cats.PNG');
      
      if (!await testImage.exists()) {
        fail('Test image file not found at: ${testImage.path}');
      }
    });

    group('analyzeColoringImage', () {
      test('ImageColorAnalyzer_Integration_ShouldAnalyzeImageAndReturnValidColorDescriptions', () async {
        final imageBytes = await testImage.readAsBytes();
        
        ColorAnalysisResult? result;
        try {
          result = await analyzer.analyzeColoringImage(imageBytes).timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw TimeoutException('API call timed out after 60 seconds');
            },
          );
        } on TimeoutException catch (e) {
          fail('Test timed out: ${e.message}');
        }

        expect(
          result.colors, 
          isNotEmpty,
          reason: 'Color list should not be empty'
        );
        expect(
          result.contextDescriptions, 
          isNotEmpty,
          reason: 'Description list should not be empty'
        );
        
        for (final color in result.colors) {
          expect(
            color, 
            allOf([
              isNotEmpty,
              isA<String>(),
              matches(RegExp(r'^[a-zA-Z\s]+$')),
            ]),
            reason: 'Each color should be a non-empty string containing only letters and spaces'
          );
        }
        
        for (final description in result.contextDescriptions) {
          expect(
            description, 
            allOf([
              isNotEmpty,
              contains(' - '),
              matches(RegExp(r'^.+ - [a-zA-Z\s]+$')),
            ]),
            reason: 'Each description should be in format "element - color"'
          );
          
          final colorFromDescription = description.split(' - ').last.toLowerCase();
          expect(
            result.colors.map((c) => c.toLowerCase()).toList(),
            contains(colorFromDescription),
            reason: 'Each description should reference a color from the colors list'
          );
        }
      }, timeout: const Timeout(Duration(minutes: 2)));

      test('ImageColorAnalyzer_Integration_ShouldHandleLargeImageFileCorrectly', () async {
        final largeImage = File('test/sample/large_image.png');
        if (!await largeImage.exists()) {
          return;
        }

        final imageBytes = await largeImage.readAsBytes();
        ColorAnalysisResult? result;
        
        try {
          result = await analyzer.analyzeColoringImage(imageBytes).timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw TimeoutException('API call timed out after 60 seconds');
            },
          );
        } on TimeoutException catch (e) {
          fail('Test timed out: ${e.message}');
        }

        expect(
          result.colors, 
          isNotEmpty,
          reason: 'Should extract colors from large image'
        );
        expect(
          result.contextDescriptions, 
          isNotEmpty,
          reason: 'Should provide descriptions for large image'
        );
      }, timeout: const Timeout(Duration(minutes: 2)));

      test('ImageColorAnalyzer_Integration_ShouldHandleImageWithLimitedColorPalette', () async {
        final monochromeImage = File('test/sample/monochrome.png');
        if (!await monochromeImage.exists()) {
          return;
        }

        final imageBytes = await monochromeImage.readAsBytes();
        ColorAnalysisResult? result;
        
        try {
          result = await analyzer.analyzeColoringImage(imageBytes).timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw TimeoutException('API call timed out after 60 seconds');
            },
          );
        } on TimeoutException catch (e) {
          fail('Test timed out: ${e.message}');
        }

        expect(
          result.colors, 
          hasLength(lessThanOrEqualTo(3)),
          reason: 'Should detect limited color palette'
        );
        expect(
          result.contextDescriptions,
          isNotEmpty,
          reason: 'Should provide descriptions even for limited palette'
        );
      }, timeout: const Timeout(Duration(minutes: 2)));
    });
  });
}
