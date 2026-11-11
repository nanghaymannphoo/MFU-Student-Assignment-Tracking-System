import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_notification.dart';
import '../../models/project_model.dart';
import '../../models/task_item.dart';
import '../../data/workspace_store.dart';
import '../../widgets/empty_state_card.dart';
import '../tasks/task_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback onRefresh;

  const NotificationsScreen({super.key, required this.onRefresh});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // 'ALL' or 'UNREAD'
  String _activeFilter = 'ALL';

  void _markAllAsRead() {
    WorkspaceStore.markAllReadForCurrentUser();
    setState(() {});
    widget.onRefresh();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deleteNotification(AppNotification n) {
    // Only the recipient may delete a notification (same rule as the database API).
    final removed = WorkspaceStore.deleteNotificationIfRecipient(
      notificationId: n.id,
      actorStudentId: WorkspaceStore.currentStudentId,
    );
    if (!removed) return;
    setState(() {});
    widget.onRefresh();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleNotificationTap(AppNotification n) async {
    // 1. Immediately mark notification as read and update unread badges
    if (!n.isRead) {
      setState(() {
        n.isRead = true;
        n.readAt = DateTime.now();
      });
      widget.onRefresh();
    }

    // 2. If this notification has a linked project and task, navigate to it safely
    if (n.projectId != null && n.taskId != null) {
      // Find project by explicit projectId
      ProjectModel? targetProject;
      for (final p in WorkspaceStore.projects) {
        if (p.id == n.projectId) {
          targetProject = p;
          break;
        }
      }

      if (targetProject == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This project is no longer available.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Verify current user still has access to this project
      final hasAccess = targetProject.members.any(
        (m) => m.studentId == WorkspaceStore.currentStudentId,
      );
      if (!hasAccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You no longer have access to this project.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Find task by explicit taskId (never parse titles or text)
      TaskItem? targetTask;
      for (final t in targetProject.tasks) {
        if (t.id == n.taskId) {
          targetTask = t;
          break;
        }
      }

      if (targetTask == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This task has been deleted or is no longer available.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Open destination TaskDetailScreen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailScreen(
            project: targetProject!,
            task: targetTask!,
          ),
        ),
      );

      if (mounted) {
        setState(() {});
        widget.onRefresh();
      }
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'COMMENT':
        return Icons.chat_bubble_outline_rounded;
      case 'TASK_ASSIGNED':
        return Icons.assignment_ind_outlined;
      case 'SUBMISSION':
        return Icons.cloud_done_outlined;
      case 'STATUS_CHANGED':
        return Icons.sync_rounded;
      case 'DEADLINE_EXTENDED':
        return Icons.event_repeat_rounded;
      case 'OVERDUE':
        return Icons.warning_amber_rounded;
      case 'ANNOUNCEMENT':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getIconColorForType(String type) {
    switch (type) {
      case 'OVERDUE':
        return AppColors.danger;
      case 'DEADLINE_EXTENDED':
        return AppColors.gold;
      case 'SUBMISSION':
        return const Color(0xFF16A34A);
      case 'COMMENT':
      case 'TASK_ASSIGNED':
      case 'STATUS_CHANGED':
      case 'ANNOUNCEMENT':
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Strictly retrieve notifications addressed to the current signed-in user
    final userNotifications = WorkspaceStore.getNotificationsForCurrentUser();
    final unreadCount = userNotifications.where((n) => !n.isRead).length;

    final displayedList = _activeFilter == 'UNREAD'
        ? userNotifications.where((n) => !n.isRead).toList()
        : userNotifications;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                disabledForegroundColor: AppColors.textSecondary.withValues(alpha: 0.38),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: unreadCount > 0 ? _markAllAsRead : null,
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text(
                'Mark all as read',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              // 1. Filter Chips Row (All vs Unread)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'All (${userNotifications.length})',
                      isSelected: _activeFilter == 'ALL',
                      onTap: () => setState(() => _activeFilter = 'ALL'),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Unread ($unreadCount)',
                      isSelected: _activeFilter == 'UNREAD',
                      badgeCount: unreadCount,
                      onTap: () => setState(() => _activeFilter = 'UNREAD'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // 2. Notification List or Empty State
              Expanded(
                child: displayedList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: _activeFilter == 'UNREAD'
                              ? const EmptyStateCard(
                                  icon: Icons.mark_email_read_outlined,
                                  title: 'No Unread Notifications',
                                  message: 'You have caught up with all your project alerts and updates.',
                                )
                              : const EmptyStateCard(
                                  icon: Icons.notifications_off_outlined,
                                  title: 'No Notifications Yet',
                                  message: 'Task assignments, comments, and project deadline updates will appear here.',
                                ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          WorkspaceStore.checkOverdueTasksAndNotify();
                          setState(() {});
                          widget.onRefresh();
                        },
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: displayedList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (ctx, index) {
                            final n = displayedList[index];
                            final isOverdue = n.type == 'OVERDUE';
                            final icon = _getIconForType(n.type);
                            final iconColor = _getIconColorForType(n.type);

                            // Subtle unread background vs clean card background
                            final cardBg = n.isRead
                                ? AppColors.cardBackground
                                : (isOverdue ? AppColors.dangerLight : AppColors.lightAccent);
                            final borderCol = n.isRead
                                ? AppColors.border
                                : (isOverdue
                                    ? AppColors.danger.withValues(alpha: 0.35)
                                    : AppColors.primary.withValues(alpha: 0.35));

                            return Card(
                              elevation: 0,
                              margin: EdgeInsets.zero,
                              color: cardBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: borderCol,
                                  width: !n.isRead ? 1.2 : 1.0,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _handleNotificationTap(n),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Type icon badge
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: n.isRead
                                              ? const Color(0xFFF1F5F9)
                                              : Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(icon, size: 18, color: iconColor),
                                      ),
                                      const SizedBox(width: 12),

                                      // Content details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Top Row: Title, relative time, and unread dot
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    n.title,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: n.isRead
                                                          ? FontWeight.w600
                                                          : FontWeight.bold,
                                                      color: isOverdue
                                                          ? AppColors.danger
                                                          : AppColors.textPrimary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  n.timeAgo,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                                if (!n.isRead) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    width: 7,
                                                    height: 7,
                                                    decoration: BoxDecoration(
                                                      color: isOverdue
                                                          ? AppColors.danger
                                                          : AppColors.primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),

                                            // Project & Task Context (if available)
                                            if (n.projectName != null || n.taskTitle != null) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                [
                                                  if (n.projectName != null) n.projectName!,
                                                  if (n.taskTitle != null) n.taskTitle!,
                                                ].join(' • '),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textSecondary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],

                                            // Notification Message preview
                                            const SizedBox(height: 5),
                                            Text(
                                              n.message,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: n.isRead
                                                    ? AppColors.textSecondary
                                                    : AppColors.textPrimary,
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Delete notification',
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        iconSize: 18,
                                        color: AppColors.textSecondary,
                                        icon: const Icon(Icons.delete_outline_rounded),
                                        onPressed: () => _deleteNotification(n),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
