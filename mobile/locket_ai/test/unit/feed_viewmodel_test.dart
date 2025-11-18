import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';
import 'package:locket_ai/models/friendship_model.dart';
import 'package:locket_ai/models/post_model.dart';

class MockFriendshipVM extends FriendshipViewModel {
  final List<Friendship> _seed;
  MockFriendshipVM(this._seed);
  @override
  List<Friendship> get friendships => List.unmodifiable(_seed);
}

void main() {
  group('FeedViewModel visibility filtering', () {
    late User current;
    late User friend;
    late User stranger;
    late FeedViewModel feedVM;

    setUp(() {
      current = User(
        userId: 'u_current',
        phoneNumber: '',
        username: 'current',
        email: 'c@example.com',
        fullName: 'Current User',
        profilePictureUrl: null,
        passwordHash: '',
        subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null,
        accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      friend = User(
        userId: 'u_friend',
        phoneNumber: '',
        username: 'friend',
        email: 'f@example.com',
        fullName: 'Friend User',
        profilePictureUrl: null,
        passwordHash: '',
        subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null,
        accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      stranger = User(
        userId: 'u_stranger',
        phoneNumber: '',
        username: 'stranger',
        email: 's@example.com',
        fullName: 'Stranger User',
        profilePictureUrl: null,
        passwordHash: '',
        subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null,
        accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final accepted = Friendship(
        friendshipId: 'acc_${current.userId}_${friend.userId}',
        userOne: current,
        userTwo: friend,
        status: FriendshipStatus.accepted,
        createdAt: DateTime.now(),
      );

      final userVM = UserViewModel();
      final friendshipVM = MockFriendshipVM([accepted]);
      feedVM = FeedViewModel();
      feedVM.setDependencies(userVM, friendshipVM);

      feedVM.posts = [
        Post(
          postId: 'p1',
          user: current,
          mediaType: MediaType.PHOTO,
          mediaUrl: 'url1',
          generatedCaption: 'mine',
          captionStatus: CaptionStatus.COMPLETED,
          createdAt: DateTime.now(),
        ),
        Post(
          postId: 'p2',
          user: friend,
          mediaType: MediaType.PHOTO,
          mediaUrl: 'url2',
          generatedCaption: 'friend',
          captionStatus: CaptionStatus.COMPLETED,
          createdAt: DateTime.now().add(const Duration(seconds: 1)),
        ),
        Post(
          postId: 'p3',
          user: stranger,
          mediaType: MediaType.PHOTO,
          mediaUrl: 'url3',
          generatedCaption: 'stranger',
          captionStatus: CaptionStatus.COMPLETED,
          createdAt: DateTime.now().add(const Duration(seconds: 2)),
        ),
      ];
    });

    test('All filter shows only own and accepted-friend posts', () {
      final visible = feedVM.getVisiblePosts(currentUser: current);
      expect(visible.any((p) => p.postId == 'p1'), isTrue); // mine
      expect(visible.any((p) => p.postId == 'p2'), isTrue); // friend
      expect(visible.any((p) => p.postId == 'p3'), isFalse); // stranger
    });

    test('Friend filter hides posts if not accepted', () {
      // Pick stranger as selectedFriend → should be empty
      feedVM.setFilterFriend(stranger);
      final visible = feedVM.getVisiblePosts(currentUser: current);
      expect(visible, isEmpty);
    });

    test('Friend filter shows posts for accepted friend', () {
      feedVM.setFilterFriend(friend);
      final visible = feedVM.getVisiblePosts(currentUser: current);
      expect(visible.length, 1);
      expect(visible.first.postId, 'p2');
    });

    test('Me filter only shows own posts', () {
      feedVM.setFilterMe();
      final visible = feedVM.getVisiblePosts(currentUser: current);
      expect(visible.length, 1);
      expect(visible.first.user.userId, current.userId);
    });

    test('All filter sorts by newest first', () {
      final visible = feedVM.getVisiblePosts(currentUser: current);
      expect(visible.first.postId, 'p2');
    });
  });
}