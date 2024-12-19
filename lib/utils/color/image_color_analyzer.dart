import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/environment_config.dart';

class ColorAnalysisResult {
  final List<String> colors;
  final List<String> contextDescriptions;

  ColorAnalysisResult({
    required this.colors,
    required this.contextDescriptions,
  });
}

class ImageColorAnalyzer {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';

  const ImageColorAnalyzer();

  Future<ColorAnalysisResult> analyzeColoringImage(Uint8List imageBytes) async {
    final String apiKey = EnvironmentConfig.openRouterApiKey;
    if (apiKey.isEmpty) {
      throw Exception('OpenRouter API key not configured. Please check your .env file.');
    }

    try {
      final String base64Image = base64Encode(imageBytes);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/your-repo', // Replace with your app's URL
        },
        body: jsonEncode({
          'model': 'gpt-4-vision-preview',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Analyze this coloring image and provide: 1) A list of main colors that would be appropriate for coloring the different elements, considering the context and objects shown. 2) Brief descriptions of the key elements and their suggested colors. Format the response as JSON with "colors" and "descriptions" arrays.',
                },
                {
                  'type': 'image',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final String content = data['choices'][0]['message']['content'];
      final Map<String, dynamic> parsedContent = jsonDecode(content);

      return ColorAnalysisResult(
        colors: List<String>.from(parsedContent['colors']),
        contextDescriptions: List<String>.from(parsedContent['descriptions']),
      );
    } catch (e) {
      throw Exception('Error analyzing image: $e');
    }
  }
}
