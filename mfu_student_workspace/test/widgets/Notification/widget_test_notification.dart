import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mfu_student_workspace/core/constants/app_colors.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/app_notification.dart';
import 'package:mfu_student_workspace/models/project_model.dart';
import 'package:mfu_student_workspace/models/task_item.dart';
import 'package:mfu_student_workspace/models/team_member.dart';
import 'package:mfu_student_workspace/screens/notifications/notifications_screen.dart';
import 'package:mfu_student_workspace/screens/projects/project_detail_screen.dart';
import 'package:mfu_student_workspace/screens/tasks/task_detail_screen.dart';

const myId = '6731501140';

// count how many times the screen asks the parent to refresh
int refreshCount = 0;

// notifications are local (isLocal) by default so that read / delete
// do not call the server
AppNotification makeNotification({
  required String id,
  String type = 'COMMENT',
  String title = 'Title',
  String message = 'Message',
  bool isRead = false,
  bool isLocal = true,
  String recipient = myId,
  String? projectId,
  String? taskId,
  String? projectName,
  String? taskTitle,
}) {
  return AppNotification(
    id: id,
    eventId: id,
    type: type,
    title: title,
    message: message,
    recipientStudentId: recipient,
    actorStudentId: 'SYSTEM',
    projectId: projectId,
    taskId: taskId,
    projectName: projectName,
    taskTitle: taskTitle,
    createdAt: DateTime.now(),
    isRead: isRead,
    isLocal: isLocal,
  );
}

ProjectModel makeProject({
  String id = 'p1',
  List<TeamMember>? members,
  List<TaskItem>? tasks,
}) {
  return ProjectModel(
    id: id,
    title: 'Mobile App',
    courseCode: 'CS101',
    description: 'Project description',
    deadline: '2026-12-31',
    myRole: 'MEMBER',
    members: members ??
        [TeamMember(studentId: myId, name: 'Puttapoom', role: 'MEMBER')],
    tasks: tasks ?? [],
  );
}

// the screen has its own Scaffold, so only MaterialApp is needed
Widget buildScreen() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: NotificationsScreen(onRefresh: () => refreshCount++),
  );
}

// unread dot is the 7x7 circle at the end of the title row
Finder unreadDotFinder() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Container &&
        widget.constraints == BoxConstraints.tightFor(width: 7, height: 7),
  );
}

// "Mark all as read" is a TextButton.icon
Finder markAllButtonFinder() {
  return find.byWidgetPredicate((widget) => widget is TextButton);
}

