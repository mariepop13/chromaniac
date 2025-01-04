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
      // Load environment variables from root .env
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
      test('ImageColorAnalyzer_Integration_ShouldAnalyzeImageAndReturnValidColorAnalysis', () async {
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
        } on Exception catch (e) {
          // Check for specific authentication error
          if (e.toString().contains('401')) {
            AppLogger.w('OpenRouter API authentication failed. Please check your API key.');
            AppLogger.w('Skipping test due to authentication error.');
            return;
          }
          rethrow;
        }

        expect(
          result.colorAnalysis, 
          isNotEmpty,
          reason: 'Color analysis should not be empty'
        );
        
        for (final colorInfo in result.colorAnalysis) {
          expect(
            colorInfo['object'], 
            allOf([
              isNotNull,
              isNotEmpty,
              isA<String>(),
            ]),
            reason: 'Each color analysis should have a valid object field'
          );

          expect(
            colorInfo['colorName'], 
            allOf([
              isNotNull,
              isNotEmpty,
              isA<String>(),
              matches(RegExp(r'^[a-zA-Z\s-]+$')),
            ]),
            reason: 'Each color analysis should have a valid color name'
          );

          expect(
            colorInfo['hexCode'], 
            allOf([
              isNotNull,
              isNotEmpty,
              isA<String>(),
              matches(RegExp(r'^#[0-9A-Fa-f]{6}$')),
            ]),
            reason: 'Each color analysis should have a valid hex code'
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
        } on Exception catch (e) {
          // Check for specific authentication error
          if (e.toString().contains('401')) {
            AppLogger.w('OpenRouter API authentication failed. Please check your API key.');
            AppLogger.w('Skipping test due to authentication error.');
            return;
          }
          rethrow;
        }

        expect(
          result.colorAnalysis, 
          isNotEmpty,
          reason: 'Should extract colors from large image'
        );

        for (final colorInfo in result.colorAnalysis) {
          expect(colorInfo['object'], isNotNull);
          expect(colorInfo['colorName'], 
            allOf([
              isNotNull,
              matches(RegExp(r'^[a-zA-Z\s-]+$'))
            ])
          );
          expect(colorInfo['hexCode'], matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
        }
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
        } on Exception catch (e) {
          // Check for specific authentication error
          if (e.toString().contains('401')) {
            AppLogger.w('OpenRouter API authentication failed. Please check your API key.');
            AppLogger.w('Skipping test due to authentication error.');
            return;
          }
          rethrow;
        }

        expect(
          result.colorAnalysis, 
          hasLength(lessThanOrEqualTo(3)),
          reason: 'Should detect limited color palette'
        );

        for (final colorInfo in result.colorAnalysis) {
          expect(colorInfo['object'], isNotNull);
          expect(colorInfo['colorName'], 
            allOf([
              isNotNull,
              matches(RegExp(r'^[a-zA-Z\s-]+$'))
            ])
          );
          expect(colorInfo['hexCode'], matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
        }
      }, timeout: const Timeout(Duration(minutes: 2)));
    });
  });
}
