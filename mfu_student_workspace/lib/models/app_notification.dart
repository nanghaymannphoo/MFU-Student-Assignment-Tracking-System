class AppNotification {
  final String id;
  final String eventId;
  final String type; // 'TASK_ASSIGNED', 'TASK_REASSIGNED', 'SUBMISSION', 'DEADLINE_EXTENDED', 'STATUS_CHANGED', 'COMMENT', 'OVERDUE', 'ANNOUNCEMENT'
  final String title;
  final String message;
  final String recipientStudentId;
  final String actorStudentId;
  final String? projectId;
  final String? taskId;
  final String? commentId;
  final String? taskTitle;
  final String? projectName;
  final DateTime createdAt;
  DateTime? readAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.eventId,
    required this.type,
    required this.title,
    required this.message,
    required this.recipientStudentId,
    required this.actorStudentId,
    this.projectId,
    this.taskId,
    this.commentId,
    this.taskTitle,
    this.projectName,
    required this.createdAt,
    this.readAt,
    this.isRead = false,
  });

  /// Derives human-readable relative time from real stored createdAt timestamp.
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.isNegative || diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
    }
  }
}
