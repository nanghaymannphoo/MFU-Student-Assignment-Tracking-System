import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/controller/api_controller.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/api_models.dart';
import 'package:mfu_student_workspace/screens/auth/auth_screen.dart';
import 'package:mfu_student_workspace/screens/profile/profile_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockUserController extends Mock implements UserController {}

class MockProjectController extends Mock implements ProjectController {}

class MockAuthController extends Mock implements AuthController {}

/// Lightweight user returned by the mocked getMe (only the getters ProfileScreen reads)
class FakeUser extends Fake implements UserModel {
  @override
  final String studentId;
  @override
  final String fullName;
  @override
  final String email;

  FakeUser({
    this.studentId = '6531503001',
    this.fullName = 'Alice Test',
    this.email = 'alice@lamduan.mfu.ac.th',
  });
}

/// Only the length of the project list is used by ProfileScreen
class FakeProject extends Fake implements ProjectData {}

void main() {
  late MockUserController mockUserController;
  late MockProjectController mockProjectController;
  late MockAuthController mockAuthController;

  setUp(() {
    mockUserController = MockUserController();
    mockProjectController = MockProjectController();
    mockAuthController = MockAuthController();

    // reset the static store (user fields + projects) so tests do not leak state
    WorkspaceStore.clearSession();

    // default: profile loads successfully with 2 projects
    when(() => mockUserController.getMe()).thenAnswer((_) async => FakeUser());
    when(() => mockProjectController.getProjects())
        .thenAnswer((_) async => [FakeProject(), FakeProject()]);
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          userController: mockUserController,
          projectController: mockProjectController,
          authController: mockAuthController,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // FilledButton.icon is a private subclass, so find.byType(FilledButton) does not match it
  FilledButton saveButton(WidgetTester tester) {
    return tester.widget<FilledButton>(
      find.ancestor(
        of: find.textContaining(RegExp(r'Save Changes|Saving')),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
  }

  TextField nameField(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).at(0));
  TextField emailField(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).at(1));

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  group('Loading the profile', () {
    testWidgets(
      '1. At first, the profile page should show data loaded from the server.',
      (WidgetTester tester) async {
        await pumpProfile(tester);

        expect(find.byType(ProfileScreen), findsOne);
        expect(find.text('My Profile'), findsOne);
        expect(find.text('Student ID: 6531503001'), findsOne);
        // name appears in the header and in the text field
        expect(find.text('Alice Test'), findsNWidgets(2));
        expect(nameField(tester).controller!.text, 'Alice Test');
        expect(emailField(tester).controller!.text, 'alice@lamduan.mfu.ac.th');
        expect(WorkspaceStore.currentUserName, 'Alice Test');
        // 2 TextFields: name and email
        expect(find.byType(TextField), findsNWidgets(2));
      },
    );

    testWidgets('2. The email field should be read-only.', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      expect(emailField(tester).readOnly, isTrue);
      expect(nameField(tester).readOnly, isFalse);
      expect(find.text('Email cannot be changed'), findsOne);
    });

    testWidgets('3. The project count should come from the API.', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      verify(() => mockUserController.getMe()).called(1);
      verify(() => mockProjectController.getProjects()).called(1);
      expect(find.text('Projects'), findsOne);
      // WorkspaceStore.projects is empty after clearSession(), so My Tasks/Completed are '0'
      expect(find.text('2'), findsOne);
    });

    testWidgets(
      '4. The Save button should be disabled while the profile is loading.',
      (WidgetTester tester) async {
        final completer = Completer<UserModel>();
        when(() => mockUserController.getMe())
            .thenAnswer((_) => completer.future);

        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(
              userController: mockUserController,
              projectController: mockProjectController,
              authController: mockAuthController,
            ),
          ),
        );
        await tester.pump();
        expect(saveButton(tester).onPressed, isNull);

        completer.complete(FakeUser());
        await tester.pumpAndSettle();
        expect(saveButton(tester).onPressed, isNotNull);
      },
    );

    testWidgets(
      '5. If the token is expired (401), the login page should be shown.',
      (WidgetTester tester) async {
        when(() => mockUserController.getMe())
            .thenThrow(ApiException('Please log in again', statusCode: 401));

        await pumpProfile(tester);

        expect(find.byType(AuthScreen), findsOne);
        expect(find.byType(ProfileScreen), findsNothing);
      },
    );

    testWidgets(
      '6. If loading fails (not 401), an error message should be shown.',
      (WidgetTester tester) async {
        when(() => mockUserController.getMe())
            .thenThrow(ApiException('Connection error'));

        await pumpProfile(tester);

        expect(find.text('Connection error'), findsOne);
        expect(find.byType(ProfileScreen), findsOne);
      },
    );
  });

  group('Saving the profile', () {
    testWidgets('7. Empty name and save should show error.', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      await tester.enterText(find.byType(TextField).at(0), '   ');
      await tapVisible(tester, find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOne);
      verifyNever(
        () => mockUserController.updateMe(fullName: any(named: 'fullName')),
      );
    });

    testWidgets(
      '8. Saving without any change should show "No changes to save."',
      (WidgetTester tester) async {
        await pumpProfile(tester);

        await tapVisible(tester, find.text('Save Changes'));
        await tester.pumpAndSettle();

        expect(find.text('No changes to save.'), findsOne);
        verifyNever(
          () => mockUserController.updateMe(fullName: any(named: 'fullName')),
        );
      },
    );

    testWidgets('9. Saving a new name should call the API and show success.', (
      WidgetTester tester,
    ) async {
      when(() => mockUserController.updateMe(fullName: any(named: 'fullName')))
          .thenAnswer((_) async {});
      await pumpProfile(tester);

      // spaces around the name must be trimmed
      await tester.enterText(find.byType(TextField).at(0), '  Alice Updated  ');
      await tapVisible(tester, find.text('Save Changes'));
      await tester.pumpAndSettle();

      verify(() => mockUserController.updateMe(fullName: 'Alice Updated'))
          .called(1);
      expect(find.text('Profile details updated successfully!'), findsOne);
      expect(WorkspaceStore.currentUserName, 'Alice Updated');
    });

    testWidgets(
      '10. While saving, the button should show "Saving..." and be disabled.',
      (WidgetTester tester) async {
        final completer = Completer<void>();
        when(
          () => mockUserController.updateMe(fullName: any(named: 'fullName')),
        ).thenAnswer((_) => completer.future);
        await pumpProfile(tester);

        await tester.enterText(find.byType(TextField).at(0), 'Alice Updated');
        await tapVisible(tester, find.text('Save Changes'));
        await tester.pump(); // do not settle

        expect(find.text('Saving...'), findsOne);
        expect(saveButton(tester).onPressed, isNull);

        completer.complete();
        await tester.pumpAndSettle();
        expect(find.text('Save Changes'), findsOne);
        expect(saveButton(tester).onPressed, isNotNull);
      },
    );

    testWidgets('11. If saving fails, the error message should be shown.', (
      WidgetTester tester,
    ) async {
      when(() => mockUserController.updateMe(fullName: any(named: 'fullName')))
          .thenThrow(ApiException('Server error (500)', statusCode: 500));
      await pumpProfile(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Alice Updated');
      await tapVisible(tester, find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('Server error (500)'), findsOne);
      expect(find.byType(ProfileScreen), findsOne);
      // the name in the store must not change when saving fails
      expect(WorkspaceStore.currentUserName, 'Alice Test');
    });

    testWidgets(
      '12. If the token is expired while saving (401), the login page should be shown.',
      (WidgetTester tester) async {
        when(
          () => mockUserController.updateMe(fullName: any(named: 'fullName')),
        ).thenThrow(ApiException('Please log in again', statusCode: 401));
        await pumpProfile(tester);

        await tester.enterText(find.byType(TextField).at(0), 'Alice Updated');
        await tapVisible(tester, find.text('Save Changes'));
        await tester.pumpAndSettle();

        expect(find.byType(AuthScreen), findsOne);
      },
    );
  });

  group('Logging out', () {
    // the dialog also has a "Log Out" button, so look for it inside the AlertDialog
    final dialogLogout = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Log Out'),
    );

    testWidgets('13. Tapping Log Out should show a confirmation dialog.', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      await tapVisible(tester, find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOne);
      expect(find.text('Log Out?'), findsOne);
      expect(
        find.text('Are you sure you want to log out of your workspace?'),
        findsOne,
      );
    });

    testWidgets('14. Cancel in the dialog should stay on the profile page.', (
      WidgetTester tester,
    ) async {
      await pumpProfile(tester);

      await tapVisible(tester, find.text('Log Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ProfileScreen), findsOne);
      verifyNever(() => mockAuthController.logout());
    });

    testWidgets(
      '15. Confirming log out should call logout and show the login page.',
      (WidgetTester tester) async {
        when(() => mockAuthController.logout()).thenAnswer((_) async {});
        await pumpProfile(tester);

        await tapVisible(tester, find.text('Log Out'));
        await tester.pumpAndSettle();
        await tester.tap(dialogLogout);
        await tester.pumpAndSettle();

        verify(() => mockAuthController.logout()).called(1);
        expect(find.byType(AuthScreen), findsOne);
        expect(find.byType(ProfileScreen), findsNothing);
      },
    );
  });
}
