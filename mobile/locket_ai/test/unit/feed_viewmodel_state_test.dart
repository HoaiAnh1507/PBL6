import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  group('FeedViewModel filter label', () {
    test('default label is All', () {
      final vm = FeedViewModel();
      expect(vm.filterLabel, 'All');
    });

    test('label for Me', () {
      final vm = FeedViewModel();
      vm.setFilterMe();
      expect(vm.filterLabel, 'Me');
    });

    test('label for Friend uses username then fullName', () {
      final vm = FeedViewModel();
      final friend1 = User(
        userId: 'f1', phoneNumber: '0900000001', username: 'alice', email: 'a@example.com', fullName: 'Alice',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      vm.setFilterFriend(friend1);
      expect(vm.filterLabel, 'alice');

      final friend2 = User(
        userId: 'f2', phoneNumber: '0900000002', username: 'bob', email: 'b@example.com', fullName: 'Bob',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      vm.setFilterFriend(friend2);
      expect(vm.filterLabel, 'bob');
    });
  });
}