import 'package:flutter/material.dart';

import '../../controller/api_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../data/workspace_store.dart';
import '../../navigation/main_navigation_shell.dart';
import '../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _authController = AuthController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: isError ? AppColors.danger : AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _handleSubmit() async {
    if (_loading || !_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      if (_isLogin) {
        final user = await _authController.login(
          _studentIdCtrl.text.trim(),
          _passwordCtrl.text,
        );
        if (!mounted) return;
        if (user == null) {
          _showMessage('Student ID or password is incorrect.', isError: true);
          return;
        }

        WorkspaceStore.currentStudentId = user.studentId;
        WorkspaceStore.currentUserName = user.fullName;
        WorkspaceStore.currentEmail = user.email;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationShell()),
        );
      } else {
        if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
          _showMessage(
            'Passwords do not match. Please verify your password.',
            isError: true,
          );
          return;
        }
        await _authController.register(
          studentId: _studentIdCtrl.text.trim(),
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
        if (!mounted) return;
        _showMessage('Account created successfully! You can now log in.');
        _passwordCtrl.clear();
        _confirmPasswordCtrl.clear();
        setState(() => _isLogin = true);
      }
    } on ApiException catch (e) {
      _showMessage(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    bool confirmPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: obscureText ? 'Show password' : 'Hide password',
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return confirmPassword
              ? 'Please confirm your password'
              : 'Please enter your password';
        }
        if (!_isLogin && !confirmPassword && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        if (confirmPassword && value != _passwordCtrl.text) {
          return 'Passwords do not match';
        }
        return null;
      },
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.lightAccent,
                      child: Icon(
                        Icons.school_rounded,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'MFU Student Workspace',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Mae Fah Luang University Academic Project Tracker',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Log In')),
                        ButtonSegment(value: false, label: Text('Sign Up')),
                      ],
                      selected: {_isLogin},
                      onSelectionChanged: _loading
                          ? null
                          : (selection) =>
                                setState(() => _isLogin = selection.first),
                    ),
                    const SizedBox(height: 20),
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
                            if (!_isLogin) ...[
                              TextFormField(
                                controller: _nameCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().length < 2
                                    ? 'Please enter your full name'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextFormField(
                              controller: _studentIdCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Student ID',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (value) {
                                final id = value?.trim() ?? '';
                                if (id.isEmpty)
                                  return 'Please enter your student ID';
                                if (id.length != 10 ||
                                    int.tryParse(id) == null) {
                                  return 'Student ID must be exactly 10 digits';
                                }
                                return null;
                              },
                            ),
                            if (!_isLogin) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Lamduan Mail (@lamduan.mfu.ac.th)',
                                  prefixIcon: Icon(Icons.alternate_email),
                                ),
                                validator: (value) {
                                  final email =
                                      value?.trim().toLowerCase() ?? '';
                                  if (email.isEmpty)
                                    return 'Please enter your Lamduan email';
                                  if (!email.endsWith('@lamduan.mfu.ac.th')) {
                                    return 'Must end with @lamduan.mfu.ac.th';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 14),
                            _buildPasswordField(
                              label: 'Password',
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              onToggleVisibility: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            if (!_isLogin) ...[
                              const SizedBox(height: 14),
                              _buildPasswordField(
                                label: 'Confirm Password',
                                controller: _confirmPasswordCtrl,
                                obscureText: _obscureConfirmPassword,
                                onToggleVisibility: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                                confirmPassword: true,
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: _loading ? null : _handleSubmit,
                                child: _loading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isLogin
                                            ? 'Log In to Workspace'
                                            : 'Create Account',
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
        ),
      ),
    );
  }
}

/// หน้าแรกของแอป: เช็ค token ที่บันทึกไว้ก่อนตัดสินใจว่าจะไปหน้าไหน
///   - ไม่มี token / token หมดอายุ (401)  -> AuthScreen
///   - token ใช้ได้                        -> MainNavigationShell (ไม่ต้อง login ใหม่)
///   - เน็ต/เซิร์ฟเวอร์มีปัญหา              -> หน้า Retry (ไม่เตะผู้ใช้ออกจากระบบโดยไม่จำเป็น)
///
/// วิธีใช้: ใน main.dart ให้ตั้ง  home: const AuthGate()
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

enum _GateStatus { loading, authenticated, guest, error }

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  final _userController = UserController();

  _GateStatus _status = _GateStatus.loading;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    setState(() => _status = _GateStatus.loading);

    final token = await _authService.loadToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _status = _GateStatus.guest);
      return;
    }

    try {
      final me = await _userController.getMe();
      WorkspaceStore.currentStudentId = me.studentId;
      WorkspaceStore.currentUserName = me.fullName;
      WorkspaceStore.currentEmail = me.email;
      if (mounted) setState(() => _status = _GateStatus.authenticated);
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 404) {
        // token หมดอายุ หรือบัญชีไม่มีแล้ว -> เคลียร์แล้วให้ login ใหม่
        await _authService.removeToken();
        if (mounted) setState(() => _status = _GateStatus.guest);
      } else if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _status = _GateStatus.error;
        });
      }
    }
  }

  Future<void> _discardTokenAndLogin() async {
    await _authService.removeToken();
    if (mounted) setState(() => _status = _GateStatus.guest);
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _GateStatus.authenticated:
        return const MainNavigationShell();
      case _GateStatus.guest:
        return const AuthScreen();
      case _GateStatus.error:
        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _restoreSession,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try again'),
                  ),
                  TextButton(
                    onPressed: _discardTokenAndLogin,
                    child: const Text('Log in again'),
                  ),
                ],
              ),
            ),
          ),
        );
      case _GateStatus.loading:
        return const Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          body: Center(child: CircularProgressIndicator()),
        );
    }
  }
}
