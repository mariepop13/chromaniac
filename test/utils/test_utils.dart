import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'test_utils.mocks.dart';

@GenerateMocks([http.Client])


class TestUtils {
  static final sampleImageBytes = Uint8List.fromList([1, 2, 3, 4]);


  static void mockSuccessfulColorResponse(MockClient mockClient) {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(
      jsonEncode({
        'choices': [{
          'message': {
            'content': jsonEncode({
              'colors': [
                {
                  'object': 'sky',
                  'colorName': 'light blue',
                  'hexCode': '#87CEEB'
                },
                {
                  'object': 'grass',
                  'colorName': 'light green',
                  'hexCode': '#90EE90'
                },
                {
                  'object': 'sun',
                  'colorName': 'yellow',
                  'hexCode': '#FFD700'
                }
              ]
            })
          }
        }]
      }),
      200,
    ));
  }


  static void mockUnauthorizedResponse(MockClient mockClient) {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response('Unauthorized', 401));
  }


  static void mockServerErrorResponse(MockClient mockClient) {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response('Internal Server Error', 500));
  }


  static void mockInvalidFormatResponse(MockClient mockClient) {
    when(mockClient.post(
      any,
      headers: anyNamed('headers'),
      body: anyNamed('body'),
    )).thenAnswer((_) async => http.Response(
      jsonEncode({
        'choices': [{
          'message': {
            'content': 'Invalid Format'
          }
        }]
      }),
      200,
    ));
  }


  static void verifyRequestFormat(MockClient mockClient) {
    verify(mockClient.post(
      any,
      headers: argThat(
        predicate<Map<String, String>>((headers) =>
          headers['Authorization'] != null &&
          headers['Content-Type'] == 'application/json'
        ),
        named: 'headers',
      ),
      body: argThat(
        predicate<String>((body) =>
          body.contains('system') &&
          body.contains('user') &&
          body.contains('base64')
        ),
        named: 'body',
      ),
    )).called(1);
  }
}
