
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mfu_student_workspace/controller/api_controller.dart';

void main() {
  group('AuthController Unit Tests', () {
    // Test 1: Register สำเร็จ
    test('register succeeds with valid data', () async {
      final controller = AuthController();

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/register');

        final body = jsonDecode(request.body);

        expect(body['student_id'], '6731501122');
        expect(body['full_name'], 'Test Student');
        expect(body['email'], 'test@example.com');
        expect(body['password'], 'password123');

        return http.Response(
          jsonEncode({'message': 'Registration successful'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      await http.runWithClient(
        () => controller.register(
          studentId: '6731501122',
          fullName: 'Test Student',
          email: 'test@example.com',
          password: 'password123',
        ),
        () => mockClient,
      );
    });

    // Test 2: Register ข้อมูลซ้ำ
    test('register throws ApiException when data already exists', () async {
      final controller = AuthController();

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Student ID or email already exists',
          }),
          409,
          headers: {'content-type': 'application/json'},
        );
      });

      await expectLater(
        http.runWithClient(
          () => controller.register(
            studentId: '6731501122',
            fullName: 'Test Student',
            email: 'test@example.com',
            password: 'password123',
          ),
          () => mockClient,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            409,
          ),
        ),
      );
    });

    // Test 3: Login รหัสผ่านผิด
    test('login returns null when status code is 401', () async {
      SharedPreferences.setMockInitialValues({});

      final controller = AuthController();

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/login');

        return http.Response(
          jsonEncode({'message': 'Invalid credentials'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await http.runWithClient(
        () => controller.login('6731501122', 'wrongpassword'),
        () => mockClient,
      );

      expect(result, isNull);
    });

    // Test 4: Login ถูกปฏิเสธสิทธิ์
    test('login throws ApiException when status code is 403', () async {
      SharedPreferences.setMockInitialValues({});

      final controller = AuthController();

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Forbidden'}),
          403,
          headers: {'content-type': 'application/json'},
        );
      });

      await expectLater(
        http.runWithClient(
          () => controller.login('6731501122', 'password123'),
          () => mockClient,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    });

    // Test 5: Logout สำเร็จและลบ Token
    test('logout sends authorization header and removes token', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'test-token-123',
      });

      final controller = AuthController();

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/logout');

        expect(
          request.headers.entries.any(
            (entry) =>
                entry.key.toLowerCase() == 'authorization' &&
                entry.value == 'Bearer test-token-123',
          ),
          isTrue,
        );

        return http.Response('', 200);
      });

      await http.runWithClient(
        () => controller.logout(),
        () => mockClient,
      );

      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getString('auth_token'), isNull);
    });

    // Test 6: Logout ลบ Token แม้ Network Error
    test('logout removes token when network request fails', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'test-token-123',
      });

      final controller = AuthController();

      final mockClient = MockClient((request) async {
        throw Exception('Network error');
      });

      await http.runWithClient(
        () => controller.logout(),
        () => mockClient,
      );

      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getString('auth_token'), isNull);
    });

    // Test 7: Login สำเร็จและบันทึก Token
    test('login returns user and saves token when successful', () async {
      SharedPreferences.setMockInitialValues({});

      final controller = AuthController();

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/login');

        final body = jsonDecode(request.body);

        expect(body['student_id'], '6731501122');
        expect(body['password'], 'password123');

        return http.Response(
          jsonEncode({
            'token': 'test-token-123',
            'user': {
              'student_id': '6731501122',
              'full_name': 'Test Student',
              'email': 'test@example.com',
              'avatar_url': null,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final user = await http.runWithClient(
        () => controller.login('6731501122', 'password123'),
        () => mockClient,
      );

      // ตรวจสอบข้อมูล User
      expect(user, isNotNull);
      expect(user!.studentId, '6731501122');
      expect(user.fullName, 'Test Student');
      expect(user.email, 'test@example.com');
      expect(user.avatarUrl, isNull);

      // ตรวจสอบ Token ที่บันทึกใน SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getString('auth_token'), 'test-token-123');
    });
  });
}
