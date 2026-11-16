import '../core/utils/status_helpers.dart';
import '../models/team_member.dart';
import '../models/comment_item.dart';
import '../models/task_item.dart';
import '../models/project_model.dart';
import '../models/app_notification.dart';
import '../models/assigned_task_entry.dart';
import '../models/api_models.dart';
import '../controller/api_controller.dart';

// ==========================================
// MOCK CONTROLLER / STATE (MVC - Controller)
// ==========================================

class WorkspaceStore {
  // ค่าเหล่านี้ถูกเติมจาก API ตอน login / AuthGate (GET /api/users/me)
  static String currentUserName = '';
  static String currentStudentId = '';
  static String currentEmail = '';

  /// โปรเจคของผู้ใช้ปัจจุบัน — โหลดจาก SQL ผ่าน loadProjectsFromServer()
  static List<ProjectModel> projects = <ProjectModel>[];

  // ==========================================
  // SERVER SYNC (Auth / User / Project / Member)
  // ==========================================

  /// ล้างข้อมูลผู้ใช้ + โปรเจคในเครื่อง (ใช้ตอน logout / token หมดอายุ)
  static void clearSession() {
    currentStudentId = '';
    currentUserName = '';
    currentEmail = '';
    projects = <ProjectModel>[];
    notifications = <AppNotification>[];
  }

  static ProjectModel _projectFromApi(
    ProjectData d, {
    required bool hasDetail,
    List<TaskItem>? tasks,
  }) {
    final members = hasDetail
        ? d.members
            .map((m) => TeamMember(
                  studentId: m.studentId,
                  name: m.fullName.isNotEmpty ? m.fullName : m.studentId,
                  role: m.projectRole,
                ))
            .toList()
        // โหลดรายละเอียดไม่ได้: ใส่ตัวเองไว้ก่อน กัน members ว่าง
        : <TeamMember>[
            TeamMember(
              studentId: currentStudentId,
              name: currentUserName.split(' ').first,
              role: d.myRole,
            ),
          ];
    return ProjectModel(
      id: d.id,
      title: d.title,
      courseCode: d.courseCode,
      description:
          d.description.isEmpty ? 'No project description provided.' : d.description,
      deadline: d.deadline,
      myRole: d.myRole,
      members: members,
      tasks: tasks ?? <TaskItem>[], // งานโหลดแยกผ่าน GET /api/projects/:id/tasks
    );
  }

  /// GET /api/projects + GET /api/projects/:id (สมาชิก) + GET /api/projects/:id/tasks
  /// แล้วแทนที่ [projects] — งานเดิมในเครื่องจะถูกอัปเดตในอ็อบเจกต์เดิม (คอมเมนต์ไม่หาย)
  /// โยน ApiException ออกไปให้หน้าจอจัดการ (401 -> กลับหน้า login)
  static Future<void> loadProjectsFromServer() async {
    final pc = ProjectController();
    final tc = TaskController();
    final list = await pc.getProjects();
    final oldTasks = {for (final p in projects) p.id: p.tasks};

    final details = await Future.wait(list.map((p) async {
      try {
        return await pc.getProject(p.id);
      } on ApiException catch (e) {
        if (e.statusCode == 401) rethrow;
        return null;
      }
    }));

    final taskData = await Future.wait(list.map((p) async {
      try {
        return await tc.getTasks(p.id);
      } on ApiException catch (e) {
        if (e.statusCode == 401) rethrow;
        return null; // โหลดไม่ได้ -> ใช้งานเดิมในเครื่องไปก่อน
      }
    }));

    final loaded = <ProjectModel>[];
    for (var i = 0; i < list.length; i++) {
      final detail = details[i];
      final data = taskData[i];
      loaded.add(_projectFromApi(
        detail ?? list[i],
        hasDetail: detail != null,
        tasks: data == null
            ? oldTasks[list[i].id]
            : _mergeTasks(oldTasks[list[i].id], data),
      ));
    }
    projects = loaded;
  }

  /// ดึงรายชื่อสมาชิกล่าสุดของโปรเจคเดียว แล้วอัปเดตในอ็อบเจกต์เดิม
  static Future<void> refreshProjectMembers(String projectId) async {
    final idx = projects.indexWhere((p) => p.id == projectId);
    if (idx < 0) return;
    final d = await ProjectController().getProject(projectId);
    final fresh = _projectFromApi(d, hasDetail: true);
    projects[idx].members
      ..clear()
      ..addAll(fresh.members);
  }

