import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:locket_ai/views/chat/chat_list_view.dart';
import 'package:locket_ai/viewmodels/chat_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/viewmodels/auth_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';

void main() {
  testWidgets('ChatListView shows title and empty state', (tester) async {
    final userVM = UserViewModel();
    final friendshipVM = FriendshipViewModel();
    final chatVM = ChatViewModel()..setDependencies(userVM, friendshipVM);
    final authVM = AuthViewModel(userViewModel: userVM);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserViewModel>.value(value: userVM),
          ChangeNotifierProvider<FriendshipViewModel>.value(value: friendshipVM),
          ChangeNotifierProvider<ChatViewModel>.value(value: chatVM),
          ChangeNotifierProvider<AuthViewModel>.value(value: authVM),
        ],
        child: const MaterialApp(
          home: ChatListView(currentUserId: 'u0'),
        ),
      ),
    );

    expect(find.text('Messengers'), findsOneWidget);
    expect(find.text('No friends yet.'), findsOneWidget);
  });
}