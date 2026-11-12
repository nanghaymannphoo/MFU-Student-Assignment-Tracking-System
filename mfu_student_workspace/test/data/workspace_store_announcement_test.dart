
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/app_notification.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/team_member.dart';

void main() {
  late List<ProjectModel> originalProjects;
  late List<AppNotification> originalNotifications;

  setUp(() {
    originalProjects = List<ProjectModel>.from(WorkspaceStore.projects);
    originalNotifications =
        List<AppNotification>.from(WorkspaceStore.notifications);

    WorkspaceStore.projects.clear();
    WorkspaceStore.notifications.clear();
  });

  tearDown(() {
    WorkspaceStore.projects
      ..clear()
      ..addAll(originalProjects);

    WorkspaceStore.notifications
      ..clear()
      ..addAll(originalNotifications);
  });

  ProjectModel createProject({
    List<TeamMember>? members,
  }) {
    return ProjectModel(
      id: 'P001',
      title: 'Project Alpha',
      courseCode: 'CE101',
      description: 'Test project',
      deadline: '2026-12-31',
      myRole: 'PC',
      members: members ??
          [
            TeamMember(
              studentId: 'PC001',
              name: 'Project Coordinator',
              role: 'PC',
            ),
            TeamMember(
              studentId: 'M001',
              name: 'Member One',
              role: 'MEMBER',
            ),
            TeamMember(
              studentId: 'M002',
              name: 'Member Two',
              role: 'MEMBER',
            ),
          ],
      tasks: [],
    );
  }

  group('WorkspaceStore.onProjectAnnouncement', () {
    test('should notify all project members except the sender', () {
      final project = createProject();

      WorkspaceStore.onProjectAnnouncement(
        project: project,
        title: 'Meeting',
        message: 'Tomorrow at 10 AM',
        actorStudentId: 'PC001',
      );

      expect(WorkspaceStore.notifications.length, 2);

      final recipients = WorkspaceStore.notifications
          .map((notification) => notification.recipientStudentId)
          .toList();

      expect(recipients, contains('M001'));
      expect(recipients, contains('M002'));
      expect(recipients, isNot(contains('PC001')));
    });

    test('should create announcement with correct information', () {
      final project = createProject();

      WorkspaceStore.onProjectAnnouncement(
        project: project,
        title: 'Meeting',
        message: 'Tomorrow at 10 AM',
        actorStudentId: 'PC001',
      );

      final notification = WorkspaceStore.notifications.first;

      expect(notification.type, 'ANNOUNCEMENT');
      expect(notification.title, 'Project Announcement: Project Alpha');
      expect(notification.message, 'Meeting: Tomorrow at 10 AM');
      expect(notification.actorStudentId, 'PC001');
      expect(notification.projectId, 'P001');
      expect(notification.projectName, 'Project Alpha');
      expect(notification.isRead, false);
    });

    test('should not create notification when sender is the only member', () {
      final project = createProject(
        members: [
          TeamMember(
            studentId: 'PC001',
            name: 'Project Coordinator',
            role: 'PC',
          ),
        ],
      );

      WorkspaceStore.onProjectAnnouncement(
        project: project,
        title: 'Meeting',
        message: 'Tomorrow at 10 AM',
        actorStudentId: 'PC001',
      );

      expect(WorkspaceStore.notifications, isEmpty);
    });
  });
}
