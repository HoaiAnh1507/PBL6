import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:locket_ai/views/auth/register_view.dart';
import 'package:locket_ai/viewmodels/auth_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';

class TestAuthVM extends AuthViewModel {
  TestAuthVM() : super(userViewModel: UserViewModel());
  @override
  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String email,
  }) async {
    return true;
  }
  @override
  Future<bool> requestOtpForEmail(String email) async {
    return true;
  }
}

void main() {
  testWidgets('RegisterView proceeds to OTP step after successful Sign Up', (tester) async {
    final authVM = TestAuthVM();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthViewModel>.value(
        value: authVM,
        child: const MaterialApp(home: RegisterView()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'user');
    await tester.enterText(find.byType(TextFormField).at(1), 'Full Name');
    await tester.enterText(find.byType(TextFormField).at(2), '0123456789');
    await tester.enterText(find.byType(TextFormField).at(3), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(4), 'P@ssw0rd');

    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text('Resend OTP'), findsOneWidget);
    expect(find.text('Verify & Continue'), findsOneWidget);
  });
}