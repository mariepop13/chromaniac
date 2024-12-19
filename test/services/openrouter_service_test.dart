import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:chromaniac/services/openrouter_service.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:chromaniac/utils/config/environment_config.dart';

import '../utils/test_utils.dart';
import '../utils/test_utils.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('OpenRouterService', () {
    late OpenRouterService service;
    late MockClient mockClient;

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
        TestUtils.mockSuccessfulColorResponse(mockClient);

        final result = await service.analyzeImage(TestUtils.sampleImageBytes);

        final colors = result['colors'] as List;
        expect(colors.length, 3);

        expect(colors[0]['object'], 'sky');
        expect(colors[0]['colorName'], 'light blue');
        expect(colors[0]['hexCode'], '#87CEEB');

        expect(colors[1]['object'], 'grass');
        expect(colors[1]['colorName'], 'light green');
        expect(colors[1]['hexCode'], '#90EE90');

        expect(colors[2]['object'], 'sun');
        expect(colors[2]['colorName'], 'yellow');
        expect(colors[2]['hexCode'], '#FFD700');

        TestUtils.verifyRequestFormat(mockClient);
      });

      test('OpenRouter_AnalyzeImage_ShouldThrowOnEmptyImage', () {
        expect(
          () => service.analyzeImage(Uint8List(0)),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Image data is empty'),
          )),
        );
      });

      test('OpenRouter_AnalyzeImage_ShouldHandleUnauthorizedError', () async {
        TestUtils.mockUnauthorizedResponse(mockClient);

        expect(
          () => service.analyzeImage(TestUtils.sampleImageBytes),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API request failed with status: 401'),
          )),
        );
      });

      test('OpenRouter_AnalyzeImage_ShouldHandleServerError', () async {
        TestUtils.mockServerErrorResponse(mockClient);

        expect(
          () => service.analyzeImage(TestUtils.sampleImageBytes),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('API request failed with status: 500'),
          )),
        );
      });

      test('OpenRouter_AnalyzeImage_ShouldHandleInvalidResponse', () async {
        TestUtils.mockInvalidFormatResponse(mockClient);

        expect(
          () => service.analyzeImage(TestUtils.sampleImageBytes),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to process API response'),
          )),
        );
      });
    });
  });
}
