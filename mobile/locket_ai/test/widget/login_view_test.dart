import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:locket_ai/views/auth/login_view.dart';
import 'package:locket_ai/views/main_view.dart';
import 'package:locket_ai/viewmodels/auth_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/viewmodels/chat_viewmodel.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

class TestAuthVM extends AuthViewModel {
  TestAuthVM() : super(userViewModel: UserViewModel());
  @override
  Future<bool> login(String identifier, String password) async {
    await Future.delayed(const Duration(milliseconds: 50));
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
    updateCurrentUser(u);
    setJwtToken('jwt');
    return true;
  }
}

class FakeFriendshipVM extends FriendshipViewModel {
  @override
  Future<void> loadFriendsRemote({required String jwt, required User current}) async {}
  @override
  Future<void> loadRequestsRemote({required String jwt, required String currentUserId}) async {}
}

class FakeChatVM extends ChatViewModel {
  @override
  Future<void> loadRemoteConversations({required String jwt, required String currentUserId}) async {}
  @override
  Future<void> prefetchLatestMessagesForAll({required String jwt, required String currentUserId}) async {}
}

class FakeFeedVM extends FeedViewModel {
  @override
  Future<void> loadRemoteFeed({required String jwt, required User current}) async {}
}

void main() {
  testWidgets('LoginView shows spinner and navigates to MainView', (tester) async {
    final authVM = TestAuthVM();
    final userVM = UserViewModel();
    final friendshipVM = FakeFriendshipVM();
    final chatVM = FakeChatVM();
    final feedVM = FakeFeedVM();
    feedVM.setDependencies(userVM, friendshipVM);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
          ChangeNotifierProvider<UserViewModel>.value(value: userVM),
          ChangeNotifierProvider<FriendshipViewModel>.value(value: friendshipVM),
          ChangeNotifierProvider<ChatViewModel>.value(value: chatVM),
          ChangeNotifierProvider<FeedViewModel>.value(value: feedVM),
        ],
        child: const MaterialApp(home: LoginView()),
      ),
    );

    expect(find.text('Sign In'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 't@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    await tester.tap(find.text('Sign In'));

    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(MainView), findsOneWidget);
  });
}