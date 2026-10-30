import 'package:flutter/material.dart';

// ==========================================
// THEME COLOR PALETTE (Official MFU Red & Gold CI)
// ==========================================
class AppColors {
  // Primary Brand Color (MFU Red / Crimson)
  static const Color primary = Color(0xFF8B1538);

  // Dark Accent / Gradient End (MFU Deep Maroon)
  static const Color darkAccent = Color(0xFF5B0D23);

  // Secondary Accent (MFU Gold)
  static const Color accentGold = Color(0xFFC59B27);

  // Light Accent (Soft Red Tint for Cards, Badges, Info boxes)
  static const Color lightAccent = Color(0xFFFDF2F4);

  // Light Gold Accent (PC Badges, Subtle Warnings)
  static const Color lightGold = Color(0xFFFEF9EE);
  static const Color borderGold = Color(0xFFFDE68A);

  // App Scaffold Background
  static const Color scaffoldBackground = Color(0xFFF8FAFC);

  // Card Background / Pure White
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Border & Divider Color
  static const Color border = Color(0xFFE2E8F0);

  // Text Primary
  static const Color textPrimary = Color(0xFF0F172A);

  // Text Secondary
  static const Color textSecondary = Color(0xFF64748B);
}

void main() {
  runApp(const MfuWorkspaceApp());
}

class MfuWorkspaceApp extends StatelessWidget {
  const MfuWorkspaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MFU Student Workspace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accentGold,
          surface: AppColors.cardBackground,
          surfaceContainerLowest: AppColors.cardBackground,
          surfaceContainerLow: AppColors.scaffoldBackground,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        cardColor: AppColors.cardBackground,
        dividerColor: AppColors.border,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.scaffoldBackground,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.cardBackground,
          indicatorColor: AppColors.lightAccent,
          elevation: 2,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary);
            }
            return const IconThemeData(color: AppColors.textSecondary);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              );
            }
            return const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            );
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIconColor: AppColors.textSecondary,
          suffixIconColor: AppColors.textSecondary,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.cardBackground,
          selectedColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

// ==========================================
// 1. MODELS (MVC - Model Layer)
// ==========================================

class TeamMember {
  final String studentId;
  final String name;
  final String role;

  TeamMember({
    required this.studentId,
    required this.name,
    required this.role,
  });
}

class CommentItem {
  final String authorName;
  final String authorRole;
  final String text;
  final String timeAgo;

  CommentItem({
    required this.authorName,
    required this.authorRole,
    required this.text,
    required this.timeAgo,
  });
}

class TaskItem {
  String id;
  String title;
  String description;
  String assignedTo;
  String dueDate;
  String status;
  String? submissionUrl;
  List<CommentItem> comments;

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.dueDate,
    this.status = 'TODO',
    this.submissionUrl,
    List<CommentItem>? comments,
  }) : comments = comments ?? [];
}

class ProjectModel {
  final String id;
  final String title;
  final String courseCode;
  final String description;
  final String deadline;
  final String myRole;
  final List<TeamMember> members;
  final List<TaskItem> tasks;

  ProjectModel({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.description,
    required this.deadline,
    required this.myRole,
    required this.members,
    required this.tasks,
  });

  bool get isCurrentUserPC => myRole == 'PC';
  int get completedTasks => tasks.where((t) => t.status == 'DONE').length;
  double get progress => tasks.isEmpty ? 0.0 : completedTasks / tasks.length;
}

class AppNotification {
  final String id;
  final String message;
  final String timeAgo;
  bool isRead;

  AppNotification({
    required this.id,
    required this.message,
    required this.timeAgo,
    this.isRead = false,
  });
}

