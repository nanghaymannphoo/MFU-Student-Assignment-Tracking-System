import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/task_item.dart';
import 'package:mfu_student_workspace/models/team_member.dart';
import 'package:mfu_student_workspace/screens/projects/project_detail_screen.dart';
import 'package:mfu_student_workspace/screens/tasks/task_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget tests for the "Track Assignments" tab (PC view) of ProjectDetailScreen.
///
/// The screen reads everything from the ProjectModel we pass in, and the project is
/// NOT added to WorkspaceStore.projects, so the screen's background refresh returns
/// immediately and no API call is made. Dates: '2020-01-01' is always overdue and
/// '2099-12-31' is never overdue, so the tests do not depend on today's date.
void main() {
  const pastDate = '2020-01-01';
  const futureDate = '2099-12-31';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WorkspaceStore.clearSession();
    WorkspaceStore.currentStudentId = '6731501141';
    WorkspaceStore.currentUserName = 'Pat';
  });

  // ---------------------------------------------------------------- test data

  TeamMember pat() =>
      TeamMember(studentId: '6731501141', name: 'Pat', role: 'PC');
  TeamMember ann() =>
      TeamMember(studentId: '6731501142', name: 'Ann', role: 'MEMBER');
  TeamMember ben() =>
      TeamMember(studentId: '6731501143', name: 'Ben', role: 'MEMBER');

  /// 4 tasks: 1 done, 1 in progress, 2 todo (1 of them overdue)
  /// Pat: Setup Database (DONE), Fix Login Bug (TODO, overdue)
  /// Ann: Design ER Diagram (TODO), Write API Docs (IN_PROGRESS)
  /// Ben: no tasks
  List<TaskItem> fullTasks() => [
    TaskItem(
      id: 't1',
      title: 'Design ER Diagram',
      description: 'Draw the ERD',
      assignedTo: 'Ann',
      assignedStudentId: '6731501142',
      dueDate: futureDate,
      status: 'TODO',
    ),
    TaskItem(
      id: 't2',
      title: 'Write API Docs',
      description: 'Document endpoints',
      assignedTo: 'Ann',
      assignedStudentId: '6731501142',
      dueDate: futureDate,
      status: 'IN_PROGRESS',
    ),
    TaskItem(
      id: 't3',
      title: 'Setup Database',
      description: 'Import schema',
      assignedTo: 'Pat',
      assignedStudentId: '6731501141',
      dueDate: futureDate,
      status: 'DONE',
    ),
    TaskItem(
      id: 't4',
      title: 'Fix Login Bug',
      description: 'Token is not saved',
      assignedTo: 'Pat',
      assignedStudentId: '6731501141',
      dueDate: pastDate,
      status: 'TODO',
    ),
  ];

  ProjectModel buildProject({
    List<TeamMember>? members,
    List<TaskItem>? tasks,
  }) {
    return ProjectModel(
      id: 'p1',
      title: 'Number Project',
      courseCode: '1305204 Mobile App Dev',
      description: 'Flutter + Node.js',
      deadline: '2026-12-01',
      myRole: 'PC',
      members: members ?? [pat(), ann(), ben()],
      tasks: tasks ?? fullTasks(),
    );
  }

  // ------------------------------------------------------------------ helpers

  void setScreenSize(WidgetTester tester, {double width = 1000}) {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Open the screen as PC and switch to the Track Assignments tab
  Future<void> pumpTrack(
    WidgetTester tester,
    ProjectModel project, {
    double width = 1000,
  }) async {
    setScreenSize(tester, width: width);
    await tester.pumpWidget(
      MaterialApp(home: ProjectDetailScreen(project: project)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Track Assignments'));
    await tester.pumpAndSettle();
  }

  Future<void> openMembersTab(WidgetTester tester, int count) async {
    await tester.tap(find.text('Members ($count)'));
    await tester.pumpAndSettle();
  }

  /// The label of a filter card (All Tasks / To Do / ...). Scoped to AnimatedContainer
  /// because words like "To Do", "Completed" and "Overdue" also appear in task rows.
  Finder filterLabel(String label) => find.descendant(
    of: find.byType(AnimatedContainer),
    matching: find.text(label),
  );

  /// The whole filter card that contains this label
  Finder filterCard(String label) => find.ancestor(
    of: filterLabel(label),
    matching: find.byType(AnimatedContainer),
  );

  Future<void> tapFilter(WidgetTester tester, String label) async {
    await tester.tap(filterLabel(label));
    await tester.pumpAndSettle();
  }

  // ===================================================== Entering Track tab

  group('Track Assignments tab', () {
    // เปิดแท็บ Track แล้วเห็นหัวโปรเจกต์ ปุ่ม PC และจำนวนในแท็บย่อย Tasks/Members (เริ่มที่ Tasks)
    testWidgets('1. The Track tab shows the header and both sub-tabs with counts.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject());

      expect(find.text('Manage Team & Tasks'), findsOneWidget);
      expect(find.text('Track Assignments'), findsOneWidget);
      expect(find.byTooltip('Notify All Members'), findsOneWidget);
      expect(find.text('Number Project'), findsWidgets);
      expect(find.textContaining('Coordinator (PC)'), findsOneWidget);
      expect(find.text('1/4 Tasks Done'), findsOneWidget);
      expect(find.text('Tasks (4)'), findsOneWidget);
      expect(find.text('Members (3)'), findsOneWidget);
      // Tasks is the default sub-tab
      expect(find.text('Team Progress Overview'), findsOneWidget);
      expect(find.text('Member Workload Breakdown'), findsNothing);
    });
  });

  // ======================================================== Tasks sub-tab

  group('Tasks sub-tab', () {
    // % ความคืบหน้าและตัวเลขบนการ์ดกรองทั้ง 5 ใบต้องตรงกับข้อมูล
    testWidgets('2. Progress and the five filter cards show the correct counts.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject());

      expect(find.text('25% Completed'), findsOneWidget);

      void expectCount(String label, int count) {
        expect(
          find.descendant(
            of: filterCard(label),
            matching: find.text('$count'),
          ),
          findsOneWidget,
          reason: '$label should show $count',
        );
      }

      expectCount('All Tasks', 4);
      expectCount('To Do', 2);
      expectCount('In Progress', 1);
      expectCount('Completed', 1);
      expectCount('Overdue', 1);
    });

    // ตอนเริ่ม เลือก All Tasks อยู่ และแสดงงานครบทุกงาน
    testWidgets('3. By default All Tasks is selected and every task is listed.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject());

      expect(
        find.descendant(
          of: filterCard('All Tasks'),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(find.text('Design ER Diagram'), findsOneWidget);
      expect(find.text('Write API Docs'), findsOneWidget);
      expect(find.text('Setup Database'), findsOneWidget);
      expect(find.text('Fix Login Bug'), findsOneWidget);
    });

    // กดการ์ดกรองแต่ละใบ (To Do / In Progress / Completed / Overdue) แล้วแสดงเฉพาะงานที่ตรง
    testWidgets('4. Each filter card shows only the matching tasks.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject());

      void expectOnly(List<String> shown) {
        const all = [
          'Design ER Diagram',
          'Write API Docs',
          'Setup Database',
          'Fix Login Bug',
        ];
        for (final title in all) {
          expect(
            find.text(title),
            shown.contains(title) ? findsOneWidget : findsNothing,
            reason: title,
          );
        }
      }

      await tapFilter(tester, 'To Do');
      expectOnly(['Design ER Diagram', 'Fix Login Bug']);
      expect(
        find.descendant(
          of: filterCard('To Do'),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );

      await tapFilter(tester, 'In Progress');
      expectOnly(['Write API Docs']);

      await tapFilter(tester, 'Completed');
      expectOnly(['Setup Database']);

      await tapFilter(tester, 'Overdue');
      expectOnly(['Fix Login Bug']);
    });

    // กด Show All Tasks แล้วล้างตัวกรอง กลับมาเห็นงานทั้งหมด
    testWidgets('5. Show All Tasks clears the filter.', (tester) async {
      await pumpTrack(tester, buildProject());
      await tapFilter(tester, 'Completed');
      expect(find.text('Show All Tasks'), findsOneWidget);

      await tester.tap(find.text('Show All Tasks'));
      await tester.pumpAndSettle();

      expect(find.text('Show All Tasks'), findsNothing);
      expect(find.text('Design ER Diagram'), findsOneWidget);
      expect(find.text('Setup Database'), findsOneWidget);
    });

    // โปรเจกต์ที่ยังไม่มีงานต้องแสดงหน้าว่างพร้อมข้อความแนะนำ
    testWidgets('6. A project with no tasks shows the empty state.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject(tasks: []));

      expect(find.text('Tasks (0)'), findsOneWidget);
      expect(find.text('0% Completed'), findsOneWidget);
      expect(find.text('No Tasks in this Project'), findsOneWidget);
      expect(
        find.text(
          'Switch to the "Manage Team & Tasks" tab to create your first milestone.',
        ),
        findsOneWidget,
      );
    });

    // ตัวกรองที่ไม่มีงานต้องแสดงข้อความอธิบาย และปุ่ม View All Tasks กลับไปดูทั้งหมดได้
    testWidgets('7. An empty filter explains why and View All Tasks goes back.', (
      tester,
    ) async {
      // no DONE task and no overdue task
      final tasks = fullTasks()
        ..removeWhere((t) => t.status == 'DONE' || t.id == 't4');
      await pumpTrack(tester, buildProject(tasks: tasks));

      await tapFilter(tester, 'Overdue');
      expect(find.text('No Overdue Tasks'), findsOneWidget);
      expect(
        find.text('Great news! No tasks are currently overdue in this project.'),
        findsOneWidget,
      );

      await tapFilter(tester, 'Completed');
      expect(find.text('No Completed Tasks'), findsOneWidget);
      expect(
        find.text(
          'No tasks currently matching the selected "Completed" filter.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('View All Tasks'));
      await tester.pumpAndSettle();

      expect(find.text('No Completed Tasks'), findsNothing);
      expect(find.text('Design ER Diagram'), findsOneWidget);
    });

    // แถวงานแสดงผู้รับงาน วันส่ง และป้าย Overdue เฉพาะงานที่เลยกำหนด
    testWidgets('8. A task row shows assignee, due date and the Overdue badge.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject());

      expect(find.text('Ann'), findsNWidgets(2));
      expect(find.text('Pat'), findsNWidgets(2));
      expect(find.text(futureDate), findsNWidgets(3));
      expect(find.text(pastDate), findsOneWidget);
      // 1 filter card + 1 badge on "Fix Login Bug"
      expect(find.text('Overdue'), findsNWidgets(2));
    });

    // งานที่ Done แล้ว แม้เลยวันส่งก็ต้องไม่นับเป็น Overdue
    testWidgets('9. A done task is never marked overdue.', (tester) async {
      final tasks = [
        TaskItem(
          id: 't_done_old',
          title: 'Old Finished Task',
          description: '',
          assignedTo: 'Pat',
          assignedStudentId: '6731501141',
          dueDate: pastDate,
          status: 'DONE',
        ),
      ];
      await pumpTrack(tester, buildProject(tasks: tasks));

      expect(
        find.descendant(of: filterCard('Overdue'), matching: find.text('0')),
        findsOneWidget,
      );
      // only the filter card label, no badge on the row
      expect(find.text('Overdue'), findsOneWidget);
    });

    // PC เห็นเมนูสถานะและปุ่มลบทุกงาน และเมนูมี Extend Deadline / Delete Task
    testWidgets('10. A PC gets a status menu and a delete button on every task.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject());

      expect(find.byTooltip('Task actions & status'), findsNWidgets(4));
      expect(find.byTooltip('Delete Task'), findsNWidgets(4));

      await tester.tap(find.byTooltip('Task actions & status').first);
      await tester.pumpAndSettle();

      expect(find.text('Extend Deadline'), findsOneWidget);
      expect(find.text('Delete Task'), findsOneWidget);
      expect(find.text('In Progress'), findsWidgets);
    });

    // กดงานแล้วเปิดหน้า Task Detail
    testWidgets('11. Tapping a task opens the Task Detail screen.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject());

      await tester.tap(find.text('Design ER Diagram'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TaskDetailScreen), findsOneWidget);
    });
  });

  // ====================================================== Members sub-tab

  group('Members sub-tab', () {
    // แท็บ Members แสดงสมาชิกทุกคน พร้อมป้าย PC/Member และ Student ID
    testWidgets('12. The Members sub-tab lists every member with role and ID.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject());

      await openMembersTab(tester, 3);

      expect(find.text('Member Workload Breakdown'), findsOneWidget);
      expect(find.text('Team Progress Overview'), findsNothing);
      expect(find.text('Pat'), findsOneWidget);
      expect(find.text('Ann'), findsOneWidget);
      expect(find.text('Ben'), findsOneWidget);
      expect(find.text('ID: 6731501141'), findsOneWidget);
      expect(find.text('ID: 6731501142'), findsOneWidget);
      expect(find.text('ID: 6731501143'), findsOneWidget);
      expect(find.text('👑 PC'), findsOneWidget);
      expect(find.text('👤 Member'), findsNWidgets(2));
    });

    // ตัวเลขต่อคน (เปอร์เซ็นต์ ชิปสถานะ จำนวน Overdue) ต้องนับถูกเฉพาะงานของคนนั้น
    testWidgets('13. Each member shows their own percentage, chips and overdue count.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject());

      await openMembersTab(tester, 3);

      expect(find.text('1/2 Done (50%)'), findsOneWidget); // Pat
      expect(find.text('0/2 Done (0%)'), findsOneWidget); // Ann
      expect(find.text('0/0 Done (0%)'), findsOneWidget); // Ben

      expect(find.text('Done: 1'), findsOneWidget); // Pat
      expect(find.text('Done: 0'), findsNWidgets(2)); // Ann, Ben
      expect(find.text('In Progress: 1'), findsOneWidget); // Ann
      expect(find.text('To Do: 1'), findsNWidgets(2)); // Pat, Ann

      // "1 Overdue" appears twice: in the project header and on Pat's row
      expect(find.text('1 Overdue'), findsNWidgets(2));
      // only Pat has an "Overdue: n" chip
      expect(find.text('Overdue: 1'), findsOneWidget);
      expect(find.textContaining('Overdue: '), findsOneWidget);
    });

    // กดสมาชิกเพื่อดูงานของเขา กดซ้ำเพื่อซ่อน
    testWidgets('14. Tapping a member shows their tasks, tapping again hides them.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject());
      await openMembersTab(tester, 3);

      // hidden at first
      expect(find.text('Setup Database'), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNWidgets(3));

      await tester.tap(find.text('Pat'));
      await tester.pumpAndSettle();

      expect(find.text('Assigned Tasks (2)'), findsOneWidget);
      expect(find.text('Setup Database'), findsOneWidget);
      expect(find.text('Fix Login Bug'), findsOneWidget);
      expect(find.text('Due $pastDate'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
      expect(find.text('Design ER Diagram'), findsNothing); // Ann is still closed

      await tester.tap(find.text('Pat'));
      await tester.pumpAndSettle();

      expect(find.text('Assigned Tasks (2)'), findsNothing);
      expect(find.text('Setup Database'), findsNothing);
    });

    // เปิดหลายคนพร้อมกันได้ และคนที่ไม่มีงานแสดงข้อความว่ายังไม่มีงาน
    testWidgets('15. Several members can be open at once and an empty member says so.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject());
      await openMembersTab(tester, 3);

      await tester.tap(find.text('Pat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ann'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();

      expect(find.text('Assigned Tasks (2)'), findsNWidgets(2));
      expect(find.text('Setup Database'), findsOneWidget);
      expect(find.text('Design ER Diagram'), findsOneWidget);
      expect(
        find.text('No tasks assigned to this member yet.'),
        findsOneWidget,
      );
    });

    // จับคู่งานกับสมาชิกด้วยชื่อได้เมื่อไม่มี ID และสมาชิกที่ไม่มีชื่อแสดงเป็น Student <ID>
    testWidgets('16. Tasks match a member by name, and a nameless member shows Student <ID>.', (
      tester,
    ) async {
      final members = [
        pat(),
        ben(),
        TeamMember(
          studentId: '6731501150',
          name: '6731501150',
          role: 'MEMBER',
        ),
      ];
      final tasks = [
        TaskItem(
          id: 't_name_only',
          title: 'Prepare Slides',
          description: '',
          assignedTo: 'ben', // lower case, no student ID
          dueDate: futureDate,
          status: 'TODO',
        ),
      ];
      await pumpTrack(tester, buildProject(members: members, tasks: tasks));
      await openMembersTab(tester, 3);

      expect(find.text('Student 6731501150'), findsOneWidget);
      expect(find.text('0/1 Done (0%)'), findsOneWidget); // Ben, matched by name

      await tester.tap(find.text('Ben'));
      await tester.pumpAndSettle();

      expect(find.text('Prepare Slides'), findsOneWidget);
    });

    // กดงานที่อยู่ในรายการของสมาชิกแล้วเปิดหน้า Task Detail
    testWidgets('17. Tapping a task inside a member opens Task Detail.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject());
      await openMembersTab(tester, 3);
      await tester.tap(find.text('Ann'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Write API Docs'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TaskDetailScreen), findsOneWidget);
    });
  });

  // ================================================== Switching sub-tabs

  group('Switching tabs', () {
    // สลับแท็บแล้วตัวกรองและสมาชิกที่เปิดอยู่ไม่หาย และสลับ Manage ↔ Track ได้
    testWidgets('18. The filter and expanded members survive switching tabs.', (
      tester,
    ) async {
      await pumpTrack(tester, buildProject());
      await tapFilter(tester, 'To Do');

      await openMembersTab(tester, 3);
      await tester.tap(find.text('Pat'));
      await tester.pumpAndSettle();

      // back to Tasks: the To Do filter is still active
      await tester.tap(find.text('Tasks (4)'));
      await tester.pumpAndSettle();
      expect(find.text('Design ER Diagram'), findsOneWidget);
      expect(find.text('Fix Login Bug'), findsOneWidget);
      expect(find.text('Write API Docs'), findsNothing);
      expect(find.text('Setup Database'), findsNothing);

      // back to Members: Pat is still expanded
      await openMembersTab(tester, 3);
      expect(find.text('Assigned Tasks (2)'), findsOneWidget);

      // Manage -> Track returns to the Track tab
      await tester.tap(find.text('Tasks (4)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manage Team & Tasks'));
      await tester.pumpAndSettle();
      expect(find.text('Team Progress Overview'), findsNothing);

      await tester.tap(find.text('Track Assignments'));
      await tester.pumpAndSettle();
      expect(find.text('Team Progress Overview'), findsOneWidget);
    });
  });
}