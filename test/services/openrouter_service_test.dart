import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chromaniac/services/openrouter_service.dart';

import 'openrouter_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('OpenRouterService', () {
    late OpenRouterService service;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      service = OpenRouterService(client: mockClient);
    });

    test('analyzeImage handles successful response', () async {
      // Arrange
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"choices":[{"message":{"content":'
        '{"colors":["red","blue"],"descriptions":["Sky - blue","Flower - red"]}'
        '}}]}',
        200,
      ));

      // Act
      final result = await service.analyzeImage(imageBytes);

      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['colors'], ['red', 'blue']);
      expect(result['descriptions'], ['Sky - blue', 'Flower - red']);
    });

    test('analyzeImage throws on empty image', () async {
      // Arrange
      final imageBytes = Uint8List(0);

      // Act & Assert
      expect(
        () => service.analyzeImage(imageBytes),
        throwsA(isA<Exception>()),
      );
    });

    test('analyzeImage retries on failure', () async {
      // Arrange
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      var callCount = 0;

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        callCount++;
        if (callCount < 3) {
          return http.Response('{"error": "Server error"}', 500);
        }
        return http.Response(
          '{"choices":[{"message":{"content":'
          '{"colors":["red"],"descriptions":["Flower - red"]}'
          '}}]}',
          200,
        );
      });

      // Act
      final result = await service.analyzeImage(imageBytes);

      // Assert
      expect(callCount, 3);
      expect(result['colors'], ['red']);
      expect(result['descriptions'], ['Flower - red']);
    });

    test('analyzeImage throws after max retries', () async {
      // Arrange
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"error": {"message": "Server error"}}',
        500,
      ));

      // Act & Assert
      expect(
        () => service.analyzeImage(imageBytes),
        throwsA(isA<Exception>()),
      );
    });
  });
}