// ==========================================
// 2. MOCK CONTROLLER / STATE (MVC - Controller)
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
      myRole: 'PC',
      members: [
        TeamMember(studentId: '6731501105', name: 'Phoo', role: 'PC'),
        TeamMember(studentId: '6731501101', name: 'Menisa', role: 'Frontend Dev'),
        TeamMember(studentId: '6731501102', name: 'Puttapoom', role: 'Backend Dev'),
        TeamMember(studentId: '6731501108', name: 'Glade', role: 'UI/UX Designer'),
      ],
      tasks: [
        TaskItem(
          id: 't1',
          title: 'Design MySQL Schema & Junction Table',
          description: 'Create users, projects, project_members, and tasks tables.',
          assignedTo: 'Puttapoom',
          dueDate: '2026-11-05',
          status: 'DONE',
          submissionUrl: 'https://github.com/mfu-team/db-schema.sql',
          comments: [
            CommentItem(
              authorName: 'Phoo',
              authorRole: 'PC',
              text: 'Great job! Make sure argon2id hash column is VARCHAR(255).',
              timeAgo: '2h ago',
            ),
          ],
        ),
        TaskItem(
          id: 't2',
          title: 'Build Flutter Auth & Dashboard UI',
          description: 'Implement Lamduan email validation and multi-role cards.',
          assignedTo: 'Menisa',
          dueDate: '2026-11-10',
          status: 'IN_PROGRESS',
          comments: [],
        ),
        TaskItem(
          id: 't3',
          title: 'JWT Role Middleware Setup',
          description: 'Verify project_role from project_members table.',
          assignedTo: 'Phoo',
          dueDate: '2026-11-12',
          status: 'TODO',
          comments: [],
        ),
      ],
    ),
    ProjectModel(
      id: 'p2',
      title: 'Hospital Database System',
      courseCode: '1305202 Database Systems',
      description: 'ER Diagram, Normalization, and SQL Triggers for clinic.',
      deadline: '2026-11-25',
      myRole: 'Backend Developer',
      members: [
        TeamMember(studentId: '6731501102', name: 'Puttapoom', role: 'PC'),
        TeamMember(studentId: '6731501105', name: 'Phoo', role: 'Backend Developer'),
        TeamMember(studentId: '6731501109', name: 'Mary', role: 'Data Analyst'),
      ],
      tasks: [
        TaskItem(
          id: 't201',
          title: 'Write Stored Procedures for Appointments',
          description: 'Create MySQL stored procedures and test with sample data.',
          assignedTo: 'Phoo',
          dueDate: '2026-11-14',
          status: 'IN_PROGRESS',
          comments: [
            CommentItem(
              authorName: 'Puttapoom',
              authorRole: 'PC',
              text: 'Phoo, please upload the .sql link here when finished.',
              timeAgo: '1d ago',
            ),
          ],
        ),
        TaskItem(
          id: 't202',
          title: '3NF Normalization Report',
          description: 'Document all functional dependencies.',
          assignedTo: 'Mary',
          dueDate: '2026-11-12',
          status: 'DONE',
          submissionUrl: 'https://drive.google.com/file/d/3nf-report',
        ),
      ],
    ),
  ];

  static List<AppNotification> notifications = [
    AppNotification(
      id: 'n1',
      message: '📌 Puttapoom (PC) assigned you "Write Stored Procedures" in Hospital DB.',
      timeAgo: '10 mins ago',
      isRead: false,
    ),
    AppNotification(
      id: 'n2',
      message: '✅ Puttapoom submitted work for "Design MySQL Schema".',
      timeAgo: '2 hours ago',
      isRead: false,
    ),
    AppNotification(
      id: 'n3',
      message: '⏰ Reminder: "Build Flutter Auth" is due in 3 days.',
      timeAgo: '1 day ago',
      isRead: true,
    ),
  ];
}

