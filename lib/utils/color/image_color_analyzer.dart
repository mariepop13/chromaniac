import 'dart:typed_data';
import 'package:chromaniac/services/openrouter_service.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';

class ColorAnalysisResult {
  final List<Map<String, String>> colorAnalysis;

  ColorAnalysisResult({
    required this.colorAnalysis,
  });

  @override
  String toString() => 'ColorAnalysisResult(colorAnalysis: $colorAnalysis)';
}

class ImageColorAnalyzer {
  final OpenRouterService _service;

  ImageColorAnalyzer({OpenRouterService? service})
      : _service = service ?? OpenRouterService();

  Future<ColorAnalysisResult> analyzeColoringImage(Uint8List imageBytes) async {
    // Prevent initial analysis without a theme
    throw Exception('Initial color analysis is not allowed without a theme');
  }

  Future<ColorAnalysisResult> analyzeColoringImageWithTheme(
    Uint8List imageBytes,
    String theme,
  ) async {
    try {
      AppLogger.d('Starting color analysis with theme: $theme');
      final result = await _service.analyzeImage(imageBytes, theme);
      AppLogger.d('Got API result: $result');

      final colorAnalysis = List<Map<String, String>>.from(
        (result['colors'] as List).map((color) => {
              'object': color['object'] as String,
              'colorName': color['colorName'] as String,
              'hexCode': color['hexCode'] as String,
            }),
      );
      AppLogger.d('Processed color analysis: $colorAnalysis');

      return ColorAnalysisResult(colorAnalysis: colorAnalysis);
    } catch (e, stackTrace) {
      AppLogger.e('Error analyzing colors', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
