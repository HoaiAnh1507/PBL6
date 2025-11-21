import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/main.dart' as app;
import 'package:locket_ai/views/auth/login_view.dart';
import 'package:locket_ai/views/auth/register_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('khởi động ứng dụng hiển thị màn hình đăng nhập', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    expect(find.byType(LoginView), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });

  testWidgets('chuyển sang màn hình đăng ký khi bấm Create an account', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterView), findsOneWidget);
    expect(find.text('Sign Up'), findsWidgets);
  });
}