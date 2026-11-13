import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/task_item.dart';
import 'package:mfu_student_workspace/models/team_member.dart';
import 'package:mfu_student_workspace/screens/projects/project_detail_screen.dart';
import 'package:mfu_student_workspace/screens/tasks/task_detail_screen.dart';

void main() {
  setUp(() {
    WorkspaceStore.currentStudentId = '6731501105';
    WorkspaceStore.currentUserName = 'Nang Hay Man Phoo';
  });

  ProjectModel createMemberProject() {
    return ProjectModel(
      id: 'p_member',
      title: 'Hospital Database System',
      courseCode: '1305202 Database Systems',
      description: 'ER Diagram and Normalization',
      deadline: '2026-11-25',
      myRole: 'Member', // Current user is Member
      members: [
        TeamMember(studentId: '6731501102', name: 'Puttapoom', role: 'PC'),
        TeamMember(studentId: '6731501105', name: 'Phoo', role: 'Member'),
        TeamMember(studentId: '6731501109', name: 'Mary', role: 'Member'),
      ],
      tasks: [
        TaskItem(
          id: 't_phoo_1',
          title: 'Write Stored Procedures for Appointments',
          description: 'Create MySQL stored procedures',
          assignedTo: 'Phoo',
          assignedStudentId: '6731501105', // Assigned to Phoo
          dueDate: '2026-11-14',
          status: 'IN_PROGRESS',
        ),
        TaskItem(
          id: 't_phoo_overdue',
          title: 'Initial ER Draft',
          description: 'Draft initial ER schema',
          assignedTo: 'Phoo',
          assignedStudentId: '6731501105', // Assigned to Phoo, Overdue
          dueDate: '2026-11-01',
          status: 'TODO',
        ),
        TaskItem(
          id: 't_mary',
          title: '3NF Normalization Report',
          description: 'Document dependencies',
          assignedTo: 'Mary',
          assignedStudentId: '6731501109', // Assigned to Mary (not Phoo)
          dueDate: '2026-11-12',
          status: 'DONE',
        ),
      ],
    );
  }

  ProjectModel createPCProject() {
    return ProjectModel(
      id: 'p_pc',
      title: 'Student Assignment Tracker',
      courseCode: '1305204 Mobile App Dev',
      description: 'Flutter + Node.js workspace',
      deadline: '2026-11-20',
      myRole: 'PC', // Current user is PC
      members: [
        TeamMember(studentId: '6731501105', name: 'Phoo', role: 'PC'),
        TeamMember(studentId: '6731501101', name: 'Menisa', role: 'Member'),
      ],
      tasks: [
        TaskItem(
          id: 't_pc_1',
          title: 'JWT Role Middleware Setup',
          description: 'Verify project role',
          assignedTo: 'Phoo',
          assignedStudentId: '6731501105',
          dueDate: '2026-11-12',
          status: 'TODO',
        ),
      ],
    );
  }

  group('ProjectDetailScreen - Member View Tests', () {
    testWidgets('Member view shows exactly two tabs: My Tasks and Team Members, defaulting to My Tasks', (tester) async {
      final project = createMemberProject();

      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(project: project),
        ),
      );
      await tester.pumpAndSettle();

      // Exactly two tabs
      expect(find.text('My Tasks (2)'), findsOneWidget);
      expect(find.text('Team Members (3)'), findsOneWidget);

      // Verify PC tabs are NOT present
      expect(find.text('Manage Team & Tasks'), findsNothing);
      expect(find.text('Track Assignments'), findsNothing);

      // Default is My Tasks -> shows Phoo tasks
      expect(find.text('Write Stored Procedures for Appointments'), findsOneWidget);
      expect(find.text('Initial ER Draft'), findsOneWidget);

      // Does NOT show Mary's task
      expect(find.text('3NF Normalization Report'), findsNothing);

      // Overdue badge is shown for overdue task
      expect(find.text('Overdue'), findsWidgets);

      // No progress bars or percentages or management controls
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Add Member'), findsNothing);
      expect(find.text('Add Task'), findsNothing);
      expect(find.text('Team Progress Overview'), findsNothing);

      // Compact header shows Member role, course, title, deadline
      expect(find.text('Member'), findsOneWidget);
      expect(find.text('1305202 Database Systems'), findsOneWidget);
      expect(find.text('Hospital Database System'), findsWidgets);
      expect(find.text('Deadline: 2026-11-25'), findsOneWidget);
    });

    testWidgets('Team Members tab shows read-only member list without management controls', (tester) async {
      final project = createMemberProject();

      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(project: project),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Team Members tab
      await tester.tap(find.text('Team Members (3)'));
      await tester.pumpAndSettle();

      // Verify members are listed with name, student ID, and role
      expect(find.text('Puttapoom'), findsOneWidget);
      expect(find.text('Student ID: 6731501102'), findsOneWidget);
      expect(find.text('Coordinator (PC)'), findsOneWidget);

      expect(find.text('Phoo'), findsOneWidget);
      expect(find.text('(You)'), findsOneWidget);
      expect(find.text('Student ID: 6731501105'), findsOneWidget);

      expect(find.text('Mary'), findsOneWidget);
      expect(find.text('Student ID: 6731501109'), findsOneWidget);

      // Read-only: No delete or edit controls
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.person_add_alt_1_rounded), findsNothing);
      expect(find.text('Add Member'), findsNothing);
    });

    testWidgets('Tapping a task in Member view opens TaskDetailScreen', (tester) async {
      final project = createMemberProject();

      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(project: project),
        ),
      );
      await tester.pumpAndSettle();

      // Tap task card
      await tester.tap(find.text('Write Stored Procedures for Appointments'));
      await tester.pumpAndSettle();

      // Opens TaskDetailScreen
      expect(find.byType(TaskDetailScreen), findsOneWidget);
      expect(find.text('Write Stored Procedures for Appointments'), findsWidgets);
    });
  });

  group('ProjectDetailScreen - PC View Preservation Tests', () {
    testWidgets('PC view preserves Manage Team & Tasks, Track Assignments, and controls', (tester) async {
      final project = createPCProject();

      await tester.pumpWidget(
        MaterialApp(
          home: ProjectDetailScreen(project: project),
        ),
      );
      await tester.pumpAndSettle();

      // PC view shows primary tabs: Manage Team & Tasks vs Track Assignments
      expect(find.text('Manage Team & Tasks'), findsOneWidget);
      expect(find.text('Track Assignments'), findsOneWidget);

      // PC controls are present
      expect(find.text('Add Member'), findsOneWidget);
      expect(find.text('Add Task'), findsOneWidget);
      expect(find.text('👑 Coordinator (PC)'), findsOneWidget);
    });
  });
}

