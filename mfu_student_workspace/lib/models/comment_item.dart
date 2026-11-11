class CommentItem {
  final String id; // Unique comment id (task_comments.id)
  final String authorStudentId; // Author (task_comments.author_id)
  final String authorName;
  final String authorRole; // 'PC' or 'MEMBER'
  final String text;
  final DateTime createdAt; // task_comments.created_at

  CommentItem({
    required this.id,
    required this.authorStudentId,
    required this.authorName,
    required this.authorRole,
    required this.text,
    required this.createdAt,
  });

  /// Relative time such as "Just now", "2h ago" or "3d ago".
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
