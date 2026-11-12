
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/app_notification.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/team_member.dart';

void main() {
  group('WorkspaceStore - resolveMemberName', () {
    late List<ProjectModel> originalProjects;
    late List<AppNotification> originalNotifications;
    late String originalStudentId;
    late String originalUserName;

    setUp(() {
      originalProjects = WorkspaceStore.projects;
      originalNotifications = WorkspaceStore.notifications;
      originalStudentId = WorkspaceStore.currentStudentId;
      originalUserName = WorkspaceStore.currentUserName;

      WorkspaceStore.currentStudentId = 'ST001';
      WorkspaceStore.currentUserName = 'Alex Smith';

      WorkspaceStore.projects = [
        ProjectModel(
          id: 'P001',
          title: 'Test Project',
          courseCode: 'TEST101',
          description: 'Test Description',
          deadline: '2026-12-01',
          myRole: 'PC',
          members: [
            TeamMember(
              studentId: 'ST001',
              name: 'Alex',
              role: 'PC',
            ),
            TeamMember(
              studentId: 'ST002',
              name: 'Taylor',
              role: 'MEMBER',
            ),
          ],
          tasks: [],
        ),
      ];

      WorkspaceStore.notifications = [];
    });

    tearDown(() {
      WorkspaceStore.projects = originalProjects;
      WorkspaceStore.notifications = originalNotifications;
      WorkspaceStore.currentStudentId = originalStudentId;
      WorkspaceStore.currentUserName = originalUserName;
    });

    test('should return current user first name', () {
      final result = WorkspaceStore.resolveMemberName('ST001');

      expect(result, 'Alex');
    });

    test('should return member name from project', () {
      final result = WorkspaceStore.resolveMemberName('ST002');

      expect(result, 'Taylor');
    });

    test('should return student ID when member is not found', () {
      final result = WorkspaceStore.resolveMemberName('ST999');

      expect(result, 'ST999');
    });
  });
}
