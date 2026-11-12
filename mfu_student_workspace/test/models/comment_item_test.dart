
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/models/comment_item.dart';

CommentItem createComment(DateTime createdAt) {
  return CommentItem(
    id: 'C001',
    authorStudentId: 'ST001',
    authorName: 'Test User',
    authorRole: 'MEMBER',
    text: 'Test comment',
    createdAt: createdAt,
  );
}

void main() {
  group('CommentItem Model Tests', () {
    test('future timestamp should return Just now', () {
      final comment = createComment(
        DateTime.now().add(const Duration(minutes: 5)),
      );

      expect(comment.timeAgo, 'Just now');
    });

    test('should handle the one-minute boundary', () {
      final underOneMinute = createComment(
        DateTime.now().subtract(const Duration(seconds: 59)),
      );

      final oneMinute = createComment(
        DateTime.now().subtract(const Duration(minutes: 1)),
      );

      expect(underOneMinute.timeAgo, 'Just now');
      expect(oneMinute.timeAgo, '1m ago');
    });

    test('should show hours before reaching 24 hours', () {
      final comment = createComment(
        DateTime.now().subtract(
          const Duration(hours: 23, minutes: 59),
        ),
      );

      expect(comment.timeAgo, '23h ago');
    });

    test('should show formatted date after 7 days', () {
      final createdAt = DateTime.now().subtract(
        const Duration(days: 7),
      );

      final comment = createComment(createdAt);

      final expectedDate =
          '${createdAt.year}-'
          '${createdAt.month.toString().padLeft(2, '0')}-'
          '${createdAt.day.toString().padLeft(2, '0')}';

      expect(comment.timeAgo, expectedDate);
    });
  });
}
