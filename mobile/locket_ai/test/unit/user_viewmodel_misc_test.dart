import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  group('UserViewModel misc', () {
    test('logout clears currentUser', () {
      final vm = UserViewModel();
      final u = User(
        userId: 'u1', phoneNumber: '', username: 'u1', email: '', fullName: 'U1',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      vm.setCurrentUser(u);
      vm.logout();
      expect(vm.currentUser, isNull);
    });

    test('getUserById returns null when not found', () {
      final vm = UserViewModel();
      expect(vm.getUserById('missing'), isNull);
    });
  });
}