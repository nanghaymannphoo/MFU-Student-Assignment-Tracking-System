
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/models/app_notification.dart';

AppNotification createNotification({
  DateTime? createdAt,
  DateTime? readAt,
  bool isRead = false,
  String? projectId,
  String? taskId,
  String? commentId,
  String? taskTitle,
  String? projectName,
}) {
  return AppNotification(
    id: 'N001',
    eventId: 'E001',
    type: 'COMMENT',
    title: 'New Comment',
    message: 'Someone commented on your task',
    recipientStudentId: 'ST001',
    actorStudentId: 'ST002',
    projectId: projectId,
    taskId: taskId,
    commentId: commentId,
    taskTitle: taskTitle,
    projectName: projectName,
    createdAt: createdAt ?? DateTime(2026, 11, 1),
    readAt: readAt,
    isRead: isRead,
  );
}

void main() {
  group('AppNotification Model Tests', () {
    test('should use correct default values', () {
      final notification = createNotification();

      expect(notification.isRead, false);
      expect(notification.readAt, isNull);
      expect(notification.projectId, isNull);
      expect(notification.taskId, isNull);
      expect(notification.commentId, isNull);
    });

    test('should preserve provided notification data', () {
      final createdAt = DateTime(2026, 11, 1);
      final readAt = DateTime(2026, 11, 2);

      final notification = createNotification(
        createdAt: createdAt,
        readAt: readAt,
        isRead: true,
        projectId: 'P001',
        taskId: 'T001',
        commentId: 'C001',
        taskTitle: 'Test Task',
        projectName: 'Test Project',
      );

      expect(notification.createdAt, createdAt);
      expect(notification.readAt, readAt);
      expect(notification.isRead, true);
      expect(notification.projectId, 'P001');
      expect(notification.taskId, 'T001');
      expect(notification.commentId, 'C001');
      expect(notification.taskTitle, 'Test Task');
      expect(notification.projectName, 'Test Project');
    });

    test('timeAgo should return Just now for future timestamps', () {
      final notification = createNotification(
        createdAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      expect(notification.timeAgo, 'Just now');
    });

    test('timeAgo should return Just now for timestamps under one minute', () {
      final notification = createNotification(
        createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      expect(notification.timeAgo, 'Just now');
    });

    test('timeAgo should return minutes ago', () {
      final notification = createNotification(
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      expect(notification.timeAgo, '10m ago');
    });

    test('timeAgo should return hours ago', () {
      final notification = createNotification(
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      expect(notification.timeAgo, '2h ago');
    });

    test('timeAgo should return days ago', () {
      final notification = createNotification(
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      );

      expect(notification.timeAgo, '3d ago');
    });

    test('timeAgo should return date for timestamps older than 7 days', () {
      final notification = createNotification(
        createdAt: DateTime(2026, 10, 1),
      );

      expect(notification.timeAgo, '2026-10-01');
    });
  });
}