  /// เหมือน removeMemberFromProject แต่ยิง DELETE /api/projects/:id/members/:studentId จริง
  static Future<RemoveMemberResult> removeMemberViaApi({
    required String projectId,
    required String memberStudentId,
    required String actingStudentId,
  }) async {
    final projectIndex = projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) {
      return const RemoveMemberResult(success: false, message: 'Project not found.');
    }
    final project = projects[projectIndex];

    final actingMember = project.members.firstWhere(
      (m) => m.studentId == actingStudentId,
      orElse: () => TeamMember(studentId: '', name: '', role: ''),
    );
    final isActingPC = actingMember.role.toUpperCase() == 'PC' ||
        (actingStudentId == currentStudentId && project.isCurrentUserPC);
    if (!isActingPC) {
      return const RemoveMemberResult(
        success: false,
        message: 'Only that project’s PC can remove members.',
      );
    }

    final memberIndex = project.members.indexWhere((m) => m.studentId == memberStudentId);
    if (memberIndex == -1) {
      return const RemoveMemberResult(
        success: false,
        message: 'Member not found in this project.',
      );
    }
    if (project.members[memberIndex].role.toUpperCase() == 'PC') {
      return const RemoveMemberResult(
        success: false,
        message: 'The project PC cannot be removed.',
      );
    }
    if (project.tasks.any((t) => t.assignedStudentId == memberStudentId)) {
      return const RemoveMemberResult(
        success: false,
        message: 'Please reassign this member’s tasks before removing them.',
      );
    }

