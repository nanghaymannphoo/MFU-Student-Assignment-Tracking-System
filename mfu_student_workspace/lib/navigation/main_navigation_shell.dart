import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../data/workspace_store.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Timer? _overdueCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial check when the shell starts
    WorkspaceStore.checkOverdueTasksAndNotify();
    // Periodic check while app is open so overdue badges and notifications stay current
    _overdueCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      WorkspaceStore.checkOverdueTasksAndNotify();
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WorkspaceStore.checkOverdueTasksAndNotify();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _overdueCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = WorkspaceStore.getUnreadCountForCurrentUser();

    // Use IndexedStack to preserve scroll states & performance across bottom navigation
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardScreen(
            onOpenNotifications: () => setState(() => _selectedIndex = 1),
            onRefresh: () {
              WorkspaceStore.checkOverdueTasksAndNotify();
              setState(() {});
            },
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
