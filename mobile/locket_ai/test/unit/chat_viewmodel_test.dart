import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/chat_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';
import 'package:locket_ai/models/friendship_model.dart';

class SeedFriendshipVM extends FriendshipViewModel {
  final List<Friendship> _seed;
  SeedFriendshipVM(this._seed);
  @override
  List<Friendship> get friendships => List.unmodifiable(_seed);
}

void main() {
  test('ChatViewModel getAcceptedFriends returns only accepted friends for current user', () {
    final uCurrent = User(
      userId: 'u_current', phoneNumber: '', username: 'curr', email: '', fullName: 'Current',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    final uFriend = User(
      userId: 'u_friend', phoneNumber: '', username: 'fr', email: '', fullName: 'Friend',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    final uPending = User(
      userId: 'u_pending', phoneNumber: '', username: 'pd', email: '', fullName: 'Pending',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );

    final accepted = Friendship(
      friendshipId: 'f_acc', userOne: uCurrent, userTwo: uFriend, status: FriendshipStatus.accepted, createdAt: DateTime.now(),
    );
    final pending = Friendship(
      friendshipId: 'f_pd', userOne: uCurrent, userTwo: uPending, status: FriendshipStatus.pending, createdAt: DateTime.now(),
    );

    final friendVM = SeedFriendshipVM([accepted, pending]);
    final userVM = UserViewModel();
    final chatVM = ChatViewModel();
    chatVM.setDependencies(userVM, friendVM);

    final list = chatVM.getAcceptedFriends(uCurrent.userId);
    expect(list.length, 1);
    expect(list.first.userId, 'u_friend');
  });
}