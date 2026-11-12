
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/task_item.dart';
import 'package:mfu_student_workspace/models/team_member.dart';

ProjectModel createProject({
  String myRole = 'MEMBER',
  List<TaskItem> tasks = const [],
}) {
  return ProjectModel(
    id: 'p1',
    title: 'Test Project',
    courseCode: 'TEST101',
    description: 'Project for unit testing',
    deadline: '2026-12-01',
    myRole: myRole,
    members: <TeamMember>[],
    tasks: tasks,
  );
}

TaskItem createTask(String id, String status) {
  return TaskItem(
    id: id,
    title: 'Task $id',
    description: 'Test task',
    assignedTo: 'Test Member',
    dueDate: '2026-11-20',
    status: status,
  );
}

void main() {
  group('ProjectModel Unit Tests', () {
    test('PC role should return true', () {
      final project = createProject(myRole: 'PC');

      expect(project.isCurrentUserPC, true);
    });

    test('MEMBER role should return false', () {
      final project = createProject(myRole: 'MEMBER');

      expect(project.isCurrentUserPC, false);
    });

    test('completedTasks should count only DONE tasks', () {
      final project = createProject(
        tasks: [
          createTask('1', 'DONE'),
          createTask('2', 'TODO'),
          createTask('3', 'IN_PROGRESS'),
          createTask('4', 'DONE'),
        ],
      );

      expect(project.completedTasks, 2);
    });

    test('progress should be 0.0 when there are no tasks', () {
      final project = createProject();

      expect(project.progress, 0.0);
    });

    test('progress should calculate completed task ratio', () {
      final project = createProject(
        tasks: [
          createTask('1', 'DONE'),
          createTask('2', 'TODO'),
          createTask('3', 'DONE'),
          createTask('4', 'IN_PROGRESS'),
        ],
      );

      expect(project.progress, 0.5);
    });
  });
}
