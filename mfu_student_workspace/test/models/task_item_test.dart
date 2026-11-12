
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/models/task_item.dart';

void main() {
  group('TaskItem Model Tests', () {
    test('should use correct default values', () {
      final task = TaskItem(
        id: 'T001',
        title: 'Test Task',
        description: 'Test Description',
        assignedTo: 'Test User',
        dueDate: '2026-12-01',
      );

      expect(task.assignedStudentId, '');
      expect(task.status, 'TODO');
      expect(task.submissionUrl, isNull);
      expect(task.submittedAt, isNull);
      expect(task.completedAt, isNull);
      expect(task.comments, isEmpty);
    });

    test('should preserve explicitly provided timestamps', () {
      final submittedAt = DateTime(2026, 11, 10, 10);
      final completedAt = DateTime(2026, 11, 11, 15);

      final task = TaskItem(
        id: 'T002',
        title: 'Completed Task',
        description: 'Test Description',
        assignedTo: 'Test User',
        dueDate: '2026-12-01',
        status: 'DONE',
        submittedAt: submittedAt,
        completedAt: completedAt,
      );

      expect(task.submittedAt, submittedAt);
      expect(task.completedAt, completedAt);
    });

    test('submissionUrl should set submittedAt without completing a TODO task', () {
      final task = TaskItem(
        id: 'T003',
        title: 'Submitted Task',
        description: 'Test Description',
        assignedTo: 'Test User',
        dueDate: '2026-12-01',
        submissionUrl: 'https://example.com/submission',
      );

      expect(task.status, 'TODO');
      expect(task.submittedAt, isNotNull);
      expect(task.completedAt, isNull);
    });
  });
}
