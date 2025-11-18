import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/chat_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';
import 'package:locket_ai/models/friendship_model.dart';
import 'package:locket_ai/models/message_model.dart';

class SeedFriendshipVM extends FriendshipViewModel {
  final List<Friendship> _seed;
  SeedFriendshipVM(this._seed);
  @override
  List<Friendship> get friendships => List.unmodifiable(_seed);
}

void main() {
  test('getLatestMessage returns most recent message', () {
    final userVM = UserViewModel();
    final chatVM = ChatViewModel();

    final current = User(
      userId: 'u_current', phoneNumber: '', username: 'curr', email: '', fullName: 'Current',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    final friend = User(
      userId: 'u_friend', phoneNumber: '', username: 'fr', email: '', fullName: 'Friend',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );

    userVM.setCurrentUser(current);
    userVM.setCurrentUser(friend);
    final friendVM = SeedFriendshipVM([
      Friendship(friendshipId: 'f', userOne: current, userTwo: friend, status: FriendshipStatus.accepted, createdAt: DateTime.now()),
    ]);
    chatVM.setDependencies(userVM, friendVM);

    final conv = chatVM.getConversation(current.userId, friend.userId)!;
    final m1 = Message(messageId: 'm1', conversation: conv, sender: current, content: '1', sentAt: DateTime.now());
    final m2 = Message(messageId: 'm2', conversation: conv, sender: friend, content: '2', sentAt: DateTime.now().add(const Duration(seconds: 1)));
    conv.messages!.addAll([m1, m2]);

    final latest = chatVM.getLatestMessage(current.userId, friend.userId)!;
    expect(latest.messageId, 'm2');
  });
}