import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:locket_ai/app/app.dart';
import 'package:locket_ai/views/auth/login_view.dart';
import 'package:locket_ai/views/main_view.dart';
import 'package:locket_ai/viewmodels/auth_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/viewmodels/chat_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  group('LocketApp routes base on authentication state', () {
    testWidgets('Show LoginView before log in', (tester) async {
      final userVM = UserViewModel();
      final friendshipVM = FriendshipViewModel();
      final feedVM = FeedViewModel()..setDependencies(userVM, friendshipVM);
      final chatVM = ChatViewModel()..setDependencies(userVM, friendshipVM);
      final authVM = AuthViewModel(userViewModel: userVM);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserViewModel>.value(value: userVM),
            ChangeNotifierProvider<FriendshipViewModel>.value(value: friendshipVM),
            ChangeNotifierProvider<FeedViewModel>.value(value: feedVM),
            ChangeNotifierProvider<ChatViewModel>.value(value: chatVM),
            ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
          ],
          child: const LocketApp(),
        ),
      );

      expect(find.byType(LoginView), findsOneWidget);
      expect(find.byType(MainView), findsNothing);
    });

    testWidgets('Show MainView after logged in', (tester) async {
      final userVM = UserViewModel();
      final friendshipVM = FriendshipViewModel();
      final feedVM = FeedViewModel()..setDependencies(userVM, friendshipVM);
      final chatVM = ChatViewModel()..setDependencies(userVM, friendshipVM);
      final authVM = AuthViewModel(userViewModel: userVM);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserViewModel>.value(value: userVM),
            ChangeNotifierProvider<FriendshipViewModel>.value(value: friendshipVM),
            ChangeNotifierProvider<FeedViewModel>.value(value: feedVM),
            ChangeNotifierProvider<ChatViewModel>.value(value: chatVM),
            ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
          ],
          child: const LocketApp(),
        ),
      );

      final user = User(
        userId: 'u1',
        phoneNumber: '0123456789',
        username: 'tester',
        email: 'tester@example.com',
        fullName: 'Tester',
        profilePictureUrl: null,
        passwordHash: 'hash',
        subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null,
        accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      authVM.updateCurrentUser(user);
      await tester.pump();

      expect(find.byType(MainView), findsOneWidget);
      expect(find.byType(LoginView), findsNothing);
    });
  });
}