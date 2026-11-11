import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_picker_utils.dart';
import '../../core/utils/status_helpers.dart';
import '../../models/comment_item.dart';
import '../../models/project_model.dart';
import '../../models/task_item.dart';
import '../../models/team_member.dart';
import '../../data/workspace_store.dart';

class TaskDetailScreen extends StatefulWidget {
  final ProjectModel project;
  final TaskItem task;

  const TaskDetailScreen({
    super.key,
    required this.project,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _uploadUrlCtrl;
  final TextEditingController _commentCtrl = TextEditingController();
  final _uploadFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _uploadUrlCtrl = TextEditingController(text: widget.task.submissionUrl ?? '');
  }

  @override
  void dispose() {
    _uploadUrlCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  /// Opens date picker and confirmation dialog to extend task deadline (PC only).
  Future<void> _showExtendDeadlineModal() async {
    // 1. Enforce PC role check
    if (!widget.project.isCurrentUserPC) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the Project Coordinator (PC) can extend task deadlines.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final parsedCurrent = DateTime.tryParse(widget.task.dueDate.trim());
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // The new date must be later than the current deadline and cannot be in the past
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

    // Check if new task deadline exceeds the project deadline
    final projectDeadline = DateTime.tryParse(widget.project.deadline.trim());
    final bool exceedsProjectDeadline =
        projectDeadline != null && picked.isAfter(projectDeadline);

    // Ask for confirmation before saving
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
              'Extend deadline for "${widget.task.title}"?',
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
                      Text(
                        widget.task.dueDate,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('New Deadline', style: TextStyle(fontSize: 10, color: AppColors.primary)),
                      Text(
                        newDateStr,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
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
        task: widget.task,
        newDueDate: newDateStr,
        actorStudentId: WorkspaceStore.currentStudentId,
      );

      if (success) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text('Deadline extended to $newDateStr! Assignee has been notified.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _editTaskModal() {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: widget.task.title);
    final descCtrl = TextEditingController(text: widget.task.description);
    final dueCtrl = TextEditingController(text: widget.task.dueDate);

    // Initial selected student ID
    String selectedStudentId = widget.task.assignedStudentId.isNotEmpty
        ? widget.task.assignedStudentId
        : (widget.project.members.isNotEmpty ? widget.project.members.first.studentId : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Task',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Task Title *'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: widget.project.members.any((m) => m.studentId == selectedStudentId)
                      ? selectedStudentId
                      : (widget.project.members.isNotEmpty ? widget.project.members.first.studentId : null),
                  decoration: const InputDecoration(
                    labelText: 'Assign to Member',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  items: widget.project.members.isEmpty
                      ? [
                          DropdownMenuItem(
                            value: selectedStudentId,
                            child: Text(widget.task.assignedTo),
                          )
                        ]
                      : widget.project.members
                          .map((m) => DropdownMenuItem(
                                value: m.studentId,
                                child: Text(
                                  m.name == m.studentId
                                      ? 'ID: ${m.studentId} (${formatRole(m.role)})'
                                      : '${m.name} (${formatRole(m.role)})',
                                ),
                              ))
                          .toList(),
                  onChanged: (val) {
                    if (val != null) selectedStudentId = val;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: dueCtrl,
                  readOnly: true,
                  onTap: () => selectAppDate(ctx, dueCtrl),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Due Date *',
                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a due date' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(120, 40),
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final member = widget.project.members.firstWhere(
                (m) => m.studentId == selectedStudentId,
                orElse: () => TeamMember(
                  studentId: selectedStudentId,
                  name: widget.task.assignedTo,
                  role: 'MEMBER',
                ),
              );

              final previousAssigneeId = widget.task.assignedStudentId;

              setState(() {
                widget.task.title = titleCtrl.text.trim();
                widget.task.description = descCtrl.text.trim();
                widget.task.dueDate = dueCtrl.text.trim();
                widget.task.assignedStudentId = member.studentId;
                widget.task.assignedTo = member.name;
              });

              if (member.studentId != previousAssigneeId) {
                WorkspaceStore.onTaskAssignedOrReassigned(
                  project: widget.project,
                  task: widget.task,
                  newAssigneeStudentId: member.studentId,
                  actorStudentId: WorkspaceStore.currentStudentId,
                );
              }

              Navigator.pop(ctx);
              WorkspaceStore.checkOverdueTasksAndNotify();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task changes saved successfully!'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTask() {
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
          'Are you sure you want to delete "${widget.task.title}"? This action cannot be undone.',
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
              widget.project.tasks.remove(widget.task);
              Navigator.pop(ctx);
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "${widget.task.title}"'),
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
    final isOverdue = isTaskOverdue(widget.task);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (isPC) ...[
            IconButton(
              tooltip: 'Extend Deadline',
              icon: const Icon(Icons.event_repeat_rounded, color: AppColors.primary),
              onPressed: _showExtendDeadlineModal,
            ),
            IconButton(
              tooltip: 'Edit Task',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editTaskModal,
            ),
            IconButton(
              tooltip: 'Delete Task',
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _confirmDeleteTask,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Task Overview Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isOverdue ? AppColors.danger.withValues(alpha: 0.4) : AppColors.border,
                      width: isOverdue ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.task.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isOverdue) ...[
                                buildOverdueBadge(),
                                const SizedBox(width: 6),
                              ],
                              _buildStatusBadge(widget.task.status),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.task.description.isEmpty
                            ? 'No description provided.'
                            : widget.task.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Assigned To and Due Date Container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_pin_rounded, size: 20, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Assigned To', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                      Text(
                                        widget.task.assignedTo.isNotEmpty
                                            ? widget.task.assignedTo
                                            : 'Student ${widget.task.assignedStudentId}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.event_available_rounded, size: 20, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Due Date', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.task.dueDate,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isOverdue ? AppColors.danger : AppColors.textPrimary,
                                          ),
                                        ),
                                        if (isOverdue) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.danger),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (isPC) ...[
                              const Divider(height: 16, color: AppColors.border),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: _showExtendDeadlineModal,
                                  icon: const Icon(Icons.event_repeat_rounded, size: 16),
                                  label: const Text(
                                    'Extend Deadline (PC Action)',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(height: 24, color: AppColors.border),

                      // Status Dropdown selector
                      DropdownButtonFormField<String>(
                        initialValue: widget.task.status,
                        decoration: const InputDecoration(
                          labelText: 'Update Task Status',
                          prefixIcon: Icon(Icons.sync_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'TODO', child: Text('To Do (Pending)')),
                          DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress (Active)')),
                          DropdownMenuItem(value: 'DONE', child: Text('Completed (Done)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => widget.task.setStatus(val));
                            WorkspaceStore.onStatusChanged(
                              project: widget.project,
                              task: widget.task,
                              newStatus: val,
                              actorStudentId: WorkspaceStore.currentStudentId,
                            );
                            WorkspaceStore.checkOverdueTasksAndNotify();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Status changed to ${formatStatus(val)}'),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Submission / Work Delivery Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPC ? Icons.inventory_2_outlined : Icons.cloud_upload_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPC
                                ? 'Member Deliverable (Coordinator View)'
                                : 'Submit Assignment Link',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (!isPC) ...[
                        Form(
                          key: _uploadFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _uploadUrlCtrl,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'https://github.com/... or Google Drive URL',
                                  labelText: 'Work URL *',
                                  prefixIcon: Icon(Icons.link_rounded),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Please paste a valid submission link';
                                  }
                                  if (!v.trim().startsWith('http://') && !v.trim().startsWith('https://')) {
                                    return 'URL must start with http:// or https://';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    if (!_uploadFormKey.currentState!.validate()) return;
                                    setState(() {
                                      widget.task.submissionUrl = _uploadUrlCtrl.text.trim();
                                      widget.task.submittedAt = DateTime.now();
                                      widget.task.setStatus('DONE');
                                    });
                                    WorkspaceStore.onWorkSubmitted(
                                      project: widget.project,
                                      task: widget.task,
                                      actorStudentId: WorkspaceStore.currentStudentId,
                                    );
                                    WorkspaceStore.onStatusChanged(
                                      project: widget.project,
                                      task: widget.task,
                                      newStatus: 'DONE',
                                      actorStudentId: WorkspaceStore.currentStudentId,
                                    );
                                    WorkspaceStore.checkOverdueTasksAndNotify();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: AppColors.primary,
                                        content: Text('Deliverable saved! Status updated to Completed.'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.check_rounded, size: 18),
                                  label: const Text('Save Submission Link & Mark Completed'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        if (widget.task.submissionUrl == null || widget.task.submissionUrl!.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.scaffoldBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.hourglass_empty_rounded, size: 20, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No deliverable submitted yet from ${widget.task.assignedTo.isNotEmpty ? widget.task.assignedTo : widget.task.assignedStudentId}.',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightAccent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.attachment_rounded, size: 22, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Submitted Link:',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        widget.task.submissionUrl!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                          decoration: TextDecoration.underline,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Comments Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Task Discussion',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    Text(
                      '${widget.task.comments.length} Comments',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (widget.task.comments.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'No comments yet. Start the conversation below!',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...widget.task.comments.map((c) => Card(
                        elevation: 0,
                        color: AppColors.cardBackground,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.lightAccent,
                                    foregroundColor: AppColors.primary,
                                    child: Text(
                                      c.authorName.isNotEmpty ? c.authorName[0] : '?',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    c.authorName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGold,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      formatRole(c.authorRole),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.gold),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    c.timeAgo,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  if (c.authorStudentId == WorkspaceStore.currentStudentId) ...[
                                    const SizedBox(width: 6),
                                    IconButton(
                                      tooltip: 'Delete comment',
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      iconSize: 16,
                                      color: AppColors.textSecondary,
                                      icon: const Icon(Icons.delete_outline_rounded),
                                      onPressed: () => _confirmDeleteComment(c),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c.text,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Add Comment Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      enabled: widget.project.members.any((m) => m.studentId == WorkspaceStore.currentStudentId),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: widget.project.members.any((m) => m.studentId == WorkspaceStore.currentStudentId)
                            ? 'Add a comment or question...'
                            : 'Only project participants can comment',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final isParticipant = widget.project.members.any(
                        (m) => m.studentId == WorkspaceStore.currentStudentId,
                      );
                      if (!isParticipant) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Only project participants can comment on this task.'),
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final text = _commentCtrl.text.trim();
                      if (text.isEmpty) return;

                      final commentId = 'c_${DateTime.now().millisecondsSinceEpoch}';
                      setState(() {
                        widget.task.comments.add(
                          CommentItem(
                            id: commentId,
                            authorStudentId: WorkspaceStore.currentStudentId,
                            authorName: WorkspaceStore.currentUserName.split(' ').first,
                            authorRole: widget.project.myRole,
                            text: text,
                            createdAt: DateTime.now(),
                          ),
                        );
                        _commentCtrl.clear();
                      });

                      // Generate a comment notification only after the comment is saved
                      WorkspaceStore.onCommentAdded(
                        project: widget.project,
                        task: widget.task,
                        commentText: text,
                        actorStudentId: WorkspaceStore.currentStudentId,
                        actorName: WorkspaceStore.currentUserName.split(' ').first,
                        commentId: commentId,
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteComment(CommentItem comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Comment',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: const Text('Delete this comment? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Only the author may delete a comment (same rule as the database API).
    final removed = WorkspaceStore.deleteCommentIfAuthor(
      task: widget.task,
      commentId: comment.id,
      actorStudentId: WorkspaceStore.currentStudentId,
    );
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(removed ? 'Comment deleted' : 'You can only delete your own comments'),
        backgroundColor: removed ? AppColors.primary : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getStatusIcon(status), size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            formatStatus(status),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}
