import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/app/app_theme.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/task_item.dart';
import 'package:mfu_student_workspace/models/team_member.dart';
import 'package:mfu_student_workspace/screens/projects/project_detail_screen.dart';

/// Widget tests for the Project Coordinator (PC) Manage Team & Tasks screen.
///
/// These tests focus on visible UI and user interactions only.
/// They do not test controllers, models, API requests, or backend behavior.
void main() {
  late ProjectModel project;

  setUp(() {
    // Keep the screen's background API refreshes from making network requests.
    // The screen still receives all test data directly through [project].
    WorkspaceStore.projects = [];
    WorkspaceStore.currentStudentId = '6731501122';
    WorkspaceStore.currentUserName = 'Jiran unwat Test';

    project = ProjectModel(
      id: 'widget_test_project',
      title: 'CPE Project',
      courseCode: '1305204 Mobile App Dev',
      description: 'Project used for Manage (PC) widget tests.',
      deadline: '2026-12-15',
      myRole: 'PC',
      members: [
        TeamMember(
          studentId: '6731501122',
          name: 'Jiran uwat Test',
          role: 'PC',
        ),
        TeamMember(
          studentId: '6731501123',
          name: 'Member One',
          role: 'Member',
        ),
        TeamMember(
          studentId: '6731501124',
          name: 'Member Two',
          role: 'Member',
        ),
      ],
      tasks: [
        TaskItem(
          id: 'task_1',
          title: 'Design Database',
          description: 'Prepare database schema.',
          assignedTo: 'Member One',
          assignedStudentId: '6731501123',
          dueDate: '2026-12-15',
          status: 'TODO',
        ),
      ],
    );
  });

  Future<void> pumpManageScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ProjectDetailScreen(project: project),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Manage (PC) - initial screen', () {
    testWidgets('shows project information, management buttons, and team members',
        (tester) async {
      await pumpManageScreen(tester);

      expect(find.text('CPE Project'), findsWidgets);
      expect(find.text('👑 Coordinator (PC)'), findsOneWidget);
      expect(find.text('Manage Team & Tasks'), findsOneWidget);
      expect(find.text('Track Assignments'), findsOneWidget);

      expect(find.text('Add Member'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);

      expect(find.text('Team Members (3)'), findsOneWidget);
      expect(find.text('Jiran uwat Test'), findsOneWidget);
      expect(find.text('Member One'), findsOneWidget);
      expect(find.text('Member Two'), findsOneWidget);

      expect(find.text('👑 PC'), findsOneWidget);
      expect(find.text('👤 Member'), findsNWidgets(2));
    });

    testWidgets('does not show a Remove button for the PC', (tester) async {
      await pumpManageScreen(tester);

      expect(
        find.byKey(const Key('remove_member_6731501122')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('remove_member_6731501123')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('remove_member_6731501124')),
        findsOneWidget,
      );
    });
  });

  group('Manage (PC) - Add Team Member bottom sheet', () {
    testWidgets('opens Add Team Member bottom sheet', (tester) async {
      await pumpManageScreen(tester);

      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      expect(find.text('Add Team Member'), findsOneWidget);
      expect(find.text('Student ID *'), findsOneWidget);
      expect(
        find.text(
          'Enter 10-digit Student ID. Newly added students are automatically assigned as Members.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel closes the Add Team Member bottom sheet',
        (tester) async {
      await pumpManageScreen(tester);

      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add Team Member'), findsNothing);
      expect(find.text('Team Members (3)'), findsOneWidget);
    });

    testWidgets('shows validation when Student ID is empty', (tester) async {
      await pumpManageScreen(tester);

      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      final addButton = find.widgetWithText(FilledButton, 'Add Member').last;
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter student ID'), findsOneWidget);
      expect(find.text('Add Team Member'), findsOneWidget);
      expect(project.members.length, 3);
    });

    testWidgets('rejects a Student ID that is not exactly 10 digits',
        (tester) async {
      await pumpManageScreen(tester);

      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).last, '12345');
      final addButton = find.widgetWithText(FilledButton, 'Add Member').last;
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('Must be exactly 10 digits'), findsOneWidget);
      expect(project.members.length, 3);
    });

    testWidgets('rejects a Student ID that already belongs to the project',
        (tester) async {
      await pumpManageScreen(tester);

      await tester.tap(find.text('Add Member'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).last,
        '6731501123',
      );
      final addButton = find.widgetWithText(FilledButton, 'Add Member').last;
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Student ID is already in this project'),
        findsOneWidget,
      );
      expect(project.members.length, 3);
    });
  });

  group('Manage (PC) - Add New Task bottom sheet', () {
    testWidgets('opens Add New Task bottom sheet with project deadline',
        (tester) async {
      await pumpManageScreen(tester);

      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Task'), findsOneWidget);
      expect(find.text('Task Name *'), findsOneWidget);
      expect(find.text('Assign to Member *'), findsOneWidget);
      expect(
        find.text(
          'Starts in To Do status. Inherits project deadline (2026-12-15).',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save Task'), findsOneWidget);
    });

    testWidgets('defaults the assignee to the first team member',
        (tester) async {
      await pumpManageScreen(tester);

      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      // The first member is the PC in this fixture.
      expect(find.text('Jiran uwat Test (PC)'), findsOneWidget);
    });

    testWidgets('Cancel closes the Add New Task bottom sheet',
        (tester) async {
      await pumpManageScreen(tester);

      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Task'), findsNothing);
      expect(find.text('Team Members (3)'), findsOneWidget);
    });

    testWidgets('shows validation when Task Name is empty', (tester) async {
      await pumpManageScreen(tester);

      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save Task'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a task name'), findsOneWidget);
      expect(find.text('Add New Task'), findsOneWidget);
      expect(project.tasks.length, 1);
    });
  });

  group('Manage (PC) - Remove Team Member', () {
    testWidgets('blocks removal when the member has an assigned task',
        (tester) async {
      await pumpManageScreen(tester);

      await tester.tap(
        find.byKey(const Key('remove_member_6731501123')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cannot Remove Member'), findsOneWidget);
      expect(
        find.text(
          'Please reassign this member’s tasks before removing them.',
        ),
        findsWidgets,
      );
      expect(project.members.length, 3);
      expect(
        project.members.any((m) => m.studentId == '6731501123'),
        isTrue,
      );
    });

    testWidgets('shows a confirmation dialog before removing an unassigned member',
        (tester) async {
      // Use a member with no task assigned to them.
      project.members.add(
        TeamMember(
          studentId: '6731501199',
          name: 'Unassigned Member',
          role: 'Member',
        ),
      );

      await pumpManageScreen(tester);

      await tester.tap(
        find.byKey(const Key('remove_member_6731501199')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Remove Team Member'), findsOneWidget);
      expect(
        find.textContaining(
          'Are you sure you want to remove Unassigned Member',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(
  find.widgetWithText(FilledButton, 'Remove'),
  findsOneWidget,
);
    });

    testWidgets('Cancel keeps the unassigned member in the project',
        (tester) async {
      project.members.add(
        TeamMember(
          studentId: '6731501199',
          name: 'Unassigned Member',
          role: 'Member',
        ),
      );

      await pumpManageScreen(tester);

      await tester.tap(
        find.byKey(const Key('remove_member_6731501199')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Team Member'), findsNothing);
      expect(find.text('Unassigned Member'), findsOneWidget);
      expect(project.members.length, 4);
    });
  });
}
