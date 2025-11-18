import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  test('setFilterAll resets selectedFriend to null', () {
    final vm = FeedViewModel();
    final friend = User(
      userId: 'f', phoneNumber: '0903', username: 'fr', email: 'f@example.com', fullName: 'Friend',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    vm.setFilterFriend(friend);
    vm.setFilterAll();
    expect(vm.selectedFriend, isNull);
  });
}