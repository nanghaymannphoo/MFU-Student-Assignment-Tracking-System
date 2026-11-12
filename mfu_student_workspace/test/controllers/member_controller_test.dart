
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

  bool hasAuthorization(http.Request? request) {
    return request != null &&
        request.headers.entries.any(
          (entry) =>
              entry.key.toLowerCase() == 'authorization' &&
              entry.value == 'Bearer test-token',
        );
  }

  group('MemberController', () {
    // 1. getMembers: ดึงรายชื่อสมาชิก
    test('getMembers returns member list successfully', () async {
      http.Request? capturedRequest;
      List<dynamic>? result;

      await http.runWithClient(
        () async {
          result = await MemberController().getMembers('P001');
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode([]), 200);
        }),
      );

      expect(capturedRequest!.method, 'GET');
      expect(
        capturedRequest!.url.path,
        '/api/projects/P001/members',
      );
      expect(hasAuthorization(capturedRequest), isTrue);
      expect(result, isEmpty);
    });

    // 2. addMember: เพิ่มสมาชิก
    test('addMember sends student ID and MEMBER role', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await MemberController().addMember('P001', '650000001');
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 201);
        }),
      );

      expect(capturedRequest!.method, 'POST');
      expect(
        capturedRequest!.url.path,
        '/api/projects/P001/members',
      );
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(
        jsonDecode(capturedRequest!.body),
        equals({
          'student_id': '650000001',
          'project_role': 'MEMBER',
        }),
      );
    });

    // 3. removeMember: ลบสมาชิก
    test('removeMember sends DELETE request successfully', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await MemberController().removeMember(
            'P001',
            '650000001',
          );
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('', 204);
        }),
      );

      expect(capturedRequest!.method, 'DELETE');
      expect(
        capturedRequest!.url.path,
        '/api/projects/P001/members/650000001',
      );
      expect(hasAuthorization(capturedRequest), isTrue);
    });
  });
}
