import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/chat_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';
import 'package:locket_ai/models/friendship_model.dart';
import 'package:locket_ai/models/post_model.dart';

class SeedFriendshipVM extends FriendshipViewModel {
  final List<Friendship> _seed;
  SeedFriendshipVM(this._seed);
  @override
  List<Friendship> get friendships => List.unmodifiable(_seed);
}

void main() {
  test('sendMessageWithPost creates conversation and adds message with reply', () {
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

    final accepted = Friendship(
      friendshipId: 'f_acc', userOne: current, userTwo: friend, status: FriendshipStatus.accepted, createdAt: DateTime.now(),
    );
    final friendVM = SeedFriendshipVM([accepted]);
    chatVM.setDependencies(userVM, friendVM);

    final repliedPost = Post(
      postId: 'p1', user: friend, mediaType: MediaType.PHOTO, mediaUrl: '',
      generatedCaption: 'caption', captionStatus: CaptionStatus.COMPLETED, createdAt: DateTime.now(),
    );

    chatVM.sendMessageWithPost(current.userId, friend.userId, 'hello', repliedPost);
    final conv = chatVM.getConversation(current.userId, friend.userId)!;
    expect(conv.messages!.isNotEmpty, isTrue);
    expect(conv.messages!.last.repliedToPost?.postId, 'p1');
    expect(conv.messages!.last.content, 'hello');
  });
}