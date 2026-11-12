import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_picker_utils.dart';
import '../../core/utils/status_helpers.dart';
import '../../models/project_model.dart';
import '../../models/task_item.dart';
import '../../models/team_member.dart';
import '../../data/workspace_store.dart';
import '../../widgets/empty_state_card.dart';
import '../projects/project_detail_screen.dart';
import '../tasks/task_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onOpenNotifications;
  final VoidCallback onRefresh;

  const DashboardScreen({
    super.key,
    required this.onOpenNotifications,
    required this.onRefresh,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 0 = My Projects (default), 1 = Deadlines
  int _selectedDashboardTab = 0;

  void _showCreateProjectSheet() {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final courseCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final deadlineCtrl = TextEditingController(text: '2026-12-01');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Create Group Project',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'As the creator, you will automatically be designated as the Project Coordinator (PC).',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Project Name *',
                    hintText: 'e.g. Mobile App Assignment 2',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a project name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: courseCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Course Code & Name *',
                    hintText: 'e.g. 1305204 Mobile App Dev',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter course code and title' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Project Description',
                    hintText: 'Brief summary of objectives and stack...',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: deadlineCtrl,
                  readOnly: true,
                  onTap: () => selectAppDate(ctx, deadlineCtrl),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Project Deadline *',
                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                    hintText: 'YYYY-MM-DD',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please select a deadline' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      setState(() {
                        WorkspaceStore.projects.insert(
                          0,
                          ProjectModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleCtrl.text.trim(),
                            courseCode: courseCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty
                                ? 'No project description provided.'
                                : descCtrl.text.trim(),
                            deadline: deadlineCtrl.text.trim(),
                            myRole: 'PC',
                            members: [
                              TeamMember(
                                studentId: WorkspaceStore.currentStudentId,
                                name: WorkspaceStore.currentUserName.split(' ').first,
                                role: 'PC',
                              ),
                            ],
                            tasks: [],
                          ),
                        );
                      });
                      widget.onRefresh();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Project created successfully! You are the Coordinator.'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Project'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusTasksSheet(String statusKey, String statusLabel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            // Find all tasks with this status or condition across all projects
            final List<Map<String, dynamic>> tasksWithStatus = [];
            for (var project in WorkspaceStore.projects) {
              for (var task in project.tasks) {
                if (statusKey == 'OVERDUE') {
                  if (isTaskOverdue(task)) {
                    tasksWithStatus.add({
                      'project': project,
                      'task': task,
                    });
                  }
                } else if (task.status == statusKey) {
                  tasksWithStatus.add({
                    'project': project,
                    'task': task,
                  });
                }
              }
            }
            // Sort: overdue tasks first, then by due date
            tasksWithStatus.sort((a, b) {
              final taskA = a['task'] as TaskItem;
              final taskB = b['task'] as TaskItem;
              final aOverdue = isTaskOverdue(taskA);
              final bOverdue = isTaskOverdue(taskB);
              if (aOverdue && !bOverdue) return -1;
              if (!aOverdue && bOverdue) return 1;
              return taskA.dueDate.compareTo(taskB.dueDate);
            });

            Color statusFg;
            Color statusBg;
            if (statusKey == 'OVERDUE') {
              statusFg = AppColors.danger;
              statusBg = AppColors.dangerLight;
            } else if (statusKey == 'DONE') {
              statusFg = AppColors.primary;
              statusBg = AppColors.lightAccent;
            } else if (statusKey == 'IN_PROGRESS') {
              statusFg = AppColors.gold;
              statusBg = AppColors.lightGold;
            } else {
              statusFg = AppColors.textSecondary;
              statusBg = const Color(0xFFF1F5F9);
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.45,
              maxChildSize: 0.94,
              expand: false,
              builder: (sheetContext, scrollController) {
                return Column(
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$statusLabel Tasks',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(
                                'Across all group projects',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusFg.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '${tasksWithStatus.length} tasks',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusFg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                    Expanded(
                      child: tasksWithStatus.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: EmptyStateCard(
                                  icon: Icons.assignment_outlined,
                                  title: 'No $statusLabel Tasks',
                                  message: statusKey == 'OVERDUE'
                                      ? 'No tasks are currently overdue across your projects.'
                                      : statusKey == 'DONE'
                                          ? 'No tasks completed yet.'
                                          : 'No tasks currently marked as $statusLabel.',
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              itemCount: tasksWithStatus.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (itemCtx, index) {
                                final item = tasksWithStatus[index];
                                final ProjectModel project = item['project'];
                                final TaskItem task = item['task'];
                                final taskIsOverdue = isTaskOverdue(task);
                                final relative = getDeadlineRelativeLabel(task.dueDate, status: task.status);

                                return Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 0,
                                  color: AppColors.cardBackground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: taskIsOverdue
                                          ? AppColors.danger.withValues(alpha: 0.35)
                                          : AppColors.border,
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
                                      setModalState(() {});
                                      setState(() {});
                                      widget.onRefresh();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
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
                                              Text(
                                                relative,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: taskIsOverdue
                                                      ? AppColors.danger
                                                      : AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            task.title,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  task.assignedTo.isNotEmpty ? task.assignedTo : 'ID: ${task.assignedStudentId}',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Due ${task.dueDate}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: taskIsOverdue ? AppColors.danger : AppColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = WorkspaceStore.projects.expand((p) => p.tasks).toList();
    final todoCount = allTasks.where((t) => t.status == 'TODO').length;
    final inProgressCount = allTasks.where((t) => t.status == 'IN_PROGRESS').length;
    final doneCount = allTasks.where((t) => t.status == 'DONE').length;
    final overdueCount = allTasks.where((t) => isTaskOverdue(t)).length;

    // Overdue is an overlapping condition: do not add it again when calculating total or completion
    final totalTasks = allTasks.length;
    final overallPercent = totalTasks == 0 ? 0 : ((doneCount / totalTasks) * 100).round();

    // Collect pending incomplete tasks across all projects
    final List<Map<String, dynamic>> pendingDeadlines = [];
    for (var project in WorkspaceStore.projects) {
      for (var task in project.tasks) {
        if (task.status != 'DONE') {
          pendingDeadlines.add({
            'project': project,
            'task': task,
          });
        }
      }
    }

    // Sort: unfinished overdue tasks first, then by nearest due date
    pendingDeadlines.sort((a, b) {
      final taskA = a['task'] as TaskItem;
      final taskB = b['task'] as TaskItem;
      final aOverdue = isTaskOverdue(taskA);
      final bOverdue = isTaskOverdue(taskB);

      if (aOverdue && !bOverdue) return -1;
      if (!aOverdue && bOverdue) return 1;
      return taskA.dueDate.compareTo(taskB.dueDate);
    });

    final unreadNotificationCount = WorkspaceStore.getUnreadCountForCurrentUser();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.lightAccent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.school_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'MFU Student Workspace',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Open Notifications',
            onPressed: widget.onOpenNotifications,
            icon: Badge(
              isLabelVisible: unreadNotificationCount > 0,
              label: Text('$unreadNotificationCount'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      ),
      // Removed floating action button to avoid overlapping content
      floatingActionButton: null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              WorkspaceStore.checkOverdueTasksAndNotify();
              setState(() {});
              widget.onRefresh();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // 1. Compact White Workload Summary Card
                _buildCompactWorkloadCard(
                  totalTasks: totalTasks,
                  doneCount: doneCount,
                  todoCount: todoCount,
                  inProgressCount: inProgressCount,
                  overdueCount: overdueCount,
                  overallPercent: overallPercent,
                ),
                const SizedBox(height: 16),

                // 2. Clearly Labeled Secondary Navigation Tabs (My Projects vs Deadlines)
                _buildDashboardTabSelector(
                  projectsCount: WorkspaceStore.projects.length,
                  deadlinesCount: pendingDeadlines.length,
                ),
                const SizedBox(height: 14),

                // 3. Tab Contents: Open My Projects by default (Tab 0)
                if (_selectedDashboardTab == 0)
                  _buildProjectsTabContent()
                else
                  _buildDeadlinesTabContent(pendingDeadlines),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. COMPACT WORKLOAD SUMMARY CARD (WHITE CARD)
  // ==========================================
  Widget _buildCompactWorkloadCard({
    required int totalTasks,
    required int doneCount,
    required int todoCount,
    required int inProgressCount,
    required int overdueCount,
    required int overallPercent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Team Projects Workload',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'All team members across your projects',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '$overallPercent% Completed ($doneCount/$totalTasks)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalTasks == 0 ? 0 : doneCount / totalTasks,
              minHeight: 6,
              backgroundColor: AppColors.lightAccent,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),

          // Simple Clickable Count Controls (2-by-2 on narrow phones, 1 row on wider screens)
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              final todoControl = _buildCountControl(
                label: 'To Do',
                count: todoCount,
                accentColor: AppColors.textPrimary,
                onTap: () => _showStatusTasksSheet('TODO', 'To Do'),
              );

              final inProgressControl = _buildCountControl(
                label: 'In Progress',
                count: inProgressCount,
                accentColor: AppColors.gold,
                onTap: () => _showStatusTasksSheet('IN_PROGRESS', 'In Progress'),
              );

              final doneControl = _buildCountControl(
                label: 'Done',
                count: doneCount,
                accentColor: AppColors.primary,
                onTap: () => _showStatusTasksSheet('DONE', 'Completed'),
              );

              final overdueControl = _buildCountControl(
                label: 'Overdue',
                count: overdueCount,
                accentColor: overdueCount > 0 ? AppColors.danger : AppColors.textSecondary,
                isOverdue: overdueCount > 0,
                onTap: () => _showStatusTasksSheet('OVERDUE', 'Overdue'),
              );

              if (isNarrow) {
                // Balanced 2-by-2 layout on narrow phones
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: todoControl),
                        const SizedBox(width: 8),
                        Expanded(child: inProgressControl),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: doneControl),
                        const SizedBox(width: 8),
                        Expanded(child: overdueControl),
                      ],
                    ),
                  ],
                );
              } else {
                // 4-in-a-row on wider layouts
                return Row(
                  children: [
                    Expanded(child: todoControl),
                    const SizedBox(width: 8),
                    Expanded(child: inProgressControl),
                    const SizedBox(width: 8),
                    Expanded(child: doneControl),
                    const SizedBox(width: 8),
                    Expanded(child: overdueControl),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCountControl({
    required String label,
    required int count,
    required Color accentColor,
    required VoidCallback onTap,
    bool isOverdue = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isOverdue ? AppColors.dangerLight : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOverdue ? AppColors.danger.withValues(alpha: 0.4) : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isOverdue ? AppColors.danger : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
                  color: isOverdue ? AppColors.danger : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 2. SECONDARY TABS SELECTOR (MY PROJECTS VS DEADLINES)
  // ==========================================
  Widget _buildDashboardTabSelector({
    required int projectsCount,
    required int deadlinesCount,
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
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _selectedDashboardTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedDashboardTab == 0 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'My Projects ($projectsCount)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _selectedDashboardTab == 0 ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _selectedDashboardTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedDashboardTab == 1 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Deadlines ($deadlinesCount)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _selectedDashboardTab == 1 ? Colors.white : AppColors.textSecondary,
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
  // 3. TAB 1: VERTICAL DEADLINES LIST
  // ==========================================
  Widget _buildDeadlinesTabContent(List<Map<String, dynamic>> pendingDeadlines) {
    if (pendingDeadlines.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: EmptyStateCard(
          icon: Icons.done_all_rounded,
          title: 'No Pending Deadlines',
          message: 'All tasks are completed across your projects.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'Upcoming Deadlines (${pendingDeadlines.length})',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pendingDeadlines.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final item = pendingDeadlines[i];
            final ProjectModel project = item['project'];
            final TaskItem task = item['task'];
            final isOverdue = isTaskOverdue(task);
            final isDueToday = isTaskDueToday(task);
            final relativeLabel = getDeadlineRelativeLabel(task.dueDate, status: task.status);

            return Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isOverdue
                      ? AppColors.danger.withValues(alpha: 0.35)
                      : isDueToday
                          ? AppColors.gold.withValues(alpha: 0.4)
                          : AppColors.border,
                  width: isOverdue ? 1.5 : 1.0,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(project: project, task: task),
                    ),
                  );
                  setState(() {});
                  widget.onRefresh();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOverdue
                                  ? AppColors.dangerLight
                                  : isDueToday
                                      ? AppColors.lightGold
                                      : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              relativeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOverdue
                                    ? AppColors.danger
                                    : isDueToday
                                        ? AppColors.gold
                                        : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              task.assignedTo.isNotEmpty ? task.assignedTo : 'ID: ${task.assignedStudentId}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: isOverdue ? AppColors.danger : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due ${task.dueDate}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isOverdue ? AppColors.danger : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // 4. TAB 2: MY PROJECTS (SIMPLIFIED & COMPACT)
  // ==========================================
  Widget _buildProjectsTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Header with integrated "New Project" button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Projects (${WorkspaceStore.projects.length})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _showCreateProjectSheet,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Project', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (WorkspaceStore.projects.isEmpty)
          EmptyStateCard(
            icon: Icons.folder_open_rounded,
            title: 'No Projects Yet',
            message: 'You have not joined or created any workspace projects.',
            actionLabel: 'Create Project',
            onAction: _showCreateProjectSheet,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: WorkspaceStore.projects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final project = WorkspaceStore.projects[i];
              final isPC = project.isCurrentUserPC;
              final projectOverdue = project.tasks.where((t) => isTaskOverdue(t)).length;

              return Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                color: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: projectOverdue > 0
                        ? AppColors.danger.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailScreen(project: project),
                      ),
                    );
                    setState(() {});
                    widget.onRefresh();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                project.courseCode,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (projectOverdue > 0) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.dangerLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$projectOverdue overdue',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isPC ? AppColors.lightGold : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isPC ? 'Coordinator (PC)' : 'Member',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isPC ? AppColors.gold : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          project.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress: ${project.completedTasks}/${project.tasks.length} Done (${(project.progress * 100).round()}%)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Due ${project.deadline}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: project.progress,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