// ==========================================
// PAGE 1: LOGIN & SIGN UP SCREEN (Auth Page)
// ==========================================

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool obscurePassword = true;

  final TextEditingController _studentIdCtrl =
      TextEditingController(text: '6731501105');
  final TextEditingController _nameCtrl =
      TextEditingController(text: 'Nang Hay Man Phoo');
  final TextEditingController _emailCtrl =
      TextEditingController(text: '6731501105@lamduan.mfu.ac.th');
  final TextEditingController _passwordCtrl =
      TextEditingController(text: '••••••••');

  void _handleSubmit() {
    if (!isLogin) {
      if (!_emailCtrl.text.trim().endsWith('@lamduan.mfu.ac.th')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please use your @lamduan.mfu.ac.th email!'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
      WorkspaceStore.currentUserName = _nameCtrl.text.trim();
      WorkspaceStore.currentStudentId = _studentIdCtrl.text.trim();
      WorkspaceStore.currentEmail = _emailCtrl.text.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account Created with Argon2id! Please login.'),
          backgroundColor: AppColors.primary,
        ),
      );
      setState(() => isLogin = true);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.lightAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'MFU Student Workspace',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mae Fah Luang University Collaborative Project Tracker',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // Toggle Tab (Login | Sign Up)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isLogin = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isLogin ? AppColors.cardBackground : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isLogin
                                  ? [
                                      BoxShadow(
                                        color: AppColors.textPrimary.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Login',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isLogin
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isLogin = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !isLogin ? AppColors.cardBackground : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !isLogin
                                  ? [
                                      BoxShadow(
                                        color: AppColors.textPrimary.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !isLogin
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Card
                Card(
                  elevation: 0,
                  color: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (!isLogin) ...[
                          TextField(
                            controller: _nameCtrl,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Real Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextField(
                          controller: _studentIdCtrl,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Student ID (e.g. 6731501105)',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (!isLogin) ...[
                          TextField(
                            controller: _emailCtrl,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Lamduan Gmail',
                              helperText: 'Must end with @lamduan.mfu.ac.th',
                              helperStyle: TextStyle(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: obscurePassword,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => setState(
                                  () => obscurePassword = !obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (!isLogin)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightGold,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderGold),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 18, color: AppColors.accentGold),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No fixed role needed! You become PC when you create a project, or Developer/Designer when invited.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF92400E),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _handleSubmit,
                            child: Text(
                              isLogin ? 'Login' : 'Sign Up',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// MAIN SHELL (Bottom Nav: Dashboard | Noti | Profile)
// ==========================================

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        WorkspaceStore.notifications.where((n) => !n.isRead).length;

    final pages = [
      DashboardScreen(
        onOpenNotifications: () => setState(() => _selectedIndex = 1),
        onRefresh: () => setState(() {}),
      ),
      NotificationsScreen(onRefresh: () => setState(() {})),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              backgroundColor: AppColors.primary,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PAGE 2: MAIN DASHBOARD SCREEN
// ==========================================

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
  void _showCreateProjectSheet() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Group Project',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'You will automatically be assigned as PC (Project Coordinator) for this project.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Project Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: courseCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Course Code & Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deadlineCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Deadline (YYYY-MM-DD)',
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  setState(() {
                    WorkspaceStore.projects.insert(
                      0,
                      ProjectModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleCtrl.text.trim(),
                        courseCode: courseCtrl.text.trim().isEmpty
                            ? 'General Course'
                            : courseCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        deadline: deadlineCtrl.text.trim(),
                        myRole: 'PC',
                        members: [
                          TeamMember(
                            studentId: WorkspaceStore.currentStudentId,
                            name: 'Phoo',
                            role: 'PC',
                          ),
                        ],
                        tasks: [],
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Create Project (Become PC)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTasks =
        WorkspaceStore.projects.expand((p) => p.tasks).toList();
    final todoCount = allTasks.where((t) => t.status == 'TODO').length;
    final inProgressCount =
        allTasks.where((t) => t.status == 'IN_PROGRESS').length;
    final doneCount = allTasks.where((t) => t.status == 'DONE').length;
    final overallPercent =
        allTasks.isEmpty ? 0 : ((doneCount / allTasks.length) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${WorkspaceStore.currentUserName.split(' ').last} 👋',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const Text(
              'ID: 6731501105 • Multi-Role Workspace',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: widget.onOpenNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showCreateProjectSheet,
        icon: const Icon(Icons.add),
        label: const Text('Create Project'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overall Progress Card - MFU Red to Deep Maroon Gradient
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.darkAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Overall Tasks Completed',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$overallPercent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: allTasks.isEmpty ? 0 : doneCount / allTasks.length,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatBox('To Do', todoCount, Colors.white.withOpacity(0.18)),
                    const SizedBox(width: 8),
                    _buildStatBox('In Progress', inProgressCount, AppColors.accentGold.withOpacity(0.35)),
                    const SizedBox(width: 8),
                    _buildStatBox('Done', doneCount, Colors.white.withOpacity(0.25)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'My Group Projects (Role Per Project)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Project Cards
          ...WorkspaceStore.projects.map((project) {
            final isPC = project.isCurrentUserPC;
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              elevation: 0,
              color: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectDetailScreen(project: project),
                    ),
                  );
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            project.courseCode,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPC
                                  ? AppColors.lightGold
                                  : AppColors.lightAccent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isPC
                                    ? AppColors.borderGold
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              isPC
                                  ? '👑 Role: PC'
                                  : '💻 Role: ${project.myRole}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPC
                                    ? const Color(0xFF92400E)
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress: ${project.completedTasks}/${project.tasks.length} Tasks',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Due: ${project.deadline}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: project.progress,
                          minHeight: 6,
                          backgroundColor: AppColors.lightAccent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, int count, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PAGE 3: PROJECT DETAIL SCREEN
// ==========================================

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  String selectedFilter = 'ALL';

  void _showAddMemberDialog() {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedMemberRole = 'Frontend Dev';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Add Member to Group',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Student ID (e.g. 6731501199)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Member Name',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMemberRole,
                decoration: const InputDecoration(labelText: 'Assign Role'),
                items: const [
                  DropdownMenuItem(
                      value: 'Frontend Dev', child: Text('Frontend Dev')),
                  DropdownMenuItem(
                      value: 'Backend Dev', child: Text('Backend Dev')),
                  DropdownMenuItem(
                      value: 'UI/UX Designer', child: Text('UI/UX Designer')),
                  DropdownMenuItem(value: 'Tester', child: Text('Tester')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedMemberRole = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  widget.project.members.add(
                    TeamMember(
                      studentId: idCtrl.text.trim(),
                      name: nameCtrl.text.trim(),
                      role: selectedMemberRole,
                    ),
                  );
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primary,
                    content: Text(
                        'Added ${nameCtrl.text} as $selectedMemberRole & sent notification!'),
                  ),
                );
              },
              child: const Text('Add to Group'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dueCtrl = TextEditingController(text: '2026-11-18');
    String assignedMember = widget.project.members.first.name;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Task (PC Only)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Task Title',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: assignedMember,
              decoration: const InputDecoration(
                labelText: 'Assign To Member',
              ),
              items: widget.project.members
                  .map((m) => DropdownMenuItem(
                        value: m.name,
                        child: Text('${m.name} (${m.role})'),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) assignedMember = val;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dueCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Due Date',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  setState(() {
                    widget.project.tasks.add(
                      TaskItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        assignedTo: assignedMember,
                        dueDate: dueCtrl.text.trim(),
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Save Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPC = widget.project.isCurrentUserPC;
    final filteredTasks = widget.project.tasks.where((t) {
      if (selectedFilter == 'ALL') return true;
      return t.status == selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(widget.project.title),
        actions: [
          if (isPC)
            IconButton(
              tooltip: 'Notify Team',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.primary,
                    content: Text('🔔 Reminder notification sent to all members!'),
                  ),
                );
              },
              icon: const Icon(Icons.campaign_outlined, color: AppColors.primary),
            ),
        ],
      ),
      floatingActionButton: isPC
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _showAddTaskModal,
              icon: const Icon(Icons.add_task),
              label: const Text('Add Task'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Project Header Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.project.description,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deadline: ${widget.project.deadline}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.lightAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Your Role: ${widget.project.myRole}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Team Members Horizontal Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team Members (${widget.project.members.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isPC)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                  onPressed: _showAddMemberDialog,
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('+ Add Member'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.project.members.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                final m = widget.project.members[i];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.lightAccent,
                        foregroundColor: AppColors.primary,
                        child: Text(
                          m.name[0],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            m.role,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Task Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['ALL', 'TODO', 'IN_PROGRESS', 'DONE'].map((filter) {
                final active = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.replaceAll('_', ' ')),
                    selected: active,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.cardBackground,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: active ? AppColors.primary : AppColors.border,
                    ),
                    onSelected: (_) => setState(() => selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Task List Cards
          ...filteredTasks.map((task) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              color: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
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
                title: Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Assigned to: ${task.assignedTo} • Due: ${task.dueDate}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: _buildStatusChip(task.status),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = AppColors.textSecondary;
    if (status == 'IN_PROGRESS') {
      bg = AppColors.lightGold;
      fg = const Color(0xFF92400E);
    } else if (status == 'DONE') {
      bg = AppColors.lightAccent;
      fg = AppColors.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

// ==========================================
// PAGE 4: TASK DETAIL & SUBMISSION SCREEN
// ==========================================

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

  @override
  void initState() {
    super.initState();
    _uploadUrlCtrl =
        TextEditingController(text: widget.task.submissionUrl ?? '');
  }

  void _editTaskModal() {
    final titleCtrl = TextEditingController(text: widget.task.title);
    final descCtrl = TextEditingController(text: widget.task.description);
    final dueCtrl = TextEditingController(text: widget.task.dueDate);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Task (PC Only)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dueCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Due Date'),
            ),
          ],
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
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                widget.task.title = titleCtrl.text.trim();
                widget.task.description = descCtrl.text.trim();
                widget.task.dueDate = dueCtrl.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTask() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Task?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this task from DB?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              widget.project.tasks.remove(widget.task);
              Navigator.pop(ctx);
              Navigator.pop(context);
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

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (isPC) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editTaskModal,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              onPressed: _confirmDeleteTask,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Task Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.task.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.task.description,
                        style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Assigned to: ${widget.task.assignedTo}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Due: ${widget.task.dueDate}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.border),
                      // Status Dropdown
                      DropdownButtonFormField<String>(
                        value: widget.task.status,
                        decoration: const InputDecoration(
                          labelText: 'Update Task Status',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'TODO', child: Text('TO DO')),
                          DropdownMenuItem(
                              value: 'IN_PROGRESS', child: Text('IN PROGRESS')),
                          DropdownMenuItem(value: 'DONE', child: Text('DONE')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => widget.task.status = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Submission / Upload Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightAccent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPC
                            ? '📦 Member Submitted Work (PC View)'
                            : '📤 Submit Your Work (${widget.project.myRole})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!isPC) ...[
                        TextField(
                          controller: _uploadUrlCtrl,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Paste GitHub / Google Drive link...',
                            filled: true,
                            fillColor: AppColors.cardBackground,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                widget.task.submissionUrl =
                                    _uploadUrlCtrl.text.trim();
                                widget.task.status = 'DONE';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.primary,
                                  content: Text(
                                      'Work uploaded! Status set to DONE & PC notified.'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Task'),
                          ),
                        ),
                      ] else ...[
                        Text(
                          widget.task.submissionUrl == null ||
                                  widget.task.submissionUrl!.isEmpty
                              ? 'No submission yet from ${widget.task.assignedTo}.'
                              : 'Link: ${widget.task.submissionUrl}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Comments Section
                const Text(
                  'Comments & Discussion',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                ...widget.task.comments.map((c) => Card(
                      elevation: 0,
                      color: AppColors.cardBackground,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.lightAccent,
                          foregroundColor: AppColors.primary,
                          child: Text(
                            c.authorName[0],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              c.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.lightAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.authorRole,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              c.timeAgo,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            c.text,
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                    )),
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
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      isDense: true,
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
                    if (_commentCtrl.text.trim().isEmpty) return;
                    setState(() {
                      widget.task.comments.add(
                        CommentItem(
                          authorName: 'Phoo',
                          authorRole: widget.project.myRole,
                          text: _commentCtrl.text.trim(),
                          timeAgo: 'Just now',
                        ),
                      );
                      _commentCtrl.clear();
                    });
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PAGE 5: NOTIFICATIONS SCREEN
// ==========================================

class NotificationsScreen extends StatelessWidget {
  final VoidCallback onRefresh;

  const NotificationsScreen({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            onPressed: () {
              for (var n in WorkspaceStore.notifications) {
                n.isRead = true;
              }
              onRefresh();
            },
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: WorkspaceStore.notifications.length,
        itemBuilder: (ctx, i) {
          final n = WorkspaceStore.notifications[i];
          return Card(
            elevation: 0,
            color: n.isRead ? AppColors.cardBackground : AppColors.lightAccent,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: n.isRead
                    ? AppColors.border
                    : AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: ListTile(
              onTap: () {
                n.isRead = true;
                onRefresh();
              },
              leading: Icon(
                n.isRead
                    ? Icons.notifications_none
                    : Icons.notifications_active,
                color: n.isRead ? AppColors.textSecondary : AppColors.primary,
              ),
              title: Text(
                n.message,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
                ),
              ),
              subtitle: Text(
                n.timeAgo,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// PAGE 6: USER PROFILE SCREEN
// ==========================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: WorkspaceStore.currentUserName);
    _emailCtrl = TextEditingController(text: WorkspaceStore.currentEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary,
              child: Text(
                'P',
                style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              WorkspaceStore.currentUserName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              'Student ID: ${WorkspaceStore.currentStudentId}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Full Name',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _emailCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Lamduan Email',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                WorkspaceStore.currentUserName = _nameCtrl.text.trim();
                WorkspaceStore.currentEmail = _emailCtrl.text.trim();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.primary,
                  content: Text('Profile updated successfully!'),
                ),
              );
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Changes'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}