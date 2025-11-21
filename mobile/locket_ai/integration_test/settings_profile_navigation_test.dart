import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:locket_ai/views/settings/settings_view.dart';
import 'package:locket_ai/views/profile/profile_view.dart';
import 'package:locket_ai/viewmodels/auth_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/viewmodels/chat_viewmodel.dart';
import 'package:locket_ai/viewmodels/settings_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('mở Profile từ Settings', (tester) async {
    final authVM = AuthViewModel(userViewModel: UserViewModel());
    final userVM = authVM.userViewModel;
    final feedVM = FeedViewModel();
    final friendshipVM = FriendshipViewModel();
    final chatVM = ChatViewModel();
    final sVM = SettingsViewModel();

    final user = User(
      userId: 'u1', phoneNumber: '0', username: 'tester', email: 't@e.com', fullName: 'Tester',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    authVM.updateCurrentUser(user);
    feedVM.setDependencies(userVM, friendshipVM);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
          ChangeNotifierProvider<UserViewModel>.value(value: userVM),
          ChangeNotifierProvider<FeedViewModel>.value(value: feedVM),
          ChangeNotifierProvider<FriendshipViewModel>.value(value: friendshipVM),
          ChangeNotifierProvider<ChatViewModel>.value(value: chatVM),
          ChangeNotifierProvider<SettingsViewModel>.value(value: sVM),
        ],
        child: const MaterialApp(home: SettingsView()),
      ),
    );

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileView), findsOneWidget);
  });
}