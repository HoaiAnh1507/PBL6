import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/models/post_model.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  group('FeedViewModel mutations', () {
    late FeedViewModel vm;
    late User u;

    setUp(() {
      vm = FeedViewModel();
      u = User(
        userId: 'u', phoneNumber: '', username: 'user', email: '', fullName: 'User',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
    });

    test('addPost inserts at start', () {
      final p1 = Post(
        postId: 'p1', user: u, mediaType: MediaType.PHOTO, mediaUrl: '',
        generatedCaption: '', captionStatus: CaptionStatus.PENDING, createdAt: DateTime.now(),
      );
      final p2 = Post(
        postId: 'p2', user: u, mediaType: MediaType.PHOTO, mediaUrl: '',
        generatedCaption: '', captionStatus: CaptionStatus.PENDING, createdAt: DateTime.now(),
      );
      vm.addPost(p1);
      vm.addPost(p2);
      expect(vm.posts.first.postId, 'p2');
    });

    test('removePost removes by id', () {
      final p1 = Post(
        postId: 'p1', user: u, mediaType: MediaType.PHOTO, mediaUrl: '',
        generatedCaption: '', captionStatus: CaptionStatus.PENDING, createdAt: DateTime.now(),
      );
      vm.addPost(p1);
      vm.removePost('p1');
      expect(vm.posts, isEmpty);
    });

    test('clearAll resets state', () {
      final p1 = Post(
        postId: 'p1', user: u, mediaType: MediaType.PHOTO, mediaUrl: '',
        generatedCaption: '', captionStatus: CaptionStatus.PENDING, createdAt: DateTime.now(),
      );
      vm.addPost(p1);
      vm.setFilterMe();
      vm.clearAll();
      expect(vm.posts, isEmpty);
      expect(vm.filterType, FeedFilterType.all);
      expect(vm.selectedFriend, isNull);
    });
  });
}