void main() {
  setUp(() {
    // no token saved, so every API call fails with 'Please log in again'
    SharedPreferences.setMockInitialValues({});
    WorkspaceStore.clearSession();
    WorkspaceStore.currentStudentId = myId;
    refreshCount = 0;
  });

  testWidgets('1. Launch with no notification should show the empty state', (
    tester,
  ) async {
    // Build the widget.
    await tester.pumpWidget(buildScreen());

    // Expect to find the empty state and zero counts.
    expect(find.text('Notifications'), findsOne);
    expect(find.text('No Notifications Yet'), findsOne);
    expect(find.text('All (0)'), findsOne);
    expect(find.text('Unread (0)'), findsOne);
    expect(find.byType(Card), findsNothing);

    // Mark all as read is disabled when nothing is unread.
    final button = tester.widget<TextButton>(markAllButtonFinder());
    expect(button.onPressed, isNull);
  });

  testWidgets('2. Launch with notifications should show the cards', (
    tester,
  ) async {
    // add two unread and one read notification
    WorkspaceStore.notifications = [
      makeNotification(
        id: 'n1',
        title: 'New comment',
        message: 'Alice commented on your task',
        projectName: 'Mobile App',
        taskTitle: 'Design UI',
      ),
      makeNotification(id: 'n2', title: 'Task assigned'),
      makeNotification(id: 'n3', title: 'Old news', isRead: true),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());

    // Expect to find three cards and the counts.
    expect(find.byType(Card), findsNWidgets(3));
    expect(find.text('All (3)'), findsOne);
    expect(find.text('Unread (2)'), findsOne);

    // Expect to find the content of the first card.
    expect(find.text('New comment'), findsOne);
    expect(find.text('Alice commented on your task'), findsOne);
    expect(find.text('Mobile App • Design UI'), findsOne);
    expect(find.text('Just now'), findsNWidgets(3));

    // only unread notifications have the dot
    expect(unreadDotFinder(), findsNWidgets(2));
    expect(find.text('No Notifications Yet'), findsNothing);
  });

  testWidgets('3. Each notification type should show its own icon', (
    tester,
  ) async {
    // make the screen tall enough to build every card
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // add one notification for each type
    final types = [
      'COMMENT',
      'TASK_ASSIGNED',
      'SUBMISSION',
      'STATUS_CHANGED',
      'DEADLINE_EXTENDED',
      'OVERDUE',
      'ANNOUNCEMENT',
      'UNKNOWN',
    ];
    WorkspaceStore.notifications = [
      for (int i = 0; i < types.length; i++)
        makeNotification(id: 'n$i', type: types[i], title: 'Title $i'),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());

    // Expect to find the icon of each type.
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOne);
    expect(find.byIcon(Icons.assignment_ind_outlined), findsOne);
    expect(find.byIcon(Icons.cloud_done_outlined), findsOne);
    expect(find.byIcon(Icons.sync_rounded), findsOne);
    expect(find.byIcon(Icons.event_repeat_rounded), findsOne);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOne);
    expect(find.byIcon(Icons.campaign_outlined), findsOne);
    // unknown type uses the default icon
    expect(find.byIcon(Icons.notifications_none_rounded), findsOne);
  });

  testWidgets('4. Overdue notification should show the title in red', (
    tester,
  ) async {
    WorkspaceStore.notifications = [
      makeNotification(id: 'n1', type: 'OVERDUE', title: 'Overdue Task Alert'),
      makeNotification(id: 'n2', type: 'COMMENT', title: 'New comment'),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());

    // the overdue title uses the danger color
    Finder overdueFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == 'Overdue Task Alert' &&
          widget.style?.color == AppColors.danger,
    );
    expect(overdueFinder, findsOne);

    // the normal title uses the primary text color
    Finder normalFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == 'New comment' &&
          widget.style?.color == AppColors.textPrimary,
    );
    expect(normalFinder, findsOne);
  });

  testWidgets('5. Local notification of another user should be hidden', (
    tester,
  ) async {
    WorkspaceStore.notifications = [
      makeNotification(id: 'n1', title: 'Mine'),
      makeNotification(id: 'n2', title: 'Not mine', recipient: '6731501999'),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());

    // Expect to find only my notification.
    expect(find.text('Mine'), findsOne);
    expect(find.text('Not mine'), findsNothing);
    expect(find.text('All (1)'), findsOne);
  });

  testWidgets('6. Tap the Unread chip should show only unread notifications', (
    tester,
  ) async {
    WorkspaceStore.notifications = [
      makeNotification(id: 'n1', title: 'Unread one'),
      makeNotification(id: 'n2', title: 'Read one', isRead: true),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());
    expect(find.byType(Card), findsNWidgets(2));

    // Click the unread chip
    await tester.tap(find.text('Unread (1)'));
    await tester.pump();

    // Expect to find only the unread one.
    expect(find.byType(Card), findsOne);
    expect(find.text('Unread one'), findsOne);
    expect(find.text('Read one'), findsNothing);

    // Click the all chip, both are shown again
    await tester.tap(find.text('All (2)'));
    await tester.pump();
    expect(find.byType(Card), findsNWidgets(2));
    expect(find.text('Read one'), findsOne);
  });

  testWidgets('7. Unread filter with all read should show the caught up state', (
    tester,
  ) async {
    WorkspaceStore.notifications = [
      makeNotification(id: 'n1', title: 'Read one', isRead: true),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());

    // Click the unread chip
    await tester.tap(find.text('Unread (0)'));
    await tester.pump();

    // Expect to find the empty state of the unread tab.
    expect(find.text('No Unread Notifications'), findsOne);
    expect(find.text('No Notifications Yet'), findsNothing);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('8. Tap a notification should mark it as read', (tester) async {
    WorkspaceStore.notifications = [
      makeNotification(id: 'n1', title: 'New comment'),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());
    expect(find.text('Unread (1)'), findsOne);
    expect(unreadDotFinder(), findsOne);

    // Click the notification (no linked project, so no navigation)
    await tester.tap(find.text('New comment'));
    await tester.pump();

    // Expect the unread count and the dot to disappear.
    expect(find.text('Unread (0)'), findsOne);
    expect(unreadDotFinder(), findsNothing);
    expect(WorkspaceStore.notifications[0].isRead, isTrue);
    // the parent is asked to refresh the badge
    expect(refreshCount, 1);
  });

  testWidgets('9. Tap the delete icon should remove the notification', (
    tester,
  ) async {
    WorkspaceStore.notifications = [
      makeNotification(id: 'n1', title: 'Delete me'),
      makeNotification(id: 'n2', title: 'Keep me'),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());
    expect(find.byType(Card), findsNWidgets(2));

    // Click the delete icon of the first card
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    // Wait for the async delete, then rebuild
    await tester.pump();
    await tester.pump();

    // Expect only the second one and the snackbar.
    expect(find.text('Delete me'), findsNothing);
    expect(find.text('Keep me'), findsOne);
    expect(find.byType(Card), findsOne);
    expect(find.text('All (1)'), findsOne);
    expect(find.text('Notification deleted'), findsOne);
    expect(WorkspaceStore.notifications.length, 1);
    expect(refreshCount, 1);
  });

  testWidgets('10. Mark all as read without login should show the error', (
    tester,
  ) async {
    WorkspaceStore.notifications = [
      makeNotification(id: 'n1', title: 'New comment'),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());

    // the button is enabled when there is an unread notification
    final button = tester.widget<TextButton>(markAllButtonFinder());
    expect(button.onPressed, isNotNull);

    // Click mark all as read
    await tester.tap(find.text('Mark all as read'));
    await tester.pump();
    await tester.pump();

    // Expect the error snackbar and nothing changed.
    expect(find.text('Please log in again'), findsOne);
    expect(find.text('All notifications marked as read'), findsNothing);
    expect(find.text('Unread (1)'), findsOne);
    expect(WorkspaceStore.notifications[0].isRead, isFalse);
  });

  testWidgets('11. Click the refresh icon should show the error and refresh', (
    tester,
  ) async {
    WorkspaceStore.notifications = [
      makeNotification(id: 'n1', title: 'New comment'),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());

    // Click the refresh icon
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pump();
    await tester.pump();

    // Expect the error snackbar, the local list stays and the parent refreshes.
    expect(find.text('Please log in again'), findsOne);
    expect(find.text('New comment'), findsOne);
    expect(refreshCount, 1);
  });

  testWidgets('12. Tap a notification of a missing project should show a message', (
    tester,
  ) async {
    WorkspaceStore.projects = [];
    WorkspaceStore.notifications = [
      makeNotification(id: 'n1', title: 'Project update', projectId: 'p99'),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());

    // Click the notification
    await tester.tap(find.text('Project update'));
    await tester.pump();

    // Expect to stay on this page with the message.
    expect(find.text('This project is no longer available.'), findsOne);
    expect(find.byType(NotificationsScreen), findsOne);
    expect(find.byType(ProjectDetailScreen), findsNothing);
  });

  testWidgets('13. Tap a notification without project access should show a message', (
    tester,
  ) async {
    // I am not a member of this project
    WorkspaceStore.projects = [
      makeProject(
        members: [
          TeamMember(studentId: '6731501999', name: 'Other', role: 'PC'),
        ],
      ),
    ];
    WorkspaceStore.notifications = [
      makeNotification(id: 'n1', title: 'Project update', projectId: 'p1'),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());

    // Click the notification
    await tester.tap(find.text('Project update'));
    await tester.pump();

    // Expect to stay on this page with the message.
    expect(find.text('You no longer have access to this project.'), findsOne);
    expect(find.byType(ProjectDetailScreen), findsNothing);
  });

  testWidgets('14. Tap a notification of a deleted task should show a message', (
    tester,
  ) async {
    // the project has no task t99 (the API refresh fails, local data is used)
    WorkspaceStore.projects = [makeProject()];
    WorkspaceStore.notifications = [
      makeNotification(
        id: 'n1',
        title: 'Task update',
        projectId: 'p1',
        taskId: 't99',
      ),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());

    // Click the notification and wait for the refresh
    await tester.tap(find.text('Task update'));
    await tester.pump();
    await tester.pump();

    // Expect to stay on this page with the message.
    expect(
      find.text('This task has been deleted or is no longer available.'),
      findsOne,
    );
    expect(find.byType(TaskDetailScreen), findsNothing);
  });

  testWidgets('15. Tap a task notification should navigate to the task detail', (
    tester,
  ) async {
    // the project has the task t1
    WorkspaceStore.projects = [
      makeProject(
        tasks: [
          TaskItem(
            id: 't1',
            title: 'Design UI',
            description: 'Design the login page',
            assignedTo: 'Puttapoom',
            assignedStudentId: myId,
            dueDate: '2026-12-31',
          ),
        ],
      ),
    ];
    WorkspaceStore.notifications = [
      makeNotification(
        id: 'n1',
        type: 'TASK_ASSIGNED',
        title: 'Task assigned',
        projectId: 'p1',
        taskId: 't1',
      ),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());

    // Click the notification
    await tester.tap(find.text('Task assigned'));
    // Wait until the navigation done
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Expect to find the task detail page.
    expect(find.byType(TaskDetailScreen), findsOne);
    expect(find.text('Task Details'), findsOne);
    // and it is marked as read
    expect(WorkspaceStore.notifications[0].isRead, isTrue);
  });

  testWidgets('16. Tap a project notification should navigate to the project detail', (
    tester,
  ) async {
    // the notification has no taskId, so it opens the project
    WorkspaceStore.projects = [makeProject()];
    WorkspaceStore.notifications = [
      makeNotification(
        id: 'n1',
        type: 'ANNOUNCEMENT',
        title: 'Announcement',
        projectId: 'p1',
      ),
    ];

    // Build the widget.
    await tester.pumpWidget(buildScreen());

    // Click the notification
    await tester.tap(find.text('Announcement'));
    // Wait until the navigation done
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Expect to find the project detail page.
    expect(find.byType(ProjectDetailScreen), findsOne);
    expect(find.byType(TaskDetailScreen), findsNothing);
  });
}
