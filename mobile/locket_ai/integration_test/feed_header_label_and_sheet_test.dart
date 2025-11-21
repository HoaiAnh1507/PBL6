import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:locket_ai/views/feed/feed_view.dart';
import 'package:locket_ai/viewmodels/auth_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/viewmodels/chat_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('label mặc định của Feed là All', (tester) async {
    final hCtrl = PageController(initialPage: 1);
    final vCtrl = PageController(initialPage: 1);
    final authVM = AuthViewModel(userViewModel: UserViewModel());
    final userVM = authVM.userViewModel;
    final feedVM = FeedViewModel();
    final friendshipVM = FriendshipViewModel();
    final chatVM = ChatViewModel();
    final current = User(
      userId: 'u1', phoneNumber: '0', username: 'tester', email: 't@e.com', fullName: 'Tester',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    authVM.updateCurrentUser(current);
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
        child: MaterialApp(
          home: FeedView(
            horizontalController: hCtrl,
            verticalController: vCtrl,
            currentUser: current,
            messageFocus: FocusNode(),
          ),
        ),
      ),
    );

    expect(find.text('All'), findsWidgets);
  });

  testWidgets('chọn Me trong friends sheet đổi label về Me', (tester) async {
    final hCtrl = PageController(initialPage: 1);
    final vCtrl = PageController(initialPage: 1);
    final authVM = AuthViewModel(userViewModel: UserViewModel());
    final userVM = authVM.userViewModel;
    final feedVM = FeedViewModel();
    final friendshipVM = FriendshipViewModel();
    final chatVM = ChatViewModel();
    final current = User(
      userId: 'u1', phoneNumber: '0', username: 'tester', email: 't@e.com', fullName: 'Tester',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    authVM.updateCurrentUser(current);
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
        child: MaterialApp(
          home: FeedView(
            horizontalController: hCtrl,
            verticalController: vCtrl,
            currentUser: current,
            messageFocus: FocusNode(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();
    expect(find.text('Your friends'), findsOneWidget);
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    expect(find.text('Me'), findsWidgets);
  });
}