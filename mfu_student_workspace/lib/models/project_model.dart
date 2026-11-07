import 'team_member.dart';
import 'task_item.dart';

class ProjectModel {
  final String id;
  final String title;
  final String courseCode;
  final String description;
  final String deadline;
  final String myRole; // 'PC' or 'Member'
  final List<TeamMember> members;
  final List<TaskItem> tasks;

  ProjectModel({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.description,
    required this.deadline,
    required this.myRole,
    required this.members,
    required this.tasks,
  });

  bool get isCurrentUserPC => myRole == 'PC';

  int get completedTasks => tasks.where((t) => t.status == 'DONE').length;
  double get progress => tasks.isEmpty ? 0.0 : completedTasks / tasks.length;
}

