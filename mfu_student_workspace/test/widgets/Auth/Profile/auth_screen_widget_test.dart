import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfu_student_workspace/controller/api_controller.dart';
import 'package:mfu_student_workspace/data/workspace_store.dart';
import 'package:mfu_student_workspace/models/api_models.dart';
import 'package:mfu_student_workspace/navigation/main_navigation_shell.dart';
import 'package:mfu_student_workspace/screens/auth/auth_screen.dart';
import 'package:mfu_student_workspace/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthController extends Mock implements AuthController {}

/// Lightweight user returned by the mocked login (only the getters AuthScreen reads)
class FakeUser extends Fake implements UserModel {
  @override
  final String studentId;
  @override
  final String fullName;
  @override
  final String email;

  FakeUser({
    this.studentId = '6531503001',
    this.fullName = 'Test User',
    this.email = 'test@lamduan.mfu.ac.th',
  });
}

void main() {
  late MockAuthController mockAuthController;

  setUp(() {
    mockAuthController = MockAuthController();
    SharedPreferences.setMockInitialValues({});
    // reset the static store (user fields + projects) so tests do not leak state
    WorkspaceStore.clearSession();
  });

  Future<void> pumpAuthScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AuthScreen(authController: mockAuthController)),
    );
    await tester.pumpAndSettle();
  }

  // Login form: index 0 = Student ID, index 1 = Password
  Future<void> fillLogin(WidgetTester tester, String id, String pw) async {
    await tester.enterText(find.byType(TextField).at(0), id);
    await tester.enterText(find.byType(TextField).at(1), pw);
  }

  // Sign Up form: 0 = Full name, 1 = Student ID, 2 = Email, 3 = Password, 4 = Confirm
  Future<void> openSignUp(WidgetTester tester) async {
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
  }

  Finder submitButton(String label) => find.widgetWithText(FilledButton, label);

  Future<void> tapSubmit(WidgetTester tester, String label) async {
    final button = submitButton(label);
    await tester.ensureVisible(button);
    await tester.tap(button);
  }

  group('Login mode', () {
    testWidgets('1. At first, the login page should be shown.', (
      WidgetTester tester,
    ) async {
      await pumpAuthScreen(tester);

      expect(find.byType(AuthScreen), findsOne);
      // 2 TextFields: student id and password
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Log In to Workspace'), findsOne);
      expect(find.text('Create Account'), findsNothing);
    });

    testWidgets(
      '2. In the login page, empty input and login should show validation errors.',
      (WidgetTester tester) async {
        await pumpAuthScreen(tester);

        await tapSubmit(tester, 'Log In to Workspace');
        await tester.pumpAndSettle();

        expect(find.text('Please enter your student ID'), findsOne);
        expect(find.text('Please enter your password'), findsOne);
        verifyNever(() => mockAuthController.login(any(), any()));
      },
    );

    testWidgets(
      '3. In the login page, student ID that is not 10 digits should show error.',
      (WidgetTester tester) async {
        await pumpAuthScreen(tester);

        await fillLogin(tester, '12345', 'password');
        await tapSubmit(tester, 'Log In to Workspace');
        await tester.pumpAndSettle();

        expect(find.text('Student ID must be exactly 10 digits'), findsOne);
        verifyNever(() => mockAuthController.login(any(), any()));
      },
    );

    testWidgets(
      '4. In the login page, wrong input and login should show error.',
      (WidgetTester tester) async {
        // mocked login method, wrong login
        when(() => mockAuthController.login(any(), any()))
            .thenAnswer((_) async => null);
        await pumpAuthScreen(tester);

        await fillLogin(tester, '6531503001', 'wrongpass');
        await tapSubmit(tester, 'Log In to Workspace');
        await tester.pumpAndSettle();

        expect(find.text('Student ID or password is incorrect.'), findsOne);
        // still on the login page
        expect(find.byType(AuthScreen), findsOne);
        expect(find.byType(MainNavigationShell), findsNothing);
      },
    );

    testWidgets(
      '5. In the login page, server error should show the error message.',
      (WidgetTester tester) async {
        when(() => mockAuthController.login(any(), any()))
            .thenThrow(ApiException('Connection error'));
        await pumpAuthScreen(tester);

        await fillLogin(tester, '6531503001', 'password');
        await tapSubmit(tester, 'Log In to Workspace');
        await tester.pumpAndSettle();

        expect(find.text('Connection error'), findsOne);
        expect(find.byType(AuthScreen), findsOne);
      },
    );

    testWidgets(
      '6. In the login page, while logging in should show a loading indicator.',
      (WidgetTester tester) async {
        final completer = Completer<UserModel?>();
        when(() => mockAuthController.login(any(), any()))
            .thenAnswer((_) => completer.future);
        await pumpAuthScreen(tester);

        await fillLogin(tester, '6531503001', 'password');
        await tapSubmit(tester, 'Log In to Workspace');
        await tester.pump(); // start the request, do not settle

        expect(find.byType(CircularProgressIndicator), findsOne);
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull); // button disabled while loading

        // finish the request (wrong login)
        completer.complete(null);
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      '7. In the login page, correct login should show the main page and keep the user.',
      (WidgetTester tester) async {
        await http.runWithClient(
          () async {
            when(() => mockAuthController.login(any(), any()))
                .thenAnswer((_) async {
                  await AuthService().saveToken('test-token');
                  return FakeUser();
                });
            await pumpAuthScreen(tester);

            await fillLogin(tester, ' 6531503001 ', 'password');
            await tapSubmit(tester, 'Log In to Workspace');
            await tester.pumpAndSettle();

            verify(() => mockAuthController.login('6531503001', 'password'))
                .called(1);
            expect(WorkspaceStore.currentStudentId, '6531503001');
            expect(WorkspaceStore.currentUserName, 'Test User');
            expect(WorkspaceStore.currentEmail, 'test@lamduan.mfu.ac.th');
            expect(find.byType(MainNavigationShell), findsOne);
            expect(find.byType(AuthScreen), findsNothing);
          },
          () => MockClient(
            (_) async => http.Response('{"message":"test API response"}', 500),
          ),
        );
      },
    );

    testWidgets(
      '8. In the login page, tapping the eye icon should show/hide the password.',
      (WidgetTester tester) async {
        await pumpAuthScreen(tester);

        EditableText passwordField() =>
            tester.widget<EditableText>(find.byType(EditableText).at(1));

        expect(passwordField().obscureText, isTrue);

        await tester.tap(find.byIcon(Icons.visibility_off_outlined));
        await tester.pumpAndSettle();
        expect(passwordField().obscureText, isFalse);

        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pumpAndSettle();
        expect(passwordField().obscureText, isTrue);
      },
    );
  });

  group('Sign Up mode', () {
    testWidgets('9. Tapping Sign Up should show the registration form.', (
      WidgetTester tester,
    ) async {
      await pumpAuthScreen(tester);
      await openSignUp(tester);

      // full name, student id, email, password, confirm password
      expect(find.byType(TextField), findsNWidgets(5));
      expect(find.text('Create Account'), findsOne);
      expect(find.text('Confirm Password'), findsOne);
      expect(find.text('Log In to Workspace'), findsNothing);
    });

    testWidgets(
      '10. In the sign up page, invalid email and short password should show errors.',
      (WidgetTester tester) async {
        await pumpAuthScreen(tester);
        await openSignUp(tester);

        await tester.enterText(find.byType(TextField).at(0), 'Test User');
        await tester.enterText(find.byType(TextField).at(1), '6531503001');
        await tester.enterText(find.byType(TextField).at(2), 'test@gmail.com');
        await tester.enterText(find.byType(TextField).at(3), '123');
        await tester.enterText(find.byType(TextField).at(4), '123');
        await tapSubmit(tester, 'Create Account');
        await tester.pumpAndSettle();

        expect(find.text('Must end with @lamduan.mfu.ac.th'), findsOne);
        expect(find.text('Password must be at least 6 characters'), findsOne);
        verifyNever(
          () => mockAuthController.register(
            studentId: any(named: 'studentId'),
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    testWidgets(
      '11. In the sign up page, different passwords should show error.',
      (WidgetTester tester) async {
        await pumpAuthScreen(tester);
        await openSignUp(tester);

        await tester.enterText(find.byType(TextField).at(0), 'Test User');
        await tester.enterText(find.byType(TextField).at(1), '6531503001');
        await tester.enterText(
          find.byType(TextField).at(2),
          'test@lamduan.mfu.ac.th',
        );
        await tester.enterText(find.byType(TextField).at(3), 'password1');
        await tester.enterText(find.byType(TextField).at(4), 'password2');
        await tapSubmit(tester, 'Create Account');
        await tester.pumpAndSettle();

        expect(find.text('Passwords do not match'), findsOne);
        verifyNever(
          () => mockAuthController.register(
            studentId: any(named: 'studentId'),
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    testWidgets(
      '12. In the sign up page, correct input should register and go back to login.',
      (WidgetTester tester) async {
        when(
          () => mockAuthController.register(
            studentId: any(named: 'studentId'),
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async {});
        await pumpAuthScreen(tester);
        await openSignUp(tester);

        await tester.enterText(find.byType(TextField).at(0), 'Test User');
        await tester.enterText(find.byType(TextField).at(1), '6531503001');
        await tester.enterText(
          find.byType(TextField).at(2),
          'test@lamduan.mfu.ac.th',
        );
        await tester.enterText(find.byType(TextField).at(3), 'password123');
        await tester.enterText(find.byType(TextField).at(4), 'password123');
        await tapSubmit(tester, 'Create Account');
        await tester.pumpAndSettle();

        verify(
          () => mockAuthController.register(
            studentId: '6531503001',
            fullName: 'Test User',
            email: 'test@lamduan.mfu.ac.th',
            password: 'password123',
          ),
        ).called(1);
        expect(
          find.text('Account created successfully! You can now log in.'),
          findsOne,
        );
        // switched back to login mode
        expect(find.text('Log In to Workspace'), findsOne);
        expect(find.byType(TextField), findsNWidgets(2));
      },
    );

    testWidgets(
      '13. In the sign up page, duplicated account should show the server error.',
      (WidgetTester tester) async {
        when(
          () => mockAuthController.register(
            studentId: any(named: 'studentId'),
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          ApiException('Student ID or email already exists', statusCode: 409),
        );
        await pumpAuthScreen(tester);
        await openSignUp(tester);

        await tester.enterText(find.byType(TextField).at(0), 'Test User');
        await tester.enterText(find.byType(TextField).at(1), '6531503001');
        await tester.enterText(
          find.byType(TextField).at(2),
          'test@lamduan.mfu.ac.th',
        );
        await tester.enterText(find.byType(TextField).at(3), 'password123');
        await tester.enterText(find.byType(TextField).at(4), 'password123');
        await tapSubmit(tester, 'Create Account');
        await tester.pumpAndSettle();

        expect(find.text('Student ID or email already exists'), findsOne);
        // stays on the sign up form
        expect(find.text('Create Account'), findsOne);
      },
    );
  });
}
