import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  group('UserViewModel multiple users', () {
    test('currentUser equals last set user', () {
      final vm = UserViewModel();
      final u1 = User(
        userId: 'u1', phoneNumber: '0901', username: 'u1', email: 'u1@example.com', fullName: 'U1',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final u2 = User(
        userId: 'u2', phoneNumber: '0902', username: 'u2', email: 'u2@example.com', fullName: 'U2',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      vm.setCurrentUser(u1);
      vm.setCurrentUser(u2);
      expect(vm.currentUser!.userId, 'u2');
    });

    test('getUserById finds previously set user', () {
      final vm = UserViewModel();
      final u1 = User(
        userId: 'u1', phoneNumber: '0901', username: 'u1', email: 'u1@example.com', fullName: 'U1',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      vm.setCurrentUser(u1);
      final found = vm.getUserById('u1');
      expect(found, isNotNull);
      expect(found!.userId, 'u1');
    });
  });
}