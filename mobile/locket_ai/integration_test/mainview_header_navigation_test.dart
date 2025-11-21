import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:locket_ai/views/main_view.dart';
import 'package:locket_ai/views/chat/chat_list_view.dart';
import 'package:locket_ai/views/settings/settings_view.dart';
import 'package:locket_ai/viewmodels/auth_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/viewmodels/chat_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';
import 'package:locket_ai/widgets/app_header.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tap icon phải của header chuyển sang ChatList', (tester) async {
    final userVM = UserViewModel();
    final friendshipVM = FriendshipViewModel();
    final feedVM = FeedViewModel()..setDependencies(userVM, friendshipVM);
    final chatVM = ChatViewModel()..setDependencies(userVM, friendshipVM);
    final authVM = AuthViewModel(userViewModel: userVM);
    final user = User(
      userId: 'u1', phoneNumber: '0', username: 'tester', email: 't@e.com', fullName: 'Tester',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    authVM.updateCurrentUser(user);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserViewModel>.value(value: userVM),
          ChangeNotifierProvider<FriendshipViewModel>.value(value: friendshipVM),
          ChangeNotifierProvider<FeedViewModel>.value(value: feedVM),
          ChangeNotifierProvider<ChatViewModel>.value(value: chatVM),
          ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
        ],
        child: const MaterialApp(home: MainView()),
      ),
    );

    // Kéo vertical PageView để chuyển sang FeedView (nơi có AppHeader)
    await tester.drag(find.byType(PageView).at(1), const Offset(0, -500));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.maps_ugc_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(ChatListView), findsOneWidget);
  });
}