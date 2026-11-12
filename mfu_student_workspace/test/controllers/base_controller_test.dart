
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mfu_student_workspace/controller/api_controller.dart';

void main() {
  group('ApiException', () {
    test('toString should return the error message', () {
      final error = ApiException('Unauthorized');

      expect(error.toString(), 'Unauthorized');
    });
  });

  group('BaseController.decode', () {
    final controller = BaseController();

    test('should decode a valid JSON response', () {
      final response = http.Response('{"id": 1}', 200);

      expect(controller.decode(response), {'id': 1});
    });

    test('should return null for an empty response body', () {
      final response = http.Response('', 204);

      expect(controller.decode(response), isNull);
    });

    test('should return null when successful response contains invalid JSON', () {
      final response = http.Response('invalid-json', 200);

      expect(controller.decode(response), isNull);
    });

    test('should throw ApiException with backend message for error response', () {
      final response = http.Response(
        '{"message": "Unauthorized"}',
        401,
      );

      expect(
        () => controller.decode(response),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Unauthorized')
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
    });

    test('should use fallback message when error response has invalid JSON', () {
      final response = http.Response('invalid-json', 500);

      expect(
        () => controller.decode(response),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.message,
                'message',
                'Server error (500)',
              )
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('should treat 3xx status as an error', () {
      final response = http.Response('', 302);

      expect(
        () => controller.decode(response),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            302,
          ),
        ),
      );
    });
  });

  group('BaseController.guard', () {
    final controller = BaseController();

    test('should return the result when action succeeds', () async {
      final result = await controller.guard<int>(() async => 42);

      expect(result, 42);
    });

    test('should rethrow ApiException without changing it', () async {
      final future = controller.guard<void>(() async {
        throw ApiException('Forbidden', statusCode: 403);
      });

      await expectLater(
        future,
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Forbidden')
              .having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });

    test('should convert other exceptions into Connection error', () async {
      final future = controller.guard<void>(() async {
        throw Exception('Unexpected error');
      });

      await expectLater(
        future,
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Connection error',
          ),
        ),
      );
    });
  });
}
