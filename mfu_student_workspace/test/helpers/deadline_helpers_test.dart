
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/core/utils/deadline_helpers.dart';
import 'package:mfu_student_workspace/models/task_item.dart';

TaskItem createTask({
  String dueDate = '',
  String status = 'TODO',
}) {
  return TaskItem(
    id: 'test-001',
    title: 'Test Task',
    description: 'Unit Test',
    assignedTo: 'Test User',
    dueDate: dueDate,
    status: status,
  );
}

String dateOnly(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}

void main() {
  group('isTaskOverdue', () {
    test('returns true when task deadline has passed', () {
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 1));

      final task = createTask(dueDate: dateOnly(yesterday));

      expect(isTaskOverdue(task), isTrue);
    });

    test('returns false when deadline is today', () {
      final task = createTask(dueDate: dateOnly(DateTime.now()));

      expect(isTaskOverdue(task), isFalse);
    });

    test('returns false when deadline is in the future', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final task = createTask(dueDate: dateOnly(tomorrow));

      expect(isTaskOverdue(task), isFalse);
    });

    test('returns false when task is completed', () {
      final task = createTask(
        dueDate: '2020-01-01',
        status: 'DONE',
      );

      expect(isTaskOverdue(task), isFalse);
    });

    test('returns false when deadline is empty', () {
      final task = createTask(dueDate: '');

      expect(isTaskOverdue(task), isFalse);
    });

    test('returns false when deadline is invalid', () {
      final task = createTask(dueDate: 'invalid-date');

      expect(isTaskOverdue(task), isFalse);
    });
  });

  group('isTaskDueToday', () {
    test('returns true when deadline is today', () {
      final task = createTask(dueDate: dateOnly(DateTime.now()));

      expect(isTaskDueToday(task), isTrue);
    });

    test('returns false when deadline is yesterday', () {
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 1));

      final task = createTask(dueDate: dateOnly(yesterday));

      expect(isTaskDueToday(task), isFalse);
    });

    test('returns false when task is completed', () {
      final task = createTask(
        dueDate: dateOnly(DateTime.now()),
        status: 'DONE',
      );

      expect(isTaskDueToday(task), isFalse);
    });

    test('returns false when deadline is empty', () {
      final task = createTask(dueDate: '');

      expect(isTaskDueToday(task), isFalse);
    });

    test('returns false when deadline is invalid', () {
      final task = createTask(dueDate: 'invalid-date');

      expect(isTaskDueToday(task), isFalse);
    });
  });

  group('getDeadlineRelativeLabel', () {
    test('returns Completed when status is DONE', () {
      expect(
        getDeadlineRelativeLabel('2020-01-01', status: 'DONE'),
        'Completed',
      );
    });

    test('returns No deadline when date is empty', () {
      expect(getDeadlineRelativeLabel(''), 'No deadline');
    });

    test('returns Invalid date when date is invalid', () {
      expect(
        getDeadlineRelativeLabel('invalid-date'),
        'Invalid date',
      );
    });

    test('returns Due today when deadline is today', () {
      expect(
        getDeadlineRelativeLabel(dateOnly(DateTime.now())),
        'Due today',
      );
    });

    test('returns Due tomorrow when deadline is tomorrow', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      expect(
        getDeadlineRelativeLabel(dateOnly(tomorrow)),
        'Due tomorrow',
      );
    });

    test('returns correct label for future deadlines', () {
      final futureDate = DateTime.now().add(const Duration(days: 3));

      expect(
        getDeadlineRelativeLabel(dateOnly(futureDate)),
        'Due in 3 days',
      );
    });

    test('returns 1 day overdue when deadline was yesterday', () {
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 1));

      expect(
        getDeadlineRelativeLabel(dateOnly(yesterday)),
        '1 day overdue',
      );
    });

    test('returns correct label for multiple overdue days', () {
      final today = DateTime.now();
      final fourDaysAgo = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 4));

      expect(
        getDeadlineRelativeLabel(dateOnly(fourDaysAgo)),
        '4 days overdue',
      );
    });
  });
}
