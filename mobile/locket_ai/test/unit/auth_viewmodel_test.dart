import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/auth_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  test('AuthViewModel updateCurrentUser syncs with UserViewModel', () {
    final userVM = UserViewModel();
    final authVM = AuthViewModel(userViewModel: userVM);

    final u = User(
      userId: 'u1', phoneNumber: '', username: 'u1', email: '', fullName: 'U1',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );

    authVM.updateCurrentUser(u);
    expect(authVM.currentUser, isNotNull);
    expect(userVM.currentUser, isNotNull);
    expect(userVM.currentUser!.userId, 'u1');
  });

  test('AuthViewModel setJwtToken stores token', () {
    final userVM = UserViewModel();
    final authVM = AuthViewModel(userViewModel: userVM);
    authVM.setJwtToken('jwt');
    expect(authVM.jwtToken, 'jwt');
  });
}