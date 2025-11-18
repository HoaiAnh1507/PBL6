import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/message_viewmodel.dart';
import 'package:locket_ai/models/message_model.dart';
import 'package:locket_ai/models/conversation_model.dart';
import 'package:locket_ai/models/user_model.dart';

void main() {
  group('MessageViewModel conversation updates', () {
    late Conversation conv;
    late User u1;
    late User u2;
    setUp(() {
      u1 = User(
        userId: 'u1', phoneNumber: '0901', username: 'u1', email: 'u1@example.com', fullName: 'U1',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      u2 = User(
        userId: 'u2', phoneNumber: '0902', username: 'u2', email: 'u2@example.com', fullName: 'U2',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      conv = Conversation(conversationId: 'c', userOne: u1, userTwo: u2, createdAt: DateTime.now(), messages: []);
    });

    test('hasConversation true initially', () {
      final msg = Message(messageId: 'm', conversation: conv, sender: u1, content: 'hi', sentAt: DateTime.now());
      final vm = MessageViewModel(msg);
      expect(vm.hasConversation, isTrue);
    });

    test('updateContent updates message content correctly', () {
      final msg = Message(messageId: 'm', conversation: conv, sender: u1, content: 'hi', sentAt: DateTime.now());
      final vm = MessageViewModel(msg);
      vm.updateContent("hello");
      expect(vm.content, "hello");
    });

    test('id and sentAt reflect message', () {
      final now = DateTime.now();
      final msg = Message(messageId: 'm', conversation: conv, sender: u1, content: 'hi', sentAt: now);
      final vm = MessageViewModel(msg);
      expect(vm.id, 'm');
      expect(vm.sentAt, now);
    });
  });
}