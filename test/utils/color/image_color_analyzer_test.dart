import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chromaniac/utils/color/image_color_analyzer.dart';
import 'package:mockito/mockito.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';

import 'image_color_analyzer_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  final logger = Logger();
  group('ImageColorAnalyzer', () {
    late ImageColorAnalyzer analyzer;
    late MockClient mockClient;

    setUpAll(() async {
      await dotenv.load(fileName: 'test/.env.test');
      AppLogger.init();
    });

    setUp(() {
      mockClient = MockClient();
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': '{"colors": ["red", "blue", "green"], "descriptions": ["Sky - blue", "Tree - green", "Flower - red"]}'
              }
            }
          ]
        }),
        200,
      ));
      analyzer = ImageColorAnalyzer();
    });

    test('analyzeColoringImage returns ColorAnalysisResult on successful API call', () async {
      // Arrange
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]); // Sample image bytes

      // Act
      final result = await analyzer.analyzeColoringImage(imageBytes);

      // Assert
      expect(result, isA<ColorAnalysisResult>());
      expect(result.colors, containsAll(['red', 'blue', 'green']));
      expect(result.contextDescriptions, containsAll(['Sky - blue', 'Tree - green', 'Flower - red']));
    });

    test('analyzeColoringImage throws exception when API key is empty', () async {
      // Arrange
      await dotenv.load(fileName: 'test/.env.test');
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      final analyzer = ImageColorAnalyzer();

      // Act & Assert
      expect(
        () => analyzer.analyzeColoringImage(imageBytes),
        throwsException,
      );
    });

    test('analyzeColoringImage throws exception on API error', () async {
      // Arrange
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        'Error',
        500,
      ));

      // Act & Assert
      expect(
        () => analyzer.analyzeColoringImage(imageBytes),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('API request failed with status: 500'),
        )),
      );
    });

    test('analyzeColoringImage throws exception on invalid JSON response', () async {
      // Arrange
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      final mockResponse = {
        'choices': [
          {
            'message': {
              'content': 'Invalid JSON'
            }
          }
        ]
      };

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        jsonEncode(mockResponse),
        200,
      ));

      // Act & Assert
      expect(
        () => analyzer.analyzeColoringImage(imageBytes),
        throwsA(isA<Exception>()),
      );
    });

    test('analyzeColoringImage returns ColorAnalysisResult with real image', () async {
      // Arrange
      final File imageFile = File('test/sample/gaming_cats.PNG');
      final imageBytes = await imageFile.readAsBytes();

      // Act
      final result = await analyzer.analyzeColoringImage(imageBytes);

      // Assert
      expect(result, isA<ColorAnalysisResult>());
      expect(result.colors, isNotEmpty);  // We expect some colors
      expect(result.contextDescriptions, isNotEmpty);  // We expect some descriptions
      
      // Log the results for manual verification
      logger.i('Colors found: ${result.colors}');
      logger.i('Descriptions: ${result.contextDescriptions}');
    });

    test('analyzeColoringImage retries on invalid response format', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      var callCount = 0;

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': '{"colors": [], "descriptions": []}'
                  }
                }
              ]
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '{"colors": ["red"], "descriptions": ["Apple - red"]}'
                }
              }
            ]
          }),
          200,
        );
      });

      final result = await analyzer.analyzeColoringImage(imageBytes);
      
      expect(callCount, 2);
      expect(result.colors, ['red']);
      expect(result.contextDescriptions, ['Apple - red']);
    });

    test('analyzeColoringImage gives up after max retries', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      var callCount = 0;

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        callCount++;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '{"colors": [], "descriptions": []}'
                }
              }
            ]
          }),
          200,
        );
      });

      await expectLater(
        () => analyzer.analyzeColoringImage(imageBytes),
        throwsA(isA<Exception>()),
      );
      
      expect(callCount, 3); // Initial attempt + 2 retries
    });

    test('analyzeColoringImage validates response format', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      var callCount = 0;
      
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        callCount++;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '{"colors": [""], "descriptions": ["Valid description"]}'
                }
              }
            ]
          }),
          200,
        );
      });

      await expectLater(
        () => analyzer.analyzeColoringImage(imageBytes),
        throwsA(isA<Exception>()),
      );
      
      expect(callCount, 3); // Should retry twice after initial failure
    });

    test('sends correct request to OpenRouter API', () async {
      // Arrange
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      final expectedUrl = Uri.parse('https://openrouter.ai/api/v1');
      
      // Act
      try {
        await analyzer.analyzeColoringImage(imageBytes);
        
        // Assert
        final verification = verify(mockClient.post(
          expectedUrl,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        ));
        
        verification.called(1);
        
        final capturedHeaders = verification.captured[0] as Map<String, String>;
        final capturedBody = jsonDecode(verification.captured[1] as String);
        
        logger.i('Captured headers: $capturedHeaders');
        logger.i('Captured body: $capturedBody');
        
        expect(capturedHeaders['HTTP-Referer'], 'https://github.com/mariepop13/chromaniac');
        expect(capturedHeaders['X-Title'], 'Chromaniac Color Analyzer');
        expect(capturedHeaders['Content-Type'], 'application/json');
        expect(capturedHeaders['Authorization'], startsWith('Bearer '));
        
        expect(capturedBody['model'], equals('openai/gpt-4o-mini'));
        expect(capturedBody['messages'], hasLength(2));
        expect(capturedBody['messages'][1]['content'][1]['type'], equals('image'));
      } catch (e, stackTrace) {
logger.e('Test failed', error: e, stackTrace: stackTrace);        rethrow;
      }
    });

    test('handles successful OpenRouter response correctly', () async {
      // Arrange
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      final expectedResponse = {
        'choices': [
          {
            'message': {
              'content': '{"colors": ["blue", "green"], "descriptions": ["Sky - blue", "Tree - green"]}'
            }
          }
        ]
      };
      
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) {
        logger.i('Mocked response being returned');
        return Future.value(http.Response(jsonEncode(expectedResponse), 200));
      });
      
      try {
        // Act
        final result = await analyzer.analyzeColoringImage(imageBytes);
        logger.i('Received result: $result');
        
        // Assert
        expect(result.colors, containsAll(['blue', 'green']));
        expect(result.contextDescriptions, containsAll(['Sky - blue', 'Tree - green']));
      } catch (e, stackTrace) {
logger.e('Test failed', error: e, stackTrace: stackTrace);        rethrow;
      }
    });

    test('handles OpenRouter error response correctly', () async {
      // Arrange
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      final errorResponse = {
        'error': {
          'message': 'Invalid request',
          'type': 'invalid_request_error'
        }
      };
      
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) {
        logger.i('Returning error response');
        return Future.value(http.Response(jsonEncode(errorResponse), 400));
      });
      
      try {
        // Act & Assert
        await expectLater(
          () => analyzer.analyzeColoringImage(imageBytes),
          throwsA(isA<Exception>()),
        );
        logger.i('Error was correctly thrown and caught');
      } catch (e, stackTrace) {
logger.e('Test failed', error: e, stackTrace: stackTrace);        rethrow;
      }
    });
  });
}
