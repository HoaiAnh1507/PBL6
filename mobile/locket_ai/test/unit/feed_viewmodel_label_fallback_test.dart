import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  test('Friend label shows username when provided', () {
    final vm = FeedViewModel();
    final friend = User(
      userId: 'f', phoneNumber: '0900000003', username: 'charlie', email: 'c@example.com', fullName: 'Charlie',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    vm.setFilterFriend(friend);
    expect(vm.filterLabel, 'charlie');
  });
}