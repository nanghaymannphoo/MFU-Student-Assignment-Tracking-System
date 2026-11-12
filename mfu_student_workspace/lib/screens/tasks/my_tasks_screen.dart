import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/deadline_helpers.dart';
import '../../data/workspace_store.dart';
import '../../models/assigned_task_entry.dart';
import '../../widgets/empty_state_card.dart';
import 'task_detail_screen.dart';

class MyTasksScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const MyTasksScreen({super.key, this.onRefresh});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  // 'PENDING' (default) or 'DONE'
  String _activeFilter = 'PENDING';

  @override
  Widget build(BuildContext context) {
    // 1. Fetch strictly tasks assigned to the signed-in user's Student ID
    // across projects they belong to (including projects where they are PC).
    final allMyTasks = WorkspaceStore.getAssignedTasksForCurrentUser();

    final pendingTasks = allMyTasks.where((e) => e.task.status != 'DONE').toList();
    final doneTasks = allMyTasks.where((e) => e.task.status == 'DONE').toList();

    // Group pending tasks: Overdue, Due Today, Upcoming, No Deadline
    final overdueEntries = <AssignedTaskEntry>[];
    final dueTodayEntries = <AssignedTaskEntry>[];
    final upcomingEntries = <AssignedTaskEntry>[];
    final noDeadlineEntries = <AssignedTaskEntry>[];

    for (final entry in pendingTasks) {
      final dueDateStr = entry.task.dueDate.trim();
      if (dueDateStr.isEmpty) {
        noDeadlineEntries.add(entry);
      } else if (isTaskOverdue(entry.task)) {
        overdueEntries.add(entry);
      } else if (isTaskDueToday(entry.task)) {
        dueTodayEntries.add(entry);
      } else if (DateTime.tryParse(dueDateStr) != null) {
        upcomingEntries.add(entry);
      } else {
        noDeadlineEntries.add(entry);
      }
    }

    // Sort overdue tasks by oldest deadline first (earliest calendar date first)
    overdueEntries.sort((a, b) => a.task.dueDate.trim().compareTo(b.task.dueDate.trim()));

    // Sort upcoming tasks by nearest deadline first (earliest upcoming date first)
    upcomingEntries.sort((a, b) => a.task.dueDate.trim().compareTo(b.task.dueDate.trim()));

    // Sort due today and no-deadline by task title
    dueTodayEntries.sort((a, b) => a.task.title.compareTo(b.task.title));
    noDeadlineEntries.sort((a, b) => a.task.title.compareTo(b.task.title));

    // Sort done tasks by due date descending (or title)
    doneTasks.sort((a, b) {
      if (a.task.dueDate.isNotEmpty && b.task.dueDate.isNotEmpty) {
        return b.task.dueDate.compareTo(a.task.dueDate);
      }
      return a.task.title.compareTo(b.task.title);
    });

    final remainingCount = pendingTasks.length;
    final overdueCount = overdueEntries.length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Tasks',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Student ID: ${WorkspaceStore.currentStudentId}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              WorkspaceStore.checkOverdueTasksAndNotify();
              setState(() {});
              widget.onRefresh?.call();
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              WorkspaceStore.checkOverdueTasksAndNotify();
              setState(() {});
              widget.onRefresh?.call();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // 1. Compact Summary Card: e.g. "5 tasks remaining · 1 overdue"
                _buildCompactSummaryCard(
                  remainingCount: remainingCount,
                  overdueCount: overdueCount,
                  totalAssigned: allMyTasks.length,
                ),
                const SizedBox(height: 12),

                // 2. Pending / Done Filter Selector
                _buildFilterSelector(
                  pendingCount: pendingTasks.length,
                  doneCount: doneTasks.length,
                ),
                const SizedBox(height: 16),

                // 3. Filtered Content
                if (_activeFilter == 'PENDING') ...[
                  if (pendingTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: allMyTasks.isEmpty
                          ? const EmptyStateCard(
                              icon: Icons.assignment_outlined,
                              title: 'No Tasks Assigned',
                              message: 'You currently have no tasks assigned to your Student ID.',
                            )
                          : const EmptyStateCard(
                              icon: Icons.task_alt_rounded,
                              title: 'All Tasks Completed!',
                              message: 'Great job! You have completed all personal tasks assigned to you.',
                            ),
                    )
                  else ...[
                    // Group 1: Overdue (hidden if empty)
                    if (overdueEntries.isNotEmpty) ...[
                      _buildGroupHeader(
                        title: 'Overdue',
                        count: overdueEntries.length,
                        color: AppColors.danger,
                        bgColor: AppColors.dangerLight,
                      ),
                      const SizedBox(height: 8),
                      ...overdueEntries.map((e) => _buildTaskCard(e)),
                      const SizedBox(height: 16),
                    ],

                    // Group 2: Due Today (hidden if empty)
                    if (dueTodayEntries.isNotEmpty) ...[
                      _buildGroupHeader(
                        title: 'Due Today',
                        count: dueTodayEntries.length,
                        color: AppColors.primary,
                        bgColor: AppColors.lightAccent,
                      ),
                      const SizedBox(height: 8),
                      ...dueTodayEntries.map((e) => _buildTaskCard(e)),
                      const SizedBox(height: 16),
                    ],

                    // Group 3: Upcoming (hidden if empty)
                    if (upcomingEntries.isNotEmpty) ...[
                      _buildGroupHeader(
                        title: 'Upcoming',
                        count: upcomingEntries.length,
                        color: AppColors.textPrimary,
                        bgColor: const Color(0xFFF1F5F9),
                      ),
                      const SizedBox(height: 8),
                      ...upcomingEntries.map((e) => _buildTaskCard(e)),
                      const SizedBox(height: 16),
                    ],

                    // Group 4: No Deadline (hidden if empty)
                    if (noDeadlineEntries.isNotEmpty) ...[
                      _buildGroupHeader(
                        title: 'No Deadline',
                        count: noDeadlineEntries.length,
                        color: AppColors.textSecondary,
                        bgColor: const Color(0xFFF1F5F9),
                      ),
                      const SizedBox(height: 8),
                      ...noDeadlineEntries.map((e) => _buildTaskCard(e)),
                    ],
                  ],
                ] else ...[
                  // Done filter content
                  if (doneTasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: EmptyStateCard(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'No Completed Tasks',
                        message: 'Tasks you finish will be kept accessible here.',
                      ),
                    )
                  else
                    ...doneTasks.map((e) => _buildTaskCard(e)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // COMPACT SUMMARY CARD
  // ==========================================
  Widget _buildCompactSummaryCard({
    required int remainingCount,
    required int overdueCount,
    required int totalAssigned,
  }) {
    final taskWord = remainingCount == 1 ? 'task' : 'tasks';
    final remainingText = '$remainingCount $taskWord remaining';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: overdueCount > 0
              ? AppColors.danger.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: overdueCount > 0 ? AppColors.dangerLight : AppColors.lightAccent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              overdueCount > 0 ? Icons.warning_amber_rounded : Icons.task_alt_rounded,
              size: 20,
              color: overdueCount > 0 ? AppColors.danger : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      remainingText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      ' · ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$overdueCount overdue',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: overdueCount > 0 ? AppColors.danger : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Personal assignments across your group projects ($totalAssigned total)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PENDING / DONE FILTER SELECTOR
  // ==========================================
  Widget _buildFilterSelector({
    required int pendingCount,
    required int doneCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _activeFilter = 'PENDING'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _activeFilter == 'PENDING' ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Pending ($pendingCount)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _activeFilter == 'PENDING' ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _activeFilter = 'DONE'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _activeFilter == 'DONE' ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'Done ($doneCount)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _activeFilter == 'DONE' ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION GROUP HEADER
  // ==========================================
  Widget _buildGroupHeader({
    required String title,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // COMPACT TASK CARD
  // ==========================================
  Widget _buildTaskCard(AssignedTaskEntry entry) {
    final task = entry.task;
    final project = entry.project;
    final isOverdue = isTaskOverdue(task);
    final isDueToday = isTaskDueToday(task);
    final relativeLabel = getDeadlineRelativeLabel(task.dueDate, status: task.status);

    Color statusFg;
    Color statusBg;
    String statusLabel;

    switch (task.status.toUpperCase()) {
      case 'DONE':
        statusFg = AppColors.primary;
        statusBg = AppColors.lightAccent;
        statusLabel = 'Completed';
        break;
      case 'IN_PROGRESS':
        statusFg = AppColors.gold;
        statusBg = AppColors.lightGold;
        statusLabel = 'In Progress';
        break;
      case 'TODO':
      default:
        statusFg = AppColors.textSecondary;
        statusBg = const Color(0xFFF1F5F9);
        statusLabel = 'To Do';
        break;
    }

    final cardBg = isOverdue ? AppColors.dangerLight : AppColors.cardBackground;
    final borderCol = isOverdue
        ? AppColors.danger.withValues(alpha: 0.35)
        : AppColors.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderCol,
            width: isOverdue ? 1.2 : 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TaskDetailScreen(
                  project: project,
                  task: task,
                ),
              ),
            );
            if (mounted) {
              setState(() {});
              widget.onRefresh?.call();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Project info & Status badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${project.courseCode} • ${project.title}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusFg.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Middle row: Task Title
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Bottom row: Due Date and Relative Deadline indicator
                Row(
                  children: [
                    Icon(
                      task.dueDate.trim().isEmpty
                          ? Icons.event_busy_rounded
                          : Icons.calendar_today_rounded,
                      size: 12,
                      color: isOverdue ? AppColors.danger : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.dueDate.trim().isEmpty
                          ? 'No deadline set'
                          : 'Due ${task.dueDate.trim()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? AppColors.danger : AppColors.textPrimary,
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (task.dueDate.trim().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '•  $relativeLabel',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: (isOverdue || isDueToday)
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isOverdue
                              ? AppColors.danger
                              : (isDueToday ? AppColors.primary : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
