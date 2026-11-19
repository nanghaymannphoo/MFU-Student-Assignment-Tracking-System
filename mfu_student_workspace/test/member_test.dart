import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/task_item.dart';
import 'package:mfu_student_workspace/models/team_member.dart';
import 'package:mfu_student_workspace/screens/projects/project_detail_screen.dart';
import 'package:mfu_student_workspace/screens/tasks/task_detail_screen.dart';

ProjectModel createIsolatedMemberTestProject() {
  return ProjectModel(
    id: 'proj_fixture_101',
    title: 'Autonomous Campus Shuttle System',
    courseCode: '1305301 Software Engineering',
    description: 'Real-time navigation and scheduling for campus shuttles',
    deadline: '2026-12-31',
    myRole: 'MEMBER',
    members: [
      TeamMember(studentId: '6731501001', name: 'Somchai PC', role: 'PC'),
      TeamMember(
        studentId: '6731501002',
        name: 'Nattapong Member',
        role: 'MEMBER',
      ),
      TeamMember(
        studentId: '6731501003',
        name: 'Supaporn Member',
        role: 'MEMBER',
      ),
      TeamMember(studentId: '6731501004', name: 'Kanya Member', role: 'MEMBER'),
    ],
    tasks: [
      TaskItem(
        id: 'task_fixture_001',
        title: 'Database Schema Design',
        description: 'Create ER diagram and tables',
        assignedTo: 'Nattapong Member',
        assignedStudentId: '6731501002',
        dueDate: '2026-12-10',
        status: 'IN_PROGRESS',
      ),
      TaskItem(
        id: 'task_fixture_002',
        title: 'API Authentication Flow',
        description: 'Implement JWT tokens',
        assignedTo: 'Nattapong Member',
        assignedStudentId: '6731501002',
        dueDate: '2026-12-15',
        status: 'TODO',
      ),
      TaskItem(
        id: 'task_fixture_003',
        title: 'Frontend State Management',
        description: 'Setup store and controllers',
        assignedTo: 'Supaporn Member',
        assignedStudentId: '6731501003',
        dueDate: '2026-12-20',
        status: 'DONE',
      ),
      TaskItem(
        id: 'task_fixture_004',
        title: 'Unit Test Coverage',
        description: 'Write widget and unit tests',
        assignedTo: 'Supaporn Member',
        assignedStudentId: '6731501003',
        dueDate: '2026-12-25',
        status: 'TODO',
      ),
      TaskItem(
        id: 'task_fixture_005',
        title: 'Project Roadmap Milestone',
        description: 'Coordinate project deliverables',
        assignedTo: 'Somchai PC',
        assignedStudentId: '6731501001',
        dueDate: '2026-12-05',
        status: 'TODO',
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Members see their own tasks and a read-only team list', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    final originalProjects = List.of(WorkspaceStore.projects);
    final originalStudentId = WorkspaceStore.currentStudentId;
    final originalUserName = WorkspaceStore.currentUserName;
    final originalEmail = WorkspaceStore.currentEmail;
    final originalNotifications = List.of(WorkspaceStore.notifications);

    // Restore all modified global store state and screen size after the test.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      WorkspaceStore.projects = originalProjects;
      WorkspaceStore.currentStudentId = originalStudentId;
      WorkspaceStore.currentUserName = originalUserName;
      WorkspaceStore.currentEmail = originalEmail;
      WorkspaceStore.notifications = originalNotifications;
      await tester.binding.setSurfaceSize(null);
    });

    await tester.binding.setSurfaceSize(const Size(1000, 1600));

    // Populate local project fixtures in WorkspaceStore.
    // Must work independently of login, demo data, and a running backend.
    final fixtureProject = createIsolatedMemberTestProject();
    WorkspaceStore.projects = [fixtureProject];

    await http.runWithClient(
      () async {
        // Read existing local project data.
        // No specific project name or Student ID is hardcoded.
        final projects = List.of(WorkspaceStore.projects);

        expect(
          projects,
          isNotEmpty,
          reason: 'Tests need local project fixtures in WorkspaceStore.',
        );

        int checkedMembers = 0;
        int checkedOwnTasks = 0;
        int checkedEmptyMembers = 0;
        int checkedTaskDetailNavigations = 0;

        for (final project in projects) {
          final members = project.members.where((member) {
            final role = member.role.toUpperCase();
            return role == 'MEMBER';
          }).toList();

          for (final member in members) {
            // Close the previous screen before changing the user.
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();

            WorkspaceStore.currentStudentId = member.studentId;
            WorkspaceStore.currentUserName = member.name;

            expect(
              project.isCurrentUserPC,
              isFalse,
              reason:
                  '${member.name} should have Member view in '
                  '${project.title}.',
            );

            final ownTasks = project.tasks
                .where((task) => task.assignedStudentId == member.studentId)
                .toList();

            final ownTitles = ownTasks.map((task) => task.title).toSet();

            final otherTasks = project.tasks
                .where((task) => task.assignedStudentId != member.studentId)
                .toList();

            // Open the real project screen.
            await tester.pumpWidget(
              MaterialApp(home: ProjectDetailScreen(project: project)),
            );

            await tester.pumpAndSettle();

            final myTasksTab = find.text('My Tasks (${ownTasks.length})');

            final teamMembersTab = find.text(
              'Team Members (${project.members.length})',
            );

            // Check the two Member tabs.
            expect(myTasksTab, findsOneWidget);
            expect(teamMembersTab, findsOneWidget);

            expect(find.text('Manage Team & Tasks'), findsNothing);

            expect(find.text('Track Assignments'), findsNothing);

            // My Tasks is the default tab.
            if (ownTasks.isEmpty) {
              expect(
                find.text('No Tasks Assigned'),
                findsOneWidget,
                reason: 'A member with no assigned tasks sees the empty state.',
              );
              checkedEmptyMembers++;
            } else {
              expect(find.text('No Tasks Assigned'), findsNothing);
              for (final task in ownTasks) {
                expect(
                  find.text(task.title),
                  findsWidgets,
                  reason: 'The member must see their own task.',
                );
              }
            }

            // Other members' task titles must be hidden.
            // Skip duplicate titles shared with the user's own tasks:
            // text alone cannot distinguish those cards.
            for (final task in otherTasks) {
              if (!ownTitles.contains(task.title)) {
                expect(
                  find.text(task.title),
                  findsNothing,
                  reason: 'Other members’ tasks must be hidden.',
                );
              }
            }

            expect(find.byType(LinearProgressIndicator), findsNothing);

            for (final label in [
              'Add Member',
              'Add Team Member',
              'Add Task',
              'Add New Task',
              'Remove',
              'Remove Member',
            ]) {
              expect(find.text(label), findsNothing);
            }

            // Tapping an assigned task opens TaskDetailScreen with the correct task and project.
            if (ownTasks.isNotEmpty) {
              final targetTask = ownTasks.first;
              await tester.tap(find.text(targetTask.title).first);
              await tester.pumpAndSettle();

              expect(
                find.byType(TaskDetailScreen),
                findsOneWidget,
                reason: 'Tapping an assigned task opens TaskDetailScreen.',
              );

              final detailWidget = tester.widget<TaskDetailScreen>(
                find.byType(TaskDetailScreen),
              );
              expect(
                detailWidget.task.id,
                targetTask.id,
                reason: 'TaskDetailScreen must receive the tapped task.',
              );
              expect(detailWidget.task.title, targetTask.title);
              expect(
                detailWidget.project.id,
                project.id,
                reason: 'TaskDetailScreen must receive the correct project.',
              );

              // Return to ProjectDetailScreen
              final navigator = tester.state<NavigatorState>(
                find.byType(Navigator),
              );
              navigator.pop();
              await tester.pumpAndSettle();

              expect(find.byType(TaskDetailScreen), findsNothing);
              expect(find.byType(ProjectDetailScreen), findsOneWidget);
              checkedTaskDetailNavigations++;
            }

            // Open the read-only Team Members tab.
            await tester.tap(teamMembersTab);
            await tester.pumpAndSettle();

            for (final teammate in project.members) {
              expect(find.text(teammate.name), findsWidgets);

              expect(
                find.text('Student ID: ${teammate.studentId}'),
                findsOneWidget,
              );
            }

            // Roles shown on Team Members tab
            expect(find.text('Coordinator (PC)'), findsOneWidget);
            expect(find.text('Member'), findsWidgets);

            // Current user indicator
            expect(find.text('(You)'), findsOneWidget);

            // Read-only verification on Team Members tab
            expect(find.text('Remove'), findsNothing);
            expect(find.text('Add Member'), findsNothing);

            expect(find.byType(LinearProgressIndicator), findsNothing);

            // Return to My Tasks.
            await tester.tap(myTasksTab);
            await tester.pumpAndSettle();

            if (ownTasks.isEmpty) {
              expect(find.text('No Tasks Assigned'), findsOneWidget);
            } else {
              for (final task in ownTasks) {
                expect(find.text(task.title), findsWidgets);
              }
            }

            expect(tester.takeException(), isNull);

            checkedMembers++;
            checkedOwnTasks += ownTasks.length;
          }
        }

        // Ensure the test actually exercised Member views.
        expect(
          checkedMembers,
          greaterThanOrEqualTo(3),
          reason: 'Fixtures must include at least two members with tasks and one without.',
        );

        expect(
          checkedOwnTasks,
          greaterThan(0),
          reason: 'Fixtures must include tasks assigned to MEMBERs.',
        );

        expect(
          checkedEmptyMembers,
          greaterThan(0),
          reason: 'Fixtures must exercise a member with no assigned tasks.',
        );

        expect(
          checkedTaskDetailNavigations,
          greaterThan(0),
          reason: 'Fixtures must exercise navigating to TaskDetailScreen.',
        );
      },
      () => MockClient((request) async {
        return http.Response(
          '{"message": "Unauthorized"}',
          401,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
}
