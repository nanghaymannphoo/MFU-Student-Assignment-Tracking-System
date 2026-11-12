import 'project_model.dart';
import 'task_item.dart';

/// Represents a task associated with its parent project.
class AssignedTaskEntry {
  final ProjectModel project;
  final TaskItem task;

  const AssignedTaskEntry({
    required this.project,
    required this.task,
  });
}

