import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/auth_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  group('AuthViewModel no JWT flows', () {
    test('fetchMe returns false and sets error when jwt missing', () async {
      final authVM = AuthViewModel(userViewModel: UserViewModel());
      authVM.setJwtToken(null);
      final ok = await authVM.fetchMe();
      expect(ok, isFalse);
      expect(authVM.errorMessage, 'JWT token missing');
    });

    test('resetPassword returns false when not logged in', () async {
      final authVM = AuthViewModel(userViewModel: UserViewModel());
      authVM.setJwtToken(null);
      final ok = await authVM.resetPassword('user', 'newpass');
      expect(ok, isFalse);
      expect(authVM.errorMessage, 'Not logged in');
    });

    test('logout clears currentUser and jwt', () async {
      final userVM = UserViewModel();
      final authVM = AuthViewModel(userViewModel: userVM);
      final u = User(
        userId: 'u1', phoneNumber: '0900000001', username: 'u1', email: 'u1@example.com', fullName: 'U1',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      authVM.updateCurrentUser(u);
      authVM.setJwtToken('token');
      await authVM.logout();
      expect(authVM.currentUser, isNull);
      expect(authVM.jwtToken, isNull);
    });
  });
}