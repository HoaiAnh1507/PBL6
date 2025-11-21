import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/main.dart' as app;
import 'package:locket_ai/views/auth/login_view.dart';
import 'package:locket_ai/views/auth/register_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('quay lại Login từ Register bằng nút back', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.byType(LoginView), findsOneWidget);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterView), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(LoginView), findsOneWidget);
  });
}