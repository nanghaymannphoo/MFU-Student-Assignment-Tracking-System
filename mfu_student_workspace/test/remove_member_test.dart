import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/app/app_theme.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/task_item.dart';
import 'package:mfu_student_workspace/models/team_member.dart';
import 'package:mfu_student_workspace/screens/projects/project_detail_screen.dart';

void main() {
  late ProjectModel testProject;

  setUp(() {
    WorkspaceStore.currentStudentId = '6731501105'; // Phoo
    WorkspaceStore.currentUserName = 'Phoo';

    testProject = ProjectModel(
      id: 'test_p1',
      title: 'Test Software Project',
      courseCode: '1305204 Mobile App Dev',
      description: 'Project for testing member removal',
      deadline: '2026-12-01',
      myRole: 'PC',
      members: [
        TeamMember(studentId: '6731501105', name: 'Phoo', role: 'PC'),
        TeamMember(studentId: '6731501101', name: 'Menisa', role: 'Member'),
        TeamMember(studentId: '6731501102', name: 'Puttapoom', role: 'Member'),
        TeamMember(studentId: '6731501199', name: 'UnassignedMember', role: 'Member'),
      ],
      tasks: [
        TaskItem(
          id: 't_assigned_todo',
          title: 'Active Task',
          description: 'Task assigned to Menisa',
          assignedTo: 'Menisa',
          assignedStudentId: '6731501101',
          dueDate: '2026-11-20',
          status: 'TODO',
          comments: [],
        ),
        TaskItem(
          id: 't_assigned_done',
          title: 'Completed Task',
          description: 'Completed task assigned to Puttapoom',
          assignedTo: 'Puttapoom',
          assignedStudentId: '6731501102',
          dueDate: '2026-11-01',
          status: 'DONE',
          comments: [],
        ),
      ],
    );

    // Ensure WorkspaceStore has this project in its list
    WorkspaceStore.projects = [testProject];
  });

  Widget buildProjectDetailScreen(ProjectModel project) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: ProjectDetailScreen(project: project),
    );
  }

  group('Project Member Removal Tests', () {
    test('Store: Removal blocked when member has active or completed tasks assigned', () {
      // 1. Menisa has a TODO task
      final resultMenisa = WorkspaceStore.removeMemberFromProject(
        projectId: testProject.id,
        memberStudentId: '6731501101',
        actingStudentId: '6731501105',
      );
      expect(resultMenisa.success, isFalse);
      expect(resultMenisa.message, 'Please reassign this member’s tasks before removing them.');

      // 2. Puttapoom has a DONE task (ALL tasks including completed ones must be checked)
      final resultPuttapoom = WorkspaceStore.removeMemberFromProject(
        projectId: testProject.id,
        memberStudentId: '6731501102',
        actingStudentId: '6731501105',
      );
      expect(resultPuttapoom.success, isFalse);
      expect(resultPuttapoom.message, 'Please reassign this member’s tasks before removing them.');
    });

    test('Store: PC cannot remove themselves or another PC', () {
      final resultPC = WorkspaceStore.removeMemberFromProject(
        projectId: testProject.id,
        memberStudentId: '6731501105',
        actingStudentId: '6731501105',
      );
      expect(resultPC.success, isFalse);
      expect(resultPC.message, 'The project PC cannot be removed.');
    });

    test('Store: Member cannot remove anyone', () {
      // Non-PC user attempting removal
      final resultMemberAttempt = WorkspaceStore.removeMemberFromProject(
        projectId: testProject.id,
        memberStudentId: '6731501199',
        actingStudentId: '6731501101', // Menisa is a Member, not PC
      );
      expect(resultMemberAttempt.success, isFalse);
      expect(resultMemberAttempt.message, 'Only that project’s PC can remove members.');
    });

    test('Store: PC can remove a member with no assigned tasks', () {
      expect(testProject.members.length, 4);

      final resultSuccess = WorkspaceStore.removeMemberFromProject(
        projectId: testProject.id,
        memberStudentId: '6731501199',
        actingStudentId: '6731501105',
      );
      expect(resultSuccess.success, isTrue);
      expect(resultSuccess.message, 'Member removed successfully.');

      // Verify member is removed
      expect(testProject.members.length, 3);
      expect(testProject.members.any((m) => m.studentId == '6731501199'), isFalse);
    });

    testWidgets('UI: Removal blocked with dialog when member has assigned tasks', (tester) async {
      await tester.pumpWidget(buildProjectDetailScreen(testProject));
      await tester.pumpAndSettle();

      // Tap remove on Menisa (has assigned task)
      final removeMenisaBtn = find.byKey(const Key('remove_member_6731501101'));
      expect(removeMenisaBtn, findsOneWidget);

      await tester.tap(removeMenisaBtn);
      await tester.pumpAndSettle();

      // Must show the blocking dialog with exact required text
      expect(find.text('Cannot Remove Member'), findsOneWidget);
      expect(find.text('Please reassign this member’s tasks before removing them.'), findsWidgets);

      // Verify member was NOT removed
      expect(testProject.members.any((m) => m.studentId == '6731501101'), isTrue);
    });

    testWidgets('UI: PC does not have a Remove action beside their own row', (tester) async {
      await tester.pumpWidget(buildProjectDetailScreen(testProject));
      await tester.pumpAndSettle();

      // PC row (Phoo, 6731501105) must not have a remove button
      final removePCBtn = find.byKey(const Key('remove_member_6731501105'));
      expect(removePCBtn, findsNothing);
    });

    testWidgets('UI: PC removes member with no tasks via confirmation dialog and updates immediately', (tester) async {
      await tester.pumpWidget(buildProjectDetailScreen(testProject));
      await tester.pumpAndSettle();

      expect(find.text('Team Members (4)'), findsOneWidget);

      // Tap remove on UnassignedMember (6731501199)
      final removeUnassignedBtn = find.byKey(const Key('remove_member_6731501199'));
      expect(removeUnassignedBtn, findsOneWidget);

      await tester.tap(removeUnassignedBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog should appear naming the member
      expect(find.text('Remove Team Member'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('UnassignedMember'),
        ),
        findsOneWidget,
      );

      // Tap the confirm 'Remove' button in dialog
      final confirmBtn = find.widgetWithText(FilledButton, 'Remove');
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Member count updates immediately to 3
      expect(find.text('Team Members (3)'), findsOneWidget);
      expect(find.byKey(const Key('remove_member_6731501199')), findsNothing);
      expect(testProject.members.length, 3);
    });

    testWidgets('UI: Members cannot see any Remove actions in Member view', (tester) async {
      // Simulate signed in as Member (e.g., Menisa 6731501101)
      WorkspaceStore.currentStudentId = '6731501101';
      final memberProject = ProjectModel(
        id: testProject.id,
        title: testProject.title,
        courseCode: testProject.courseCode,
        description: testProject.description,
        deadline: testProject.deadline,
        myRole: 'Member',
        members: testProject.members,
        tasks: testProject.tasks,
      );

      await tester.pumpWidget(buildProjectDetailScreen(memberProject));
      await tester.pumpAndSettle();

      // Switch to Team Members tab
      final teamMembersTab = find.textContaining('Team Members');
      expect(teamMembersTab, findsOneWidget);
      await tester.tap(teamMembersTab);
      await tester.pumpAndSettle();

      // Zero remove buttons should exist in Member view
      expect(find.text('Remove'), findsNothing);
      expect(find.byIcon(Icons.person_remove_outlined), findsNothing);
    });
  });
}
