import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/message_viewmodel.dart';
import 'package:locket_ai/models/message_model.dart';
import 'package:locket_ai/models/conversation_model.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  test('MessageViewModel updateContent changes content', () {
    final u1 = User(
      userId: 'u1', phoneNumber: '', username: 'u1', email: '', fullName: 'U1',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    final u2 = User(
      userId: 'u2', phoneNumber: '', username: 'u2', email: '', fullName: 'U2',
      profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
    );
    final conv = Conversation(
      conversationId: 'c1', userOne: u1, userTwo: u2, createdAt: DateTime.now(), messages: [],
    );
    final msg = Message(
      messageId: 'm1', conversation: conv, sender: u1, content: 'hi', sentAt: DateTime.now(),
    );
    final vm = MessageViewModel(msg);
    vm.updateContent('hello');
    expect(vm.content, 'hello');
  });
}