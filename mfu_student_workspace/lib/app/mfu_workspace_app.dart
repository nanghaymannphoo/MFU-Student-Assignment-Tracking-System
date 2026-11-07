import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../screens/auth/auth_screen.dart';

class MfuWorkspaceApp extends StatelessWidget {
  const MfuWorkspaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MFU Student Workspace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthScreen(),
    );
  }
}

