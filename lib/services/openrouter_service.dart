import 'dart:convert';
import 'dart:typed_data';
import 'package:chromaniac/utils/config/environment_config.dart';
import 'package:http/http.dart' as http;
import 'package:chromaniac/utils/logger/app_logger.dart';
import '../core/constants.dart';

class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const int _maxRetries = AppConstants.maxApiRetries;
  final http.Client _client;

  OpenRouterService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> analyzeImage(Uint8List imageBytes) async {
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
        final response = await _sendRequest(apiKey, imageBytes);
        
        // Don't retry on permanent failures
        if (response.statusCode == 401 || response.statusCode == 403) {
          final message = 'API request failed with status: ${response.statusCode}';
          AppLogger.e(message);
          throw Exception(message);
        }
        
        // Don't retry on server errors
        if (response.statusCode >= 500) {
          final message = 'API request failed with status: ${response.statusCode}';
          AppLogger.e(message);
          throw Exception(message);
        }
        
        // Only retry on temporary failures (429, 408, etc.)
        if (response.statusCode != 200) {
          final message = 'API request failed with status: ${response.statusCode}';
          AppLogger.e(message);
          if (attempt == _maxRetries) {
            throw Exception(message);
          }
          await Future.delayed(Duration(seconds: 1 << attempt));
          continue;
        }
        
        return _processResponse(response);
      } catch (e) {
        if (e is Exception && e.toString().contains('API request failed with status:')) {
          rethrow; // Don't retry status code errors
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

  Future<http.Response> _sendRequest(String apiKey, Uint8List imageBytes) async {
    final url = Uri.parse(_baseUrl);
    final base64Image = base64Encode(imageBytes);

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'HTTP-Referer': 'https://github.com/mariepop13/chromaniac',
      'X-Title': 'Chromaniac Color Analyzer',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'model': 'google/gemini-2.0-flash-exp:free',
      'messages': [
        {
          'role': 'system',
          'content': '''
            You are a color analysis expert. Analyze the image and provide color suggestions in the following strict JSON format:

            {
              "colors": [
                {
                  "object": "sky",
                  "colorName": "light blue",
                  "hexCode": "#87CEEB"
                },
                {
                  "object": "tree",
                  "colorName": "forest green",
                  "hexCode": "#228B22"
                }
              ]
            }

            Requirements:
            1. Each color suggestion must have:
               - object: the element or part of the image to color
               - colorName: natural language color name (like "purple", "light blue")
               - hexCode: valid hex color code starting with # (e.g., "#FF0000")
            2. Use standard web color hex codes
            3. Ensure hex codes match the natural color names
            4. Keep object and color names concise but descriptive
            5. Return at least 3 color suggestions
            6. Ensure all hex codes are valid 6-digit codes (e.g., #FF0000, not #F00)
          '''
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Analyze this coloring image and provide: 1) A list of main colors that would be appropriate for coloring the different elements, considering the context and objects shown. 2) Brief descriptions of the key elements and their suggested colors. Format the response as JSON with "colors" array.'
            },
            {
              'type': 'image_url',
              'image_url': 'data:image/png;base64,$base64Image',
            }
          ]
        }
      ],
      'max_tokens': AppConstants.maxTokens,
      'temperature': AppConstants.temperature,
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
      
      // Remove markdown code block if present
      content = content.replaceAll(RegExp(r'```json\n|\n```', multiLine: true), '');
      AppLogger.d('API Response content: $content');
      
      try {
        final result = jsonDecode(content);
        AppLogger.d('Parsed JSON result: $result');

        // Handle old format and convert to new format
        if (result['colors'] is List && result['descriptions'] is List) {
          final colors = result['colors'] as List;
          final descriptions = result['descriptions'] as List;
          
          // For old format, if either list is empty, treat as invalid structure
          if (colors.isEmpty || descriptions.isEmpty) {
            AppLogger.e('Invalid response data structure: empty colors or descriptions list');
            throw Exception('Invalid response data structure');
          }

          final transformedColors = <Map<String, String>>[];
          
          for (var i = 0; i < colors.length; i++) {
            final description = i < descriptions.length ? descriptions[i] : '';
            final parts = description.split(' - ');
            final object = parts.length > 1 ? parts[0] : 'element ${i + 1}';
            final colorName = colors[i];
            
            // Convert color name to hex code
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
        if (e.toString().contains('Invalid response data structure')) {
          rethrow;
        }
        AppLogger.e('Failed to parse content as JSON: $content');
        throw Exception('Failed to parse content as JSON: ${e.toString()}');
      }
    } catch (e) {
      if (e.toString().contains('Invalid response data structure')) {
        rethrow;
      }
      AppLogger.e('Failed to process API response: ${e.toString()}');
      throw Exception('Failed to process API response: ${e.toString()}');
    }
  }

  String _colorNameToHex(String colorName) {
    // Basic color mapping
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

    // Convert to lowercase and try to find an exact match
    final normalizedColor = colorName.toLowerCase();
    if (colorMap.containsKey(normalizedColor)) {
      return colorMap[normalizedColor]!;
    }

    // Try to find a partial match
    for (final entry in colorMap.entries) {
      if (normalizedColor.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default to a gray if no match is found
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
