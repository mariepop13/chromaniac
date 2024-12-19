import 'package:chromaniac/services/openrouter_service.dart';
import 'package:chromaniac/utils/color/image_color_analyzer.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';

import '../test_utils.dart';
import '../test_utils.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late ImageColorAnalyzer analyzer;
  late MockClient mockClient;

  setUpAll(() async {
    await dotenv.load(fileName: 'test/.env.test');
    AppLogger.enableTestMode();
    await AppLogger.init();
  });

  setUp(() {
    mockClient = MockClient();
    analyzer = ImageColorAnalyzer(service: OpenRouterService(client: mockClient));
  });

  group('ImageColorAnalyzer - Success Cases', () {
    test('extractColorAnalysis_WithValidImage_ReturnsCorrectColorData', () async {
      TestUtils.mockSuccessfulColorResponse(mockClient);

      final result = await analyzer.analyzeColoringImage(TestUtils.sampleImageBytes);

      expect(result.colorAnalysis, hasLength(3));
      expect(result.colorAnalysis[0]['object'], equals('sky'));
      expect(result.colorAnalysis[0]['colorName'], equals('light blue'));
      expect(result.colorAnalysis[0]['hexCode'], equals('#87CEEB'));
      
      TestUtils.verifyRequestFormat(mockClient);
    });
  });

  group('ImageColorAnalyzer - Error Cases', () {
    test('analyzeColoringImage_WithUnauthorizedAccess_ThrowsException', () async {
      TestUtils.mockUnauthorizedResponse(mockClient);

      expect(
        () => analyzer.analyzeColoringImage(TestUtils.sampleImageBytes),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('API request failed with status: 401'),
        )),
      );
    });

    test('analyzeColoringImage_WithServerError_ThrowsException', () async {
      TestUtils.mockServerErrorResponse(mockClient);

      expect(
        () => analyzer.analyzeColoringImage(TestUtils.sampleImageBytes),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('API request failed with status: 500'),
        )),
      );
    });

    test('analyzeColoringImage_WithInvalidResponse_ThrowsException', () async {
      TestUtils.mockInvalidFormatResponse(mockClient);

      expect(
        () => analyzer.analyzeColoringImage(TestUtils.sampleImageBytes),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to process API response'),
        )),
      );
    });
  });
}
