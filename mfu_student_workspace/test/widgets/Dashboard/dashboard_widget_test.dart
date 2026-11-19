import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/core/constants/app_colors.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/navigation/main_navigation_shell.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/team_member.dart';
import 'package:mfu_student_workspace/screens/dashboard/dashboard_screen.dart';

Widget dashboardHarness({VoidCallback? onNotifications}) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      useMaterial3: true,
    ),
    home: DashboardScreen(
      onOpenNotifications: onNotifications ?? () {},
      onRefresh: () {},
    ),
  );
}

void main() {
  setUp(() {
    // Keep tests independent from data left by another test.
    WorkspaceStore.projects.clear();
  });

  group('Dashboard widget tests', () {
    testWidgets('My Projects is selected by default and Deadlines switches tab',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(dashboardHarness());
      await tester.pumpAndSettle();

      expect(find.textContaining('My Projects ('), findsWidgets);
      expect(find.text('No Projects Yet'), findsOneWidget);

      await tester.tap(find.textContaining('Deadlines ('));
      await tester.pumpAndSettle();

      expect(find.text('No Pending Deadlines'), findsOneWidget);

      await tester.tap(find.textContaining('My Projects ('));
      await tester.pumpAndSettle();
      expect(find.text('No Projects Yet'), findsOneWidget);

      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
    });

    testWidgets('Tapping a project card opens its Project Detail page',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;

      final project = ProjectModel(
        id: 'widget-test-project',
        title: 'Widget Test Project',
        courseCode: 'CE1234',
        description: 'Project detail navigation test',
        deadline: '2026-12-01',
        myRole: 'PC',
        members: [
          TeamMember(
            studentId: WorkspaceStore.currentStudentId,
            name: WorkspaceStore.currentUserName,
            role: 'PC',
          ),
        ],
        tasks: [],
      );
      WorkspaceStore.projects.add(project);

      await tester.pumpWidget(dashboardHarness());
      await tester.pumpAndSettle();

      // Tap the project card on Dashboard > My Projects.
      await tester.tap(find.text('Widget Test Project').first);
      await tester.pumpAndSettle();

      // The detail screen displays the project title and team controls.
      expect(find.text('Widget Test Project'), findsOneWidget);
      expect(find.text('Manage Team & Tasks'), findsOneWidget);
      expect(find.text('Track Assignments'), findsOneWidget);
      expect(find.text('Add Member'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));

      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
    });

    testWidgets('Dashboard notification bell invokes navigation callback',
        (tester) async {
      var opened = false;
      await tester.pumpWidget(dashboardHarness(onNotifications: () {
        opened = true;
      }));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open Notifications'));
      await tester.pump();

      expect(opened, isTrue);
    });

    testWidgets('New Project opens the create project form', (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(dashboardHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('New Project'));
      await tester.pumpAndSettle();

      expect(find.text('Create Group Project'), findsOneWidget);
      expect(find.text('Project Name *'), findsOneWidget);
      expect(find.text('Course Code & Name *'), findsOneWidget);
      expect(find.text('Project Description'), findsOneWidget);
      expect(find.text('Project Deadline *'), findsOneWidget);
      expect(find.text('Create Project'), findsWidgets);

      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
    });

    testWidgets('Create Project empty state action opens the same form',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(dashboardHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      expect(find.text('Create Group Project'), findsOneWidget);
      expect(find.text('Project Name *'), findsOneWidget);
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
    });

    testWidgets('Workload status cards open the corresponding task sheet',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(dashboardHarness());
      await tester.pumpAndSettle();

      final cases = <String, String>{
        'To Do': 'To Do',
        'In Progress': 'In Progress',
        'Done': 'Completed',
        'Overdue': 'Overdue',
      };

      for (final entry in cases.entries) {
        await tester.tap(find.text(entry.key).first);
        await tester.pumpAndSettle();

        // The sheet heading is rendered as '<status> Tasks'.
        expect(find.text('${entry.value} Tasks'), findsOneWidget);
        await tester.tapAt(const Offset(450, 100));
        await tester.pumpAndSettle();
      }

      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
    });
  });

  group('Bottom navigation widget tests', () {
    testWidgets('Bottom navigation opens My Tasks, Notifications and Profile',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const MaterialApp(home: MainNavigationShell()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Tasks').last);
      await tester.pumpAndSettle();
      expect(find.text('My Tasks'), findsWidgets);

      await tester.tap(find.text('Notifications').last);
      await tester.pumpAndSettle();
      expect(find.text('Notifications').first, findsOneWidget);

      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();
      expect(find.text('My Profile'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));

      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
    });

    testWidgets('Dashboard bell opens Notifications destination',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(const MaterialApp(home: MainNavigationShell()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Open Notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Notifications').first, findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));

      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());
    });
  });
}
