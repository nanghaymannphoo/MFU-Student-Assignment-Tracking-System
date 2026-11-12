
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

  group('CommentController', () {
    // 1. getComments
    test('getComments returns comment list successfully', () async {
      http.Request? capturedRequest;
      List<CommentData>? result;

      await http.runWithClient(
        () async {
          result = await CommentController().getComments('T001');
        },
        () => MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode([
              {
                'id': 101,
                'task_id': 'T001',
                'author_id': '650000001',
                'author_name': 'Test Student',
                'author_avatar': null,
                'author_role': 'MEMBER',
                'comment_text': 'This is a test comment',
                'created_at': '2026-11-12T10:00:00',
              }
            ]),
            200,
          );
        }),
      );

      expect(capturedRequest!.method, 'GET');
      expect(capturedRequest!.url.path, '/api/tasks/T001/comments');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(result!.length, 1);
      expect(result![0].id, 101);
      expect(result![0].taskId, 'T001');
      expect(result![0].authorId, '650000001');
      expect(result![0].authorName, 'Test Student');
      expect(result![0].text, 'This is a test comment');
      expect(result![0].authorRole, 'MEMBER');
    });

    // 2. addComment
    test('addComment sends comment text and returns created comment',
        () async {
      http.Request? capturedRequest;
      CommentData? result;

      await http.runWithClient(
        () async {
          result = await CommentController().addComment(
            'T001',
            'New test comment',
          );
        },
        () => MockClient((request) async {
          capturedRequest = request;

          return http.Response(
            jsonEncode({
              'id': 102,
              'task_id': 'T001',
              'author_id': '650000001',
              'author_name': 'Test Student',
              'author_avatar': null,
              'author_role': 'MEMBER',
              'comment_text': 'New test comment',
              'created_at': '2026-11-12T11:00:00',
            }),
            201,
          );
        }),
      );

      expect(capturedRequest!.method, 'POST');
      expect(capturedRequest!.url.path, '/api/tasks/T001/comments');
      expect(hasAuthorization(capturedRequest), isTrue);

      expect(
        jsonDecode(capturedRequest!.body),
        equals({'comment_text': 'New test comment'}),
      );

      expect(result!.id, 102);
      expect(result!.taskId, 'T001');
      expect(result!.text, 'New test comment');
      expect(result!.authorId, '650000001');
    });

    // 3. deleteComment
    test('deleteComment sends DELETE request successfully', () async {
      http.Request? capturedRequest;

      await http.runWithClient(
        () async {
          await CommentController().deleteComment(101);
        },
        () => MockClient((request) async {
          capturedRequest = request;
          return http.Response('', 204);
        }),
      );

      expect(capturedRequest!.method, 'DELETE');
      expect(capturedRequest!.url.path, '/api/comments/101');
      expect(hasAuthorization(capturedRequest), isTrue);
    });
  });
}
