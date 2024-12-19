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
        return _processResponse(response);
      } catch (e) {
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
      'model': 'google/gemini-flash-1.5',
      'messages': [
        {
          'role': 'system',
          'content': '''
            You are a color analysis expert. Analyze the image and provide color suggestions in the following strict JSON format:

            {
              "colors": ["color1", "color2", "color3"],
              "descriptions": ["description1", "description2"]
            }

            Keep descriptions concise and focus on key elements and their suggested colors.
          '''
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Analyze this coloring image and provide: 1) A list of main colors that would be appropriate for coloring the different elements, considering the context and objects shown. 2) Brief descriptions of the key elements and their suggested colors. Format the response as JSON with "colors" and "descriptions" arrays.'
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
      
      try {
        final result = jsonDecode(content);
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
      AppLogger.e('Failed to process API response: ${e.toString()}');
      throw Exception('Failed to process API response: ${e.toString()}');
    }
  }

  bool _validateResponse(Map<String, dynamic> result) {
    return result.containsKey('colors') &&
        result.containsKey('descriptions') &&
        result['colors'] is List &&
        result['descriptions'] is List &&
        (result['colors'] as List).isNotEmpty &&
        (result['descriptions'] as List).isNotEmpty;
  }
}
