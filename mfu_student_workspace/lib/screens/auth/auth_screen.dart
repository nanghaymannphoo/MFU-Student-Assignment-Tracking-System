import 'package:flutter/material.dart';
import 'package:mfu_student_workspace/models/api_models.dart';
import '../../controller/api_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../data/workspace_store.dart';
import '../../navigation/main_navigation_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  final TextEditingController _studentIdCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  final _authController = AuthController();
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

  /// เก็บข้อมูลผู้ใช้ไว้ใน WorkspaceStore เพื่อให้หน้าอื่นที่ยังอ่านจาก store ใช้ต่อได้
  void _applyUser(UserModel user) {
    WorkspaceStore.currentStudentId = user.studentId;
    WorkspaceStore.currentUserName = user.fullName;
    WorkspaceStore.currentEmail = user.email;
  }

  Future<void> _handleSubmit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      if (isLogin) {
        await _login();
      } else {
        await _register();
      }
    } on ApiException catch (e) {
      _showMessage(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    final user = await _authController.login(
      _studentIdCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (!mounted) return;

    // login() คืน null เมื่อ student id / password ไม่ถูกต้อง (HTTP 401)
    if (user == null) {
      _showMessage('Student ID or password is incorrect.', isError: true);
      return;
    }

    _applyUser(user);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
    );
  }

  Future<void> _register() async {
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      _showMessage('Passwords do not match. Please verify your password.',
          isError: true);
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
    // กลับไปแท็บ Log In โดยคง Student ID ไว้ แต่ล้างรหัสผ่าน
    _passwordCtrl.clear();
    _confirmPasswordCtrl.clear();
    setState(() => isLogin = true);
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
                                          color: AppColors.primary.withValues(alpha: 0.08),
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
                                          color: AppColors.primary.withValues(alpha: 0.08),
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
                            const SizedBox(height: 14),
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
                          const SizedBox(height: 14),

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
                            const SizedBox(height: 14),
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

                          if (!isLogin) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmPasswordCtrl,
                              obscureText: obscureConfirmPassword,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Re-enter password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                  ),
                                  tooltip: obscureConfirmPassword ? 'Show password' : 'Hide password',
                                  onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (val != _passwordCtrl.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
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
                                  : Text(isLogin ? 'Log In to Workspace' : 'Create Account'),
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