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

  ProjectData({
    required this.id,
    required this.title,
    this.courseCode = '',
    this.description = '',
    this.deadline = '',
    this.createdBy = '',
    this.myRole = 'MEMBER',
    this.members = const [],
  });

  bool get isPC => myRole == 'PC';

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
