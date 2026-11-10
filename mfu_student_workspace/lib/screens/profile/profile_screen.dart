import 'package:flutter/material.dart';
import '../../models/api_models.dart';
import '../../controller/api_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../data/workspace_store.dart';
import '../auth/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;

  final _userController = UserController();
  final _projectController = ProjectController();
  final _authController = AuthController();

  bool _loading = true; // กำลังโหลดโปรไฟล์จาก server
  bool _saving = false; // กำลังบันทึก
  int? _projectCount; // จำนวนโปรเจคจาก API (null = ยังไม่โหลด)

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: WorkspaceStore.currentUserName);
    _emailCtrl = TextEditingController(text: WorkspaceStore.currentEmail);
    _loadProfile();
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? AppColors.danger : AppColors.primary,
          content: Text(text),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// token หมดอายุ / ไม่ถูกต้อง -> กลับหน้า login
  void _goToLogin() {
    WorkspaceStore.currentStudentId = '';
    WorkspaceStore.currentUserName = '';
    WorkspaceStore.currentEmail = '';
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  Future<void> _loadProfile() async {
    try {
      final me = await _userController.getMe();
      final projects = await _projectController.getProjects();
      if (!mounted) return;
      setState(() {
        WorkspaceStore.currentStudentId = me.studentId;
        WorkspaceStore.currentUserName = me.fullName;
        WorkspaceStore.currentEmail = me.email;
        _nameCtrl.text = me.fullName;
        _emailCtrl.text = me.email;
        _projectCount = projects.length;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _goToLogin();
      } else {
        _showMessage(e.message, isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameCtrl.text.trim();
    if (newName == WorkspaceStore.currentUserName) {
      _showMessage('No changes to save.');
      return;
    }

    setState(() => _saving = true);
    try {
      // backend รองรับเฉพาะ fullName / avatarUrl / รหัสผ่าน (ยังแก้ email ไม่ได้)
      await _userController.updateMe(fullName: newName);
      if (!mounted) return;
      setState(() => WorkspaceStore.currentUserName = newName);
      _showMessage('Profile details updated successfully!');
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _goToLogin();
      } else {
        _showMessage(e.message, isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
            onPressed: () async {
              Navigator.pop(ctx);
              // logout() ลบ token ในเครื่องเสมอ แม้ server จะไม่ตอบ
              await _authController.logout();
              if (!mounted) return;
              _goToLogin();
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
    final myTasks = allTasks.where((t) => t.assignedStudentId == WorkspaceStore.currentStudentId).toList();
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
                    _buildProfileStat('Projects', '${_projectCount ?? WorkspaceStore.projects.length}'),
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
                readOnly: true, // backend ยังไม่รองรับการแก้ email
                decoration: const InputDecoration(
                  labelText: 'Lamduan Mail',
                  helperText: 'Email cannot be changed',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: (_saving || _loading) ? null : _saveProfile,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_saving ? 'Saving...' : 'Save Changes'),
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