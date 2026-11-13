
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

  group('TaskController', () {
    // 1. getTasks
    test('getTasks returns task list successfully', () async {
      http.Request? capturedRequest;
      List<dynamic>? result;

      await http.runWithClient(
        () async {
          result = await TaskController().getTasks('P001');
        },
        () => MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode([
              {
                'id': 'T001',
                'project_id': 'P001',
                'title': 'Task One',
                'description': 'Test description',
                'assigned_to': '650000001',
                'assigned_name': 'Test Student',
                'due_date': '2026-12-01',
                'status': 'TODO',
              }
            ]),
            200,
          );
        }),
      );

      expect(capturedRequest!.method, 'GET');
      expect(capturedRequest!.url.path, '/api/projects/P001/tasks');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(result!.length, 1);
      expect(result![0].id, 'T001');
      expect(result![0].title, 'Task One');
      expect(result![0].assignedTo, '650000001');
      expect(result![0].status, 'TODO');
    });

    // 2. getTask
    test('getTask returns task details successfully', () async {
      http.Request? capturedRequest;
      dynamic result;

      await http.runWithClient(
        () async {
          result = await TaskController().getTask('T001');
        },
        () => MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode({
              'id': 'T001',
              'project_id': 'P001',
              'title': 'Task Detail',
              'description': 'Detailed description',
              'assigned_to': '650000001',
              'assigned_name': 'Test Student',
              'due_date': '2026-12-01',
              'status': 'IN_PROGRESS',
              'submission_url': 'https://example.com/work',
              'submitted_at': '2026-11-12T10:00:00',
              'completed_at': null,
              'my_role': 'MEMBER',
            }),
            200,
          );
        }),
      );

      expect(capturedRequest!.method, 'GET');
      expect(capturedRequest!.url.path, '/api/tasks/T001');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(result.id, 'T001');
      expect(result.projectId, 'P001');
      expect(result.title, 'Task Detail');
      expect(result.status, 'IN_PROGRESS');
      expect(result.submissionUrl, 'https://example.com/work');
      expect(result.myRole, 'MEMBER');
    });

    // 3. createTask
    test('createTask sends task data and returns ID', () async {
      http.Request? capturedRequest;
      String? result;

      await http.runWithClient(
        () async {
          result = await TaskController().createTask(
            'P001',
            title: 'New Task',
            description: 'New task description',
            assignedTo: '650000001',
            dueDate: '2026-12-15',
          );
        },
        () => MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode({'id': 'T002'}),
            201,
          );
        }),
      );

      expect(capturedRequest!.method, 'POST');
      expect(capturedRequest!.url.path, '/api/projects/P001/tasks');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(
        jsonDecode(capturedRequest!.body),
        equals({
          'title': 'New Task',
          'description': 'New task description',
          'assigned_to': '650000001',
          'due_date': '2026-12-15',
        }),
      );

      expect(result, 'T002');
    });

    // 4. updateTask
    test('updateTask sends only provided fields', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await TaskController().updateTask(
            'T001',
            title: 'Updated Task',
            dueDate: '2026-12-20',
          );
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 200);
        }),
      );

      expect(capturedRequest!.method, 'PUT');
      expect(capturedRequest!.url.path, '/api/tasks/T001');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(
        jsonDecode(capturedRequest!.body),
        equals({
          'title': 'Updated Task',
          'due_date': '2026-12-20',
        }),
      );
    });

    // 5. updateStatus
    test('updateStatus sends new task status', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await TaskController().updateStatus('T001', 'DONE');
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 200);
        }),
      );

      expect(capturedRequest!.method, 'PATCH');
      expect(capturedRequest!.url.path, '/api/tasks/T001/status');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(
        jsonDecode(capturedRequest!.body),
        equals({'status': 'DONE'}),
      );
    });

    // 6. assignTask: มอบหมายงาน
    test('assignTask sends assigned student ID', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await TaskController().assignTask('T001', '650000001');
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 200);
        }),
      );

      expect(capturedRequest!.method, 'PATCH');
      expect(capturedRequest!.url.path, '/api/tasks/T001/assign');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(
        jsonDecode(capturedRequest!.body),
        equals({'assigned_to': '650000001'}),
      );
    });

    // 7. assignTask: ยกเลิกมอบหมายงาน
    test('assignTask sends null to unassign task', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await TaskController().assignTask('T001', null);
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 200);
        }),
      );

      expect(
        jsonDecode(capturedRequest!.body),
        equals({'assigned_to': null}),
      );
    });

    // 8. submitWork
    test('submitWork sends submission URL', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await TaskController().submitWork(
            'T001',
            'https://example.com/submission',
          );
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 200);
        }),
      );

      expect(capturedRequest!.method, 'POST');
      expect(capturedRequest!.url.path, '/api/tasks/T001/submission');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(
        jsonDecode(capturedRequest!.body),
        equals({
          'submission_url': 'https://example.com/submission',
        }),
      );
    });

    // 9. deleteTask
    test('deleteTask sends DELETE request successfully', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await TaskController().deleteTask('T001');
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('', 204);
        }),
      );

      expect(capturedRequest!.method, 'DELETE');
      expect(capturedRequest!.url.path, '/api/tasks/T001');
      expect(hasAuthorization(capturedRequest), isTrue);
    });
  });
}
