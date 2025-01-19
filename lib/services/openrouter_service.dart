import 'dart:convert';
import 'dart:typed_data';
import 'package:chromaniac/utils/config/environment_config.dart';
import 'package:http/http.dart' as http;
import 'package:chromaniac/utils/logger/app_logger.dart';
import '../core/constants.dart';

class OpenRouterService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const int _maxRetries = AppConstants.maxApiRetries;
  final http.Client _client;

  OpenRouterService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> analyzeImage(Uint8List imageBytes,
      [String? theme]) async {
    if (imageBytes.isEmpty) {
      const message = 'Image data is empty';
      AppLogger.e(message);
      throw Exception(message);
    }

    final String apiKey = EnvironmentConfig.openRouterApiKey;
    if (apiKey.isEmpty) {
      const message = 'OpenRouter API key not configured';
      AppLogger.e(message);
      throw Exception(message);
    }

    Exception? lastError;
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final String selectedTheme = theme ?? 'neutral';
        final response = await _sendRequest(apiKey, imageBytes, selectedTheme);

        if (response.statusCode == 401 || response.statusCode == 403) {
          final message =
              'API request failed with status: ${response.statusCode}';
          AppLogger.e(message);
          throw Exception(message);
        }

        if (response.statusCode >= 500) {
          final message =
              'API request failed with status: ${response.statusCode}';
          AppLogger.e(message);
          throw Exception(message);
        }

        if (response.statusCode != 200) {
          final message =
              'API request failed with status: ${response.statusCode}';
          AppLogger.e(message);
          if (attempt == _maxRetries) {
            throw Exception(message);
          }
          await Future.delayed(Duration(seconds: 1 << attempt));
          continue;
        }

        return _processResponse(response);
      } catch (e) {
        if (e is Exception &&
            e.toString().contains('API request failed with status:')) {
          rethrow;
        }
        lastError = e is Exception ? e : Exception(e.toString());
        if (attempt == _maxRetries) {
          AppLogger.e('Failed after $_maxRetries retries', error: lastError);
          rethrow;
        }
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }
    throw lastError ?? Exception('Unknown error');
  }

  Future<http.Response> _sendRequest(
      String apiKey, Uint8List imageBytes, String theme) async {
    final url = Uri.parse(_baseUrl);
    final base64Image = base64Encode(imageBytes);

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'HTTP-Referer': 'https://github.com/mariepop13/chromaniac',
      'X-Title': 'Chromaniac Color Analyzer',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'model': 'openai/gpt-4o-mini',
      'messages': [
        {
          'role': 'system',
          'content': '''
            You are an expert color palette designer focusing on the "$theme" theme.

            Theme Interpretation Guidelines:
            - Deeply analyze the image through the lens of "$theme"
            - Select colors that embody the essence and mood of "$theme"
            - Prioritize color harmony and thematic coherence

            Theme-Specific Color Selection Criteria:
            - Pastel: Soft, muted, delicate color palette
            - Noel (Christmas): Rich reds, greens, golds, winter whites
            - Summer: Bright, vibrant, warm, energetic colors
            - Autumn: Warm earth tones, deep oranges, browns, burgundies
            - Spring: Soft, fresh, light colors with floral undertones

            Strict JSON Output Format:
            {
              "colors": [
                {
                  "object": "sky",
                  "colorName": "light blue",
                  "hexCode": "#87CEEB"
                }
              ]
            }

            Requirements:
            1. Minimum 3, maximum 5 color suggestions
            2. Each color must:
               - Represent a distinct image element
               - Match the "$theme" aesthetic
               - Have a descriptive color name
               - Include a precise hex color code
            3. Ensure color diversity and thematic consistency
          '''
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  'Analyze this image and generate a color palette that perfectly captures the "$theme" theme. Focus on color selection that reflects the theme\'s mood, energy, and visual essence.'
            },
            {
              'type': 'image_url',
              'image_url': 'data:image/png;base64,$base64Image',
            }
          ]
        }
      ],
      'max_tokens': AppConstants.maxTokens,
      'temperature': 0.7, // Slightly higher for creative theme interpretation
    });

    return await _client.post(url, headers: headers, body: body);
  }

  Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final responseData = jsonDecode(response.body);

      if (responseData['choices'] == null ||
          responseData['choices'].isEmpty ||
          responseData['choices'][0]['message'] == null ||
          responseData['choices'][0]['message']['content'] == null) {
        throw Exception('Invalid API response structure');
      }

      String content = responseData['choices'][0]['message']['content'];

      // Extract JSON from content by finding the first '{' and last '}'
      final startIndex = content.indexOf('{');
      final endIndex = content.lastIndexOf('}') + 1;

      if (startIndex == -1 || endIndex == 0) {
        throw Exception('No valid JSON found in response');
      }

      content = content.substring(startIndex, endIndex);
      AppLogger.d('Extracted JSON content: $content');

      try {
        final result = jsonDecode(content);
        AppLogger.d('Parsed JSON result: $result');

        if (result['colors'] is List && result['descriptions'] is List) {
          final colors = result['colors'] as List;
          final descriptions = result['descriptions'] as List;

          if (colors.isEmpty || descriptions.isEmpty) {
            AppLogger.e(
                'Invalid response data structure: empty colors or descriptions list');
            throw Exception('Invalid response data structure');
          }

          final transformedColors = <Map<String, String>>[];

          for (var i = 0; i < colors.length; i++) {
            final description = i < descriptions.length ? descriptions[i] : '';
            final parts = description.split(' - ');
            final object = parts.length > 1 ? parts[0] : 'element ${i + 1}';
            final colorName = colors[i];

            final hexCode = _colorNameToHex(colorName);

            transformedColors.add({
              'object': object,
              'colorName': colorName,
              'hexCode': hexCode,
            });
          }

          return {
            'colors': transformedColors,
          };
        }

        if (!_validateResponse(result)) {
          AppLogger.e('Invalid response data structure: $result');
          throw Exception('Invalid response data structure');
        }
        return result;
      } catch (e) {
        AppLogger.e('Failed to parse content as JSON: $content');
        throw Exception('Failed to parse content as JSON: ${e.toString()}');
      }
    } catch (e) {
      final errorMsg = 'Failed to process API response: ${e.toString()}';
      AppLogger.e(errorMsg, error: e, stackTrace: StackTrace.current);
      throw Exception('$errorMsg. Please check debug logs for details.');
    }
  }

  String _colorNameToHex(String colorName) {
    final colorMap = {
      'red': '#FF0000',
      'green': '#00FF00',
      'blue': '#0000FF',
      'yellow': '#FFFF00',
      'purple': '#800080',
      'orange': '#FFA500',
      'pink': '#FFC0CB',
      'brown': '#A52A2A',
      'gray': '#808080',
      'black': '#000000',
      'white': '#FFFFFF',
      'light blue': '#87CEEB',
      'dark blue': '#00008B',
      'light green': '#90EE90',
      'dark green': '#006400',
      'forest green': '#228B22',
      'bright red': '#FF0000',
      'dark red': '#8B0000',
    };

    final normalizedColor = colorName.toLowerCase();
    if (colorMap.containsKey(normalizedColor)) {
      return colorMap[normalizedColor]!;
    }

    for (final entry in colorMap.entries) {
      if (normalizedColor.contains(entry.key)) {
        return entry.value;
      }
    }

    return '#808080';
  }

  bool _validateResponse(Map<String, dynamic> result) {
    if (!result.containsKey('colors')) {
      AppLogger.e('Response missing "colors" field');
      return false;
    }
    if (result['colors'] is! List) {
      AppLogger.e('Response "colors" field is not a list');
      return false;
    }
    if ((result['colors'] as List).isEmpty) {
      AppLogger.e('Response "colors" list is empty');
      return false;
    }

    final colors = result['colors'] as List;
    for (final color in colors) {
      if (color is! Map) {
        AppLogger.e('Color entry is not a map: $color');
        return false;
      }
      if (!color.containsKey('object')) {
        AppLogger.e('Color missing "object" field: $color');
        return false;
      }
      if (!color.containsKey('colorName')) {
        AppLogger.e('Color missing "colorName" field: $color');
        return false;
      }
      if (!color.containsKey('hexCode')) {
        AppLogger.e('Color missing "hexCode" field: $color');
        return false;
      }
    }
    return true;
  }
}
