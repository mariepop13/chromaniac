import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chromaniac/utils/color/image_color_analyzer.dart';
import 'package:chromaniac/services/openrouter_service.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';

// Import generated mocks
import 'image_color_analyzer_test.mocks.dart';

// Generate mocks
@GenerateMocks([OpenRouterService])
void main() {
  setUpAll(() {
    // Initialize AppLogger for tests
    AppLogger.enableTestMode();
  });

  group('ImageColorAnalyzer', () {
    late MockOpenRouterService mockService;
    late ImageColorAnalyzer analyzer;

    setUp(() {
      mockService = MockOpenRouterService();
      analyzer = ImageColorAnalyzer(service: mockService);
    });

    test('Constructor creates instance with default service', () {
      final defaultAnalyzer = ImageColorAnalyzer();
      expect(defaultAnalyzer, isNotNull);
    });

    test('analyzeColoringImage successfully processes color analysis', () async {
      // Prepare mock image bytes
      final mockImageBytes = Uint8List.fromList([1, 2, 3, 4]);

      // Prepare mock API response
      final mockApiResponse = {
        'colors': [
          {
            'object': 'Sky',
            'colorName': 'Blue',
            'hexCode': '#0000FF'
          },
          {
            'object': 'Grass',
            'colorName': 'Green',
            'hexCode': '#00FF00'
          }
        ]
      };

      // Setup mock service to return predefined response
      when(mockService.analyzeImage(any)).thenAnswer(
        (_) async => mockApiResponse
      );

      // Call method
      final result = await analyzer.analyzeColoringImage(mockImageBytes);

      // Verify result
      expect(result, isA<ColorAnalysisResult>());
      expect(result.colorAnalysis, hasLength(2));
      
      // Check first color analysis
      expect(result.colorAnalysis[0]['object'], 'Sky');
      expect(result.colorAnalysis[0]['colorName'], 'Blue');
      expect(result.colorAnalysis[0]['hexCode'], '#0000FF');

      // Check second color analysis
      expect(result.colorAnalysis[1]['object'], 'Grass');
      expect(result.colorAnalysis[1]['colorName'], 'Green');
      expect(result.colorAnalysis[1]['hexCode'], '#00FF00');

      // Verify service was called with correct image bytes
      verify(mockService.analyzeImage(mockImageBytes)).called(1);
    });

    test('analyzeColoringImage handles empty color list', () async {
      // Prepare mock image bytes
      final mockImageBytes = Uint8List.fromList([1, 2, 3, 4]);

      // Prepare mock API response with empty colors
      final mockApiResponse = {
        'colors': []
      };

      // Setup mock service to return predefined response
      when(mockService.analyzeImage(any)).thenAnswer(
        (_) async => mockApiResponse
      );

      // Call method
      final result = await analyzer.analyzeColoringImage(mockImageBytes);

      // Verify result
      expect(result, isA<ColorAnalysisResult>());
      expect(result.colorAnalysis, isEmpty);
    });

    test('analyzeColoringImage handles 401 Unauthorized error', () async {
      // Prepare mock image bytes
      final mockImageBytes = Uint8List.fromList([1, 2, 3, 4]);

      // Setup mock service to throw a 401 unauthorized exception
      when(mockService.analyzeImage(any)).thenThrow(
        Exception('API request failed with status: 401')
      );

      // Expect the method to rethrow the exception with a specific message
      expect(
        () => analyzer.analyzeColoringImage(mockImageBytes), 
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(), 
            'error message', 
            contains('401')
          )
        )
      );
    });

    test('analyzeColoringImage rethrows other service exceptions', () async {
      // Prepare mock image bytes
      final mockImageBytes = Uint8List.fromList([1, 2, 3, 4]);

      // Setup mock service to throw a generic exception
      when(mockService.analyzeImage(any)).thenThrow(
        Exception('Generic API Error')
      );

      // Expect the method to rethrow the exception
      expect(
        () => analyzer.analyzeColoringImage(mockImageBytes), 
        throwsA(isA<Exception>())
      );
    });

    test('ColorAnalysisResult toString method', () {
      final result = ColorAnalysisResult(colorAnalysis: [
        {
          'object': 'Sky',
          'colorName': 'Blue',
          'hexCode': '#0000FF'
        }
      ]);

      expect(
        result.toString(), 
        'ColorAnalysisResult(colorAnalysis: [{object: Sky, colorName: Blue, hexCode: #0000FF}])'
      );
    });
  });
}
