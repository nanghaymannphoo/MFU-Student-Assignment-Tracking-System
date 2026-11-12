
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/models/api_models.dart';

void main() {
  group('DashboardModel', () {
    test('parses dashboard JSON correctly', () {
      final dashboard = DashboardModel.fromJSON({
        'total_projects': '3',
        'total_tasks': 12,
        'todo': '4',
        'in_progress': 3.7,
        'done': 5,
        'overdue': null,
        'upcoming_deadlines': [
          {
            'id': 'task-001',
            'title': 'Submit Assignment',
            'project_id': 'project-001',
            'project_title': 'Test Project',
            'due_date': '2026-11-20',
            'status': 'TODO',
          },
          {
            'id': 'task-002',
            'title': 'Finish Report',
            'project_id': 'project-002',
            'project_title': 'Another Project',
            'due_date': '2026-11-25',
            'status': 'IN_PROGRESS',
          },
        ],
      });

      expect(dashboard.totalProjects, 3);
      expect(dashboard.totalTasks, 12);
      expect(dashboard.todo, 4);
      expect(dashboard.inProgress, 3);
      expect(dashboard.done, 5);
      expect(dashboard.overdue, 0);

      expect(dashboard.upcomingDeadlines.length, 2);
      expect(dashboard.upcomingDeadlines.first.taskId, 'task-001');
      expect(dashboard.upcomingDeadlines.first.title, 'Submit Assignment');
      expect(
        dashboard.upcomingDeadlines.first.projectTitle,
        'Test Project',
      );
      expect(dashboard.upcomingDeadlines.last.taskId, 'task-002');
      expect(dashboard.upcomingDeadlines.last.status, 'IN_PROGRESS');
    });

    test('uses zero values when dashboard counts are missing', () {
      final dashboard = DashboardModel.fromJSON({});

      expect(dashboard.totalProjects, 0);
      expect(dashboard.totalTasks, 0);
      expect(dashboard.todo, 0);
      expect(dashboard.inProgress, 0);
      expect(dashboard.done, 0);
      expect(dashboard.overdue, 0);
      expect(dashboard.upcomingDeadlines, isEmpty);
    });

    test('uses empty deadline list when upcoming_deadlines is null', () {
      final dashboard = DashboardModel.fromJSON({
        'total_projects': 2,
        'total_tasks': 5,
        'upcoming_deadlines': null,
      });

      expect(dashboard.totalProjects, 2);
      expect(dashboard.totalTasks, 5);
      expect(dashboard.upcomingDeadlines, isEmpty);
    });
  });
}
