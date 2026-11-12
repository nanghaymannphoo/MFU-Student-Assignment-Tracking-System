
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/models/api_models.dart';

String dateString(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

void main() {
  group('DeadlineItem', () {
    test('parses deadline JSON correctly', () {
      final deadline = DeadlineItem.fromJSON({
        'id': 'task-001',
        'title': 'Submit Assignment',
        'project_id': 'project-001',
        'project_title': 'Test Project',
        'due_date': '2025-05-10',
        'status': 'TODO',
      });

      expect(deadline.taskId, 'task-001');
      expect(deadline.title, 'Submit Assignment');
      expect(deadline.projectId, 'project-001');
      expect(deadline.projectTitle, 'Test Project');
      expect(deadline.dueDate, '2025-05-10');
      expect(deadline.status, 'TODO');
    });

    test('uses default project title when missing', () {
      final deadline = DeadlineItem.fromJSON({
        'id': 'task-002',
        'title': 'Another Assignment',
        'project_id': 'project-002',
        'due_date': '2025-05-15',
        'status': 'DONE',
      });

      expect(deadline.projectTitle, '');
    });
  });

  group('TaskData', () {
    test('parses task JSON correctly', () {
      final task = TaskData.fromJSON({
        'id': 'task-001',
        'project_id': 'project-001',
        'title': 'Complete Unit Test',
        'description': 'Write model unit tests',
        'assigned_to': '6731501105',
        'assigned_name': 'Test User',
        'due_date': '2099-05-10',
        'status': 'IN_PROGRESS',
        'submission_url': 'https://example.com/submission',
        'submitted_at': '2025-05-09T10:00:00',
        'completed_at': '',
        'my_role': 'MEMBER',
      });

      expect(task.id, 'task-001');
      expect(task.projectId, 'project-001');
      expect(task.title, 'Complete Unit Test');
      expect(task.description, 'Write model unit tests');
      expect(task.assignedTo, '6731501105');
      expect(task.assignedName, 'Test User');
      expect(task.dueDate, '2099-05-10');
      expect(task.status, 'IN_PROGRESS');
      expect(task.submissionUrl, 'https://example.com/submission');
      expect(task.submittedAt, '2025-05-09T10:00:00');
      expect(task.completedAt, '');
      expect(task.myRole, 'MEMBER');
      expect(task.isDone, isFalse);
      expect(task.isOverdue, isFalse);
    });

    test('uses default values for optional fields', () {
      final task = TaskData.fromJSON({
        'id': 'task-002',
        'title': 'Default Task',
      });

      expect(task.projectId, '');
      expect(task.description, '');
      expect(task.assignedTo, isNull);
      expect(task.assignedName, '');
      expect(task.dueDate, '');
      expect(task.status, 'TODO');
      expect(task.submissionUrl, isNull);
      expect(task.submittedAt, '');
      expect(task.completedAt, '');
      expect(task.myRole, '');
      expect(task.isDone, isFalse);
      expect(task.isOverdue, isFalse);
    });

    test('identifies completed task', () {
      final task = TaskData.fromJSON({
        'id': 'task-003',
        'title': 'Completed Task',
        'status': 'DONE',
      });

      expect(task.isDone, isTrue);
    });

    test('identifies task that is not completed', () {
      final task = TaskData.fromJSON({
        'id': 'task-004',
        'title': 'Incomplete Task',
        'status': 'TODO',
      });

      expect(task.isDone, isFalse);
    });

    test('identifies overdue task', () {
      final yesterday = DateTime.now().subtract(
        const Duration(days: 1),
      );

      final task = TaskData.fromJSON({
        'id': 'task-005',
        'title': 'Overdue Task',
        'due_date': dateString(yesterday),
        'status': 'TODO',
      });

      expect(task.isOverdue, isTrue);
    });

    test('does not identify task due today as overdue', () {
      final task = TaskData.fromJSON({
        'id': 'task-006',
        'title': 'Task Due Today',
        'due_date': dateString(DateTime.now()),
        'status': 'TODO',
      });

      expect(task.isOverdue, isFalse);
    });

    test('does not identify future task as overdue', () {
      final tomorrow = DateTime.now().add(
        const Duration(days: 1),
      );

      final task = TaskData.fromJSON({
        'id': 'task-007',
        'title': 'Future Task',
        'due_date': dateString(tomorrow),
        'status': 'TODO',
      });

      expect(task.isOverdue, isFalse);
    });

    test('completed task is not overdue', () {
      final task = TaskData.fromJSON({
        'id': 'task-008',
        'title': 'Completed Task',
        'due_date': '2000-01-01',
        'status': 'DONE',
      });

      expect(task.isOverdue, isFalse);
    });

    test('task without deadline is not overdue', () {
      final task = TaskData.fromJSON({
        'id': 'task-009',
        'title': 'No Deadline Task',
        'status': 'TODO',
      });

      expect(task.isOverdue, isFalse);
    });
  });
}
