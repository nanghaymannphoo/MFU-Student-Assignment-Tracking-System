
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mfu_student_workspace/controller/api_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'test-token',
    });
  });

  group('UserController', () {
    // 1. getMe: รับข้อมูลผู้ใช้ปัจจุบันสำเร็จ
    test('getMe returns current user successfully', () async {
      http.Request? capturedRequest;
      dynamic result;

      await http.runWithClient(
        () async {
          result = await UserController().getMe();
        },
        () => MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode({
              'student_id': '650000001',
              'full_name': 'Test User',
              'email': 'test@mfu.ac.th',
              'avatar_url': 'https://example.com/avatar.png',
            }),
            200,
          );
        }),
      );

      expect(capturedRequest!.method, 'GET');
      expect(capturedRequest!.url.path, '/api/users/me');

      expect(
        capturedRequest!.headers.entries.any(
          (e) =>
              e.key.toLowerCase() == 'authorization' &&
              e.value == 'Bearer test-token',
        ),
        isTrue,
      );

      expect(result.studentId, '650000001');
      expect(result.fullName, 'Test User');
      expect(result.email, 'test@mfu.ac.th');
      expect(result.avatarUrl, 'https://example.com/avatar.png');
    });

    // 2. updateMe: แก้ไขชื่อและรูปโปรไฟล์
    test('updateMe sends profile update correctly', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await UserController().updateMe(
            fullName: 'Updated User',
            avatarUrl: 'https://example.com/new-avatar.png',
          );
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 200);
        }),
      );

      expect(capturedRequest!.method, 'PUT');
      expect(capturedRequest!.url.path, '/api/users/me');

      expect(
        capturedRequest!.headers.entries.any(
          (e) =>
              e.key.toLowerCase() == 'authorization' &&
              e.value == 'Bearer test-token',
        ),
        isTrue,
      );

      expect(
        capturedRequest!.headers.entries.any(
          (e) => e.key.toLowerCase() == 'content-type',
        ),
        isTrue,
      );

      expect(
        jsonDecode(capturedRequest!.body),
        equals({
          'full_name': 'Updated User',
          'avatar_url': 'https://example.com/new-avatar.png',
        }),
      );
    });

    // 3. updateMe: เปลี่ยนรหัสผ่าน
    test('updateMe sends password update correctly', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await UserController().updateMe(
            currentPassword: 'old-password',
            newPassword: 'new-password',
          );
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 200);
        }),
      );

      expect(
        jsonDecode(capturedRequest!.body),
        equals({
          'current_password': 'old-password',
          'new_password': 'new-password',
        }),
      );
    });

    // 4. getUser: ค้นหาผู้ใช้สำเร็จ
    test('getUser returns user when found', () async {
      http.Request? capturedRequest;
      dynamic result;

      await http.runWithClient(
        () async {
          result = await UserController().getUser('650000002');
        },
        () => MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode({
              'student_id': '650000002',
              'full_name': 'Another User',
            }),
            200,
          );
        }),
      );

      expect(capturedRequest!.method, 'GET');
      expect(capturedRequest!.url.path, '/api/users/650000002');

      expect(result.studentId, '650000002');
      expect(result.fullName, 'Another User');

      // email ไม่มีใน response จึงต้องเป็นค่าว่างตาม UserModel
      expect(result.email, '');
    });

    // 5. getUser: ไม่พบผู้ใช้
    test('getUser returns null when user is not found', () async {
      dynamic result;

      await http.runWithClient(
        () async {
          result = await UserController().getUser('999999999');
        },
        () => MockClient((request) async {
          return http.Response(
            jsonEncode({'message': 'User not found'}),
            404,
          );
        }),
      );

      expect(result, isNull);
    });
  });
}
