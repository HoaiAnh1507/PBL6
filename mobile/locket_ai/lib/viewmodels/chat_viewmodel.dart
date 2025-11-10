import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/friendship_model.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../models/post_model.dart';
import 'user_viewmodel.dart';
import 'friendship_viewmodel.dart';
import '../services/conversations_api.dart';
import '../services/messages_api.dart';
import '../core/config/api_config.dart';

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

  /// Tải hội thoại từ backend nếu có JWT, fallback mock nếu không
  Future<void> loadRemoteConversations({
    required String jwt,
    required String currentUserId,
  }) async {
    try {
      final api = ConversationsApi(jwt);
      final rawList = await api.listConversations();
      _conversations.clear();

      User makeUserFromPublic(Map<String, dynamic> m) {
        final now = DateTime.now();
        DateTime createdAt;
        try {
          createdAt = DateTime.parse((m['createdAt'] ?? '').toString());
        } catch (_) {
          createdAt = now;
        }
        return User(
          userId: (m['userId'] ?? '').toString(),
          username: (m['username'] ?? '').toString(),
          fullName: (m['fullName'] ?? '').toString(),
          phoneNumber: (m['phoneNumber'] ?? '').toString(),
          email: (m['email'] ?? '').toString(),
          profilePictureUrl: (m['profilePictureUrl'] ?? '').toString().isNotEmpty
              ? (m['profilePictureUrl'] as String?)
              : null,
          passwordHash: '',
          subscriptionStatus: SubscriptionStatus.FREE,
          subscriptionExpiresAt: null,
          accountStatus: AccountStatus.ACTIVE,
          createdAt: createdAt,
          updatedAt: createdAt,
        );
      }

      Message parseMessage(Map<String, dynamic> m, Conversation conv) {
        DateTime sentAt;
        try {
          sentAt = DateTime.parse((m['sentAt'] ?? '').toString());
        } catch (_) {
          sentAt = DateTime.now();
        }
        final senderMap = (m['sender'] ?? {}) as Map<String, dynamic>;
        final sender = makeUserFromPublic(senderMap);
        return Message(
          messageId: (m['messageId'] ?? '').toString(),
          conversation: conv,
          sender: sender,
          content: (m['content'] ?? '').toString(),
          repliedToPost: null,
          sentAt: sentAt,
        );
      }

      for (final item in rawList) {
        final j = item as Map<String, dynamic>;
        final convId = (j['conversationId'] ?? '').toString();
        DateTime createdAt;
        DateTime? lastMessageAt;
        try {
          createdAt = DateTime.parse((j['createdAt'] ?? '').toString());
        } catch (_) {
          createdAt = DateTime.now();
        }
        try {
          final lm = (j['lastMessageAt'] ?? '').toString();
          lastMessageAt = lm.isNotEmpty ? DateTime.parse(lm) : null;
        } catch (_) {
          lastMessageAt = null;
        }

        final u1 = makeUserFromPublic((j['userOne'] ?? {}) as Map<String, dynamic>);
        final u2 = makeUserFromPublic((j['userTwo'] ?? {}) as Map<String, dynamic>);

        final conv = Conversation(
          conversationId: convId,
          userOne: u1,
          userTwo: u2,
          lastMessageAt: lastMessageAt,
          createdAt: createdAt,
          messages: [],
        );

        final msgsRaw = (j['messages'] ?? []) as List<dynamic>;
        for (final m in msgsRaw) {
          try {
            conv.messages!.add(parseMessage(m as Map<String, dynamic>, conv));
          } catch (_) {}
        }

        _conversations[conv.conversationId] = conv;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('loadRemoteConversations error: $e');
    }
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

  // Tìm user an toàn: ưu tiên UserViewModel, fallback sang danh sách bạn bè đã accepted
  User? _findUserById(String userId) {
    final u = userViewModel.getUserById(userId);
    if (u != null) return u;
    final list = friendshipViewModel.acceptedFriends;
    final idx = list.indexWhere((x) => x.userId == userId);
    if (idx != -1) return list[idx];
    return null;
  }

  Conversation _createConversation(String currentUserId, String friendId) {
    final currentUser = _findUserById(currentUserId) ?? userViewModel.currentUser;
    final friend = _findUserById(friendId);

    if (currentUser == null || friend == null) {
      debugPrint(
    "⚠️ Cannot create conversation because user does not exist: $currentUserId, $friendId");
    throw Exception("User does not exist in the system");
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

    final sender = _findUserById(currentUserId);
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

  /// Gửi tin nhắn qua backend nếu có hội thoại từ server
  Future<bool> sendMessageRemote({
    required String jwt,
    required String currentUserId,
    required String friendId,
    required String content,
  }) async {
    try {
      final conv = _conversations.values.firstWhere(
        (c) =>
            (c.userOne.userId == currentUserId && c.userTwo.userId == friendId) ||
            (c.userTwo.userId == currentUserId && c.userOne.userId == friendId),
      );
      final api = MessagesApi(jwt);
      final resp = await api.sendMessage(
        conversationId: conv.conversationId,
        content: content,
      );
      if (resp == null) return false;

      // Map response to Message and append
      DateTime sentAt;
      try {
        sentAt = DateTime.parse((resp['sentAt'] ?? '').toString());
      } catch (_) {
        sentAt = DateTime.now();
      }
      final senderMap = (resp['sender'] ?? {}) as Map<String, dynamic>;
      final sender = User(
        userId: (senderMap['userId'] ?? '').toString(),
        username: (senderMap['username'] ?? '').toString(),
        fullName: (senderMap['fullName'] ?? '').toString(),
        phoneNumber: (senderMap['phoneNumber'] ?? '').toString(),
        email: (senderMap['email'] ?? '').toString(),
        profilePictureUrl: (senderMap['profilePictureUrl'] ?? '').toString().isNotEmpty
            ? (senderMap['profilePictureUrl'] as String?)
            : null,
        passwordHash: '',
        subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null,
        accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final msg = Message(
        messageId: (resp['messageId'] ?? '').toString(),
        conversation: conv,
        sender: sender,
        content: (resp['content'] ?? '').toString(),
        repliedToPost: null,
        sentAt: sentAt,
      );

      conv.messages?.add(msg);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('sendMessageRemote error: $e');
      return false;
    }
  }

  /// Nạp danh sách message từ backend cho cặp (currentUserId, friendId)
  Future<void> loadRemoteMessagesForPair({
    required String jwt,
    required String currentUserId,
    required String friendId,
  }) async {
    try {
      var conv = _conversations.values.firstWhere(
        (c) =>
            (c.userOne.userId == currentUserId && c.userTwo.userId == friendId) ||
            (c.userTwo.userId == currentUserId && c.userOne.userId == friendId),
      );
      final api = ConversationsApi(jwt);
      final j = await api.getConversationById(conv.conversationId);
      if (j == null) return;

      DateTime? lastMessageAt;
      try {
        final lm = (j['lastMessageAt'] ?? '').toString();
        lastMessageAt = lm.isNotEmpty ? DateTime.parse(lm) : null;
      } catch (_) {
        lastMessageAt = null;
      }
      // messages là field final → không thể gán trực tiếp.
      // Tạo bản sao conversation với danh sách messages rỗng và cập nhật vào map.
      conv = conv.copyWith(messages: []);
      _conversations[conv.conversationId] = conv;

      List<dynamic> msgsRaw = [];
      try {
        msgsRaw = (j['messages'] ?? []) as List<dynamic>;
      } catch (_) {}
      for (final m in msgsRaw) {
        try {
          final mm = m as Map<String, dynamic>;
          DateTime sentAt;
          try {
            sentAt = DateTime.parse((mm['sentAt'] ?? '').toString());
          } catch (_) {
            sentAt = DateTime.now();
          }
          final senderMap = (mm['sender'] ?? {}) as Map<String, dynamic>;
          final sender = User(
            userId: (senderMap['userId'] ?? '').toString(),
            username: (senderMap['username'] ?? '').toString(),
            fullName: (senderMap['fullName'] ?? '').toString(),
            phoneNumber: (senderMap['phoneNumber'] ?? '').toString(),
            email: (senderMap['email'] ?? '').toString(),
            profilePictureUrl: (senderMap['profilePictureUrl'] ?? '').toString().isNotEmpty
                ? (senderMap['profilePictureUrl'] as String?)
                : null,
            passwordHash: '',
            subscriptionStatus: SubscriptionStatus.FREE,
            subscriptionExpiresAt: null,
            accountStatus: AccountStatus.ACTIVE,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          conv.messages!.add(
            Message(
              messageId: (mm['messageId'] ?? '').toString(),
              conversation: conv,
              sender: sender,
              content: (mm['content'] ?? '').toString(),
              repliedToPost: null,
              sentAt: sentAt,
            ),
          );
        } catch (_) {}
      }
      // Cập nhật lastMessageAt nếu có
      if (lastMessageAt != null) {
        _conversations[conv.conversationId] = conv.copyWith(
          lastMessageAt: lastMessageAt,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('loadRemoteMessagesForPair error: $e');
    }
  }

  /// Gửi tin nhắn kèm post được reply (dùng khi gửi từ FeedView)
  void sendMessageWithPost(
    String currentUserId,
    String friendId,
    String content,
    Post repliedPost,
  ) {
    final conv = _conversations.values.firstWhere(
      (c) =>
          (c.userOne.userId == currentUserId && c.userTwo.userId == friendId) ||
          (c.userTwo.userId == currentUserId && c.userOne.userId == friendId),
      orElse: () => _createConversation(currentUserId, friendId),
    );

    final sender = userViewModel.getUserById(currentUserId);
    if (sender == null) return;

    final msg = Message(
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      conversation: conv,
      sender: sender,
      content: content,
      repliedToPost: repliedPost,
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
      content: "Wanna play soccer this weekend?",
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
      content: "Is the new game out? Worth playing?",
            sentAt: now.subtract(const Duration(days: 1, hours: 2)),
          ),
          Message(
            messageId: 'm2_${conv.conversationId}',
            conversation: conv,
            sender: user,
      content: "Yes, story is good. Free tonight?",
            sentAt: now.subtract(const Duration(days: 1, hours: 1, minutes: 20)),
          ),
          Message(
            messageId: 'm3_${conv.conversationId}',
            conversation: conv,
            sender: friend,
      content: "Free, let's do some co-op levels!",
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
      content: "Looks great, shall we visit Ba Na Hills?",
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
      content: "Wanna see? I’ll send more photos later.",
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
