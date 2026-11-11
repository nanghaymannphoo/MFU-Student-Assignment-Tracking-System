import 'comment_item.dart';

class TaskItem {
  String id;
  String title;
  String description;
  String assignedTo; // Member display name
  String assignedStudentId; // Associated Member Student ID
  String dueDate;
  String status; // 'TODO', 'IN_PROGRESS', 'DONE'
  String? submissionUrl;
  DateTime? submittedAt; // When work was submitted (tasks.submitted_at)
  DateTime? completedAt; // When the task became DONE (tasks.completed_at)
  List<CommentItem> comments;

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    this.assignedStudentId = '',
    required this.dueDate,
    this.status = 'TODO',
    this.submissionUrl,
    DateTime? submittedAt,
    DateTime? completedAt,
    List<CommentItem>? comments,
  })  : submittedAt = submittedAt ?? (submissionUrl != null ? DateTime.now() : null),
        completedAt = completedAt ?? (status == 'DONE' ? DateTime.now() : null),
        comments = comments ?? [];

  /// Changes the status and keeps completedAt in sync:
  /// DONE sets it, any other status clears it.
  void setStatus(String newStatus) {
    status = newStatus;
    completedAt = newStatus.toUpperCase() == 'DONE' ? DateTime.now() : null;
  }
}
