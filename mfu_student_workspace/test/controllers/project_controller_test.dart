
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

  group('ProjectController', () {
    // 1. getProjects: ดึงรายการโปรเจกต์
    test('getProjects returns project list successfully', () async {
      http.Request? capturedRequest;
      List<dynamic>? result;

      await http.runWithClient(
        () async {
          result = await ProjectController().getProjects();
        },
        () => MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode([
              {
                'id': 'P001',
                'title': 'Project One',
                'course_code': 'CS101',
                'my_role': 'PC',
              },
              {
                'id': 'P002',
                'title': 'Project Two',
                'course_code': 'CS102',
                'my_role': 'MEMBER',
              },
            ]),
            200,
          );
        }),
      );

      expect(capturedRequest!.method, 'GET');
      expect(capturedRequest!.url.path, '/api/projects');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(result!.length, 2);
      expect(result![0].id, 'P001');
      expect(result![0].title, 'Project One');
      expect(result![0].isPC, isTrue);
      expect(result![1].id, 'P002');
      expect(result![1].isPC, isFalse);
    });

    // 2. getProject: ดึงรายละเอียดโปรเจกต์
    test('getProject returns project details successfully', () async {
      http.Request? capturedRequest;
      dynamic result;

      await http.runWithClient(
        () async {
          result = await ProjectController().getProject('P001');
        },
        () => MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode({
              'id': 'P001',
              'title': 'Test Project',
              'course_code': 'CS101',
              'description': 'Project description',
              'deadline': '2026-12-01',
              'created_by': '650000001',
              'my_role': 'PC',
              'members': [],
              'member_count': 3,
              'task_total': 10,
              'task_todo': 4,
              'task_in_progress': 3,
              'task_done': 3,
              'task_overdue': 1,
            }),
            200,
          );
        }),
      );

      expect(capturedRequest!.method, 'GET');
      expect(capturedRequest!.url.path, '/api/projects/P001');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(result.id, 'P001');
      expect(result.title, 'Test Project');
      expect(result.courseCode, 'CS101');
      expect(result.description, 'Project description');
      expect(result.deadline, '2026-12-01');
      expect(result.createdBy, '650000001');
      expect(result.myRole, 'PC');
      expect(result.memberCount, 3);
      expect(result.taskTotal, 10);
      expect(result.taskTodo, 4);
      expect(result.taskInProgress, 3);
      expect(result.taskDone, 3);
      expect(result.taskOverdue, 1);
    });

    // 3. createProject: สร้างโปรเจกต์
    test('createProject sends project data and returns ID', () async {
      http.Request? capturedRequest;
      String? result;

      await http.runWithClient(
        () async {
          result = await ProjectController().createProject(
            title: 'New Project',
            courseCode: 'CS201',
            description: 'New project description',
            deadline: '2026-12-15',
          );
        },
        () => MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode({'id': 'P003'}),
            201,
          );
        }),
      );

      expect(capturedRequest!.method, 'POST');
      expect(capturedRequest!.url.path, '/api/projects');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(
        capturedRequest!.headers.entries.any(
          (entry) => entry.key.toLowerCase() == 'content-type',
        ),
        isTrue,
      );

      expect(
        jsonDecode(capturedRequest!.body),
        equals({
          'title': 'New Project',
          'course_code': 'CS201',
          'description': 'New project description',
          'deadline': '2026-12-15',
        }),
      );

      expect(result, 'P003');
    });

    // 4. updateProject: แก้ไขโปรเจกต์
    test('updateProject sends only provided fields', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await ProjectController().updateProject(
            'P001',
            title: 'Updated Project',
            description: 'Updated description',
          );
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 200);
        }),
      );

      expect(capturedRequest!.method, 'PUT');
      expect(capturedRequest!.url.path, '/api/projects/P001');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(
        jsonDecode(capturedRequest!.body),
        equals({
          'title': 'Updated Project',
          'description': 'Updated description',
        }),
      );
    });

    // 5. deleteProject: ลบโปรเจกต์
    test('deleteProject sends DELETE request successfully', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await ProjectController().deleteProject('P001');
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('', 204);
        }),
      );

      expect(capturedRequest!.method, 'DELETE');
      expect(capturedRequest!.url.path, '/api/projects/P001');
      expect(hasAuthorization(capturedRequest), isTrue);
    });

    // 6. getDashboard: ดึงข้อมูล Dashboard
    test('getDashboard returns dashboard data successfully', () async {
      http.Request? capturedRequest;
      dynamic result;

      await http.runWithClient(
        () async {
          result = await ProjectController().getDashboard();
        },
        () => MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode({
              'total_projects': 5,
              'total_tasks': 20,
              'todo': 8,
              'in_progress': 6,
              'done': 4,
              'overdue': 2,
              'upcoming_deadlines': [],
            }),
            200,
          );
        }),
      );

      expect(capturedRequest!.method, 'GET');
      expect(capturedRequest!.url.path, '/api/dashboard');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(result.totalProjects, 5);
      expect(result.totalTasks, 20);
      expect(result.todo, 8);
      expect(result.inProgress, 6);
      expect(result.done, 4);
      expect(result.overdue, 2);
      expect(result.upcomingDeadlines, isEmpty);
    });

    // 7. announce: ประกาศข่าวในโปรเจกต์
    test('announce sends announcement and returns sent count', () async {
      http.Request? capturedRequest;
      int? result;

      await http.runWithClient(
        () async {
          result = await ProjectController().announce(
            'P001',
            title: 'Project Announcement',
            message: 'Meeting tomorrow',
          );
        },
        () => MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode({'sent': 3}),
            200,
          );
        }),
      );

      expect(capturedRequest!.method, 'POST');
      expect(capturedRequest!.url.path, '/api/projects/P001/announce');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(
        jsonDecode(capturedRequest!.body),
        equals({
          'title': 'Project Announcement',
          'message': 'Meeting tomorrow',
        }),
      );

      expect(result, 3);
    });
  });
}
