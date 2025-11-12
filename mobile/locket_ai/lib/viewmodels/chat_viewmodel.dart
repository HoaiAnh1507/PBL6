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

class ChatViewModel extends ChangeNotifier {
  late UserViewModel userViewModel;
  late FriendshipViewModel friendshipViewModel;

  final Map<String, Conversation> _conversations = {};
  final Set<String> _prefetchedPairs = <String>{};

  ChatViewModel();

  void setDependencies(UserViewModel userVM, FriendshipViewModel friendshipVM) {
    userViewModel = userVM;
    friendshipViewModel = friendshipVM;
  }

  // Mock loadDataForCurrentUser đã bị loại bỏ. Luôn dùng dữ liệu từ backend.

  /// Tải hội thoại từ backend nếu có JWT, fallback mock nếu không
  Future<void> loadRemoteConversations({
    required String jwt,
    required String currentUserId,
  }) async {
    try {
      final api = ConversationsApi(jwt);
      final rawList = await api.listConversations();
      // Không xóa toàn bộ cache hội thoại nữa để tránh mất tin nhắn đang có.
      // Thay vào đó, hợp nhất dữ liệu từ server với dữ liệu hiện có.

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
        final readFlag = ((m['read'] ?? m['isRead'] ?? false) == true);
        return Message(
          messageId: (m['messageId'] ?? '').toString(),
          conversation: conv,
          sender: sender,
          content: (m['content'] ?? '').toString(),
          repliedToPost: null,
          sentAt: sentAt,
          read: readFlag,
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

        // Hợp nhất với hội thoại hiện có theo cặp (userOne, userTwo)
        Conversation? existing;
        try {
          existing = _conversations.values.firstWhere(
            (c) =>
                (c.userOne.userId == u1.userId && c.userTwo.userId == u2.userId) ||
                (c.userOne.userId == u2.userId && c.userTwo.userId == u1.userId),
          );
        } catch (_) {
          existing = null;
        }

        // Nếu server không trả messages (hoặc rỗng) nhưng cache đang có → giữ lại cache
        if ((msgsRaw.isEmpty) && existing != null && (existing.messages != null) && existing.messages!.isNotEmpty) {
          final preserved = existing.copyWith(
            conversationId: conv.conversationId,
            lastMessageAt: lastMessageAt ?? existing.lastMessageAt,
            createdAt: createdAt,
          );
          // Xóa hội thoại cũ theo cặp để tránh duplicate
          final keysToRemove = _conversations.entries
              .where((e) =>
                  (e.value.userOne.userId == u1.userId && e.value.userTwo.userId == u2.userId) ||
                  (e.value.userOne.userId == u2.userId && e.value.userTwo.userId == u1.userId))
              .map((e) => e.key)
              .toList();
          for (final k in keysToRemove) {
            _conversations.remove(k);
          }
          _conversations[preserved.conversationId] = preserved;
        } else {
          // Có messages từ server hoặc chưa có cache → dùng dữ liệu mới nhất từ server
          final keysToRemove = _conversations.entries
              .where((e) =>
                  (e.value.userOne.userId == u1.userId && e.value.userTwo.userId == u2.userId) ||
                  (e.value.userOne.userId == u2.userId && e.value.userTwo.userId == u1.userId))
              .map((e) => e.key)
              .toList();
          for (final k in keysToRemove) {
            _conversations.remove(k);
          }
          _conversations[conv.conversationId] = conv;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('loadRemoteConversations error: $e');
    }
  }

  /// Prefetch latest messages for all conversations so ChatListView can show content immediately
  Future<void> prefetchLatestMessagesForAll({
    required String jwt,
    required String currentUserId,
  }) async {
    try {
      final convs = _conversations.values.toList();
      await Future.wait(convs.map((conv) async {
        final friendId = (conv.userOne.userId == currentUserId)
            ? conv.userTwo.userId
            : conv.userOne.userId;
        await loadRemoteMessagesForPair(
          jwt: jwt,
          currentUserId: currentUserId,
          friendId: friendId,
        );
      }));
    } catch (e) {
      debugPrint('prefetchLatestMessagesForAll error: $e');
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
        // Own message should be considered read
        read: true,
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
          final readFlag = ((mm['read'] ?? mm['isRead'] ?? false) == true);
          conv.messages!.add(
            Message(
              messageId: (mm['messageId'] ?? '').toString(),
              conversation: conv,
              sender: sender,
              content: (mm['content'] ?? '').toString(),
              repliedToPost: null,
              sentAt: sentAt,
              read: readFlag,
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

  /// Mark message as read on backend and update local state
  Future<bool> markMessageReadRemote({
    required String jwt,
    required String messageId,
  }) async {
    try {
      final api = MessagesApi(jwt);
      final ok = await api.markMessageAsRead(messageId: messageId);
      if (!ok) return false;
      // Update local message state
      for (final entry in _conversations.entries) {
        final conv = entry.value;
        final idx = conv.messages?.indexWhere((m) => m.messageId == messageId) ?? -1;
        if (idx != -1) {
          final msg = conv.messages![idx];
          conv.messages![idx] = msg.copyWith(read: true);
          notifyListeners();
          break;
        }
      }
      return true;
    } catch (e) {
      debugPrint('markMessageReadRemote error: $e');
      return false;
    }
  }

  /// Prefetch messages for all accepted friends of the current user
  Future<void> prefetchAllMessagesForCurrentUser({
    required String jwt,
    required String currentUserId,
  }) async {
    final friends = getAcceptedFriends(currentUserId);
    if (friends.isEmpty) return;
    final futures = <Future<void>>[];
    for (final friend in friends) {
      final key = currentUserId + '|' + friend.userId;
      if (_prefetchedPairs.contains(key)) continue;
      _prefetchedPairs.add(key);
      futures.add(loadRemoteMessagesForPair(
        jwt: jwt,
        currentUserId: currentUserId,
        friendId: friend.userId,
      ));
    }
    if (futures.isNotEmpty) {
      try {
        await Future.wait(futures);
      } catch (_) {}
    }
  }
  // Mock messages đã bị loại bỏ; chỉ sử dụng dữ liệu từ backend.
  
  // ✅ Xóa toàn bộ dữ liệu chat đã fetch (hội thoại + cặp đã prefetch)
  void clearAll() {
    _conversations.clear();
    _prefetchedPairs.clear();
    notifyListeners();
  }
}
