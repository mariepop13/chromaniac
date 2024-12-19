import 'dart:convert';
import 'dart:typed_data';
import 'package:chromaniac/core/constants.dart';
import 'package:chromaniac/services/openrouter_service.dart';
import 'package:chromaniac/utils/color/image_color_analyzer.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'image_color_analyzer_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('ImageColorAnalyzer', () {
    late ImageColorAnalyzer analyzer;
    late MockClient mockClient;
    final sampleImageBytes = Uint8List.fromList([1, 2, 3, 4]);

    setUpAll(() async {
      await dotenv.load(fileName: 'test/.env.test');
      AppLogger.enableTestMode();
      await AppLogger.init();
    });

    setUp(() {
      mockClient = MockClient();
      analyzer = ImageColorAnalyzer(service: OpenRouterService(client: mockClient));
    });

    group('analyzeColoringImage', () {
      test('ImageColorAnalyzer_AnalyzeColoringImage_ShouldExtractColorAnalysis', () async {
        _setupSuccessfulResponse(mockClient);
        final result = await analyzer.analyzeColoringImage(sampleImageBytes);

        expect(result.colorAnalysis, hasLength(3));
        
        final firstColor = result.colorAnalysis[0];
        expect(firstColor['object'], equals('sky'));
        expect(firstColor['colorName'], equals('light blue'));
        expect(firstColor['hexCode'], equals('#87CEEB'));
      });

      test('ImageColorAnalyzer_AnalyzeColoringImage_ShouldThrowErrorOnUnauthorized', () async {
        _setupUnauthorizedResponse(mockClient);

        expect(
          () => analyzer.analyzeColoringImage(sampleImageBytes),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API request failed with status: 401'),
          )),
        );
      });

      test('ImageColorAnalyzer_AnalyzeColoringImage_ShouldThrowErrorOnServerError', () async {
        _setupServerErrorResponse(mockClient);

        expect(
          () => analyzer.analyzeColoringImage(sampleImageBytes),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API request failed with status: 500'),
          )),
        );
      });

      test('ImageColorAnalyzer_AnalyzeColoringImage_ShouldThrowErrorOnInvalidDataFormat', () async {
        _setupInvalidFormatResponse(mockClient);

        expect(
          () => analyzer.analyzeColoringImage(sampleImageBytes),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to process API response'),
          )),
        );
      });

      test('ImageColorAnalyzer_AnalyzeColoringImage_ShouldSendProperlyFormattedRequestToAPI', () async {
        _setupSuccessfulResponse(mockClient);
        await analyzer.analyzeColoringImage(sampleImageBytes);
        _verifyRequestFormat(mockClient);
      });
    });
  });
}

void _setupSuccessfulResponse(MockClient mockClient) {
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
                  'object': 'sky',
                  'colorName': 'light blue',
                  'hexCode': '#87CEEB'
                },
                {
                  'object': 'tree',
                  'colorName': 'forest green',
                  'hexCode': '#228B22'
                },
                {
                  'object': 'flower',
                  'colorName': 'bright red',
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

void _setupUnauthorizedResponse(MockClient mockClient) {
  when(mockClient.post(
    any,
    headers: anyNamed('headers'),
    body: anyNamed('body'),
  )).thenAnswer((_) async => http.Response('Unauthorized', 401));
}

void _setupServerErrorResponse(MockClient mockClient) {
  when(mockClient.post(
    any,
    headers: anyNamed('headers'),
    body: anyNamed('body'),
  )).thenAnswer((_) async => http.Response('Internal Server Error', 500));
}

void _setupInvalidFormatResponse(MockClient mockClient) {
  when(mockClient.post(
    any,
    headers: anyNamed('headers'),
    body: anyNamed('body'),
  )).thenAnswer((_) async => http.Response(
    jsonEncode({'invalid': 'format'}),
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
  expect(
    headers['HTTP-Referer'], 
    equals('https://github.com/mariepop13/chromaniac')
  );
  expect(headers['X-Title'], equals('Chromaniac Color Analyzer'));
  expect(headers['Authorization'], startsWith('Bearer '));

  expect(body['model'], equals('google/gemini-flash-1.5'));
  expect(body['max_tokens'], equals(AppConstants.maxTokens));
  expect(body['temperature'], equals(AppConstants.temperature));
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
  expect(
    userMessage['content'][1]['image_url'], 
    startsWith('data:image/png;base64,')
  );
}
