import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chromaniac/services/openrouter_service.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:chromaniac/utils/config/environment_config.dart';

import 'openrouter_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('OpenRouterService', () {
    late OpenRouterService service;
    late MockClient mockClient;
    final sampleImageBytes = Uint8List.fromList([1, 2, 3, 4]);

    setUpAll(() async {
      AppLogger.enableTestMode();
      await AppLogger.init();
      await EnvironmentConfig.initialize();
    });

    setUp(() {
      mockClient = MockClient();
      service = OpenRouterService(client: mockClient);
    });

    group('analyzeImage', () {
      test('OpenRouter_AnalyzeImage_ShouldProcessValidResponse', () async {
        // Arrange
        _mockSuccessfulResponse(mockClient);

        // Act
        final result = await service.analyzeImage(sampleImageBytes);

        // Assert
        final colors = result['colors'] as List;
        expect(colors.length, 3);

        // Verify first color entry
        expect(colors[0]['object'], 'Sky');
        expect(colors[0]['colorName'], 'blue');
        expect(colors[0]['hexCode'], '#0000FF');

        // Verify second color entry
        expect(colors[1]['object'], 'Tree');
        expect(colors[1]['colorName'], 'green');
        expect(colors[1]['hexCode'], '#00FF00');

        // Verify third color entry
        expect(colors[2]['object'], 'Flower');
        expect(colors[2]['colorName'], 'red');
        expect(colors[2]['hexCode'], '#FF0000');
      });

      test('OpenRouter_AnalyzeImage_ShouldThrowExceptionOnEmptyImage',
          () async {
        // Act & Assert
        await expectLater(
          () => service.analyzeImage(Uint8List(0)),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Image data is empty'),
          )),
        );
      });

      test('OpenRouter_AnalyzeImage_ShouldThrowExceptionOnServerError',
          () async {
        // Arrange
        _mockServerErrorResponse(mockClient);

        // Act & Assert
        await expectLater(
          () => service.analyzeImage(sampleImageBytes),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API request failed with status: 500'),
          )),
        );
      });

      test(
          'OpenRouter_AnalyzeImage_ShouldThrowExceptionOnInvalidResponseFormat',
          () async {
        // Arrange
        _mockInvalidFormatResponse(mockClient);

        // Act & Assert
        await expectLater(
          () => service.analyzeImage(sampleImageBytes),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid response data structure'),
          )),
        );
      });

      test('OpenRouter_AnalyzeImage_ShouldThrowOnEmptyResponse', () async {
        // Arrange
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(
                  jsonEncode({
                    'choices': [
                      {
                        'message': {
                          'content': jsonEncode({
                            'colors': [],
                            'descriptions': ['Valid description']
                          })
                        }
                      }
                    ]
                  }),
                  200,
                ));

        // Act & Assert
        await expectLater(
          () => service.analyzeImage(sampleImageBytes),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid response data structure'),
          )),
        );
      });

      test('OpenRouter_AnalyzeImage_ShouldSendCorrectRequestFormat', () async {
        // Arrange
        _mockSuccessfulResponse(mockClient);

        // Act
        await service.analyzeImage(sampleImageBytes);

        // Assert
        _verifyRequestFormat(mockClient);
      });
    });
  });
}

void _mockSuccessfulResponse(MockClient mockClient) {
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
                  'colors': [
                    {
                      'object': 'Sky',
                      'colorName': 'blue',
                      'hexCode': '#0000FF'
                    },
                    {
                      'object': 'Tree',
                      'colorName': 'green',
                      'hexCode': '#00FF00'
                    },
                    {
                      'object': 'Flower',
                      'colorName': 'red',
                      'hexCode': '#FF0000'
                    }
                  ]
                })
              }
            }
          ]
        }),
        200,
      ));
}

void _mockServerErrorResponse(MockClient mockClient) {
  when(mockClient.post(
    any,
    headers: anyNamed('headers'),
    body: anyNamed('body'),
  )).thenAnswer((_) async => http.Response(
        jsonEncode({'error': 'Internal Server Error'}),
        500,
      ));
}

void _mockInvalidFormatResponse(MockClient mockClient) {
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
                  'colors': [],
                  'descriptions': ['Valid description']
                })
              }
            }
          ]
        }),
        200,
      ));
}

void _verifyRequestFormat(MockClient mockClient) {
  final verification = verify(mockClient.post(
    any,
    headers: captureAnyNamed('headers'),
    body: captureAnyNamed('body'),
  ));

  verification.called(1);

  final captured = verification.captured;
  expect(captured.length, 2);

  final headers = captured[0] as Map<String, String>;
  final body = jsonDecode(captured[1] as String);

  expect(headers['Content-Type'], equals('application/json'));
  expect(headers['HTTP-Referer'],
      equals('https://github.com/mariepop13/chromaniac'));
  expect(headers['X-Title'], equals('Chromaniac Color Analyzer'));
  expect(headers['Authorization'], startsWith('Bearer '));

  expect(body['model'], equals('google/gemini-flash-1.5'));
  expect(body['messages'], isA<List>());
  expect(body['messages'].length, equals(2));

  final systemMessage = body['messages'][0];
  expect(systemMessage['role'], equals('system'));
  expect(systemMessage['content'], contains('You are a color analysis expert'));

  final userMessage = body['messages'][1];
  expect(userMessage['role'], equals('user'));
  expect(userMessage['content'], isA<List>());
  expect(userMessage['content'].length, equals(2));
  expect(userMessage['content'][0]['type'], equals('text'));
  expect(userMessage['content'][1]['type'], equals('image_url'));
  expect(userMessage['content'][1]['image_url'],
      startsWith('data:image/png;base64,'));
}
