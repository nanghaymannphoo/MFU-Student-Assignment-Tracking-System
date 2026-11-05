import 'package:flutter/material.dart';

// ==========================================
// OFFICIAL MFU THEME COLOR PALETTE & DESIGN SYSTEM
// ==========================================
class AppColors {
  // Primary Brand Color (MFU Red)
  static const Color primary = Color(0xFF8B1538);

  // Dark Accent / Gradient End (MFU Deep Maroon)
  static const Color darkAccent = Color(0xFF5B0D23);

  // Secondary Accent (MFU Gold)
  static const Color gold = Color(0xFFC59B27);

  // Light Accent (Soft Red Tint)
  static const Color lightAccent = Color(0xFFFDF2F4);

  // Light Gold Accent
  static const Color lightGold = Color(0xFFFEF9EE);

  // Scaffold Background
  static const Color scaffoldBackground = Color(0xFFF8FAFC);

  // Card Background
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Border Color
  static const Color border = Color(0xFFE2E8F0);

  // Text Primary
  static const Color textPrimary = Color(0xFF0F172A);

  // Text Secondary
  static const Color textSecondary = Color(0xFF64748B);

  // Semantic Status Colors (Calibrated for High Contrast)
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEE2E2);
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
          secondary: AppColors.gold,
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.primary),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.cardBackground,
          indicatorColor: AppColors.lightAccent,
          elevation: 3,
          height: 68,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary, size: 26);
            }
            return const IconThemeData(color: AppColors.textSecondary, size: 24);
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.danger, width: 2),
          ),
          labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          secondaryLabelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

// ==========================================
// STATUS HELPERS & DATE PICKER UTILITIES
// ==========================================

String formatStatus(String status) {
  switch (status.toUpperCase()) {
    case 'DONE':
      return 'Completed';
    case 'IN_PROGRESS':
      return 'In Progress';
    case 'TODO':
    default:
      return 'To Do';
  }
}

IconData getStatusIcon(String status) {
  switch (status.toUpperCase()) {
    case 'DONE':
      return Icons.check_circle_rounded;
    case 'IN_PROGRESS':
      return Icons.hourglass_top_rounded;
    case 'TODO':
    default:
      return Icons.radio_button_unchecked_rounded;
  }
}

Future<void> selectAppDate(BuildContext context, TextEditingController controller) async {
  DateTime initialDate = DateTime.tryParse(controller.text) ?? DateTime.now().add(const Duration(days: 7));
  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime.now().subtract(const Duration(days: 30)),
    lastDate: DateTime.now().add(const Duration(days: 365)),
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
  if (picked != null) {
    controller.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
  }
}

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.lightAccent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 42),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// 1. MODELS (MVC - Model Layer)
// ==========================================

class TeamMember {
  final String studentId;
  final String name;
  final String role; // 'PC', 'Backend Dev', 'Frontend Dev', 'UI/UX', etc.

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
  String status; // 'TODO', 'IN_PROGRESS', 'DONE'
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
  final String myRole; // Phoo's role in THIS specific project ('PC' or other)
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
  final String? title;
  final String message;
  final String timeAgo;
  bool isRead;

  AppNotification({
    required this.id,
    this.title,
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
      myRole: 'PC', // Phoo is PC in this project!
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
      myRole: 'Backend Developer', // Phoo is Developer in this project!
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
      title: 'Task Assigned',
      message: '📌 Puttapoom (PC) assigned you "Write Stored Procedures" in Hospital DB.',
      timeAgo: '10 mins ago',
      isRead: false,
    ),
    AppNotification(
      id: 'n2',
      title: 'Work Submitted',
      message: '✅ Puttapoom submitted work for "Design MySQL Schema".',
      timeAgo: '2 hours ago',
      isRead: false,
    ),
    AppNotification(
      id: 'n3',
      title: 'Due Date Alert',
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
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  bool obscurePassword = true;

  final TextEditingController _studentIdCtrl =
      TextEditingController(text: '6731501105');
  final TextEditingController _nameCtrl =
      TextEditingController(text: 'Nang Hay Man Phoo');
  final TextEditingController _emailCtrl =
      TextEditingController(text: '6731501105@lamduan.mfu.ac.th');
  final TextEditingController _passwordCtrl =
      TextEditingController(text: '123456');

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!isLogin) {
      WorkspaceStore.currentUserName = _nameCtrl.text.trim();
      WorkspaceStore.currentStudentId = _studentIdCtrl.text.trim();
      WorkspaceStore.currentEmail = _emailCtrl.text.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! You can now log in.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => isLogin = true);
      return;
    }

