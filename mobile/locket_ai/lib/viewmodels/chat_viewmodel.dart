import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/friendship_model.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import 'user_viewmodel.dart';
import 'friendship_viewmodel.dart';

class ChatViewModel extends ChangeNotifier {
  late UserViewModel userViewModel;
  late FriendshipViewModel friendshipViewModel;

  final Map<String, Conversation> _conversations = {};

  ChatViewModel();

  void setDependencies(UserViewModel userVM, FriendshipViewModel friendshipVM) {
    userViewModel = userVM;
    friendshipViewModel = friendshipVM;
  }

  /// ✅ Khi người dùng đăng nhập → gọi hàm này
  void loadDataForCurrentUser() {
    final user = userViewModel.currentUser;
    if (user == null) return;

    _conversations.clear();

    final friends = getAcceptedFriends(user.userId);
    for (var friend in friends) {
      _createConversation(user.userId, friend.userId);
    }

    notifyListeners();
  }

  // ------------------- 💬 FRIENDSHIP LOGIC --------------------

  List<User> getAcceptedFriends(String currentUserId) {
    final friendships = friendshipViewModel.friendships.where(
      (f) =>
          f.status == FriendshipStatus.accepted &&
          (f.userOne?.userId == currentUserId ||
              f.userTwo?.userId == currentUserId),
    );

    return friendships.map((f) {
      return f.userOne?.userId == currentUserId ? f.userTwo! : f.userOne!;
    }).toList();
  }

  // ------------------- 💬 CHAT LOGIC --------------------

  Conversation _createConversation(String currentUserId, String friendId) {
    final currentUser = userViewModel.getUserById(currentUserId);
    final friend = userViewModel.getUserById(friendId);

    final newConv = Conversation(
      conversationId: DateTime.now().millisecondsSinceEpoch.toString(),
      userOne: currentUser!,
      userTwo: friend!,
      createdAt: DateTime.now(),
      messages: [],
    );

    _conversations[newConv.conversationId] = newConv;
    return newConv;
  }

  List<Message> getMessagesWith(String currentUserId, String friendId) {
    final conv = _conversations.values.firstWhere(
      (c) =>
          (c.userOne.userId == currentUserId &&
              c.userTwo.userId == friendId) ||
          (c.userTwo.userId == currentUserId &&
              c.userOne.userId == friendId),
      orElse: () => _createConversation(currentUserId, friendId),
    );
    return conv.messages ?? [];
  }

  void sendMessage(String currentUserId, String friendId, String content) {
    final conv = _conversations.values.firstWhere(
      (c) =>
          (c.userOne.userId == currentUserId &&
              c.userTwo.userId == friendId) ||
          (c.userTwo.userId == currentUserId &&
              c.userOne.userId == friendId),
      orElse: () => _createConversation(currentUserId, friendId),
    );

    final msg = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      conversation: conv,
      sender: userViewModel.getUserById(currentUserId),
      content: content,
      sentAt: DateTime.now(),
    );

    conv.messages?.add(msg);
    notifyListeners();
  }

  Conversation? getConversation(String currentUserId, String friendId) {
    try {
      return _conversations.values.firstWhere(
        (c) =>
            (c.userOne.userId == currentUserId && c.userTwo.userId == friendId) ||
            (c.userTwo.userId == currentUserId && c.userOne.userId == friendId),
      );
    } catch (_) {
      // Nếu không có conversation → tạo mới
      return _createConversation(currentUserId, friendId);
    }
  }

  Message? getLatestMessage(String currentUserId, String friendId) {
    final conv = getConversation(currentUserId, friendId);
    if (conv == null || conv.messages == null || conv.messages!.isEmpty) return null;
    // Lấy tin nhắn gần nhất
    conv.messages!.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return conv.messages!.first;
  }
}
