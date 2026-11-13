
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/app_notification.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/task_item.dart';
import 'package:mfu_student_workspace/models/team_member.dart';

String dateString(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

ProjectModel createProject({String role = 'PC'}) {
  return ProjectModel(
    id: 'P001',
    title: 'Test Project',
    courseCode: 'TEST101',
    description: 'Test Description',
    deadline: '2026-12-31',
    myRole: role,
    members: [
      TeamMember(
        studentId: 'ST001',
        name: 'PC User',
        role: 'PC',
      ),
      TeamMember(
        studentId: 'ST002',
        name: 'Member User',
        role: 'MEMBER',
      ),
    ],
    tasks: [],
  );
}

TaskItem createTask({
  String dueDate = '2026-11-20',
  String status = 'IN_PROGRESS',
}) {
  return TaskItem(
    id: 'T001',
    title: 'Test Task',
    description: 'Test Description',
    assignedTo: 'Member User',
    assignedStudentId: 'ST002',
    dueDate: dueDate,
    status: status,
  );
}

AppNotification createNotification({
  required String id,
  required String taskId,
  required String type,
}) {
  return AppNotification(
    id: id,
    eventId: 'event_$id',
    type: type,
    title: 'Test Notification',
    message: 'Test Message',
    recipientStudentId: 'ST002',
    actorStudentId: 'SYSTEM',
    taskId: taskId,
    createdAt: DateTime(2026, 11, 1),
  );
}

void main() {
  late List<AppNotification> originalNotifications;

  setUp(() {
    originalNotifications = WorkspaceStore.notifications;
    WorkspaceStore.notifications = [];
  });

  tearDown(() {
    WorkspaceStore.notifications = originalNotifications;
  });

  group('WorkspaceStore - extendTaskDeadline', () {
    test('should reject deadline extension by non-PC', () {
      final project = createProject(role: 'MEMBER');
      final task = createTask(
        dueDate: dateString(DateTime.now().add(const Duration(days: 5))),
      );
      final oldDate = task.dueDate;

      final result = WorkspaceStore.extendTaskDeadline(
        project: project,
        task: task,
        newDueDate: dateString(DateTime.now().add(const Duration(days: 10))),
        actorStudentId: 'ST002',
      );

      expect(result, false);
      expect(task.dueDate, oldDate);
      expect(WorkspaceStore.notifications, isEmpty);
    });

    test('should reject invalid new deadline', () {
      final project = createProject();
      final task = createTask();
      final oldDate = task.dueDate;

      final result = WorkspaceStore.extendTaskDeadline(
        project: project,
        task: task,
        newDueDate: 'invalid-date',
        actorStudentId: 'ST001',
      );

      expect(result, false);
      expect(task.dueDate, oldDate);
      expect(WorkspaceStore.notifications, isEmpty);
    });

    test('should reject deadline in the past', () {
      final project = createProject();
      final task = createTask();
      final yesterday = DateTime.now().subtract(
        const Duration(days: 1),
      );

      final result = WorkspaceStore.extendTaskDeadline(
        project: project,
        task: task,
        newDueDate: dateString(yesterday),
        actorStudentId: 'ST001',
      );

      expect(result, false);
      expect(WorkspaceStore.notifications, isEmpty);
    });

    test('should reject a deadline earlier than the current deadline', () {
      final project = createProject();
      final task = createTask(
        dueDate: dateString(DateTime.now().add(const Duration(days: 10))),
      );
      final oldDate = task.dueDate;

      final result = WorkspaceStore.extendTaskDeadline(
        project: project,
        task: task,
        newDueDate: dateString(DateTime.now().add(const Duration(days: 5))),
        actorStudentId: 'ST001',
      );

      expect(result, false);
      expect(task.dueDate, oldDate);
      expect(WorkspaceStore.notifications, isEmpty);
    });

    test('should remove old overdue alerts and preserve task status', () {
      final project = createProject();
      final task = createTask(
        dueDate: dateString(DateTime.now().add(const Duration(days: 5))),
        status: 'IN_PROGRESS',
      );

      WorkspaceStore.notifications = [
        createNotification(
          id: 'N001',
          taskId: 'T001',
          type: 'OVERDUE',
        ),
        createNotification(
          id: 'N002',
          taskId: 'T001',
          type: 'COMMENT',
        ),
        createNotification(
          id: 'N003',
          taskId: 'T999',
          type: 'OVERDUE',
        ),
      ];

      final result = WorkspaceStore.extendTaskDeadline(
        project: project,
        task: task,
        newDueDate: dateString(DateTime.now().add(const Duration(days: 15))),
        actorStudentId: 'ST001',
      );

      expect(result, true);
      expect(task.status, 'IN_PROGRESS');

      expect(
        WorkspaceStore.notifications.any(
          (n) => n.taskId == 'T001' && n.type == 'OVERDUE',
        ),
        false,
      );

      expect(
        WorkspaceStore.notifications.any((n) => n.id == 'N002'),
        true,
      );

      expect(
        WorkspaceStore.notifications.any((n) => n.id == 'N003'),
        true,
      );

      expect(
        WorkspaceStore.notifications.any(
          (n) => n.taskId == 'T001' && n.type == 'DEADLINE_EXTENDED',
        ),
        true,
      );
    });
  });
}
