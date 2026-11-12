/// Model สำหรับข้อมูลที่ได้จาก API (ตั้งชื่อไม่ชนกับ ProjectModel / TeamMember เดิมของ UI)

int _toInt(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

/// แปลงวันที่จาก backend ให้เป็น 'YYYY-MM-DD' (ตรงกับที่หน้าจอใช้)
String dateOnly(dynamic v) {
  if (v == null) return '';
  final s = v.toString();
  if (s.length == 10) return s;
  final d = DateTime.tryParse(s);
  if (d == null) return s;
  final l = d.toLocal();
  return '${l.year.toString().padLeft(4, '0')}-'
      '${l.month.toString().padLeft(2, '0')}-'
      '${l.day.toString().padLeft(2, '0')}';
}

class UserModel {
  final String studentId;
  final String fullName;
  final String email; // getUser ของคนอื่นอาจไม่มี email
  final String? avatarUrl;

  UserModel({
    required this.studentId,
    required this.fullName,
    this.email = '',
    this.avatarUrl,
  });

  factory UserModel.fromJSON(Map<String, dynamic> json) => UserModel(
        studentId: json['student_id'],
        fullName: json['full_name'],
        email: json['email'] ?? '',
        avatarUrl: json['avatar_url'],
      );
}

class MemberModel {
  final String studentId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String projectRole; // 'PC' | 'MEMBER'
  final String joinedAt;

  MemberModel({
    required this.studentId,
    required this.fullName,
    this.email = '',
    this.avatarUrl,
    required this.projectRole,
    this.joinedAt = '',
  });

  bool get isPC => projectRole == 'PC';

  factory MemberModel.fromJSON(Map<String, dynamic> json) => MemberModel(
        studentId: json['student_id'],
        fullName: json['full_name'],
        email: json['email'] ?? '',
        avatarUrl: json['avatar_url'],
        projectRole: json['project_role'] ?? 'MEMBER',
        joinedAt: json['joined_at']?.toString() ?? '',
      );
}

class ProjectData {
  final String id;
  final String title;
  final String courseCode;
  final String description;
  final String deadline; // 'YYYY-MM-DD' หรือ '' ถ้าไม่มี
  final String createdBy;
  final String myRole; // 'PC' | 'MEMBER'
  final List<MemberModel> members; // มีเฉพาะตอน getProject
  // ตัวเลขสรุปที่ GET /api/projects ส่งมา (getProject รายตัวไม่มี จะเป็น 0)
  final int memberCount;
  final int taskTotal;
  final int taskTodo;
  final int taskInProgress;
  final int taskDone;
  final int taskOverdue;

  ProjectData({
    required this.id,
    required this.title,
    this.courseCode = '',
    this.description = '',
    this.deadline = '',
    this.createdBy = '',
    this.myRole = 'MEMBER',
    this.members = const [],
    this.memberCount = 0,
    this.taskTotal = 0,
    this.taskTodo = 0,
    this.taskInProgress = 0,
    this.taskDone = 0,
    this.taskOverdue = 0,
  });

  bool get isPC => myRole == 'PC';

  /// ความคืบหน้า 0.0 - 1.0 (ไม่มีงาน = 0)
  double get progress => taskTotal == 0 ? 0 : taskDone / taskTotal;

  factory ProjectData.fromJSON(Map<String, dynamic> json) => ProjectData(
        id: json['id'],
        title: json['title'],
        courseCode: json['course_code'] ?? '',
        description: json['description'] ?? '',
        deadline: dateOnly(json['deadline']),
        createdBy: json['created_by'] ?? '',
        myRole: json['my_role'] ?? 'MEMBER',
        members: (json['members'] as List<dynamic>? ?? [])
            .map((m) => MemberModel.fromJSON(m))
            .toList(),
        memberCount: _toInt(json['member_count']),
        taskTotal: _toInt(json['task_total']),
        taskTodo: _toInt(json['task_todo']),
        taskInProgress: _toInt(json['task_in_progress']),
        taskDone: _toInt(json['task_done']),
        taskOverdue: _toInt(json['task_overdue']),
      );
}

class DeadlineItem {
  final String taskId;
  final String title;
  final String projectId;
  final String projectTitle;
  final String dueDate;
  final String status;

  DeadlineItem({
    required this.taskId,
    required this.title,
    required this.projectId,
    required this.projectTitle,
    required this.dueDate,
    required this.status,
  });

  factory DeadlineItem.fromJSON(Map<String, dynamic> json) => DeadlineItem(
        taskId: json['id'],
        title: json['title'],
        projectId: json['project_id'],
        projectTitle: json['project_title'] ?? '',
        dueDate: dateOnly(json['due_date']),
        status: json['status'],
      );
}

class DashboardModel {
  final int totalProjects;
  final int totalTasks; // งานที่มอบหมายให้ฉัน
  final int todo;
  final int inProgress;
  final int done;
  final int overdue;
  final List<DeadlineItem> upcomingDeadlines;

  DashboardModel({
    required this.totalProjects,
    required this.totalTasks,
    required this.todo,
    required this.inProgress,
    required this.done,
    required this.overdue,
    required this.upcomingDeadlines,
  });

  factory DashboardModel.fromJSON(Map<String, dynamic> json) => DashboardModel(
        totalProjects: _toInt(json['total_projects']),
        totalTasks: _toInt(json['total_tasks']),
        todo: _toInt(json['todo']),
        inProgress: _toInt(json['in_progress']),
        done: _toInt(json['done']),
        overdue: _toInt(json['overdue']),
        upcomingDeadlines: (json['upcoming_deadlines'] as List<dynamic>? ?? [])
            .map((d) => DeadlineItem.fromJSON(d))
            .toList(),
      );
}

/// งาน (ตาราง tasks) จาก GET /api/projects/:id/tasks และ GET /api/tasks/:id
class TaskData {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String? assignedTo; // student_id หรือ null ถ้ายังไม่มอบหมาย
  final String assignedName; // ชื่อผู้รับงาน ('' ถ้าไม่มี)
  final String dueDate; // 'YYYY-MM-DD' หรือ '' ถ้าไม่มี
  final String status; // 'TODO' | 'IN_PROGRESS' | 'DONE'
  final String? submissionUrl;
  final String submittedAt; // เวลาที่ส่งงานล่าสุด ('' ถ้ายังไม่ส่ง)
  final String completedAt; // เวลาที่งานเสร็จ ('' ถ้ายังไม่เสร็จ)
  final String myRole; // 'PC' | 'MEMBER' มีเฉพาะตอน getTask ('' ถ้าไม่มี)

  TaskData({
    required this.id,
    this.projectId = '',
    required this.title,
    this.description = '',
    this.assignedTo,
    this.assignedName = '',
    this.dueDate = '',
    this.status = 'TODO',
    this.submissionUrl,
    this.submittedAt = '',
    this.completedAt = '',
    this.myRole = '',
  });

  bool get isDone => status == 'DONE';

  /// กติกาเดียวกับฐานข้อมูล: ยังไม่ DONE และ due_date ผ่านมาแล้ว (เทียบแบบ YYYY-MM-DD)
  bool get isOverdue {
    if (isDone || dueDate.isEmpty) return false;
    return dueDate.compareTo(dateOnly(DateTime.now().toIso8601String())) < 0;
  }

  factory TaskData.fromJSON(Map<String, dynamic> json) => TaskData(
        id: json['id'],
        projectId: json['project_id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        assignedTo: json['assigned_to'],
        assignedName: json['assigned_name'] ?? '',
        dueDate: dateOnly(json['due_date']),
        status: json['status'] ?? 'TODO',
        submissionUrl: json['submission_url'],
        submittedAt: json['submitted_at']?.toString() ?? '',
        completedAt: json['completed_at']?.toString() ?? '',
        myRole: json['my_role'] ?? '',
      );
}

/// คอมเมนต์ (ตาราง task_comments) จาก GET/POST /api/tasks/:id/comments
class CommentData {
  final int id; // task_comments.id (INT)
  final String taskId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String authorRole; // 'PC' | 'MEMBER' ('' ถ้าผู้เขียนไม่ได้อยู่ในโปรเจคแล้ว)
  final String text;
  final String createdAt;

  CommentData({
    required this.id,
    this.taskId = '',
    required this.authorId,
    this.authorName = '',
    this.authorAvatar,
    this.authorRole = '',
    required this.text,
    this.createdAt = '',
  });

  /// ลบได้เฉพาะคอมเมนต์ของตัวเอง
  bool isMine(String studentId) => authorId == studentId;

  factory CommentData.fromJSON(Map<String, dynamic> json) => CommentData(
        id: _toInt(json['id']),
        taskId: json['task_id'] ?? '',
        authorId: json['author_id'],
        authorName: json['author_name'] ?? '',
        authorAvatar: json['author_avatar'],
        authorRole: json['author_role'] ?? '',
        text: json['comment_text'] ?? '',
        createdAt: json['created_at']?.toString() ?? '',
      );
}

/// การแจ้งเตือน (ตาราง notifications) จาก GET /api/notifications
class NotificationData {
  final String id;
  final String? senderId; // null ถ้าผู้ส่งถูกลบ หรือเป็นระบบ
  final String senderName;
  final String? projectId;
  final String? taskId;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;
  final String type; // server คำนวณให้ ('' ถ้าไม่มี)

  NotificationData({
    required this.id,
    this.senderId,
    this.senderName = '',
    this.projectId,
    this.taskId,
    required this.title,
    this.message = '',
    this.isRead = false,
    this.createdAt = '',
    this.type = '',
  });

  factory NotificationData.fromJSON(Map<String, dynamic> json) => NotificationData(
        id: json['id'],
        senderId: json['sender_id'],
        senderName: json['sender_name'] ?? '',
        projectId: json['project_id'],
        taskId: json['task_id'],
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        isRead: json['is_read'] == true || json['is_read'] == 1,
        createdAt: json['created_at']?.toString() ?? '',
        type: json['type'] ?? '',
      );
}
