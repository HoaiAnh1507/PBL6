import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/chat_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

class FriendFallbackVM extends FriendshipViewModel {
  final List<User> _accepted;
  FriendFallbackVM(this._accepted);
  @override
  List<User> get acceptedFriends => List.unmodifiable(_accepted);
}

void main() {
  test('create conversation using acceptedFriends fallback when friend not in UserVM', () {
    final userVM = UserViewModel();
    final chatVM = ChatViewModel();
    final current = User(
      userId: 'u_current', phoneNumber: '0901', username: 'curr', email: 'c@example.com', fullName: 'Current',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    final friend = User(
      userId: 'u_friend', phoneNumber: '0902', username: 'fr', email: 'f@example.com', fullName: 'Friend',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    userVM.setCurrentUser(current);
    final friendVM = FriendFallbackVM([friend]);
    chatVM.setDependencies(userVM, friendVM);
    final conv = chatVM.getConversation(current.userId, friend.userId)!;
    expect(conv.userTwo.userId == friend.userId || conv.userOne.userId == friend.userId, isTrue);
  });
}