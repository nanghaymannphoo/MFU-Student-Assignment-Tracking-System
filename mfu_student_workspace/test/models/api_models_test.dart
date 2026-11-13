
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/models/api_models.dart';

String dateString(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

void main() {
  group('dateOnly', () {
    test('returns empty string when input is null', () {
      expect(dateOnly(null), '');
    });

    test('keeps YYYY-MM-DD format unchanged', () {
      expect(dateOnly('2025-05-10'), '2025-05-10');
    });

    test('converts timestamp to local date', () {
      const timestamp = '2025-05-10T23:30:00Z';
      final expected = dateString(
        DateTime.parse(timestamp).toLocal(),
      );

      expect(dateOnly(timestamp), expected);
    });

    test('returns original value when date is invalid', () {
      expect(dateOnly('invalid-date'), 'invalid-date');
    });
  });

  group('UserModel', () {
    test('parses user JSON correctly', () {
      final user = UserModel.fromJSON({
        'student_id': '6731501105',
        'full_name': 'Test User',
        'email': 'test@example.com',
        'avatar_url': 'https://example.com/avatar.png',
      });

      expect(user.studentId, '6731501105');
      expect(user.fullName, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
    });

    test('uses default values for optional fields', () {
      final user = UserModel.fromJSON({
        'student_id': '6731501105',
        'full_name': 'Test User',
      });

      expect(user.email, '');
      expect(user.avatarUrl, isNull);
    });
  });

  group('MemberModel', () {
    test('parses member JSON correctly', () {
      final member = MemberModel.fromJSON({
        'student_id': '6731501106',
        'full_name': 'Member One',
        'email': 'member@example.com',
        'avatar_url': 'avatar.png',
        'project_role': 'PC',
        'joined_at': '2025-05-10',
      });

      expect(member.studentId, '6731501106');
      expect(member.fullName, 'Member One');
      expect(member.email, 'member@example.com');
      expect(member.avatarUrl, 'avatar.png');
      expect(member.projectRole, 'PC');
      expect(member.joinedAt, '2025-05-10');
      expect(member.isPC, isTrue);
    });

    test('uses default values for optional fields', () {
      final member = MemberModel.fromJSON({
        'student_id': '6731501107',
        'full_name': 'Member Two',
      });

      expect(member.email, '');
      expect(member.avatarUrl, isNull);
      expect(member.projectRole, 'MEMBER');
      expect(member.joinedAt, '');
      expect(member.isPC, isFalse);
    });
  });

  group('ProjectData', () {
    test('parses project JSON and nested members correctly', () {
      final project = ProjectData.fromJSON({
        'id': 'project-001',
        'title': 'Test Project',
        'course_code': 'CE101',
        'description': 'Unit Test Project',
        'deadline': '2025-05-10',
        'created_by': '6731501105',
        'my_role': 'PC',
        'members': [
          {
            'student_id': '6731501106',
            'full_name': 'Member One',
            'project_role': 'MEMBER',
          },
        ],
        'member_count': '2',
        'task_total': 4,
        'task_todo': '1',
        'task_in_progress': 1.8,
        'task_done': '2',
        'task_overdue': null,
      });

      expect(project.id, 'project-001');
      expect(project.title, 'Test Project');
      expect(project.courseCode, 'CE101');
      expect(project.description, 'Unit Test Project');
      expect(project.deadline, '2025-05-10');
      expect(project.createdBy, '6731501105');
      expect(project.myRole, 'PC');
      expect(project.isPC, isTrue);

      expect(project.members.length, 1);
      expect(project.members.first.studentId, '6731501106');

      expect(project.memberCount, 2);
      expect(project.taskTotal, 4);
      expect(project.taskTodo, 1);
      expect(project.taskInProgress, 1);
      expect(project.taskDone, 2);
      expect(project.taskOverdue, 0);

      expect(project.progress, 0.5);
    });

    test('uses default values when optional fields are missing', () {
      final project = ProjectData.fromJSON({
        'id': 'project-002',
        'title': 'Another Project',
      });

      expect(project.courseCode, '');
      expect(project.description, '');
      expect(project.deadline, '');
      expect(project.createdBy, '');
      expect(project.myRole, 'MEMBER');
      expect(project.isPC, isFalse);
      expect(project.members, isEmpty);

      expect(project.memberCount, 0);
      expect(project.taskTotal, 0);
      expect(project.taskTodo, 0);
      expect(project.taskInProgress, 0);
      expect(project.taskDone, 0);
      expect(project.taskOverdue, 0);

      expect(project.progress, 0);
    });
  });
}
