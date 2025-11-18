import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:locket_ai/views/settings/settings_view.dart';
import 'package:locket_ai/views/auth/login_view.dart';
import 'package:locket_ai/viewmodels/auth_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/viewmodels/chat_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

class TestAuthVM extends AuthViewModel {
  TestAuthVM() : super(userViewModel: UserViewModel());
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Logout navigates immediately to LoginView', (tester) async {
    final authVM = TestAuthVM();
    final userVM = UserViewModel();
    final feedVM = FeedViewModel();
    final friendshipVM = FriendshipViewModel();
    final chatVM = ChatViewModel();

    final u = User(
      userId: 'u1',
      phoneNumber: '',
      username: 'tester',
      email: 't@example.com',
      fullName: 'Tester',
      profilePictureUrl: null,
      passwordHash: '',
      subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null,
      accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    authVM.updateCurrentUser(u);
    authVM.setJwtToken('jwt');
    feedVM.setDependencies(userVM, friendshipVM);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
          ChangeNotifierProvider<UserViewModel>.value(value: userVM),
          ChangeNotifierProvider<FeedViewModel>.value(value: feedVM),
          ChangeNotifierProvider<FriendshipViewModel>.value(value: friendshipVM),
          ChangeNotifierProvider<ChatViewModel>.value(value: chatVM),
        ],
        child: const MaterialApp(home: SettingsView()),
      ),
    );

    expect(find.text('Log Out'), findsOneWidget);
    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginView), findsOneWidget);
    expect(find.text('No user logged in.'), findsNothing);
  });
}