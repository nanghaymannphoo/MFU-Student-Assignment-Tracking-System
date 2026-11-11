import '../core/utils/status_helpers.dart';
import '../models/team_member.dart';
import '../models/comment_item.dart';
import '../models/task_item.dart';
import '../models/project_model.dart';
import '../models/app_notification.dart';

// ==========================================
// MOCK CONTROLLER / STATE (MVC - Controller)
// ==========================================

class WorkspaceStore {
  static String currentUserName = 'Nang Hay Man Phoo';
  static String currentStudentId = '6731501105';
  static String currentEmail = '6731501105@lamduan.mfu.ac.th';

  static List<ProjectModel> projects = [
    ProjectModel(
      id: 'p1',
      title: 'Student Assignment Tracker',
      courseCode: '1305204 Mobile App Dev',
      description: 'Flutter + Node.js + MySQL group workspace app with MVC.',
      deadline: '2026-11-20',
      myRole: 'PC', // Phoo is PC in this project!
      members: [
        TeamMember(studentId: '6731501105', name: 'Phoo', role: 'PC'),
        TeamMember(studentId: '6731501101', name: 'Menisa', role: 'MEMBER'),
        TeamMember(studentId: '6731501102', name: 'Puttapoom', role: 'MEMBER'),
        TeamMember(studentId: '6731501108', name: 'Glade', role: 'MEMBER'),
      ],
      tasks: [
        TaskItem(
          id: 't1',
          title: 'Design MySQL Schema & Junction Table',
          description: 'Create users, projects, project_members, and tasks tables.',
          assignedTo: 'Puttapoom',
          assignedStudentId: '6731501102',
          dueDate: '2026-11-05',
          status: 'DONE',
          submissionUrl: 'https://github.com/mfu-team/db-schema.sql',
          comments: [
            CommentItem(
              id: 'c2',
              authorStudentId: '6731501105',
              authorName: 'Phoo',
              authorRole: 'PC',
              text: 'Great job! Make sure argon2id hash column is VARCHAR(255).',
              createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            ),
          ],
        ),
        TaskItem(
          id: 't2',
          title: 'Build Flutter Auth & Dashboard UI',
          description: 'Implement Lamduan email validation and multi-role cards.',
          assignedTo: 'Menisa',
          assignedStudentId: '6731501101',
          dueDate: '2026-11-10',
          status: 'IN_PROGRESS',
          comments: [],
        ),
        TaskItem(
          id: 't3',
          title: 'JWT Role Middleware Setup',
          description: 'Verify project_role from project_members table.',
          assignedTo: 'Phoo',
          assignedStudentId: '6731501105',
          dueDate: '2026-11-12',
          status: 'TODO',
          comments: [],
        ),
        TaskItem(
          id: 't4',
          title: 'API Route Specifications & Tests',
          description: 'Define Swagger API endpoints and automated test suites.',
          assignedTo: 'Glade',
          assignedStudentId: '6731501108',
          dueDate: '2026-11-04', // Overdue task (past due date in local time)
          status: 'IN_PROGRESS',
          comments: [
            CommentItem(
              id: 'c1',
              authorStudentId: '6731501108',
              authorName: 'Glade',
              authorRole: 'MEMBER',
              text: 'Working on route integration tests, finishing up mocks.',
              createdAt: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ],
        ),
      ],
    ),
    ProjectModel(
      id: 'p2',
      title: 'Hospital Database System',
      courseCode: '1305202 Database Systems',
      description: 'ER Diagram, Normalization, and SQL Triggers for clinic.',
      deadline: '2026-11-25',
      myRole: 'MEMBER', // Phoo is a member in this project!
      members: [
        TeamMember(studentId: '6731501102', name: 'Puttapoom', role: 'PC'),
        TeamMember(studentId: '6731501105', name: 'Phoo', role: 'MEMBER'),
        TeamMember(studentId: '6731501109', name: 'Mary', role: 'MEMBER'),
      ],
      tasks: [
        TaskItem(
          id: 't201',
          title: 'Write Stored Procedures for Appointments',
          description: 'Create MySQL stored procedures and test with sample data.',
          assignedTo: 'Phoo',
          assignedStudentId: '6731501105',
          dueDate: '2026-11-14',
          status: 'IN_PROGRESS',
          comments: [
            CommentItem(
              id: 'c3',
              authorStudentId: '6731501102',
              authorName: 'Puttapoom',
              authorRole: 'PC',
              text: 'Phoo, please upload the .sql link here when finished.',
              createdAt: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ],
        ),
        TaskItem(
          id: 't202',
          title: '3NF Normalization Report',
          description: 'Document all functional dependencies.',
          assignedTo: 'Mary',
          assignedStudentId: '6731501109',
          dueDate: '2026-11-12',
          status: 'DONE',
          submissionUrl: 'https://drive.google.com/file/d/3nf-report',
        ),
      ],
    ),
  ];

  /// Structured in-memory notification store.
  /// Demo records link to valid projects and tasks addressed to Phoo (6731501105).
  static List<AppNotification> notifications = [
    AppNotification(
      id: 'demo_n1',
      eventId: 'assign_t201_6731501105',
      type: 'TASK_ASSIGNED',
      title: 'Task Assigned',
      message: 'Puttapoom assigned you "Write Stored Procedures for Appointments".',
      recipientStudentId: '6731501105',
      actorStudentId: '6731501102',
      projectId: 'p2',
      taskId: 't201',
      projectName: 'Hospital Database System',
      taskTitle: 'Write Stored Procedures for Appointments',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      isRead: false,
    ),
    AppNotification(
      id: 'demo_n2',
      eventId: 'submit_t1_6731501105',
      type: 'SUBMISSION',
      title: 'Deliverable Submitted',
      message: 'Puttapoom submitted work for "Design MySQL Schema & Junction Table".',
      recipientStudentId: '6731501105',
      actorStudentId: '6731501102',
      projectId: 'p1',
      taskId: 't1',
      projectName: 'Student Assignment Tracker',
      taskTitle: 'Design MySQL Schema & Junction Table',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: false,
    ),
    AppNotification(
      id: 'demo_n3',
      eventId: 'comment_t4_c1_6731501105',
      type: 'COMMENT',
      title: 'New Comment',
      message: 'Glade: "Working on route integration tests, finishing up mocks."',
      recipientStudentId: '6731501105',
      actorStudentId: '6731501108',
      projectId: 'p1',
      taskId: 't4',
      commentId: 'c1',
      projectName: 'Student Assignment Tracker',
      taskTitle: 'API Route Specifications & Tests',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      readAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];

  /// Resolves member display name using known student records.
  static String resolveMemberName(String studentId) {
    if (studentId == currentStudentId) {
      return currentUserName.split(' ').first;
    }
    for (var p in projects) {
      for (var m in p.members) {
        if (m.studentId == studentId && m.name != studentId && m.name.isNotEmpty) {
          return m.name;
        }
      }
    }
    return studentId;
  }

  // ==========================================
  // NOTIFICATION SERVICE & ROUTING CONTROLLER
  // ==========================================

  /// Returns notifications addressed strictly to the signed-in user.
  static List<AppNotification> getNotificationsForCurrentUser() {
    return notifications
        .where((n) => n.recipientStudentId == currentStudentId)
        .toList();
  }

  /// Calculates unread count strictly for the current signed-in user.
  static int getUnreadCountForCurrentUser() {
    return getNotificationsForCurrentUser().where((n) => !n.isRead).length;
  }

  /// Marks all notifications addressed to the current signed-in user as read.
  static void markAllReadForCurrentUser() {
    final now = DateTime.now();
    for (var n in notifications) {
      if (n.recipientStudentId == currentStudentId && !n.isRead) {
        n.isRead = true;
        n.readAt = now;
      }
    }
  }

  /// Deletes a notification only if it is addressed to [actorStudentId].
  /// Returns false when it does not exist or belongs to someone else.
  static bool deleteNotificationIfRecipient({
    required String notificationId,
    required String actorStudentId,
  }) {
    final index = notifications.indexWhere(
      (n) => n.id == notificationId && n.recipientStudentId == actorStudentId,
    );
    if (index < 0) return false;
    notifications.removeAt(index);
    return true;
  }

  /// Deletes a comment only if [actorStudentId] wrote it.
  /// Returns false when it does not exist or belongs to someone else.
  static bool deleteCommentIfAuthor({
    required TaskItem task,
    required String commentId,
    required String actorStudentId,
  }) {
    final index = task.comments.indexWhere(
      (c) => c.id == commentId && c.authorStudentId == actorStudentId,
    );
    if (index < 0) return false;
    task.comments.removeAt(index);
    return true;
  }

  /// Centralized dispatcher:
  /// - Enforces no self-notifications (recipient != actor).
  /// - Enforces no duplicate notifications for the same event and recipient.
  static void dispatchNotification({
    required String eventId,
    required String type,
    required String title,
    required String message,
    required String recipientStudentId,
    required String actorStudentId,
    String? projectId,
    String? taskId,
    String? commentId,
    String? projectName,
    String? taskTitle,
  }) {
    // Rule 1: Never notify the person who performed the action!
    if (recipientStudentId == actorStudentId) return;

    // Rule 2: Prevent duplicate notifications for the same event and recipient
    final duplicate = notifications.any(
      (n) => n.eventId == eventId && n.recipientStudentId == recipientStudentId,
    );
    if (duplicate) return;

    notifications.insert(
      0,
      AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}_${notifications.length}',
        eventId: eventId,
        type: type,
        title: title,
        message: message,
        recipientStudentId: recipientStudentId,
        actorStudentId: actorStudentId,
        projectId: projectId,
        taskId: taskId,
        commentId: commentId,
        projectName: projectName,
        taskTitle: taskTitle,
        createdAt: DateTime.now(),
        isRead: false,
      ),
    );
  }

  /// Triggered after a comment is successfully saved:
  /// - When project PC comments -> notify assigned member.
  /// - When a member comments -> notify project PC.
  /// - Never notify self.
  static void onCommentAdded({
    required ProjectModel project,
    required TaskItem task,
    required String commentText,
    required String actorStudentId,
    required String actorName,
    String? commentId,
  }) {
    final pc = project.members.firstWhere(
      (m) => m.role == 'PC',
      orElse: () => project.members.first,
    );

    final isActorPC = actorStudentId == pc.studentId;
    final recipientId = isActorPC ? task.assignedStudentId : pc.studentId;

    final preview = commentText.length > 50
        ? '${commentText.substring(0, 47)}...'
        : commentText;

    final eventId = 'comment_${task.id}_${commentId ?? DateTime.now().millisecondsSinceEpoch}_$recipientId';

    dispatchNotification(
      eventId: eventId,
      type: 'COMMENT',
      title: 'New Comment',
      message: '$actorName: "$preview"',
      recipientStudentId: recipientId,
      actorStudentId: actorStudentId,
      projectId: project.id,
      taskId: task.id,
      commentId: commentId,
      projectName: project.title,
      taskTitle: task.title,
    );
  }

  /// Triggered when a task is assigned or reassigned:
  /// - Notifies the new assignee (if not self).
  static void onTaskAssignedOrReassigned({
    required ProjectModel project,
    required TaskItem task,
    required String newAssigneeStudentId,
    required String actorStudentId,
  }) {
    final actorName = resolveMemberName(actorStudentId);
    final eventId = 'assign_${task.id}_${newAssigneeStudentId}_${DateTime.now().millisecondsSinceEpoch}';

    dispatchNotification(
      eventId: eventId,
      type: 'TASK_ASSIGNED',
      title: 'Task Assigned',
      message: '$actorName assigned you "${task.title}".',
      recipientStudentId: newAssigneeStudentId,
      actorStudentId: actorStudentId,
      projectId: project.id,
      taskId: task.id,
      projectName: project.title,
      taskTitle: task.title,
    );
  }

  /// Triggered when a member submits a deliverable URL:
  /// - Notifies the project PC (if not self).
  static void onWorkSubmitted({
    required ProjectModel project,
    required TaskItem task,
    required String actorStudentId,
  }) {
    final pc = project.members.firstWhere(
      (m) => m.role == 'PC',
      orElse: () => project.members.first,
    );
    final actorName = resolveMemberName(actorStudentId);
    final eventId = 'submit_${task.id}_${DateTime.now().millisecondsSinceEpoch}';

    dispatchNotification(
      eventId: eventId,
      type: 'SUBMISSION',
      title: 'Deliverable Submitted',
      message: '$actorName submitted work for "${task.title}".',
      recipientStudentId: pc.studentId,
      actorStudentId: actorStudentId,
      projectId: project.id,
      taskId: task.id,
      projectName: project.title,
      taskTitle: task.title,
    );
  }

  /// Triggered when task status changes:
  /// - Member changes status -> notify PC.
  /// - PC changes status -> notify assignee.
  /// - Never notify self.
  static void onStatusChanged({
    required ProjectModel project,
    required TaskItem task,
    required String newStatus,
    required String actorStudentId,
  }) {
    final pc = project.members.firstWhere(
      (m) => m.role == 'PC',
      orElse: () => project.members.first,
    );
    final isActorPC = actorStudentId == pc.studentId;
    final recipientId = isActorPC ? task.assignedStudentId : pc.studentId;
    final actorName = resolveMemberName(actorStudentId);

    final eventId = 'status_${task.id}_${newStatus}_${DateTime.now().millisecondsSinceEpoch}';

    dispatchNotification(
      eventId: eventId,
      type: 'STATUS_CHANGED',
      title: 'Task Status Updated',
      message: '$actorName updated "${task.title}" to ${formatStatus(newStatus)}.',
      recipientStudentId: recipientId,
      actorStudentId: actorStudentId,
      projectId: project.id,
      taskId: task.id,
      projectName: project.title,
      taskTitle: task.title,
    );
  }

  /// Triggered when PC extends a deadline:
  /// - Notifies the assignee with the new deadline.
  /// - Resolves outdated overdue alerts for this task.
  static bool extendTaskDeadline({
    required ProjectModel project,
    required TaskItem task,
    required String newDueDate,
    required String actorStudentId,
  }) {
    // 1. Strict PC enforcement
    if (!project.isCurrentUserPC) return false;

    final parsedNew = DateTime.tryParse(newDueDate.trim());
    final parsedOld = DateTime.tryParse(task.dueDate.trim());
    if (parsedNew == null) return false;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    if (parsedNew.isBefore(todayStart)) return false;

    if (parsedOld != null && !parsedNew.isAfter(parsedOld)) {
      return false;
    }

    // 2. Update task deadline while preserving progress status
    task.dueDate = newDueDate.trim();

    // 3. Resolve any outdated overdue alerts for this task
    notifications.removeWhere((n) => n.taskId == task.id && n.type == 'OVERDUE');

    // 4. Notify assignee (if not self)
    final eventId = 'extend_${task.id}_${task.dueDate}';
    dispatchNotification(
      eventId: eventId,
      type: 'DEADLINE_EXTENDED',
      title: 'Deadline Extended',
      message: 'The deadline for "${task.title}" was extended to ${task.dueDate}.',
      recipientStudentId: task.assignedStudentId,
      actorStudentId: actorStudentId,
      projectId: project.id,
      taskId: task.id,
      projectName: project.title,
      taskTitle: task.title,
    );

    return true;
  }

  /// Checks deadlines for all tasks across all projects:
  /// - Notifies assigned member (if not self).
  /// - Notifies project PC (if not self / not assignee).
  /// - Avoids duplicate alerts.
  static void checkOverdueTasksAndNotify() {
    for (var project in projects) {
      final pcMember = project.members.firstWhere(
        (m) => m.role == 'PC',
        orElse: () => project.members.first,
      );

      for (var task in project.tasks) {
        if (isTaskOverdue(task)) {
          // 1. Notify Assignee
          if (task.assignedStudentId.isNotEmpty) {
            final eventIdAssignee = 'overdue_${task.id}_${task.dueDate}_${task.assignedStudentId}';
            dispatchNotification(
              eventId: eventIdAssignee,
              type: 'OVERDUE',
              title: 'Overdue Task Alert',
              message: 'Task "${task.title}" in ${project.title} was due on ${task.dueDate} and is now overdue.',
              recipientStudentId: task.assignedStudentId,
              actorStudentId: 'SYSTEM',
              projectId: project.id,
              taskId: task.id,
              projectName: project.title,
              taskTitle: task.title,
            );
          }

          // 2. Notify PC (if PC is not the assignee)
          if (pcMember.studentId != task.assignedStudentId) {
            final eventIdPC = 'overdue_${task.id}_${task.dueDate}_${pcMember.studentId}';
            final assigneeName = task.assignedTo.isNotEmpty
                ? task.assignedTo
                : 'Student ${task.assignedStudentId}';

            dispatchNotification(
              eventId: eventIdPC,
              type: 'OVERDUE',
              title: 'Overdue Task Alert',
              message: 'Task "${task.title}" (assigned to $assigneeName) was due on ${task.dueDate} and is now overdue.',
              recipientStudentId: pcMember.studentId,
              actorStudentId: 'SYSTEM',
              projectId: project.id,
              taskId: task.id,
              projectName: project.title,
              taskTitle: task.title,
            );
          }
        }
      }
    }
  }

  /// Broadcast announcement to all project members:
  /// - Only PC can broadcast.
  /// - Never sends to the sender.
  static void onProjectAnnouncement({
    required ProjectModel project,
    required String title,
    required String message,
    required String actorStudentId,
  }) {
    for (var member in project.members) {
      if (member.studentId != actorStudentId) {
        final eventId = 'announcement_${project.id}_${DateTime.now().millisecondsSinceEpoch}_${member.studentId}';
        dispatchNotification(
          eventId: eventId,
          type: 'ANNOUNCEMENT',
          title: 'Project Announcement: ${project.title}',
          message: '$title: $message',
          recipientStudentId: member.studentId,
          actorStudentId: actorStudentId,
          projectId: project.id,
          projectName: project.title,
        );
      }
    }
  }
}
