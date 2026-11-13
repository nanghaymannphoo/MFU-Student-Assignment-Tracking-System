import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/task_item.dart';
import 'package:mfu_student_workspace/models/team_member.dart';
import 'package:mfu_student_workspace/models/assigned_task_entry.dart';
import 'package:mfu_student_workspace/screens/tasks/my_tasks_screen.dart';
import 'package:mfu_student_workspace/screens/tasks/task_detail_screen.dart';
import 'package:mfu_student_workspace/core/utils/deadline_helpers.dart';

void main() {
  setUp(() {
    // Reset to test environment
    WorkspaceStore.currentStudentId = '6731501105';
    WorkspaceStore.currentUserName = 'Nang Hay Man Phoo';

    // Set up mock projects
    WorkspaceStore.projects = [
      ProjectModel(
        id: 'proj_alpha',
        title: 'Project Alpha',
        courseCode: '1305204 Mobile App Dev',
        description: 'First test project',
        deadline: '2026-11-20',
        myRole: 'PC', // Phoo is PC here
        members: [
          TeamMember(studentId: '6731501105', name: 'Phoo', role: 'PC'),
          TeamMember(studentId: '6731501101', name: 'Bob', role: 'Member'),
        ],
        tasks: [
          TaskItem(
            id: 'task_pc_assigned',
            title: 'PC Personal Task',
            description: 'Assigned to Phoo while she is PC',
            assignedTo: 'Phoo',
            assignedStudentId: '6731501105', // Matched by Student ID
            dueDate: '2026-11-15',
            status: 'TODO',
          ),
          TaskItem(
            id: 'task_bob',
            title: 'Bob Task',
            description: 'Assigned to Bob',
            assignedTo: 'Bob',
            assignedStudentId: '6731501101',
            dueDate: '2026-11-12',
            status: 'IN_PROGRESS',
          ),
          TaskItem(
            id: 'task_name_spoof',
            title: 'Name Spoof Task',
            description: 'Has display name Phoo but different student ID',
            assignedTo: 'Phoo', // Display name matches
            assignedStudentId: '9999999999', // Different Student ID
            dueDate: '2026-11-10',
            status: 'TODO',
          ),
        ],
      ),
      ProjectModel(
        id: 'proj_beta',
        title: 'Project Beta',
        courseCode: '1305202 Database Systems',
        description: 'Second test project',
        deadline: '2026-11-25',
        myRole: 'Member', // Phoo is Member here
        members: [
          TeamMember(studentId: '6731501102', name: 'Charlie', role: 'PC'),
          TeamMember(studentId: '6731501105', name: 'Phoo', role: 'Member'),
        ],
        tasks: [
          TaskItem(
            id: 'task_member_assigned',
            title: 'Member Personal Task',
            description: 'Assigned to Phoo while she is Member',
            assignedTo: 'Phoo',
            assignedStudentId: '6731501105',
            dueDate: '2026-11-01', // Overdue
            status: 'IN_PROGRESS',
          ),
          TaskItem(
            id: 'task_member_done',
            title: 'Completed Personal Task',
            description: 'Done task for Phoo',
            assignedTo: 'Phoo',
            assignedStudentId: '6731501105',
            dueDate: '2026-11-03',
            status: 'DONE',
          ),
          TaskItem(
            id: 'task_no_deadline',
            title: 'No Deadline Task',
            description: 'Task without due date',
            assignedTo: 'Phoo',
            assignedStudentId: '6731501105',
            dueDate: '',
            status: 'TODO',
          ),
        ],
      ),
      ProjectModel(
        id: 'proj_external',
        title: 'External Project',
        courseCode: '1305299 External',
        description: 'Project user is NOT a member of',
        deadline: '2026-12-01',
        myRole: 'None',
        members: [
          TeamMember(studentId: '8888888888', name: 'Stranger', role: 'PC'),
        ],
        tasks: [
          TaskItem(
            id: 'task_external',
            title: 'External Task',
            description: 'Task with Phoo ID in non-member project',
            assignedTo: 'Phoo',
            assignedStudentId: '6731501105',
            dueDate: '2026-11-18',
            status: 'TODO',
          ),
        ],
      ),
    ];
  });

  group('My Tasks Store & Filtering Tests', () {
    test('Strict Student ID filtering across user member projects', () {
      final tasks = WorkspaceStore.getAssignedTasksForCurrentUser();

      // Should find:
      // 1. task_pc_assigned (in proj_alpha)
      // 2. task_member_assigned (in proj_beta)
      // 3. task_member_done (in proj_beta)
      // 4. task_no_deadline (in proj_beta)
      // Total = 4 tasks
      expect(tasks.length, 4);

      final taskIds = tasks.map((e) => e.task.id).toSet();
      expect(taskIds.contains('task_pc_assigned'), isTrue);
      expect(taskIds.contains('task_member_assigned'), isTrue);
      expect(taskIds.contains('task_member_done'), isTrue);
      expect(taskIds.contains('task_no_deadline'), isTrue);

      // Verify excluded tasks:
      // - Bob's task (assigned to different student ID)
      expect(taskIds.contains('task_bob'), isFalse);
      // - Name spoof task (assignedTo is Phoo, but student ID is 9999999999)
      expect(taskIds.contains('task_name_spoof'), isFalse);
      // - External task (user is not member of proj_external)
      expect(taskIds.contains('task_external'), isFalse);
    });

    test('Includes tasks assigned to user even when they are PC', () {
      final tasks = WorkspaceStore.getAssignedTasksForCurrentUser();
      final pcTask = tasks.firstWhere((e) => e.task.id == 'task_pc_assigned');

      expect(pcTask.project.myRole, 'PC');
      expect(pcTask.project.members.firstWhere((m) => m.studentId == '6731501105').role, 'PC');
      expect(pcTask.task.assignedStudentId, '6731501105');
    });

    test('Pending vs Done separation', () {
      final allTasks = WorkspaceStore.getAssignedTasksForCurrentUser();
      final pending = allTasks.where((e) => e.task.status != 'DONE').toList();
      final done = allTasks.where((e) => e.task.status == 'DONE').toList();

      expect(pending.length, 3); // task_pc_assigned, task_member_assigned, task_no_deadline
      expect(done.length, 1); // task_member_done
    });

    test('Grouping and sorting logic for Pending tasks', () {
      final allTasks = WorkspaceStore.getAssignedTasksForCurrentUser();
      final pending = allTasks.where((e) => e.task.status != 'DONE').toList();

      final overdueEntries = <AssignedTaskEntry>[];
      final dueTodayEntries = <AssignedTaskEntry>[];
      final upcomingEntries = <AssignedTaskEntry>[];
      final noDeadlineEntries = <AssignedTaskEntry>[];

      for (final entry in pending) {
        final dueDateStr = entry.task.dueDate.trim();
        if (dueDateStr.isEmpty) {
          noDeadlineEntries.add(entry);
        } else if (isTaskOverdue(entry.task)) {
          overdueEntries.add(entry);
        } else if (isTaskDueToday(entry.task)) {
          dueTodayEntries.add(entry);
        } else if (DateTime.tryParse(dueDateStr) != null) {
          upcomingEntries.add(entry);
        } else {
          noDeadlineEntries.add(entry);
        }
      }

      // Overdue: task_member_assigned (2026-11-01)
      expect(overdueEntries.length, 1);
      expect(overdueEntries.first.task.id, 'task_member_assigned');

      // Upcoming: task_pc_assigned (2026-11-15)
      expect(upcomingEntries.length, 1);
      expect(upcomingEntries.first.task.id, 'task_pc_assigned');

      // No deadline: task_no_deadline
      expect(noDeadlineEntries.length, 1);
      expect(noDeadlineEntries.first.task.id, 'task_no_deadline');

      // Due Today is empty for these dates
      expect(dueTodayEntries.isEmpty, isTrue);

      // Verify summary: total remaining = 3, overdue = 1 (overdue is already in remaining)
      final remainingCount = pending.length;
      final overdueCount = overdueEntries.length;
      expect(remainingCount, 3);
      expect(overdueCount, 1);
    });

    test('Sorting overdue by oldest deadline and upcoming by nearest deadline', () {
      final overdueList = [
        AssignedTaskEntry(
          project: WorkspaceStore.projects[0],
          task: TaskItem(id: 'od_recent', title: 'Recent Overdue', description: '', assignedTo: 'Phoo', assignedStudentId: '6731501105', dueDate: '2026-11-05', status: 'TODO'),
        ),
        AssignedTaskEntry(
          project: WorkspaceStore.projects[0],
          task: TaskItem(id: 'od_oldest', title: 'Oldest Overdue', description: '', assignedTo: 'Phoo', assignedStudentId: '6731501105', dueDate: '2026-10-25', status: 'TODO'),
        ),
      ];

      // Oldest deadline first
      overdueList.sort((a, b) => a.task.dueDate.trim().compareTo(b.task.dueDate.trim()));
      expect(overdueList[0].task.id, 'od_oldest');
      expect(overdueList[1].task.id, 'od_recent');

      final upcomingList = [
        AssignedTaskEntry(
          project: WorkspaceStore.projects[0],
          task: TaskItem(id: 'up_later', title: 'Later Upcoming', description: '', assignedTo: 'Phoo', assignedStudentId: '6731501105', dueDate: '2026-11-28', status: 'TODO'),
        ),
        AssignedTaskEntry(
          project: WorkspaceStore.projects[0],
          task: TaskItem(id: 'up_nearest', title: 'Nearest Upcoming', description: '', assignedTo: 'Phoo', assignedStudentId: '6731501105', dueDate: '2026-11-10', status: 'TODO'),
        ),
      ];

      // Nearest deadline first
      upcomingList.sort((a, b) => a.task.dueDate.trim().compareTo(b.task.dueDate.trim()));
      expect(upcomingList[0].task.id, 'up_nearest');
      expect(upcomingList[1].task.id, 'up_later');
    });
  });

  group('My Tasks Widget Tests', () {
    testWidgets('Renders MyTasksScreen with compact summary and groups', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyTasksScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('My Tasks'), findsOneWidget);
      expect(find.text('Student ID: 6731501105'), findsOneWidget);

      // Verify Summary Text: "3 tasks remaining · 1 overdue"
      expect(find.textContaining('3 tasks remaining'), findsOneWidget);
      expect(find.textContaining('1 overdue'), findsOneWidget);

      // Verify Filter selector buttons
      expect(find.text('Pending (3)'), findsOneWidget);
      expect(find.text('Done (1)'), findsOneWidget);

      // Verify group headers: Overdue, Upcoming, No Deadline are shown; Due Today is hidden
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('No Deadline'), findsOneWidget);
      expect(find.text('Due Today'), findsNothing);

      // Verify tasks listed
      expect(find.text('PC Personal Task'), findsOneWidget);
      expect(find.text('Member Personal Task'), findsOneWidget);
      expect(find.text('No Deadline Task'), findsOneWidget);
      // Completed task not listed under Pending
      expect(find.text('Completed Personal Task'), findsNothing);

      // Switch to Done filter
      await tester.tap(find.text('Done (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Completed Personal Task'), findsOneWidget);
      expect(find.text('PC Personal Task'), findsNothing);
    });

    testWidgets('Tapping a task navigates to TaskDetailScreen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyTasksScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on 'PC Personal Task'
      await tester.tap(find.text('PC Personal Task'));
      await tester.pumpAndSettle();

      // Verify TaskDetailScreen opened with task title
      expect(find.byType(TaskDetailScreen), findsOneWidget);
      expect(find.text('PC Personal Task'), findsWidgets);
    });
  });
}

