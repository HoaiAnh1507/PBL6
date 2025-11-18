import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/conversation_viewmodel.dart';
import 'package:locket_ai/models/conversation_model.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  test('updateLastMessageAt sets time', () {
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
    final conv = Conversation(conversationId: 'c', userOne: u1, userTwo: u2, createdAt: DateTime.now(), messages: []);
    final vm = ConversationViewModel(conv);
    final t = DateTime.now().add(const Duration(minutes: 1));
    vm.updateLastMessageAt(t);
    expect(vm.lastMessageAt, t);
  });
}