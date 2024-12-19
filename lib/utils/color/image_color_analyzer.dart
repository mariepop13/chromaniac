import 'dart:typed_data';
import 'package:chromaniac/services/openrouter_service.dart';

class ColorAnalysisResult {
  final List<String> colors;
  final List<String> contextDescriptions;

  ColorAnalysisResult({
    required this.colors,
    required this.contextDescriptions,
  });

  @override
  String toString() =>
      'ColorAnalysisResult(colors: $colors, descriptions: $contextDescriptions)';
}

class ImageColorAnalyzer {
  final OpenRouterService _service;

  ImageColorAnalyzer({OpenRouterService? service})
      : _service = service ?? OpenRouterService();

  Future<ColorAnalysisResult> analyzeColoringImage(Uint8List imageBytes) async {
    final result = await _service.analyzeImage(imageBytes);

    return ColorAnalysisResult(
      colors: List<String>.from(result['colors']),
      contextDescriptions: List<String>.from(result['descriptions']),
    );
  }
}
