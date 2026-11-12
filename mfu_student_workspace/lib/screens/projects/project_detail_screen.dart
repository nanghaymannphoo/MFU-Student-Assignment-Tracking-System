import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/status_helpers.dart';
import '../../models/project_model.dart';
import '../../models/task_item.dart';
import '../../models/team_member.dart';
import '../../data/workspace_store.dart';
import '../../widgets/empty_state_card.dart';
import '../tasks/task_detail_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  // Main Tab: 0 = Manage Team & Tasks, 1 = Track Assignments
  int _selectedTab = 0;

  // Track Assignments Secondary Tab: 0 = Tasks (default), 1 = Members
  int _selectedTrackSubTab = 0;

  // Filter: 'ALL', 'TODO', 'IN_PROGRESS', 'DONE', 'OVERDUE'
  String _selectedFilter = 'ALL';

  // Set of member student IDs whose task lists are expanded in the Members tab
  final Set<String> _expandedMemberIds = {};

  // Member View Secondary Tab: 0 = My Tasks (default), 1 = Team Members
  int _selectedMemberTab = 0;

  @override
  void initState() {
    super.initState();
    // Check overdue tasks and notify on entry
    WorkspaceStore.checkOverdueTasksAndNotify();
  }

  // ==========================================
  // MODAL BOTTOM SHEET: ADD TEAM MEMBER
  // ==========================================
  void _showAddMemberBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final studentIdCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Add Team Member',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter 10-digit Student ID. Newly added students are automatically assigned as Members.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: studentIdCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Student ID *',
                    hintText: 'e.g. 6731501199',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter student ID';
                    }
                    final id = v.trim();
                    if (id.length != 10 || int.tryParse(id) == null) {
                      return 'Must be exactly 10 digits';
                    }
                    if (widget.project.members.any((m) => m.studentId == id)) {
                      return 'Student ID is already in this project';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(0, 46),
                        ),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final id = studentIdCtrl.text.trim();
                          final name = WorkspaceStore.resolveMemberName(id);

                          setState(() {
                            widget.project.members.add(
                              TeamMember(
                                studentId: id,
                                name: name,
                                role: 'Member', // Automatically set to Member
                              ),
                            );
                          });

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                name == id
                                    ? 'Added Student ID $id as Member'
                                    : 'Added $name (ID: $id) as Member',
                              ),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Member'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ACTION: REMOVE TEAM MEMBER (PC ONLY)
  // ==========================================
  void _handleRemoveMember(TeamMember member) {
    // 1. Permission check: Only project PC can remove members
    if (!widget.project.isCurrentUserPC) return;

    // 2. Cannot remove the project PC
    final isMemberPC = member.role.toUpperCase() == 'PC';
    if (isMemberPC) return;

    // 3. Before removal, check ALL project tasks, including completed tasks, for assignments to that Student ID
    final assignedTasks = widget.project.tasks
        .where((t) => t.assignedStudentId == member.studentId)
        .toList();

    // 4. If any tasks are assigned, block removal and show required warning
    if (assignedTasks.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Cannot Remove Member',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          content: const Text(
            'Please reassign this member’s tasks before removing them.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(80, 36),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please reassign this member’s tasks before removing them.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 5. If no tasks are assigned, show a confirmation dialog naming the member
    final displayName = member.name == member.studentId
        ? 'Student ${member.studentId}'
        : member.name;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove Team Member',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove $displayName (ID: ${member.studentId}) from this project?',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 36),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeRemoveMember(member);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _executeRemoveMember(TeamMember member) {
    // Recheck permissions and assignments in the store handler before changing data
    final result = WorkspaceStore.removeMemberFromProject(
      projectId: widget.project.id,
      memberStudentId: member.studentId,
      actingStudentId: WorkspaceStore.currentStudentId,
    );

    if (!result.success) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _expandedMemberIds.remove(member.studentId);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${member.name} from project.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // MODAL BOTTOM SHEET: ADD NEW TASK
  // ==========================================
  void _showAddTaskBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final taskTitleCtrl = TextEditingController();

    // Default assignee to first member
    String selectedStudentId = widget.project.members.isNotEmpty
        ? widget.project.members.first.studentId
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.add_task_rounded, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Add New Task',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Starts in To Do status. Inherits project deadline (${widget.project.deadline}).',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: taskTitleCtrl,
                    autofocus: true,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Task Name *',
                      hintText: 'e.g. Design MySQL Schema & Junction Table',
                      prefixIcon: Icon(Icons.assignment_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Please enter a task name' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStudentId.isNotEmpty ? selectedStudentId : null,
                    decoration: const InputDecoration(
                      labelText: 'Assign to Member *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    items: widget.project.members.isEmpty
                        ? const [DropdownMenuItem(value: '', child: Text('No members available'))]
                        : widget.project.members
                            .map((m) => DropdownMenuItem(
                                  value: m.studentId,
                                  child: Text(
                                    m.name == m.studentId
                                        ? 'ID: ${m.studentId} (${m.role})'
                                        : '${m.name} (${m.role})',
                                  ),
                                ))
                            .toList(),
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedStudentId = val);
                    },
                    validator: (v) => (v == null || v.isEmpty) ? 'Please select a member' : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(0, 46),
                          ),
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            final title = taskTitleCtrl.text.trim();
                            final member = widget.project.members.firstWhere(
                              (m) => m.studentId == selectedStudentId,
                              orElse: () => TeamMember(
                                studentId: selectedStudentId,
                                name: selectedStudentId,
                                role: 'Member',
                              ),
                            );

                            final newTask = TaskItem(
                              id: 't_${DateTime.now().millisecondsSinceEpoch}',
                              title: title,
                              description: 'No description',
                              assignedTo: member.name,
                              assignedStudentId: member.studentId,
                              dueDate: widget.project.deadline,
                              status: 'TODO',
                            );

                            setState(() {
                              widget.project.tasks.add(newTask);
                            });

                            WorkspaceStore.onTaskAssignedOrReassigned(
                              project: widget.project,
                              task: newTask,
                              newAssigneeStudentId: newTask.assignedStudentId,
                              actorStudentId: WorkspaceStore.currentStudentId,
                            );

                            Navigator.pop(ctx);
                            WorkspaceStore.checkOverdueTasksAndNotify();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Task "$title" created!'),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(
                                  label: 'View in Track',
                                  textColor: AppColors.gold,
                                  onPressed: () {
                                    setState(() {
                                      _selectedTab = 1;
                                      _selectedTrackSubTab = 0;
                                      _selectedFilter = 'TODO';
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Save Task'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // EXTEND DEADLINE ACTION (PC ONLY)
  // ==========================================
  Future<void> _showExtendDeadlineDialog(TaskItem task) async {
    if (!widget.project.isCurrentUserPC) return;

    final parsedCurrent = DateTime.tryParse(task.dueDate.trim());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime minDate = today.add(const Duration(days: 1));
    if (parsedCurrent != null && parsedCurrent.isAfter(today)) {
      minDate = parsedCurrent.add(const Duration(days: 1));
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'SELECT NEW TASK DEADLINE',
      confirmText: 'PROCEED',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    final newDateStr =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

    final projectDeadline = DateTime.tryParse(widget.project.deadline.trim());
    final bool exceedsProjectDeadline =
        projectDeadline != null && picked.isAfter(projectDeadline);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.event_repeat_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'Confirm Extension',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Extend deadline for "${task.title}"?',
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text(task.dueDate, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('New Deadline', style: TextStyle(fontSize: 10, color: AppColors.primary)),
                      Text(newDateStr, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            if (exceedsProjectDeadline) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.lightGold,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.gold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: This date ($newDateStr) exceeds the project deadline (${widget.project.deadline}).',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save Extension'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = WorkspaceStore.extendTaskDeadline(
        project: widget.project,
        task: task,
        newDueDate: newDateStr,
        actorStudentId: WorkspaceStore.currentStudentId,
      );

      if (success) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Deadline extended to $newDateStr! Overdue alerts resolved.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _confirmDeleteTask(TaskItem task) {
    if (!widget.project.isCurrentUserPC) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Task?',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                widget.project.tasks.remove(task);
              });
              Navigator.pop(ctx);
              WorkspaceStore.checkOverdueTasksAndNotify();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${task.title}"'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPC = widget.project.isCurrentUserPC;

    // ==========================================
    // MEMBER VIEW (ONLY TWO TABS: MY TASKS & TEAM MEMBERS)
    // ==========================================
    if (!isPC) {
      final myProjectTasks = widget.project.tasks
          .where((t) => t.assignedStudentId == WorkspaceStore.currentStudentId)
          .toList();

      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          title: Text(widget.project.title),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // 1. Compact Member Project Header (No progress bars, percentages, or summary cards)
                _buildMemberProjectHeader(),
                const SizedBox(height: 14),

                // 2. Exactly Two Tabs: "My Tasks" and "Team Members" (Default: My Tasks)
                _buildMemberTabSelector(
                  myTasksCount: myProjectTasks.length,
                  membersCount: widget.project.members.length,
                ),
                const SizedBox(height: 14),

                // 3. Tab Contents
                if (_selectedMemberTab == 0)
                  _buildMemberMyTasksSection(myProjectTasks)
                else
                  _buildMemberTeamMembersSection(),
              ],
            ),
          ),
        ),
      );
    }

    // ==========================================
    // PC VIEW (100% UNCHANGED)
    // ==========================================
    final totalTasks = widget.project.tasks.length;
    final doneCount = widget.project.tasks.where((t) => t.status == 'DONE').length;
    final inProgressCount = widget.project.tasks.where((t) => t.status == 'IN_PROGRESS').length;
    final todoCount = widget.project.tasks.where((t) => t.status == 'TODO').length;
    final overdueCount = widget.project.tasks.where((t) => isTaskOverdue(t)).length;
    final overallPercent = totalTasks == 0 ? 0 : ((doneCount / totalTasks) * 100).round();

    // 5 Clickable filters: ALL, TODO, IN_PROGRESS, DONE, OVERDUE
    final filteredTasks = widget.project.tasks.where((t) {
      if (_selectedFilter == 'ALL') return true;
      if (_selectedFilter == 'OVERDUE') return isTaskOverdue(t);
      return t.status == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(widget.project.title),
        actions: [
          if (isPC)
            IconButton(
              tooltip: 'Notify All Members',
              onPressed: () {
                WorkspaceStore.onProjectAnnouncement(
                  project: widget.project,
                  title: 'Team Reminder: ${widget.project.title}',
                  message: '🔔 Coordinator sent a reminder regarding upcoming deadlines.',
                  actorStudentId: WorkspaceStore.currentStudentId,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.primary,
                    content: Text('Reminder broadcasted to team members!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.campaign_outlined, color: AppColors.primary),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              // 1. Compact Project Header Card
              _buildCompactProjectHeader(isPC, totalTasks, doneCount, overdueCount),
              const SizedBox(height: 14),

              // 2. Primary Tabs: Manage Team & Tasks vs. Track Assignments
              _buildPrimaryTabSelector(),
              const SizedBox(height: 14),

              // 3. Tab Contents
              if (_selectedTab == 0)
                _buildManageSection(isPC)
              else
                _buildTrackSection(
                  isPC: isPC,
                  totalTasks: totalTasks,
                  doneCount: doneCount,
                  inProgressCount: inProgressCount,
                  todoCount: todoCount,
                  overdueCount: overdueCount,
                  overallPercent: overallPercent,
                  filteredTasks: filteredTasks,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MEMBER VIEW: COMPACT HEADER (READ-ONLY, NO PROGRESS BARS)
  // ==========================================
  Widget _buildMemberProjectHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              Text(
                widget.project.courseCode,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.lightAccent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: const Text(
                  'Member',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.project.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (widget.project.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.project.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Deadline: ${widget.project.deadline}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MEMBER VIEW: TWO TABS SELECTOR (MY TASKS & TEAM MEMBERS)
  // ==========================================
  Widget _buildMemberTabSelector({required int myTasksCount, required int membersCount}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => setState(() => _selectedMemberTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedMemberTab == 0 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    'My Tasks ($myTasksCount)',
                    style: TextStyle(
                      color: _selectedMemberTab == 0 ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => setState(() => _selectedMemberTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedMemberTab == 1 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    'Team Members ($membersCount)',
                    style: TextStyle(
                      color: _selectedMemberTab == 1 ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
  // MEMBER VIEW: MY TASKS SECTION
  // ==========================================
  Widget _buildMemberMyTasksSection(List<TaskItem> myProjectTasks) {
    if (myProjectTasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 24),
        child: EmptyStateCard(
          icon: Icons.assignment_outlined,
          title: 'No Tasks Assigned',
          message: 'You currently have no tasks assigned to your Student ID in this project.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: myProjectTasks.map((task) {
        final isOverdue = isTaskOverdue(task);
        final relative = getDeadlineRelativeLabel(task.dueDate, status: task.status);

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

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: isOverdue ? AppColors.dangerLight : AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isOverdue
                    ? AppColors.danger.withValues(alpha: 0.35)
                    : AppColors.border,
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
                      project: widget.project,
                      task: task,
                    ),
                  ),
                );
                if (mounted) setState(() {});
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
                            task.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
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
                    const SizedBox(height: 8),
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
                          task.dueDate.trim().isEmpty ? 'No deadline' : 'Due ${task.dueDate.trim()}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
                            color: isOverdue ? AppColors.danger : AppColors.textPrimary,
                          ),
                        ),
                        if (task.dueDate.trim().isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• $relative',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isOverdue ? FontWeight.bold : FontWeight.w500,
                              color: isOverdue ? AppColors.danger : AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (isOverdue) ...[
                          const Spacer(),
                          buildOverdueBadge(compact: true),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // MEMBER VIEW: READ-ONLY TEAM MEMBERS SECTION
  // ==========================================
  Widget _buildMemberTeamMembersSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.project.members.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (ctx, index) {
          final member = widget.project.members[index];
          final isMemberPC = member.role.toUpperCase() == 'PC' || member.role.toUpperCase() == 'COORDINATOR';
          final isCurrentUser = member.studentId == WorkspaceStore.currentStudentId;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isMemberPC ? AppColors.lightGold : const Color(0xFFF1F5F9),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isMemberPC ? AppColors.gold : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '(You)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Student ID: ${member.studentId}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMemberPC ? AppColors.lightGold : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isMemberPC
                          ? AppColors.gold.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    isMemberPC ? 'Coordinator (PC)' : 'Member',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isMemberPC ? AppColors.gold : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // COMPACT PROJECT HEADER CARD
  // ==========================================
  Widget _buildCompactProjectHeader(
    bool isPC,
    int totalTasks,
    int doneCount,
    int overdueCount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              Text(
                widget.project.courseCode,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (overdueCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '$overdueCount Overdue',
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
                      color: isPC ? AppColors.lightGold : AppColors.lightAccent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isPC
                            ? AppColors.gold.withValues(alpha: 0.4)
                            : AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      isPC ? '👑 Coordinator (PC)' : '👤 Member',
                      style: TextStyle(
                        color: isPC ? AppColors.gold : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.project.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Due ${widget.project.deadline}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '$doneCount/$totalTasks Tasks Done',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PRIMARY TAB SELECTOR (Manage vs Track)
  // ==========================================
  Widget _buildPrimaryTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? AppColors.cardBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: _selectedTab == 0 ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Manage Team & Tasks',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedTab == 0 ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? AppColors.cardBackground : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.track_changes_rounded,
                      size: 16,
                      color: _selectedTab == 1 ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Track Assignments',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedTab == 1 ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 1: MANAGE TEAM & TASKS (COMPACT)
  // ==========================================
  Widget _buildManageSection(bool isPC) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two Clearly Labeled Action Buttons (Compact, replacing permanently expanded forms)
        if (isPC) ...[
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showAddMemberBottomSheet,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Add Member'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.darkAccent,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showAddTaskBottomSheet,
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text('Add Task'),
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only the Project Coordinator (PC) can add members and assign tasks.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Compact Team Members List
        Container(
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
                  Text(
                    'Team Members (${widget.project.members.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '1 PC, ${widget.project.members.where((m) => m.role == 'Member').length} Members',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.project.members.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (ctx, i) {
                  final member = widget.project.members[i];
                  final isMemberPC = member.role == 'PC';
                  final displayName = member.name == member.studentId
                      ? 'Student ${member.studentId}'
                      : member.name;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isMemberPC ? AppColors.lightGold : AppColors.lightAccent,
                          foregroundColor: isMemberPC ? AppColors.gold : AppColors.primary,
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'ID: ${member.studentId}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isMemberPC ? AppColors.lightGold : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isMemberPC
                                  ? AppColors.gold.withValues(alpha: 0.4)
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            isMemberPC ? '👑 PC' : '👤 Member',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isMemberPC ? AppColors.gold : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (!isMemberPC) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            key: Key('remove_member_${member.studentId}'),
                            onTap: () => _handleRemoveMember(member),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.dangerLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.danger.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_remove_outlined, size: 13, color: AppColors.danger),
                                  SizedBox(width: 4),
                                  Text(
                                    'Remove',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 2: TRACK ASSIGNMENTS (TASKS & MEMBERS SUB-TABS)
  // ==========================================
  Widget _buildTrackSection({
    required bool isPC,
    required int totalTasks,
    required int doneCount,
    required int inProgressCount,
    required int todoCount,
    required int overdueCount,
    required int overallPercent,
    required List<TaskItem> filteredTasks,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Secondary Tabs inside Track Assignments: Tasks (default) vs Members
        Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                  onTap: () => setState(() => _selectedTrackSubTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: _selectedTrackSubTab == 0 ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: 15,
                          color: _selectedTrackSubTab == 0 ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tasks ($totalTasks)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedTrackSubTab == 0 ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _selectedTrackSubTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: _selectedTrackSubTab == 1 ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 15,
                          color: _selectedTrackSubTab == 1 ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Members (${widget.project.members.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedTrackSubTab == 1 ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // SUB-TAB 0: TASKS VIEW (Compact Team Progress Overview + Filterable Tasks)
        if (_selectedTrackSubTab == 0) ...[
          // Compact Team Progress Overview & Clickable Filter Controls
          Container(
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
                    const Row(
                      children: [
                        Icon(Icons.insights_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Team Progress Overview',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lightGold,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '$overallPercent% Completed',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: widget.project.progress,
                    minHeight: 6,
                    backgroundColor: AppColors.lightAccent,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),

                // 5 CLICKABLE SUMMARY CONTROLS: All, To Do, In Progress, Done, Overdue
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 540;
                    final filterCards = [
                      _buildClickableFilterCard(
                        filterKey: 'ALL',
                        label: 'All Tasks',
                        count: totalTasks,
                        bg: AppColors.scaffoldBackground,
                        accentColor: AppColors.textPrimary,
                        minWidth: isWide ? null : 84,
                      ),
                      _buildClickableFilterCard(
                        filterKey: 'TODO',
                        label: 'To Do',
                        count: todoCount,
                        bg: const Color(0xFFF1F5F9),
                        accentColor: AppColors.textSecondary,
                        minWidth: isWide ? null : 80,
                      ),
                      _buildClickableFilterCard(
                        filterKey: 'IN_PROGRESS',
                        label: 'In Progress',
                        count: inProgressCount,
                        bg: AppColors.lightGold,
                        accentColor: AppColors.gold,
                        minWidth: isWide ? null : 84,
                      ),
                      _buildClickableFilterCard(
                        filterKey: 'DONE',
                        label: 'Completed',
                        count: doneCount,
                        bg: AppColors.lightAccent,
                        accentColor: AppColors.primary,
                        minWidth: isWide ? null : 84,
                      ),
                      _buildClickableFilterCard(
                        filterKey: 'OVERDUE',
                        label: 'Overdue',
                        count: overdueCount,
                        bg: overdueCount > 0 ? AppColors.dangerLight : const Color(0xFFF1F5F9),
                        accentColor: AppColors.danger,
                        minWidth: isWide ? null : 80,
                      ),
                    ];

                    if (isWide) {
                      return Row(
                        children: [
                          for (int i = 0; i < filterCards.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(child: filterCards[i]),
                          ],
                        ],
                      );
                    } else {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (int i = 0; i < filterCards.length; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              filterCards[i],
                            ],
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // TASK LIST HEADER WITH ACTIVE FILTER STATUS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Task Assignments',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _selectedFilter == 'OVERDUE'
                          ? AppColors.dangerLight
                          : AppColors.lightAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${filteredTasks.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _selectedFilter == 'OVERDUE'
                            ? AppColors.danger
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedFilter != 'ALL')
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => setState(() => _selectedFilter = 'ALL'),
                  icon: const Icon(Icons.clear_rounded, size: 14),
                  label: const Text('Show All Tasks', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // TASK LIST
          if (filteredTasks.isEmpty)
            EmptyStateCard(
              icon: _selectedFilter == 'OVERDUE'
                  ? Icons.check_circle_outline_rounded
                  : Icons.assignment_outlined,
              title: _selectedFilter == 'ALL'
                  ? 'No Tasks in this Project'
                  : 'No ${_formatFilterTitle(_selectedFilter)} Tasks',
              message: _selectedFilter == 'OVERDUE'
                  ? 'Great news! No tasks are currently overdue in this project.'
                  : _selectedFilter == 'ALL'
                      ? 'Switch to the "Manage Team & Tasks" tab to create your first milestone.'
                      : 'No tasks currently matching the selected "${_formatFilterTitle(_selectedFilter)}" filter.',
              actionLabel: _selectedFilter != 'ALL' ? 'View All Tasks' : null,
              onAction: _selectedFilter != 'ALL' ? () => setState(() => _selectedFilter = 'ALL') : null,
            )
          else
            ...filteredTasks.map((task) {
              final isOverdue = isTaskOverdue(task);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                color: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isOverdue ? AppColors.danger.withValues(alpha: 0.4) : AppColors.border,
                    width: isOverdue ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(
                          project: widget.project,
                          task: task,
                        ),
                      ),
                    );
                    setState(() {});
                  },
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 6),
                        buildOverdueBadge(compact: true),
                      ],
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          task.assignedTo.isNotEmpty ? task.assignedTo : 'ID: ${task.assignedStudentId}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: isOverdue ? AppColors.danger : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          task.dueDate,
                          style: TextStyle(
                            color: isOverdue ? AppColors.danger : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status menu with inline update, extend deadline, and delete for PC
                      PopupMenuButton<String>(
                        tooltip: 'Task actions & status',
                        initialValue: task.status,
                        onSelected: (val) {
                          if (val == 'EXTEND') {
                            _showExtendDeadlineDialog(task);
                            return;
                          }
                          if (val == 'DELETE') {
                            _confirmDeleteTask(task);
                            return;
                          }
                          setState(() {
                            task.status = val;
                          });
                          WorkspaceStore.onStatusChanged(
                            project: widget.project,
                            task: task,
                            newStatus: val,
                            actorStudentId: WorkspaceStore.currentStudentId,
                          );
                          WorkspaceStore.checkOverdueTasksAndNotify();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Updated "${task.title}" to ${formatStatus(val)}'),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'TODO',
                            child: Row(
                              children: [
                                Icon(Icons.radio_button_unchecked_rounded,
                                    size: 16, color: AppColors.textSecondary),
                                SizedBox(width: 8),
                                Text('To Do'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'IN_PROGRESS',
                            child: Row(
                              children: [
                                Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.gold),
                                SizedBox(width: 8),
                                Text('In Progress'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'DONE',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 16, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text('Completed'),
                              ],
                            ),
                          ),
                          if (isPC) ...[
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'EXTEND',
                              child: Row(
                                children: [
                                  Icon(Icons.event_repeat_rounded,
                                      size: 16, color: AppColors.primary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Extend Deadline',
                                    style: TextStyle(
                                        color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'DELETE',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      size: 16, color: AppColors.danger),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete Task',
                                    style: TextStyle(
                                        color: AppColors.danger, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                        child: _buildStatusChip(task.status),
                      ),
                      if (isPC) ...[
                        const SizedBox(width: 2),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.danger, size: 18),
                          tooltip: 'Delete Task',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => _confirmDeleteTask(task),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ]
        // SUB-TAB 1: MEMBERS VIEW (Expandable Member Breakdown)
        else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Member Workload Breakdown',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap any member below to inspect their assigned tasks and deadlines.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ...widget.project.members.map((member) {
                  // Associate tasks by Student ID with name fallback
                  final memberTasks = widget.project.tasks
                      .where((t) =>
                          (t.assignedStudentId.isNotEmpty &&
                              t.assignedStudentId == member.studentId) ||
                          t.assignedTo.trim().toLowerCase() ==
                              member.name.trim().toLowerCase())
                      .toList();

                  final mDone = memberTasks.where((t) => t.status == 'DONE').length;
                  final mInProgress = memberTasks.where((t) => t.status == 'IN_PROGRESS').length;
                  final mTodo = memberTasks.where((t) => t.status == 'TODO').length;
                  final mOverdue = memberTasks.where((t) => isTaskOverdue(t)).length;
                  final mTotal = memberTasks.length;
                  final mPercent = mTotal == 0 ? 0 : ((mDone / mTotal) * 100).round();
                  final mRatio = mTotal == 0 ? 0.0 : mDone / mTotal;

                  final displayName = member.name == member.studentId
                      ? 'Student ${member.studentId}'
                      : member.name;

                  final isExpanded = _expandedMemberIds.contains(member.studentId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isExpanded ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
                        width: isExpanded ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Tappable Member Row Header
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedMemberIds.remove(member.studentId);
                              } else {
                                _expandedMemberIds.add(member.studentId);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundColor: member.role == 'PC'
                                          ? AppColors.lightGold
                                          : AppColors.lightAccent,
                                      foregroundColor: member.role == 'PC'
                                          ? AppColors.gold
                                          : AppColors.primary,
                                      child: Text(
                                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                displayName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: member.role == 'PC'
                                                      ? AppColors.lightGold
                                                      : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  member.role == 'PC' ? '👑 PC' : '👤 Member',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: member.role == 'PC'
                                                        ? AppColors.gold
                                                        : AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'ID: ${member.studentId}',
                                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$mDone/$mTotal Done ($mPercent%)',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        if (mOverdue > 0)
                                          Text(
                                            '$mOverdue Overdue',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                              color: AppColors.danger,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: mRatio,
                                    minHeight: 5,
                                    backgroundColor: AppColors.lightAccent,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildMiniStatusChip('Done', mDone, AppColors.lightAccent, AppColors.primary),
                                    const SizedBox(width: 5),
                                    _buildMiniStatusChip('In Progress', mInProgress, AppColors.lightGold, AppColors.gold),
                                    const SizedBox(width: 5),
                                    _buildMiniStatusChip('To Do', mTodo, const Color(0xFFF1F5F9), AppColors.textSecondary),
                                    if (mOverdue > 0) ...[
                                      const SizedBox(width: 5),
                                      _buildMiniStatusChip('Overdue', mOverdue, AppColors.dangerLight, AppColors.danger),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Expandable Tasks Section for this member
                        if (isExpanded) ...[
                          const Divider(height: 1, color: AppColors.border),
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                            color: AppColors.cardBackground,
                            child: memberTasks.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Center(
                                      child: Text(
                                        'No tasks assigned to this member yet.',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Assigned Tasks (${memberTasks.length})',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      ...memberTasks.map((task) {
                                        final isTaskItemOverdue = isTaskOverdue(task);
                                        return InkWell(
                                          borderRadius: BorderRadius.circular(8),
                                          onTap: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => TaskDetailScreen(
                                                  project: widget.project,
                                                  task: task,
                                                ),
                                              ),
                                            );
                                            setState(() {});
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: AppColors.scaffoldBackground,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isTaskItemOverdue
                                                    ? AppColors.danger.withValues(alpha: 0.4)
                                                    : AppColors.border,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        task.title,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.calendar_today_rounded,
                                                            size: 10,
                                                            color: isTaskItemOverdue
                                                                ? AppColors.danger
                                                                : AppColors.textSecondary,
                                                          ),
                                                          const SizedBox(width: 3),
                                                          Text(
                                                            'Due ${task.dueDate}',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: isTaskItemOverdue
                                                                  ? AppColors.danger
                                                                  : AppColors.textSecondary,
                                                              fontWeight: isTaskItemOverdue
                                                                  ? FontWeight.bold
                                                                  : FontWeight.normal,
                                                            ),
                                                          ),
                                                          if (isTaskItemOverdue) ...[
                                                            const SizedBox(width: 6),
                                                            buildOverdueBadge(compact: true),
                                                          ],
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                _buildStatusChip(task.status),
                                              ],
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // CLICKABLE FILTER SUMMARY CARD WIDGET
  // ==========================================
  Widget _buildClickableFilterCard({
    required String filterKey,
    required String label,
    required int count,
    required Color bg,
    required Color accentColor,
    double? minWidth,
  }) {
    final isSelected = _selectedFilter == filterKey;

    final cardContent = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: minWidth != null ? BoxConstraints(minWidth: minWidth) : null,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? (filterKey == 'DONE'
                ? AppColors.lightAccent
                : filterKey == 'IN_PROGRESS'
                    ? AppColors.lightGold
                    : filterKey == 'OVERDUE'
                        ? AppColors.dangerLight
                        : AppColors.cardBackground)
            : bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? accentColor : AppColors.border,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? accentColor : AppColors.textPrimary,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 2),
                Icon(Icons.check_rounded, size: 12, color: accentColor),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? accentColor : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedFilter = filterKey),
        child: cardContent,
      ),
    );
  }

  String _formatFilterTitle(String filterKey) {
    switch (filterKey) {
      case 'DONE':
        return 'Completed';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'TODO':
        return 'To Do';
      case 'OVERDUE':
        return 'Overdue';
      default:
        return 'All';
    }
  }

  Widget _buildMiniStatusChip(String label, int count, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = AppColors.textSecondary;
    if (status == 'IN_PROGRESS') {
      bg = AppColors.lightGold;
      fg = AppColors.gold;
    } else if (status == 'DONE') {
      bg = AppColors.lightAccent;
      fg = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getStatusIcon(status), size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            formatStatus(status),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}
