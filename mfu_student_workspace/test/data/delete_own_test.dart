import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/comment_item.dart';
import 'package:mfu_student_workspace/models/task_item.dart';

void main() {
  group('Delete only your own comments and notifications', () {
    late TaskItem testTask;

    setUp(() {
      WorkspaceStore.notifications.clear();

      testTask = TaskItem(
        id: 'test_t1',
        title: 'Build Authentication',
        description: 'Login and signup with MFU email',
        assignedTo: 'Menisa',
        assignedStudentId: '6731501101',
        dueDate: '2026-11-20',
        status: 'IN_PROGRESS',
      );
      testTask.comments.addAll([
        CommentItem(
          id: 'c1',
          authorStudentId: '6731501101',
          authorName: 'Menisa',
          authorRole: 'MEMBER',
          text: 'Working on it.',
          createdAt: DateTime.now(),
        ),
        CommentItem(
          id: 'c2',
          authorStudentId: '6731501105',
          authorName: 'Phoo',
          authorRole: 'PC',
          text: 'Please review argon2 password hashing.',
          createdAt: DateTime.now(),
        ),
      ]);
    });

    test('the author can delete their own comment', () {
      final removed = WorkspaceStore.deleteCommentIfAuthor(
        task: testTask,
        commentId: 'c1',
        actorStudentId: '6731501101',
      );

      expect(removed, true);
      expect(testTask.comments.length, 1);
      expect(testTask.comments.first.id, 'c2');
    });

    test('someone else cannot delete the comment', () {
      // Menisa tries to delete the PC's comment c2
      final removed = WorkspaceStore.deleteCommentIfAuthor(
        task: testTask,
        commentId: 'c2',
        actorStudentId: '6731501101',
      );

      expect(removed, false);
      expect(testTask.comments.length, 2);
    });

    test('deleting an unknown comment id changes nothing', () {
      final removed = WorkspaceStore.deleteCommentIfAuthor(
        task: testTask,
        commentId: 'no-such-comment',
        actorStudentId: '6731501101',
      );

      expect(removed, false);
      expect(testTask.comments.length, 2);
    });

    test('the recipient can delete their own notification', () {
      WorkspaceStore.dispatchNotification(
        eventId: 'e1',
        type: 'COMMENT',
        title: 'New Comment',
        message: 'Phoo: "Please review."',
        recipientStudentId: '6731501101',
        actorStudentId: '6731501105',
      );
      final id = WorkspaceStore.notifications.first.id;

      final removed = WorkspaceStore.deleteNotificationIfRecipient(
        notificationId: id,
        actorStudentId: '6731501101',
      );

      expect(removed, true);
      expect(WorkspaceStore.notifications.length, 0);
    });

    test('another user cannot delete the notification', () {
      WorkspaceStore.dispatchNotification(
        eventId: 'e2',
        type: 'COMMENT',
        title: 'New Comment',
        message: 'Phoo: "Please review."',
        recipientStudentId: '6731501101',
        actorStudentId: '6731501105',
      );
      final id = WorkspaceStore.notifications.first.id;

      final removed = WorkspaceStore.deleteNotificationIfRecipient(
        notificationId: id,
        actorStudentId: '6731501102',
      );

      expect(removed, false);
      expect(WorkspaceStore.notifications.length, 1);
    });
  });

  group('Task status and timestamps', () {
    test('DONE sets completedAt and moving back clears it', () {
      final task = TaskItem(
        id: 't',
        title: 'Task',
        description: 'Description',
        assignedTo: 'Menisa',
        dueDate: '2026-11-20',
      );
      expect(task.completedAt, isNull);

      task.setStatus('DONE');
      expect(task.status, 'DONE');
      expect(task.completedAt, isNotNull);

      task.setStatus('IN_PROGRESS');
      expect(task.status, 'IN_PROGRESS');
      expect(task.completedAt, isNull);
    });

    test('a task created with a submission link has submittedAt', () {
      final task = TaskItem(
        id: 't',
        title: 'Task',
        description: 'Description',
        assignedTo: 'Menisa',
        dueDate: '2026-11-20',
        status: 'DONE',
        submissionUrl: 'https://drive.google.com/file/d/example',
      );

      expect(task.submittedAt, isNotNull);
      expect(task.completedAt, isNotNull);
    });
  });

  group('Comment time', () {
    CommentItem commentAgo(Duration ago) => CommentItem(
          id: 'c',
          authorStudentId: '6731501101',
          authorName: 'Menisa',
          authorRole: 'MEMBER',
          text: 'Hello',
          createdAt: DateTime.now().subtract(ago),
        );

    test('shows a relative time based on createdAt', () {
      expect(commentAgo(const Duration(seconds: 5)).timeAgo, 'Just now');
      expect(commentAgo(const Duration(minutes: 10)).timeAgo, '10m ago');
      expect(commentAgo(const Duration(hours: 2)).timeAgo, '2h ago');
      expect(commentAgo(const Duration(days: 3)).timeAgo, '3d ago');
    });
  });
}
