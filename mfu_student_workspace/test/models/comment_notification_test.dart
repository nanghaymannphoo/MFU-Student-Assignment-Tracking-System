
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/models/api_models.dart';

void main() {
  group('CommentData', () {
    test('parses comment JSON correctly', () {
      final comment = CommentData.fromJSON({
        'id': '25',
        'task_id': 'task-001',
        'author_id': '6731501105',
        'author_name': 'Test User',
        'author_avatar': 'avatar.png',
        'author_role': 'PC',
        'comment_text': 'This is a test comment',
        'created_at': '2026-11-12T10:00:00',
      });

      expect(comment.id, 25);
      expect(comment.taskId, 'task-001');
      expect(comment.authorId, '6731501105');
      expect(comment.authorName, 'Test User');
      expect(comment.authorAvatar, 'avatar.png');
      expect(comment.authorRole, 'PC');
      expect(comment.text, 'This is a test comment');
      expect(comment.createdAt, '2026-11-12T10:00:00');
    });

    test('uses default values for optional fields', () {
      final comment = CommentData.fromJSON({
        'id': 1,
        'author_id': '6731501106',
        'comment_text': 'Hello',
      });

      expect(comment.taskId, '');
      expect(comment.authorName, '');
      expect(comment.authorAvatar, isNull);
      expect(comment.authorRole, '');
      expect(comment.createdAt, '');
    });

    test('identifies comment written by current user', () {
      final comment = CommentData.fromJSON({
        'id': 1,
        'author_id': '6731501105',
        'comment_text': 'My comment',
      });

      expect(comment.isMine('6731501105'), isTrue);
    });

    test('does not identify another user comment as mine', () {
      final comment = CommentData.fromJSON({
        'id': 2,
        'author_id': '6731501106',
        'comment_text': 'Another comment',
      });

      expect(comment.isMine('6731501105'), isFalse);
    });
  });

  group('NotificationData', () {
    test('parses notification JSON correctly', () {
      final notification = NotificationData.fromJSON({
        'id': 'notification-001',
        'sender_id': '6731501105',
        'sender_name': 'Test User',
        'project_id': 'project-001',
        'task_id': 'task-001',
        'title': 'New comment',
        'message': 'Someone commented on your task',
        'is_read': true,
        'created_at': '2026-11-12T10:00:00',
        'type': 'COMMENT',
      });

      expect(notification.id, 'notification-001');
      expect(notification.senderId, '6731501105');
      expect(notification.senderName, 'Test User');
      expect(notification.projectId, 'project-001');
      expect(notification.taskId, 'task-001');
      expect(notification.title, 'New comment');
      expect(notification.message, 'Someone commented on your task');
      expect(notification.isRead, isTrue);
      expect(notification.createdAt, '2026-11-12T10:00:00');
      expect(notification.type, 'COMMENT');
    });

    test('recognizes numeric 1 as read notification', () {
      final notification = NotificationData.fromJSON({
        'id': 'notification-002',
        'title': 'Read notification',
        'is_read': 1,
      });

      expect(notification.isRead, isTrue);
    });

    test('keeps notification unread for other values', () {
      for (final value in [false, 0, '1']) {
        final notification = NotificationData.fromJSON({
          'id': 'notification-003',
          'title': 'Unread notification',
          'is_read': value,
        });

        expect(notification.isRead, isFalse);
      }
    });

    test('uses default values for optional fields', () {
      final notification = NotificationData.fromJSON({
        'id': 'notification-004',
        'title': 'Default notification',
      });

      expect(notification.senderId, isNull);
      expect(notification.senderName, '');
      expect(notification.projectId, isNull);
      expect(notification.taskId, isNull);
      expect(notification.message, '');
      expect(notification.isRead, isFalse);
      expect(notification.createdAt, '');
      expect(notification.type, '');
    });
  });
}