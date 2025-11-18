import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  test('getUserById returns null after clearAll', () {
    final vm = UserViewModel();
    final u = User(
      userId: 'u1', phoneNumber: '0901', username: 'u1', email: 'u1@example.com', fullName: 'U1',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    vm.setCurrentUser(u);
    vm.clearAll();
    expect(vm.getUserById('u1'), isNull);
  });
}