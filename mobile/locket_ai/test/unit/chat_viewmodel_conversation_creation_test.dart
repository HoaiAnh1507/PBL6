import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/chat_viewmodel.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/viewmodels/friendship_viewmodel.dart';
import 'package:locket_ai/models/user_model.dart';

class EmptyFriendshipVM extends FriendshipViewModel {}

void main() {
  group('ChatViewModel conversation creation', () {
    late UserViewModel userVM;
    late ChatViewModel chatVM;
    late User current;
    late User friend;

    setUp(() {
      userVM = UserViewModel();
      chatVM = ChatViewModel();
      current = User(
        userId: 'u_current', phoneNumber: '0901', username: 'curr', email: 'c@example.com', fullName: 'Current',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      friend = User(
        userId: 'u_friend', phoneNumber: '0902', username: 'fr', email: 'f@example.com', fullName: 'Friend',
        profilePictureUrl: null, passwordHash: '', subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null, accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      userVM.setCurrentUser(current);
      userVM.setCurrentUser(friend);
      chatVM.setDependencies(userVM, EmptyFriendshipVM());
    });

    test('getConversation creates when none exists', () {
      final conv = chatVM.getConversation(current.userId, friend.userId)!;
      expect(conv.userOne.userId == current.userId || conv.userTwo.userId == current.userId, isTrue);
      expect(conv.userOne.userId == friend.userId || conv.userTwo.userId == friend.userId, isTrue);
    });

    test('clearAll resets conversations', () {
      final conv1 = chatVM.getConversation(current.userId, friend.userId)!;
      chatVM.clearAll();
      final conv2 = chatVM.getConversation(current.userId, friend.userId)!;
      expect(conv1.conversationId == conv2.conversationId, isFalse);
    });

    test('getLatestMessage returns null when no messages', () {
      final latest = chatVM.getLatestMessage(current.userId, friend.userId);
      expect(latest, isNull);
    });
  });
}
