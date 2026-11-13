
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mfu_student_workspace/controller/api_controller.dart';
import 'package:mfu_student_workspace/models/api_models.dart';

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

  group('NotificationController', () {
    // 1. getNotifications
    test('getNotifications returns notification list successfully',
        () async {
      http.Request? capturedRequest;
      List<NotificationData>? result;

      await http.runWithClient(
        () async {
          result = await NotificationController().getNotifications();
        },
        () => MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode([
              {
                'id': 'N001',
                'sender_id': '650000001',
                'sender_name': 'Test Student',
                'project_id': 'P001',
                'task_id': 'T001',
                'title': 'New comment',
                'message': 'Someone commented on your task',
                'is_read': 0,
                'created_at': '2026-11-12T10:00:00',
                'type': 'COMMENT',
              },
              {
                'id': 'N002',
                'sender_id': null,
                'sender_name': '',
                'project_id': 'P001',
                'task_id': null,
                'title': 'Project announcement',
                'message': 'New announcement',
                'is_read': 1,
                'created_at': '2026-11-12T11:00:00',
                'type': 'ANNOUNCEMENT',
              }
            ]),
            200,
          );
        }),
      );

      expect(capturedRequest!.method, 'GET');
      expect(capturedRequest!.url.path, '/api/notifications');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(result!.length, 2);

      expect(result![0].id, 'N001');
      expect(result![0].senderName, 'Test Student');
      expect(result![0].title, 'New comment');
      expect(result![0].isRead, false);
      expect(result![0].type, 'COMMENT');

      expect(result![1].id, 'N002');
      expect(result![1].senderId, isNull);
      expect(result![1].isRead, true);
      expect(result![1].type, 'ANNOUNCEMENT');
    });

    // 2. markRead
    test('markRead sends PATCH request for one notification', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await NotificationController().markRead('N001');
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 200);
        }),
      );

      expect(capturedRequest!.method, 'PATCH');
      expect(capturedRequest!.url.path, '/api/notifications/N001/read');
      expect(hasAuthorization(capturedRequest), isTrue);
    });

    // 3. markAllRead
    test('markAllRead sends PATCH request successfully', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await NotificationController().markAllRead();
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 200);
        }),
      );

      expect(capturedRequest!.method, 'PATCH');
      expect(capturedRequest!.url.path, '/api/notifications/read-all');
      expect(hasAuthorization(capturedRequest), isTrue);
    });

    // 4. deleteNotification
    test('deleteNotification sends DELETE request successfully', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await NotificationController().deleteNotification('N001');
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('', 204);
        }),
      );

      expect(capturedRequest!.method, 'DELETE');
      expect(capturedRequest!.url.path, '/api/notifications/N001');
      expect(hasAuthorization(capturedRequest), isTrue);
    });
  });
}
