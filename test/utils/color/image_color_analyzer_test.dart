import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:chromaniac/core/constants.dart';
import 'package:chromaniac/services/openrouter_service.dart';
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
      AppLogger.enableTestMode();
      await AppLogger.init();
      if (!AppLogger.isInitialized) {
        throw StateError('Failed to initialize AppLogger');
      }
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
                'content': jsonEncode({
                  'colors': ['red', 'blue', 'green'],
                  'descriptions': ['Sky - blue', 'Tree - green', 'Flower - red']
                })
              }
            }
          ]
        }),
        200,
      ));
      analyzer = ImageColorAnalyzer(
        service: OpenRouterService(client: mockClient),);
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
      final emptyKeyMockClient = MockClient();
      when(emptyKeyMockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        jsonEncode({'error': 'Unauthorized'}),
        401,
      ));
      
      final analyzer = ImageColorAnalyzer(
        service: OpenRouterService(client: emptyKeyMockClient),
      );

      // Act & Assert
      expect(
        () => analyzer.analyzeColoringImage(imageBytes),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('API request failed with status: 401'),
        )),
      );
    });

    test('analyzeColoringImage throws exception on API error', () async {
      // Arrange
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      final errorMockClient = MockClient();
      when(errorMockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        jsonEncode({'error': 'Internal Server Error'}),
        500,
      ));

      final analyzer = ImageColorAnalyzer(
        service: OpenRouterService(client: errorMockClient),
      );

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
      
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': jsonEncode({
                  'colors': [],  // Empty array should be invalid
                  'descriptions': ['Valid description']
                })
              }
            }
          ]
        }),
        200,
      ));

      await expectLater(
        () => analyzer.analyzeColoringImage(imageBytes),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid response data structure'),
        )),
      );
    });

    test('sends correct request to OpenRouter API', () async {
      // Arrange
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      Uri.parse('https://openrouter.ai/api/v1/chat/completions');
      
      // Act
      await analyzer.analyzeColoringImage(imageBytes);
      
      // Assert
      final verification = verify(mockClient.post(
        any,
        headers: captureAnyNamed('headers'),
        body: captureAnyNamed('body'),
      ));
      
      verification.called(1);
      
      final captured = verification.captured;
      expect(captured.length, 2); // Should have headers and body
      
      final headers = captured[0] as Map<String, String>;
      final body = jsonDecode(captured[1] as String);
      
      // Verify headers
      expect(headers['Content-Type'], equals('application/json'));
      expect(headers['HTTP-Referer'], equals('https://github.com/mariepop13/chromaniac'));
      expect(headers['X-Title'], equals('Chromaniac Color Analyzer'));
      expect(headers['Authorization'], startsWith('Bearer '));
      
      // Verify body
      expect(body['model'], equals('google/gemini-flash-1.5'));
      expect(body['max_tokens'], equals(AppConstants.maxTokens));
      expect(body['temperature'], equals(AppConstants.temperature));
      expect(body['messages'], isA<List>());
      expect(body['messages'].length, equals(2));
      
      // Verify system message
      final systemMessage = body['messages'][0];
      expect(systemMessage['role'], equals('system'));
      expect(systemMessage['content'], contains('You are a color analysis expert'));
      
      // Verify user message
      final userMessage = body['messages'][1];
      expect(userMessage['role'], equals('user'));
      expect(userMessage['content'], isA<List>());
      expect(userMessage['content'].length, equals(2));
      expect(userMessage['content'][0]['type'], equals('text'));
      expect(userMessage['content'][1]['type'], equals('image_url'));
      expect(userMessage['content'][1]['image_url'], startsWith('data:image/png;base64,'));
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
