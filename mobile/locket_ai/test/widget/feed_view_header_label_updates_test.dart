import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:locket_ai/views/feed/feed_view.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  testWidgets('FeedView header label updates when filter changes', (tester) async {
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

    final hCtrl = PageController(initialPage: 1);
    final vCtrl = PageController(initialPage: 0);

    final userVM = UserViewModel();
    final friendshipVM = FriendshipViewModel();
    final feedVM = FeedViewModel()..setDependencies(userVM, friendshipVM);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FeedViewModel>.value(value: feedVM),
          ChangeNotifierProvider<FriendshipViewModel>.value(value: friendshipVM),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: FeedView(
              horizontalController: hCtrl,
              verticalController: vCtrl,
              currentUser: user,
              messageFocus: FocusNode(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);

    feedVM.setFilterMe();
    await tester.pump();

    expect(find.text('Me'), findsOneWidget);
  });
}