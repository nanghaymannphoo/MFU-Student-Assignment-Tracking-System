
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/app_notification.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/task_item.dart';
import 'package:mfu_student_workspace/models/team_member.dart';

String getOverdueDate() {
  final date = DateTime.now().subtract(const Duration(days: 2));
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String getFutureDate() {
  final date = DateTime.now().add(const Duration(days: 2));
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

TaskItem createTask({
  String id = 'T001',
  String? dueDate,
  String status = 'IN_PROGRESS',
  String assignedStudentId = 'MEMBER001',
  String assignedTo = 'Test Member',
}) {
  return TaskItem(
    id: id,
    title: 'Test Task',
    description: 'Task for unit testing',
    assignedTo: assignedTo,
    assignedStudentId: assignedStudentId,
    dueDate: dueDate ?? getOverdueDate(),
    status: status,
  );
}

ProjectModel createProject({
  List<TaskItem>? tasks,
  List<TeamMember>? members,
}) {
  return ProjectModel(
    id: 'P001',
    title: 'Test Project',
    courseCode: 'TEST101',
    description: 'Project for unit testing',
    deadline: '2026-12-31',
    myRole: 'PC',
    members: members ?? [
      TeamMember(
        studentId: 'PC001',
        name: 'Test PC',
        role: 'PC',
      ),
      TeamMember(
        studentId: 'MEMBER001',
        name: 'Test Member',
        role: 'MEMBER',
      ),
    ],
    tasks: tasks ?? [],
  );
}

void main() {
  late List<ProjectModel> originalProjects;
  late List<AppNotification> originalNotifications;

  setUp(() {
    originalProjects = WorkspaceStore.projects;
    originalNotifications = WorkspaceStore.notifications;

    WorkspaceStore.projects = [];
    WorkspaceStore.notifications = [];
  });

  tearDown(() {
    WorkspaceStore.projects = originalProjects;
    WorkspaceStore.notifications = originalNotifications;
  });

  group('WorkspaceStore - checkOverdueTasksAndNotify', () {
    test('should notify both assignee and project PC', () {
      final task = createTask();

      WorkspaceStore.projects = [
        createProject(tasks: [task]),
      ];

      WorkspaceStore.checkOverdueTasksAndNotify();

      expect(WorkspaceStore.notifications, hasLength(2));

      expect(
        WorkspaceStore.notifications
            .map((n) => n.recipientStudentId)
            .toSet(),
        {'MEMBER001', 'PC001'},
      );

      expect(
        WorkspaceStore.notifications.every(
          (n) => n.type == 'OVERDUE',
        ),
        true,
      );
    });

    test('should not notify for future or completed tasks', () {
      final futureTask = createTask(
        id: 'T001',
        dueDate: getFutureDate(),
      );

      final completedTask = createTask(
        id: 'T002',
        status: 'DONE',
      );

      WorkspaceStore.projects = [
        createProject(tasks: [futureTask, completedTask]),
      ];

      WorkspaceStore.checkOverdueTasksAndNotify();

      expect(WorkspaceStore.notifications, isEmpty);
    });

    test('should notify only PC when task has no assigned student ID', () {
      final task = createTask(
        assignedStudentId: '',
        assignedTo: '',
      );

      WorkspaceStore.projects = [
        createProject(tasks: [task]),
      ];

      WorkspaceStore.checkOverdueTasksAndNotify();

      expect(WorkspaceStore.notifications, hasLength(1));
      expect(
        WorkspaceStore.notifications.first.recipientStudentId,
        'PC001',
      );
    });

    test('should notify only once when assignee is also PC', () {
      final task = createTask(
        assignedStudentId: 'PC001',
        assignedTo: 'Test PC',
      );

      WorkspaceStore.projects = [
        createProject(tasks: [task]),
      ];

      WorkspaceStore.checkOverdueTasksAndNotify();

      expect(WorkspaceStore.notifications, hasLength(1));
      expect(
        WorkspaceStore.notifications.first.recipientStudentId,
        'PC001',
      );
    });

    test('should prevent duplicate notifications when called repeatedly', () {
      final task = createTask();

      WorkspaceStore.projects = [
        createProject(tasks: [task]),
      ];

      WorkspaceStore.checkOverdueTasksAndNotify();
      WorkspaceStore.checkOverdueTasksAndNotify();

      expect(WorkspaceStore.notifications, hasLength(2));

      expect(
        WorkspaceStore.notifications
            .map((n) => n.eventId)
            .toSet()
            .length,
        2,
      );
    });
  });
}
