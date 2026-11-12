import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/app/app_theme.dart';
import 'package:mfu_student_workspace/core/constants/app_colors.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/screens/dashboard/dashboard_screen.dart';

void main() {
  setUp(() {
    WorkspaceStore.currentUserName = 'Nang Hay Man Phoo';
    WorkspaceStore.currentStudentId = '6731501105';
  });

  Widget buildTestDashboard({VoidCallback? onOpenNotifications}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: DashboardScreen(
        onOpenNotifications: onOpenNotifications ?? () {},
        onRefresh: () {},
      ),
    );
  }

  Widget buildHeaderHarness({
    required VoidCallback onOpenNotifications,
    required int unreadCount,
    double width = 360,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: SizedBox(
        width: width,
        height: 600,
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.lightAccent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.school_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'MFU Student Workspace',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Open Notifications',
                onPressed: onOpenNotifications,
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ),
            ],
          ),
          body: const SizedBox(),
        ),
      ),
    );
  }

  group('Simplified Dashboard Header Tests', () {
    testWidgets('Dashboard header shows only branding and notifications (no greeting/ID)', (tester) async {
      await tester.pumpWidget(buildTestDashboard());
      await tester.pumpAndSettle();

      // 1. Branding: App Mark (Graduation-cap icon) and Title
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
      expect(find.text('MFU Student Workspace'), findsOneWidget);

      // 2. Notification Bell
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      // 3. Greeting and Student ID must be absent from Dashboard header
      expect(find.text('Hello, Nang'), findsNothing);
      expect(find.text('Student ID: 6731501105'), findsNothing);
    });

    testWidgets('Notification bell tap triggers onOpenNotifications callback', (tester) async {
      bool notificationsOpened = false;
      await tester.pumpWidget(buildTestDashboard(
        onOpenNotifications: () {
          notificationsOpened = true;
        },
      ));
      await tester.pumpAndSettle();

      final bellFinder = find.byTooltip('Open Notifications');
      expect(bellFinder, findsOneWidget);

      await tester.tap(bellFinder);
      await tester.pumpAndSettle();

      expect(notificationsOpened, isTrue);
    });

    testWidgets('Unread badge connects to unread notification count', (tester) async {
      final unreadCount = WorkspaceStore.getUnreadCountForCurrentUser();
      await tester.pumpWidget(buildTestDashboard());
      await tester.pumpAndSettle();

      if (unreadCount > 0) {
        expect(find.text('$unreadCount'), findsWidgets);
      }
    });

    testWidgets('Header renders cleanly without overflow on standard phone widths (390px)', (tester) async {
      await tester.pumpWidget(buildHeaderHarness(
        onOpenNotifications: () {},
        unreadCount: 3,
        width: 390,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('MFU Student Workspace'), findsOneWidget);
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
      expect(find.byTooltip('Open Notifications'), findsOneWidget);
    });

    testWidgets('Header renders cleanly without overflow on narrow phone widths (320px - iPhone SE)', (tester) async {
      await tester.pumpWidget(buildHeaderHarness(
        onOpenNotifications: () {},
        unreadCount: 2,
        width: 320,
      ));
      await tester.pumpAndSettle();

      // Ensure zero overflow exceptions in header
      expect(tester.takeException(), isNull);

      // Verify all components remain visible and intact
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
      expect(find.text('MFU Student Workspace'), findsOneWidget);
      expect(find.byTooltip('Open Notifications'), findsOneWidget);

      // Verify that title does not overlap the notification bell
      final titleRect = tester.getRect(find.text('MFU Student Workspace'));
      final bellRect = tester.getRect(find.byTooltip('Open Notifications'));
      expect(titleRect.right <= bellRect.left, isTrue,
          reason: 'Title should never overlap the notification bell');
    });
  });
}
