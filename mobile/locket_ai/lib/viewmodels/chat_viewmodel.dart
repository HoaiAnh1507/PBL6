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
      final conv = _createConversation(user.userId, friend.userId);
      _addMockMessages(conv, user, friend);
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

    if (currentUser == null || friend == null) {
      debugPrint(
          "⚠️ Không thể tạo conversation vì user không tồn tại: $currentUserId, $friendId");
      throw Exception("User không tồn tại trong hệ thống");
    }

    final newConv = Conversation(
      conversationId: DateTime.now().millisecondsSinceEpoch.toString(),
      userOne: currentUser,
      userTwo: friend,
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

    final sender = userViewModel.getUserById(currentUserId);
    if (sender == null) return;

    final msg = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      conversation: conv,
      sender: sender,
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
    conv.messages!.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return conv.messages!.first;
  }

  // ------------------- 🧪 MOCK DATA --------------------

  void _addMockMessages(Conversation conv, User user, User friend) {
    final now = DateTime.now();

    List<Message> messages;

    switch (friend.userId) {
      case 'u1': // tuan
        messages = [
          Message(
            messageId: 'm1_${conv.conversationId}',
            conversation: conv,
            sender: friend,
            content: "Đi đá bóng cuối tuần không?",
            sentAt: now.subtract(const Duration(hours: 5)),
          ),
          Message(
            messageId: 'm2_${conv.conversationId}',
            conversation: conv,
            sender: user,
            content: "Ok, chiều chủ nhật nhé!",
            sentAt: now.subtract(const Duration(hours: 4, minutes: 15)),
          ),
          Message(
            messageId: 'm3_${conv.conversationId}',
            conversation: conv,
            sender: friend,
            content: "Sân cũ hay thử sân mới ở Q.7?",
            sentAt: now.subtract(const Duration(hours: 3, minutes: 40)),
          ),
          Message(
            messageId: 'm4_${conv.conversationId}',
            conversation: conv,
            sender: user,
            content: "Thử sân mới xem, nghe bảo mặt cỏ đẹp.",
            sentAt: now.subtract(const Duration(hours: 3, minutes: 10)),
          ),
        ];
        break;
      case 'u2': // hieu
        messages = [
          Message(
            messageId: 'm1_${conv.conversationId}',
            conversation: conv,
            sender: friend,
            content: "Game mới ra chưa? Có đáng chơi không?",
            sentAt: now.subtract(const Duration(days: 1, hours: 2)),
          ),
          Message(
            messageId: 'm2_${conv.conversationId}',
            conversation: conv,
            sender: user,
            content: "Ra rồi, story khá hay. Tối rảnh không?",
            sentAt: now.subtract(const Duration(days: 1, hours: 1, minutes: 20)),
          ),
          Message(
            messageId: 'm3_${conv.conversationId}',
            conversation: conv,
            sender: friend,
            content: "Rảnh, làm vài màn co-op nhé!",
            sentAt: now.subtract(const Duration(days: 1, hours: 1)),
          ),
        ];
        break;
      case 'u3': // rin
        messages = [
          Message(
            messageId: 'm1_${conv.conversationId}',
            conversation: conv,
            sender: friend,
            content: "Check-in Đà Nẵng nè, biển đẹp quá!",
            // > 1 tuần trước để test header thời gian
            sentAt: now.subtract(const Duration(days: 10, hours: 4)),
          ),
          Message(
            messageId: 'm2_${conv.conversationId}',
            conversation: conv,
            sender: user,
            content: "Đẹp thiệt, có đi Bà Nà Hills không?",
            sentAt: now.subtract(const Duration(days: 9, hours: 22)),
          ),
          Message(
            messageId: 'm3_${conv.conversationId}',
            conversation: conv,
            sender: friend,
            content: "Có chứ! View trên đó xịn lắm.",
            sentAt: now.subtract(const Duration(days: 9, hours: 20, minutes: 30)),
          ),
          Message(
            messageId: 'm4_${conv.conversationId}',
            conversation: conv,
            sender: friend,
            content: "Xem không, để tí nữa gửi thêm ảnh cho mà coi.",
            sentAt: now.subtract(const Duration(days: 9, hours: 20, minutes: 30, seconds: 10)),
          ),
          Message(
            messageId: 'm5_${conv.conversationId}',
            conversation: conv,
            sender: user,
            content: "Gửi mình vài tấm nữa đi!",
            sentAt: now.subtract(const Duration(days: 8, hours: 18)),
          ),
        ];
        break;
      case 'u0': // me (trường hợp bạn là 'me' khi currentUser != 'u0')
        messages = [
          Message(
            messageId: 'm1_${conv.conversationId}',
            conversation: conv,
            sender: friend,
            content: "Đang code tính năng chat, sắp xong rồi.",
            sentAt: now.subtract(const Duration(hours: 6)),
          ),
          Message(
            messageId: 'm2_${conv.conversationId}',
            conversation: conv,
            sender: user,
            content: "Ngon, tối push PR nhé.",
            sentAt: now.subtract(const Duration(hours: 5, minutes: 20)),
          ),
        ];
        break;
      default: // fallback chung
        messages = [
          Message(
            messageId: 'm1_${conv.conversationId}',
            conversation: conv,
            sender: friend,
            content: "Hey ${user.fullName.split(' ').last}, dạo này sao rồi?",
            sentAt: now.subtract(const Duration(minutes: 45)),
          ),
          Message(
            messageId: 'm2_${conv.conversationId}',
            conversation: conv,
            sender: user,
            content: "Tớ ổn, vẫn đang bận code Flutter 😆",
            sentAt: now.subtract(const Duration(minutes: 30)),
          ),
          Message(
            messageId: 'm3_${conv.conversationId}',
            conversation: conv,
            sender: friend,
            content: "Nghe hay đấy, app cậu làm tới đâu rồi?",
            sentAt: now.subtract(const Duration(minutes: 10)),
          ),
        ];
        break;
    }

    conv.messages?.addAll(messages);
  }
}
