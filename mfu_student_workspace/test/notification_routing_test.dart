import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/task_item.dart';
import 'package:mfu_student_workspace/models/team_member.dart';

void main() {
  group('Notification Routing & Rules Tests', () {
    late ProjectModel testProject;
    late TaskItem testTask;

    setUp(() {
      WorkspaceStore.currentStudentId = '6731501105';
      WorkspaceStore.currentUserName = 'Nang Hay Man Phoo';
      WorkspaceStore.notifications.clear();

      testProject = ProjectModel(
        id: 'test_p1',
        title: 'Software Engineering Project',
        courseCode: '1305204',
        description: 'Test Project',
        deadline: '2026-12-01',
        myRole: 'PC',
        members: [
          TeamMember(studentId: '6731501105', name: 'Phoo', role: 'PC'),
          TeamMember(studentId: '6731501101', name: 'Menisa', role: 'Member'),
          TeamMember(studentId: '6731501102', name: 'Puttapoom', role: 'Member'),
        ],
        tasks: [],
      );

      testTask = TaskItem(
        id: 'test_t1',
        title: 'Build Authentication',
        description: 'Login and signup with MFU email',
        assignedTo: 'Menisa',
        assignedStudentId: '6731501101',
        dueDate: '2026-11-20',
        status: 'IN_PROGRESS',
      );
      testProject.tasks.add(testTask);
    });

    test('PC commenting on a task notifies its assigned member', () {
      // Phoo (6731501105, PC) comments on task assigned to Menisa (6731501101)
      WorkspaceStore.onCommentAdded(
        project: testProject,
        task: testTask,
        commentText: 'Please review argon2 password hashing.',
        actorStudentId: '6731501105',
        actorName: 'Phoo',
        commentId: 'c1',
      );

      expect(WorkspaceStore.notifications.length, 1);
      final notif = WorkspaceStore.notifications.first;
      expect(notif.recipientStudentId, '6731501101'); // Menisa
      expect(notif.actorStudentId, '6731501105'); // Phoo
      expect(notif.projectId, 'test_p1');
      expect(notif.taskId, 'test_t1');
      expect(notif.type, 'COMMENT');
      expect(notif.isRead, false);
    });

    test('Member commenting on a task notifies the project PC', () {
      // Menisa (6731501101, Member) comments on task
      WorkspaceStore.onCommentAdded(
        project: testProject,
        task: testTask,
        commentText: 'Working on argon2 hashing, nearly complete!',
        actorStudentId: '6731501101',
        actorName: 'Menisa',
        commentId: 'c2',
      );

      expect(WorkspaceStore.notifications.length, 1);
      final notif = WorkspaceStore.notifications.first;
      expect(notif.recipientStudentId, '6731501105'); // Phoo (PC)
      expect(notif.actorStudentId, '6731501101'); // Menisa
      expect(notif.projectId, 'test_p1');
      expect(notif.taskId, 'test_t1');
    });

    test('Self-notification is strictly prevented when PC is also the assignee', () {
      // Task assigned to PC (Phoo)
      final selfTask = TaskItem(
        id: 'test_t_self',
        title: 'Backend Setup',
        description: 'Server config',
        assignedTo: 'Phoo',
        assignedStudentId: '6731501105',
        dueDate: '2026-11-25',
        status: 'TODO',
      );
      testProject.tasks.add(selfTask);

      // Phoo (PC and Assignee) comments
      WorkspaceStore.onCommentAdded(
        project: testProject,
        task: selfTask,
        commentText: 'Note to self about DB migrations',
        actorStudentId: '6731501105',
        actorName: 'Phoo',
        commentId: 'c3',
      );

      // Must be 0 notifications dispatched
      expect(WorkspaceStore.notifications.isEmpty, true);
    });

    test('Task assigned or reassigned notifies the new assignee', () {
      WorkspaceStore.onTaskAssignedOrReassigned(
        project: testProject,
        task: testTask,
        newAssigneeStudentId: '6731501102', // Puttapoom
        actorStudentId: '6731501105', // Phoo
      );

      expect(WorkspaceStore.notifications.length, 1);
      final notif = WorkspaceStore.notifications.first;
      expect(notif.recipientStudentId, '6731501102');
      expect(notif.actorStudentId, '6731501105');
      expect(notif.type, 'TASK_ASSIGNED');
      expect(notif.projectId, 'test_p1');
      expect(notif.taskId, 'test_t1');
    });

    test('Deliverable submission notifies the project PC', () {
      WorkspaceStore.onWorkSubmitted(
        project: testProject,
        task: testTask,
        actorStudentId: '6731501101', // Menisa submitted
      );

      expect(WorkspaceStore.notifications.length, 1);
      final notif = WorkspaceStore.notifications.first;
      expect(notif.recipientStudentId, '6731501105'); // Phoo (PC)
      expect(notif.actorStudentId, '6731501101');
      expect(notif.type, 'SUBMISSION');
    });

    test('Status change routing (Member -> PC, and PC -> Assignee)', () {
      // 1. Member updates status -> notify PC
      WorkspaceStore.onStatusChanged(
        project: testProject,
        task: testTask,
        newStatus: 'DONE',
        actorStudentId: '6731501101',
      );
      expect(WorkspaceStore.notifications.first.recipientStudentId, '6731501105'); // PC

      // 2. PC updates status -> notify Assignee
      WorkspaceStore.onStatusChanged(
        project: testProject,
        task: testTask,
        newStatus: 'IN_PROGRESS',
        actorStudentId: '6731501105',
      );
      expect(WorkspaceStore.notifications.first.recipientStudentId, '6731501101'); // Assignee
    });

    test('Deadline extension notifies assignee with new date', () {
      final success = WorkspaceStore.extendTaskDeadline(
        project: testProject,
        task: testTask,
        newDueDate: '2026-11-28',
        actorStudentId: '6731501105',
      );

      expect(success, true);
      expect(testTask.dueDate, '2026-11-28');
      expect(WorkspaceStore.notifications.first.recipientStudentId, '6731501101'); // Menisa
      expect(WorkspaceStore.notifications.first.type, 'DEADLINE_EXTENDED');
      expect(WorkspaceStore.notifications.first.message.contains('2026-11-28'), true);
    });

    test('Duplicate notifications for same event and recipient are prevented', () {
      WorkspaceStore.dispatchNotification(
        eventId: 'duplicate_test_evt',
        type: 'TEST',
        title: 'Test',
        message: 'Message',
        recipientStudentId: '6731501101',
        actorStudentId: '6731501105',
      );
      expect(WorkspaceStore.notifications.length, 1);

      // Attempt second dispatch with same eventId and recipient
      WorkspaceStore.dispatchNotification(
        eventId: 'duplicate_test_evt',
        type: 'TEST',
        title: 'Test',
        message: 'Message',
        recipientStudentId: '6731501101',
        actorStudentId: '6731501105',
      );
      expect(WorkspaceStore.notifications.length, 1);
    });

    test('CurrentUser filtering and unread count', () {
      // Add notification for Phoo (6731501105)
      WorkspaceStore.dispatchNotification(
        eventId: 'evt_phoo_1',
        type: 'TEST',
        title: 'For Phoo',
        message: 'Hello Phoo',
        recipientStudentId: '6731501105',
        actorStudentId: '6731501101',
      );

      // Add notification for Menisa (6731501101)
      WorkspaceStore.dispatchNotification(
        eventId: 'evt_menisa_1',
        type: 'TEST',
        title: 'For Menisa',
        message: 'Hello Menisa',
        recipientStudentId: '6731501101',
        actorStudentId: '6731501105',
      );

      // Current user is Phoo
      final forPhoo = WorkspaceStore.getNotificationsForCurrentUser();
      expect(forPhoo.length, 1);
      expect(forPhoo.first.title, 'For Phoo');
      expect(WorkspaceStore.getUnreadCountForCurrentUser(), 1);

      // Mark all read for Phoo
      WorkspaceStore.markAllReadForCurrentUser();
      expect(WorkspaceStore.getUnreadCountForCurrentUser(), 0);
      expect(forPhoo.first.isRead, true);

      // Menisa's notification is unaffected
      final menisaNotif = WorkspaceStore.notifications.firstWhere(
        (n) => n.recipientStudentId == '6731501101',
      );
      expect(menisaNotif.isRead, false);
    });
  });
}

