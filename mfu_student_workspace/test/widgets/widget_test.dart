import 'package:flutter_test/flutter_test.dart';
import 'package:mfu_student_workspace/app/mfu_workspace_app.dart';

void main() {
  testWidgets('Workspace app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MfuWorkspaceApp());
    expect(find.byType(MfuWorkspaceApp), findsOneWidget);
  });
}
