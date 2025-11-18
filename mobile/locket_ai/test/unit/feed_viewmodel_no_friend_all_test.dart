import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/models/friendship_model.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';
import 'package:locket_ai/models/post_model.dart';

class EmptyFriendshipVM extends FriendshipViewModel {
  @override
  List<Friendship> get friendships => const [];
}

void main() {
  test('All filter shows only own posts when no friendships', () {
    final userVM = UserViewModel();
    final friendVM = EmptyFriendshipVM();
    final feedVM = FeedViewModel();
    feedVM.setDependencies(userVM, friendVM);
    final current = User(
      userId: 'me', phoneNumber: '0900', username: 'me', email: 'me@example.com', fullName: 'Me',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    final other = User(
      userId: 'other', phoneNumber: '0909', username: 'other', email: 'o@example.com', fullName: 'Other',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    feedVM.posts = [
      Post(postId: 'p1', user: current, mediaType: MediaType.PHOTO, mediaUrl: '', generatedCaption: '', captionStatus: CaptionStatus.PENDING, createdAt: DateTime.now()),
      Post(postId: 'p2', user: other, mediaType: MediaType.PHOTO, mediaUrl: '', generatedCaption: '', captionStatus: CaptionStatus.PENDING, createdAt: DateTime.now()),
    ];
    final visible = feedVM.getVisiblePosts(currentUser: current);
    expect(visible.length, 1);
    expect(visible.first.user.userId, 'me');
  });
}