    try {
      await MemberController().removeMember(projectId, memberStudentId);
    } on ApiException catch (e) {
      return RemoveMemberResult(success: false, message: e.message);
    }
    project.members.removeWhere((m) => m.studentId == memberStudentId);
    return const RemoveMemberResult(
      success: true,
      message: 'Member removed successfully.',
    );
  }

  /// การแจ้งเตือนของผู้ใช้ปัจจุบัน — โหลดจาก GET /api/notifications (loadNotificationsFromServer)
  /// ยกเว้นแจ้งเตือน OVERDUE ที่แอปสร้างเอง (isLocal) ซึ่งเก็บไว้ในเครื่อง
  static List<AppNotification> notifications = <AppNotification>[];

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
  // PERSONAL TASK SERVICE (MY TASKS)
  // ==========================================

  /// Returns all tasks assigned to the signed-in user across projects they belong to.
  /// Matching strictly by Student ID, never by display name.
  /// Includes tasks assigned to the user even when they are the project PC.
  static List<AssignedTaskEntry> getAssignedTasksForCurrentUser({String? studentId}) {
    final sid = studentId ?? currentStudentId;
    final List<AssignedTaskEntry> result = [];
    for (final project in projects) {
      final isMember = project.members.any((m) => m.studentId == sid);
      if (!isMember) continue;
      for (final task in project.tasks) {
        if (task.assignedStudentId == sid) {
          result.add(AssignedTaskEntry(project: project, task: task));
        }
      }
    }
    return result;
  }

  // ==========================================
  // NOTIFICATION SERVICE & ROUTING CONTROLLER
  // ==========================================

  /// Returns notifications addressed strictly to the signed-in user.
  static List<AppNotification> getNotificationsForCurrentUser() {
    // แจ้งเตือนจาก server เป็นของผู้ใช้ปัจจุบันเสมอ; แจ้งเตือนที่สร้างในเครื่องต้องเช็กผู้รับ
    return notifications
        .where((n) => !n.isLocal || n.recipientStudentId == currentStudentId)
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
      if (!n.isLocal || n.recipientStudentId == currentStudentId) {
        n.isRead = true;
        n.readAt ??= now;
      }
    }
  }

  /// GET /api/notifications แล้วแทนที่รายการในเครื่อง
  /// (เก็บเฉพาะ OVERDUE ที่สร้างในเครื่อง และข้ามถ้า server ส่ง OVERDUE ของงานเดียวกันมาแล้ว)
  static Future<void> loadNotificationsFromServer() async {
    final list = await NotificationController().getNotifications();
    final fromServer = list.map(notificationFromApi).toList();
    final localOnly = notifications
        .where((n) =>
            n.isLocal &&
            !fromServer.any((s) => s.type == 'OVERDUE' && s.taskId == n.taskId))
        .toList();
    notifications = [...localOnly, ...fromServer]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static AppNotification notificationFromApi(NotificationData n) {
    String? projectName;
    String? taskTitle;
    if (n.projectId != null) {
      for (final p in projects) {
        if (p.id != n.projectId) continue;
        projectName = p.title;
        if (n.taskId != null) {
          for (final t in p.tasks) {
            if (t.id == n.taskId) {
              taskTitle = t.title;
              break;
            }
          }
        }
        break;
      }
    }
    return AppNotification(
      id: n.id,
      eventId: n.id,
      type: n.type,
      title: n.title,
      message: n.message,
      recipientStudentId: currentStudentId, // GET /api/notifications คืนเฉพาะของเรา
      actorStudentId: n.senderId ?? 'SYSTEM',
      projectId: n.projectId,
      taskId: n.taskId,
      projectName: projectName,
      taskTitle: taskTitle,
      createdAt: _parseTime(n.createdAt) ?? DateTime.now(),
      isRead: n.isRead,
    );
  }

  /// PATCH /api/notifications/:id/read — อัปเดตในเครื่องก่อน (optimistic)
  /// ถ้า API ล้มเหลวจะย้อนกลับเป็นยังไม่อ่านแล้วโยน ApiException
  static Future<void> markNotificationReadViaApi(AppNotification n) async {
    if (n.isRead) return;
    final previousReadAt = n.readAt;
    n.isRead = true;
    n.readAt = DateTime.now();
    if (n.isLocal) return;
    try {
      await NotificationController().markRead(n.id);
    } on ApiException {
      n.isRead = false;
      n.readAt = previousReadAt;
      rethrow;
    }
  }

  /// PATCH /api/notifications/read-all
  static Future<void> markAllNotificationsReadViaApi() async {
    await NotificationController().markAllRead();
    markAllReadForCurrentUser();
  }

  /// DELETE /api/notifications/:id (ลบได้เฉพาะของตัวเอง)
  static Future<void> deleteNotificationViaApi(AppNotification n) async {
    if (!n.isLocal) {
      await NotificationController().deleteNotification(n.id);
    }
    notifications.removeWhere((x) => x.id == n.id);
  }

  /// Centralized dispatcher (ใช้เฉพาะแจ้งเตือน OVERDUE ที่คำนวณในเครื่อง —
  /// แจ้งเตือนอื่นทั้งหมด server เป็นคนสร้างเมื่อมีการเรียก API):
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
        isLocal: true,
      ),
    );
  }

  // ==========================================
  // TASK / COMMENT (เชื่อม API จริง)
  // ==========================================
  // หมายเหตุ: การแจ้งเตือน (มอบหมายงาน, เปลี่ยนสถานะ, ส่งงาน, คอมเมนต์, ขยายเวลา)
  // server สร้างให้เองตอนเรียก API จึงไม่ต้อง dispatch ในเครื่องอีกต่อไป

  static DateTime? _parseTime(String s) {
    if (s.isEmpty) return null;
    return DateTime.tryParse(s)?.toLocal();
  }

  /// เขียนข้อมูลจาก API ลงใน TaskItem เดิม (คงอ็อบเจกต์/คอมเมนต์ไว้)
  static void applyTaskData(TaskItem t, TaskData d) {
    t.title = d.title;
    t.description = d.description;
    t.assignedStudentId = d.assignedTo ?? '';
    t.assignedTo = d.assignedName.isNotEmpty
        ? d.assignedName
        : (d.assignedTo == null ? '' : resolveMemberName(d.assignedTo!));
    t.dueDate = d.dueDate;
    t.status = d.status;
    t.submissionUrl = d.submissionUrl;
    t.submittedAt = _parseTime(d.submittedAt);
    t.completedAt = _parseTime(d.completedAt);
  }

  static TaskItem taskFromApi(TaskData d) {
    final t = TaskItem(
      id: d.id,
      title: d.title,
      description: d.description,
      assignedTo: '',
      dueDate: d.dueDate,
    );
    applyTaskData(t, d);
    return t;
  }

  /// รวมงานจาก server เข้ากับงานเดิม: id เดิมอัปเดตในอ็อบเจกต์เดิม, id ใหม่สร้างใหม่,
  /// งานที่ server ไม่มีแล้วจะหายไป
  static List<TaskItem> _mergeTasks(List<TaskItem>? old, List<TaskData> data) {
    final byId = {for (final t in old ?? const <TaskItem>[]) t.id: t};
    return data.map((d) {
      final existing = byId[d.id];
      if (existing == null) return taskFromApi(d);
      applyTaskData(existing, d);
      return existing;
    }).toList();
  }

  static CommentItem commentFromApi(CommentData c) => CommentItem(
        id: c.id.toString(),
        authorStudentId: c.authorId,
        authorName: c.authorName.isNotEmpty ? c.authorName : c.authorId,
        authorRole: c.authorRole,
        text: c.text,
        createdAt: _parseTime(c.createdAt) ?? DateTime.now(),
      );

  /// GET /api/projects/:id/tasks ของโปรเจคเดียว แล้วอัปเดตในอ็อบเจกต์เดิม
  static Future<void> refreshProjectTasks(String projectId) async {
    final idx = projects.indexWhere((p) => p.id == projectId);
    if (idx < 0) return;
    final data = await TaskController().getTasks(projectId);
    final merged = _mergeTasks(projects[idx].tasks, data);
    projects[idx].tasks
      ..clear()
      ..addAll(merged);
  }

  /// POST /api/projects/:id/tasks (PC เท่านั้น) แล้วเพิ่มงานเข้าโปรเจคในเครื่อง
  static Future<TaskItem> createTaskViaApi(
    ProjectModel project, {
    required String title,
    required String assigneeStudentId,
    String? description,
  }) async {
    final tc = TaskController();
    final due = project.deadline.trim();
    final id = await tc.createTask(
      project.id,
      title: title,
      description: description,
      assignedTo: assigneeStudentId.isEmpty ? null : assigneeStudentId,
      dueDate: due.isEmpty ? null : due,
    );
    TaskItem task;
    try {
      task = taskFromApi(await tc.getTask(id));
    } on ApiException {
      // สร้างสำเร็จแล้วแต่ดึงซ้ำไม่ได้ -> ใช้ค่าที่เรามีไปก่อน
      task = TaskItem(
        id: id,
        title: title,
        description: description ?? '',
        assignedTo: assigneeStudentId.isEmpty ? '' : resolveMemberName(assigneeStudentId),
        assignedStudentId: assigneeStudentId,
        dueDate: due,
      );
    }
    project.tasks.add(task);
    return task;
  }

  /// PUT /api/tasks/:id (+ PATCH /api/tasks/:id/assign ถ้าเปลี่ยนผู้รับงาน)
  /// ส่งเฉพาะช่องที่เปลี่ยน — เปลี่ยน due date server จะแจ้งผู้รับงานเอง
  static Future<void> updateTaskViaApi(
    TaskItem task, {
    required String title,
    required String description,
    required String dueDate,
    required String assigneeStudentId,
    required String assigneeName,
  }) async {
    final tc = TaskController();
    final dueChanged = dueDate != task.dueDate;
    if (title != task.title || description != task.description || dueChanged) {
      await tc.updateTask(
        task.id,
        title: title != task.title ? title : null,
        description: description != task.description ? description : null,
        dueDate: dueChanged ? dueDate : null,
      );
      task.title = title;
      task.description = description;
      task.dueDate = dueDate;
      if (dueChanged) {
        notifications.removeWhere(
            (n) => n.isLocal && n.taskId == task.id && n.type == 'OVERDUE');
      }
    }
    if (assigneeStudentId.isNotEmpty && assigneeStudentId != task.assignedStudentId) {
      await tc.assignTask(task.id, assigneeStudentId);
      task.assignedStudentId = assigneeStudentId;
      task.assignedTo = assigneeName;
    }
  }

  /// PATCH /api/tasks/:id/status (PC หรือผู้รับงาน)
  static Future<void> updateStatusViaApi(TaskItem task, String status) async {
    await TaskController().updateStatus(task.id, status);
    task.setStatus(status);
  }

  /// POST /api/tasks/:id/submission แล้วตั้งสถานะ DONE (ถ้า server ยังไม่ได้ตั้งให้เอง)
  static Future<void> submitWorkViaApi(TaskItem task, String url) async {
    final tc = TaskController();
    await tc.submitWork(task.id, url);
    task.submissionUrl = url;
    task.submittedAt = DateTime.now();
    var alreadyDone = false;
    try {
      alreadyDone = (await tc.getTask(task.id)).status == 'DONE';
    } on ApiException {
      alreadyDone = false;
    }
    if (!alreadyDone) {
      await tc.updateStatus(task.id, 'DONE');
    }
    task.setStatus('DONE');
  }

  /// DELETE /api/tasks/:id (PC เท่านั้น)
  static Future<void> deleteTaskViaApi(ProjectModel project, TaskItem task) async {
    await TaskController().deleteTask(task.id);
    project.tasks.remove(task);
    notifications.removeWhere((n) => n.isLocal && n.taskId == task.id);
  }

  /// PC ขยายเวลางาน: ตรวจเงื่อนไขในเครื่อง แล้ว PUT /api/tasks/:id (server แจ้งผู้รับงานเอง)
  /// คืน false ถ้าไม่ผ่านเงื่อนไข, โยน ApiException ถ้า API ล้มเหลว
  static Future<bool> extendTaskDeadline({
    required ProjectModel project,
    required TaskItem task,
    required String newDueDate,
    required String actorStudentId,
  }) async {
    if (!project.isCurrentUserPC) return false;

    final parsedNew = DateTime.tryParse(newDueDate.trim());
    final parsedOld = DateTime.tryParse(task.dueDate.trim());
    if (parsedNew == null) return false;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    if (parsedNew.isBefore(todayStart)) return false;
    if (parsedOld != null && !parsedNew.isAfter(parsedOld)) return false;

    await TaskController().updateTask(task.id, dueDate: newDueDate.trim());
    task.dueDate = newDueDate.trim();
    notifications.removeWhere(
        (n) => n.isLocal && n.taskId == task.id && n.type == 'OVERDUE');
    return true;
  }

  /// GET /api/tasks/:id/comments แล้วแทนที่คอมเมนต์ในงาน
  static Future<void> loadCommentsForTask(TaskItem task) async {
    final list = await CommentController().getComments(task.id);
    task.comments
      ..clear()
      ..addAll(list.map(commentFromApi));
  }

  /// POST /api/tasks/:id/comments — server แจ้งเตือนอีกฝ่ายเอง
  static Future<CommentItem> addCommentViaApi(TaskItem task, String text) async {
    final c = commentFromApi(await CommentController().addComment(task.id, text));
    task.comments.add(c);
    return c;
  }

  /// DELETE /api/comments/:id (ลบได้เฉพาะของตัวเอง — server ตรวจให้)
  static Future<void> deleteCommentViaApi(TaskItem task, CommentItem comment) async {
    final id = int.tryParse(comment.id);
    if (id == null) throw ApiException('Invalid comment id');
    await CommentController().deleteComment(id);
    task.comments.removeWhere((c) => c.id == comment.id);
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

  // ==========================================
  // PROJECT MEMBER MANAGEMENT
  // ==========================================

  /// Attempts to remove a member from a project:
  /// - Only that project’s PC can remove members.
  /// - The project PC cannot be removed.
  /// - Identifies members and task assignees strictly by Student ID.
  /// - Checks ALL tasks (TODO, IN_PROGRESS, DONE) in the project.
  /// - If any tasks are assigned, blocks removal and reports the required message.
  /// - Rechecks permissions and assignments before modifying data.
  static RemoveMemberResult removeMemberFromProject({
    required String projectId,
    required String memberStudentId,
    required String actingStudentId,
  }) {
    final projectIndex = projects.indexWhere((p) => p.id == projectId);
    if (projectIndex == -1) {
      return const RemoveMemberResult(
        success: false,
        message: 'Project not found.',
      );
    }
    final project = projects[projectIndex];

    // 1. Recheck acting user's permissions: must be the project PC
    final actingMember = project.members.firstWhere(
      (m) => m.studentId == actingStudentId,
      orElse: () => TeamMember(studentId: '', name: '', role: ''),
    );
    final isActingPC = actingMember.role.toUpperCase() == 'PC' ||
        (actingStudentId == currentStudentId && project.isCurrentUserPC);
    if (!isActingPC) {
      return const RemoveMemberResult(
        success: false,
        message: 'Only that project’s PC can remove members.',
      );
    }

    // 2. Member existence check
    final memberIndex = project.members.indexWhere((m) => m.studentId == memberStudentId);
    if (memberIndex == -1) {
      return const RemoveMemberResult(
        success: false,
        message: 'Member not found in this project.',
      );
    }
    final targetMember = project.members[memberIndex];

    // 3. Do not allow removing the project PC
    if (targetMember.role.toUpperCase() == 'PC') {
      return const RemoveMemberResult(
        success: false,
        message: 'The project PC cannot be removed.',
      );
    }

    // 4. Check ALL project tasks, including completed tasks, for assignments to that Student ID
    final hasAssignedTasks = project.tasks.any((t) => t.assignedStudentId == memberStudentId);
    if (hasAssignedTasks) {
      return const RemoveMemberResult(
        success: false,
        message: 'Please reassign this member’s tasks before removing them.',
      );
    }

    // 5. All checks passed -> remove only their membership from this project
    project.members.removeAt(memberIndex);
    return const RemoveMemberResult(
      success: true,
      message: 'Member removed successfully.',
    );
  }
}

class RemoveMemberResult {
  final bool success;
  final String message;

  const RemoveMemberResult({required this.success, required this.message});
}
