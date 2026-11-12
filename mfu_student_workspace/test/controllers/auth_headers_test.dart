
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mfu_student_workspace/controller/api_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BaseController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controller = BaseController();
  });

  group('BaseController.authHeaders', () {
    test('should include Bearer token when token exists', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('auth_token', 'test-token');

      final headers = await controller.authHeaders();

      expect(headers, {
        'Authorization': 'Bearer test-token',
      });
    });

    test('should include Content-Type when json is true', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('auth_token', 'test-token');

      final headers = await controller.authHeaders(json: true);

      expect(headers, {
        'Authorization': 'Bearer test-token',
        'Content-Type': 'application/json',
      });
    });

    test('should throw ApiException 401 when token is missing', () async {
      await expectLater(
        controller.authHeaders(),
        throwsA(
          isA<ApiException>()
              .having(
                (e) => e.message,
                'message',
                'Please log in again',
              )
              .having(
                (e) => e.statusCode,
                'statusCode',
                401,
              ),
        ),
      );
    });

    test('should throw ApiException 401 when token is empty', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString('auth_token', '');

      await expectLater(
        controller.authHeaders(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });
  });
}
