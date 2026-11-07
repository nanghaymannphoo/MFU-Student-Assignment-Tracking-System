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
    List<CommentItem>? comments,
  }) : comments = comments ?? [];
}
