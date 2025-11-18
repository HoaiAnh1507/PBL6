import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  group('UserViewModel', () {
    test('setCurrentUser inserts when not exists', () {
      final vm = UserViewModel();
      final u = User(
        userId: 'u1', phoneNumber: '', username: 'u1', email: '', fullName: 'U1',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      vm.setCurrentUser(u);
      expect(vm.currentUser, isNotNull);
      expect(vm.currentUser!.userId, 'u1');
    });

    test('setCurrentUser updates when exists', () {
      final vm = UserViewModel();
      final u1 = User(
        userId: 'u1', phoneNumber: '', username: 'u1', email: '', fullName: 'U1',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      vm.setCurrentUser(u1);
      final u1b = User(
        userId: 'u1', phoneNumber: '', username: 'u1b', email: '', fullName: 'U1B',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      vm.setCurrentUser(u1b);
      expect(vm.currentUser!.username, 'u1b');
      expect(vm.currentUser!.fullName, 'U1B');
    });

    test('clearAll resets state', () {
      final vm = UserViewModel();
      final u = User(
        userId: 'u1', phoneNumber: '', username: 'u1', email: '', fullName: 'U1',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      vm.setCurrentUser(u);
      vm.clearAll();
      expect(vm.currentUser, isNull);
    });
  });
}