    // Login -> Navigate to Main Shell (Page 2, 5, 6)
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Crest / Logo
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: AppColors.lightAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 46,
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Mae Fah Luang University Academic Project Tracker',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
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
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              if (!isLogin) {
                                setState(() => isLogin = true);
                                _formKey.currentState?.reset();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isLogin ? AppColors.cardBackground : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isLogin
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Log In',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isLogin ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              if (isLogin) {
                                setState(() => isLogin = false);
                                _formKey.currentState?.reset();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isLogin ? AppColors.cardBackground : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: !isLogin
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.08),
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
                                  color: !isLogin ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form Input Card
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isLogin) ...[
                            TextFormField(
                              controller: _nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'e.g. Somchai Suksan',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().length < 2) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextFormField(
                            controller: _studentIdCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Student ID',
                              hintText: '10-digit ID (e.g. 6731501105)',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your student ID';
                              }
                              if (val.trim().length != 10 || int.tryParse(val.trim()) == null) {
                                return 'Student ID must be exactly 10 digits';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          if (!isLogin) ...[
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Lamduan Mail (@lamduan.mfu.ac.th)',
                                hintText: '6731501105@lamduan.mfu.ac.th',
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter your Lamduan email';
                                }
                                if (!val.trim().toLowerCase().endsWith('@lamduan.mfu.ac.th')) {
                                  return 'Must end with @lamduan.mfu.ac.th';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: obscurePassword,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: isLogin ? 'Enter password' : 'At least 6 characters',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                tooltip: obscurePassword ? 'Show password' : 'Hide password',
                                onPressed: () => setState(() => obscurePassword = !obscurePassword),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your password';
                              }
                              if (!isLogin && val.trim().length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          if (!isLogin)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.lightGold,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                              ),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 20, color: AppColors.gold),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Dynamic project roles: Creating a project designates you as Coordinator (PC). You can also participate as a Developer or Designer in other teams.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textPrimary,
                                        height: 1.35,
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
                              onPressed: _handleSubmit,
                              child: Text(isLogin ? 'Log In to Workspace' : 'Create Account'),
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
    final unreadCount = WorkspaceStore.notifications.where((n) => !n.isRead).length;

    // Use IndexedStack to preserve scroll states & performance across bottom navigation
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(
            onOpenNotifications: () => setState(() => _selectedIndex = 1),
            onRefresh: () => setState(() {}),
          ),
          NotificationsScreen(
            onRefresh: () => setState(() {}),
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
            tooltip: 'View your projects & tasks',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              backgroundColor: AppColors.primary,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              backgroundColor: AppColors.primary,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_rounded),
            ),
            label: 'Notifications',
            tooltip: 'View announcements & updates',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
            tooltip: 'Account details and preferences',
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
                    fontSize: 19,
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
                  height: 48,
                  child: FilledButton.icon(
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
                            myRole: 'PC', // Creator becomes PC automatically
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
                    icon: const Icon(Icons.add_task_rounded, size: 18),
                    label: const Text('Create Project (Become PC)'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = WorkspaceStore.projects.expand((p) => p.tasks).toList();
    final todoCount = allTasks.where((t) => t.status == 'TODO').length;
    final inProgressCount = allTasks.where((t) => t.status == 'IN_PROGRESS').length;
    final doneCount = allTasks.where((t) => t.status == 'DONE').length;
    final overallPercent = allTasks.isEmpty ? 0 : ((doneCount / allTasks.length) * 100).round();

    // Collect upcoming incomplete tasks across all projects for easy visibility
    final List<Map<String, dynamic>> upcomingTasks = [];
    for (var project in WorkspaceStore.projects) {
      for (var task in project.tasks) {
        if (task.status != 'DONE') {
          upcomingTasks.add({
            'project': project,
            'task': task,
          });
        }
      }
    }
    // Sort by due date string
    upcomingTasks.sort((a, b) => (a['task'] as TaskItem).dueDate.compareTo((b['task'] as TaskItem).dueDate));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${WorkspaceStore.currentUserName.split(' ').first} 👋',
              style: const TextStyle(
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
            tooltip: 'Open Notifications',
            onPressed: widget.onOpenNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showCreateProjectSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Project'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Overall Progress Hero Card - MFU Maroon Gradient
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
                  color: AppColors.primary.withOpacity(0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
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
                      'Overall Workload Progress',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$overallPercent% Completed',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: allTasks.isEmpty ? 0 : doneCount / allTasks.length,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.22),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatBox('To Do', todoCount, Colors.white.withOpacity(0.16), Icons.radio_button_unchecked),
                    const SizedBox(width: 8),
                    _buildStatBox('In Progress', inProgressCount, AppColors.gold.withOpacity(0.35), Icons.hourglass_top),
                    const SizedBox(width: 8),
                    _buildStatBox('Completed', doneCount, Colors.white.withOpacity(0.25), Icons.check_circle_outline),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 2. Upcoming Deadlines Section (Prioritized info for students)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.alarm_rounded, size: 20, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'Upcoming Deadlines',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${upcomingTasks.length} pending',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (upcomingTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.done_all_rounded, color: AppColors.gold, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No pending deadlines! All your assigned tasks are completed.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 114,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: upcomingTasks.length > 5 ? 5 : upcomingTasks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final item = upcomingTasks[i];
                  final ProjectModel project = item['project'];
                  final TaskItem task = item['task'];

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
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
                    child: Container(
                      width: 250,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  project.courseCode,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.lightAccent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 10, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.dueDate,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                task.assignedTo,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const Spacer(),
                              Text(
                                formatStatus(task.status),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: task.status == 'IN_PROGRESS' ? AppColors.gold : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 22),

          // 3. Current Group Projects
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Group Projects',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${WorkspaceStore.projects.length} Active',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (WorkspaceStore.projects.isEmpty)
            EmptyStateCard(
              icon: Icons.folder_open_rounded,
              title: 'No Projects Yet',
              message: 'You have not joined or created any workspace projects. Create one as Project Coordinator!',
              actionLabel: 'Create Project',
              onAction: _showCreateProjectSheet,
            )
          else
            ...WorkspaceStore.projects.map((project) {
              final isPC = project.isCurrentUserPC;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
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
                    widget.onRefresh();
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPC ? AppColors.lightGold : AppColors.lightAccent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isPC ? AppColors.gold.withOpacity(0.4) : AppColors.primary.withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                isPC ? '👑 Coordinator (PC)' : '💻 ${project.myRole}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isPC ? AppColors.gold : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          project.title,
                          style: const TextStyle(
                            fontSize: 16,
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
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.event_outlined, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Due: ${project.deadline}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: project.progress,
                            minHeight: 6,
                            backgroundColor: AppColors.lightAccent,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, int count, Color bg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
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
  String selectedFilter = 'ALL'; // ALL, TODO, IN_PROGRESS, DONE

  void _showAddMemberDialog() {
    final formKey = GlobalKey<FormState>();
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedMemberRole = 'Frontend Dev';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Add Team Member',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: idCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Student ID *',
                    hintText: 'e.g. 6731501199',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter student ID';
                    if (v.trim().length != 10) return 'Must be 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Member Name *',
                    hintText: 'e.g. Somchai',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter member name' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMemberRole,
                  decoration: const InputDecoration(labelText: 'Assign Role'),
                  items: const [
                    DropdownMenuItem(value: 'Frontend Dev', child: Text('Frontend Dev')),
                    DropdownMenuItem(value: 'Backend Dev', child: Text('Backend Dev')),
                    DropdownMenuItem(value: 'UI/UX Designer', child: Text('UI/UX Designer')),
                    DropdownMenuItem(value: 'Tester / QA', child: Text('Tester / QA')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedMemberRole = val);
                  },
                ),
              ],
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
                minimumSize: const Size(110, 40),
              ),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
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
                    content: Text('Added ${nameCtrl.text.trim()} as $selectedMemberRole!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskModal() {
    final formKey = GlobalKey<FormState>();
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
                  'Add New Task',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Assign milestones or requirements to a team member.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Task Title *',
                    hintText: 'e.g. Implement API Endpoint',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a task title' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Details, deliverables, or acceptance criteria...',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: assignedMember,
                  decoration: const InputDecoration(
                    labelText: 'Assign to Member',
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
                TextFormField(
                  controller: dueCtrl,
                  readOnly: true,
                  onTap: () => selectAppDate(ctx, dueCtrl),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Due Date *',
                    suffixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please select a due date' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      setState(() {
                        widget.project.tasks.add(
                          TaskItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim().isEmpty ? 'No description' : descCtrl.text.trim(),
                            assignedTo: assignedMember,
                            dueDate: dueCtrl.text.trim(),
                          ),
                        );
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Task added to project!'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Save Task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPC = widget.project.isCurrentUserPC;
    final totalTasks = widget.project.tasks.length;
    final doneCount = widget.project.tasks.where((t) => t.status == 'DONE').length;
    final inProgressCount = widget.project.tasks.where((t) => t.status == 'IN_PROGRESS').length;
    final todoCount = widget.project.tasks.where((t) => t.status == 'TODO').length;
    final overallPercent = totalTasks == 0 ? 0 : ((doneCount / totalTasks) * 100).round();

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
              tooltip: 'Notify All Members',
              onPressed: () {
                WorkspaceStore.notifications.insert(
                  0,
                  AppNotification(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: 'Team Reminder: ${widget.project.title}',
                    message: '🔔 Coordinator sent a reminder regarding upcoming deadlines.',
                    timeAgo: 'Just now',
                    isRead: false,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.primary,
                    content: Text('Reminder notification broadcasted to all team members!'),
                    behavior: SnackBarBehavior.floating,
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
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Add Task'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPC ? AppColors.lightGold : AppColors.lightAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Your Role: ${widget.project.myRole}',
                        style: TextStyle(
                          color: isPC ? AppColors.gold : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.project.description,
                  style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Deadline: ${widget.project.deadline}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$doneCount/$totalTasks Tasks Done',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // TEAM PROGRESS & MEMBER BREAKDOWN (PC View Only)
          if (isPC) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.insights_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Team Progress Overview',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.lightGold,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gold.withOpacity(0.4)),
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
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: widget.project.progress,
                      minHeight: 8,
                      backgroundColor: AppColors.lightAccent,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildStatPill('Done', doneCount, AppColors.lightAccent, AppColors.primary),
                      const SizedBox(width: 8),
                      _buildStatPill('In Progress', inProgressCount, AppColors.lightGold, AppColors.gold),
                      const SizedBox(width: 8),
                      _buildStatPill('To Do', todoCount, const Color(0xFFF1F5F9), AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Per-Member Workload Breakdown Header
            const Text(
              'Member Task Breakdown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Individual Member Cards with Avatar, Progress Bar, & Status Counters
            ...widget.project.members.map((member) {
              final memberTasks = widget.project.tasks
                  .where((t) => t.assignedTo.trim().toLowerCase() == member.name.trim().toLowerCase())
                  .toList();
              final mDone = memberTasks.where((t) => t.status == 'DONE').length;
              final mInProgress = memberTasks.where((t) => t.status == 'IN_PROGRESS').length;
              final mTodo = memberTasks.where((t) => t.status == 'TODO').length;
              final mTotal = memberTasks.length;
              final mPercent = mTotal == 0 ? 0 : ((mDone / mTotal) * 100).round();
              final mRatio = mTotal == 0 ? 0.0 : mDone / mTotal;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.lightAccent,
                          foregroundColor: AppColors.primary,
                          child: Text(
                            member.name.isNotEmpty ? member.name[0] : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    member.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (member.role == 'PC') ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightGold,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                                      ),
                                      child: const Text(
                                        '👑 PC',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                member.role,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$mDone/$mTotal Tasks ($mPercent%)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
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
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMiniStatusChip('Completed', mDone, AppColors.lightAccent, AppColors.primary),
                        const SizedBox(width: 6),
                        _buildMiniStatusChip('In Progress', mInProgress, AppColors.lightGold, AppColors.gold),
                        const SizedBox(width: 6),
                        _buildMiniStatusChip('To Do', mTodo, const Color(0xFFF1F5F9), AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],

          // Team Members Horizontal Quick Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team Members (${widget.project.members.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
              if (isPC)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  onPressed: _showAddMemberDialog,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('+ Add Member'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.project.members.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final m = widget.project.members[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.lightAccent,
                        foregroundColor: AppColors.primary,
                        child: Text(m.name[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                          ),
                          Text(
                            m.role,
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Task Filter Tabs
          Row(
            children: [
              const Text(
                'Tasks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Spacer(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChoice('ALL', 'All'),
                    _buildFilterChoice('TODO', 'To Do'),
                    _buildFilterChoice('IN_PROGRESS', 'In Progress'),
                    _buildFilterChoice('DONE', 'Completed'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Task List Cards or Clean Empty State
          if (filteredTasks.isEmpty)
            EmptyStateCard(
              icon: Icons.assignment_outlined,
              title: selectedFilter == 'ALL' ? 'No Tasks in this Project' : 'No Tasks in ${formatStatus(selectedFilter)}',
              message: isPC
                  ? 'Get started by creating actionable milestones for your team.'
                  : 'Check back later or ask your Coordinator to assign requirements.',
              actionLabel: isPC ? 'Add First Task' : null,
              onAction: isPC ? _showAddTaskModal : null,
            )
          else
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          task.assignedTo,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          task.dueDate,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  trailing: _buildStatusChip(task.status),
                ),
              );
            }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFilterChoice(String key, String label) {
    final active = selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.cardBackground,
        labelStyle: TextStyle(
          color: active ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        side: BorderSide(
          color: active ? AppColors.primary : AppColors.border,
        ),
        onSelected: (_) => setState(() => selectedFilter = key),
      ),
    );
  }

  Widget _buildStatPill(String label, int count, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatusChip(String label, int count, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 10,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  void _editTaskModal() {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: widget.task.title);
    final descCtrl = TextEditingController(text: widget.task.description);
    final dueCtrl = TextEditingController(text: widget.task.dueDate);

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
              setState(() {
                widget.task.title = titleCtrl.text.trim();
                widget.task.description = descCtrl.text.trim();
                widget.task.dueDate = dueCtrl.text.trim();
              });
              Navigator.pop(ctx);
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Task?',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.35),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task deleted.'),
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

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (isPC) ...[
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
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          _buildStatusBadge(widget.task.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.task.description.isEmpty ? 'No description provided.' : widget.task.description,
                        style: const TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.scaffoldBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_pin_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Assigned To', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                Text(
                                  widget.task.assignedTo,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.event_available_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Due Date', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                Text(
                                  widget.task.dueDate,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 24, color: AppColors.border),

                      // Status Dropdown selector
                      DropdownButtonFormField<String>(
                        value: widget.task.status,
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
                            setState(() => widget.task.status = val);
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
                    border: Border.all(color: AppColors.primary.withOpacity(0.25)),
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
                                      widget.task.status = 'DONE';
                                    });
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
                                    'No deliverable submitted yet from ${widget.task.assignedTo}.',
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
                              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
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
                                      c.authorRole,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.gold),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    c.timeAgo,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
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

          // Add Comment Input Bar (With comfortable touch targets and padding)
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
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Add a comment or question...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                            authorName: WorkspaceStore.currentUserName.split(' ').first,
                            authorRole: widget.project.myRole,
                            text: _commentCtrl.text.trim(),
                            timeAgo: 'Just now',
                          ),
                        );
                        _commentCtrl.clear();
                      });
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

// ==========================================
// PAGE 5: NOTIFICATIONS SCREEN
// ==========================================

class NotificationsScreen extends StatefulWidget {
  final VoidCallback onRefresh;

  const NotificationsScreen({super.key, required this.onRefresh});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  void _showNotifyMembersBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    String targetOption = 'All members'; // 'All members' or 'Selected members'

    final List<String> memberNames = WorkspaceStore.projects
        .expand((p) => p.members)
        .map((m) => m.name)
        .toSet()
        .toList();
    if (memberNames.isEmpty) {
      memberNames.addAll(['Menisa', 'Puttapoom', 'Glade', 'Mary', 'Phoo']);
    }
    String selectedMember = memberNames.first;

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.lightAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.campaign_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send Member Notification',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Broadcast announcements or task alerts',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: titleCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Notification Subject *',
                      hintText: 'e.g. Sprint Review Due Today',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a subject' : null,
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Target Audience:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['All members', 'Selected members'].map((option) {
                      final isSelected = targetOption == option;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(option),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.cardBackground,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                          onSelected: (_) {
                            setSheetState(() => targetOption = option);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  if (targetOption == 'Selected members') ...[
                    DropdownButtonFormField<String>(
                      value: selectedMember,
                      decoration: const InputDecoration(
                        labelText: 'Select Recipient Member',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: memberNames
                          .map((name) => DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedMember = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  TextFormField(
                    controller: messageCtrl,
                    minLines: 3,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Message Body *',
                      hintText: 'Details, reminders, or questions for team members...',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter message details' : null,
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final recipientLabel = targetOption == 'All members' ? 'All Members' : selectedMember;

                        setState(() {
                          WorkspaceStore.notifications.insert(
                            0,
                            AppNotification(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              title: titleCtrl.text.trim(),
                              message: '📢 [$recipientLabel] ${messageCtrl.text.trim()}',
                              timeAgo: 'Just now',
                              isRead: false,
                            ),
                          );
                        });
                        widget.onRefresh();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.primary,
                            content: Text('Notification sent to $recipientLabel!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send Notification'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (WorkspaceStore.notifications.any((n) => !n.isRead))
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              onPressed: () {
                for (var n in WorkspaceStore.notifications) {
                  n.isRead = true;
                }
                setState(() {});
                widget.onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read.'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Action Button to Notify Members
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _showNotifyMembersBottomSheet,
              icon: const Icon(Icons.campaign_rounded, size: 20),
              label: const Text('Notify Members'),
            ),
          ),

          if (WorkspaceStore.notifications.isEmpty)
            const EmptyStateCard(
              icon: Icons.notifications_off_outlined,
              title: 'No Notifications',
              message: 'You are all caught up! New project updates and task alerts will appear here.',
            )
          else
            ...WorkspaceStore.notifications.map((n) {
              return Card(
                elevation: 0,
                color: n.isRead ? AppColors.cardBackground : AppColors.lightAccent,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: n.isRead ? AppColors.border : AppColors.primary.withOpacity(0.35),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  onTap: () {
                    setState(() => n.isRead = true);
                    widget.onRefresh();
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: n.isRead ? AppColors.scaffoldBackground : AppColors.cardBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      n.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                      color: n.isRead ? AppColors.textSecondary : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title ?? 'Workspace Notification',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: n.isRead ? AppColors.textPrimary : AppColors.primary,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.message,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              n.timeAgo,
                              style: TextStyle(
                                fontSize: 11,
                                color: n.isRead ? AppColors.textSecondary : AppColors.primary,
                                fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: WorkspaceStore.currentUserName);
    _emailCtrl = TextEditingController(text: WorkspaceStore.currentEmail);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      WorkspaceStore.currentUserName = _nameCtrl.text.trim();
      WorkspaceStore.currentEmail = _emailCtrl.text.trim();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('Profile details updated successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to log out of your workspace?',
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
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Quick calculation of tasks assigned to this user
    final allTasks = WorkspaceStore.projects.expand((p) => p.tasks).toList();
    final myTasks = allTasks.where((t) => t.assignedTo.toLowerCase() == 'phoo').toList();
    final myDone = myTasks.where((t) => t.status == 'DONE').length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    WorkspaceStore.currentUserName.isNotEmpty ? WorkspaceStore.currentUserName[0] : 'P',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                WorkspaceStore.currentUserName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Student ID: ${WorkspaceStore.currentStudentId}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Student Overview Badges
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _buildProfileStat('Projects', '${WorkspaceStore.projects.length}'),
                    const SizedBox(
                      height: 32,
                      child: VerticalDivider(color: AppColors.border),
                    ),
                    _buildProfileStat('My Tasks', '${myTasks.length}'),
                    const SizedBox(
                      height: 32,
                      child: VerticalDivider(color: AppColors.border),
                    ),
                    _buildProfileStat('Completed', '$myDone'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Edit Form Fields
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Lamduan Mail *',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter your email';
                  if (!v.trim().toLowerCase().endsWith('@lamduan.mfu.ac.th')) {
                    return 'Must end with @lamduan.mfu.ac.th';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                  ),
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Log Out'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
