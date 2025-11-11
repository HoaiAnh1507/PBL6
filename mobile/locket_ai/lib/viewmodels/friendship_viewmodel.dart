import 'package:flutter/foundation.dart';
import '../services/friendships_api.dart';
import '../models/friendship_model.dart';
import '../models/user_model.dart';

class FriendshipViewModel extends ChangeNotifier {
  final List<Friendship> _friendships = [];
  bool _loading = false;

  bool get loading => _loading;
  List<Friendship> get friendships => List.unmodifiable(_friendships);

  // Mock friendships đã bị loại bỏ. Sử dụng các hàm remote bên dưới.

  /// Tải danh sách bạn bè đã chấp nhận từ backend và đồng bộ vào state
  Future<void> loadFriendsRemote({
    required String jwt,
    required User current,
  }) async {
    try {
      final api = FriendshipsApi(jwt);
      final raw = await api.listFriends();
      final now = DateTime.now();

      // Chuyển PublicUserResponse[] thành User[]
      final friends = raw.map((e) {
        final m = e as Map<String, dynamic>;
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
      }).whereType<User>().toList();

      // Loại bỏ các quan hệ accepted hiện tại liên quan đến current để tránh trùng
      _friendships.removeWhere((f) {
        final isPair = (f.userOne?.userId == current.userId) || (f.userTwo?.userId == current.userId);
        return isPair && f.status == FriendshipStatus.accepted;
      });

      // Thêm lại danh sách accepted mới từ backend
      for (final friend in friends) {
        final fid = 'acc_${current.userId}_${friend.userId}';
        _friendships.add(
          Friendship(
            friendshipId: fid,
            userOne: current,
            userTwo: friend,
            status: FriendshipStatus.accepted,
            createdAt: now,
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('loadFriendsRemote error: $e');
    }
  }

  /// Update status of a friendship locally and notify listeners (optimistic UI)
  void updateFriendshipStatus(String friendshipId, FriendshipStatus status) {
    final index = _friendships.indexWhere((f) => f.friendshipId == friendshipId);
    if (index == -1) return;
    _friendships[index] = _friendships[index].copyWith(status: status);
    notifyListeners();
  }

  // Gửi lời mời kết bạn mock đã bị loại bỏ. Dùng sendFriendRequestRemote.

  // ===== Backend-integrated actions =====

  /// Gửi lời mời kết bạn qua backend, sau đó cập nhật local state (pending)
  Future<bool> sendFriendRequestRemote({
    required String jwt,
    required User from,
    required User to,
  }) async {
    try {
      final api = FriendshipsApi(jwt);
      final ok = await api.sendRequest(to.username);
      if (ok) {
        final friendship = Friendship(
          friendshipId: DateTime.now().millisecondsSinceEpoch.toString(),
          userOne: from,
          userTwo: to,
          status: FriendshipStatus.pending,
          createdAt: DateTime.now(),
        );
        _friendships.add(friendship);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('sendFriendRequestRemote error: $e');
      return false;
    }
  }

  /// Hủy lời mời đã gửi (backend hiện CHƯA có endpoint riêng cho sender cancel)
  Future<bool> cancelSentRequestRemote({
    required String jwt,
    required User from,
    required User to,
  }) async {
    // Placeholder: cần backend hỗ trợ. Tạm thời xóa local nếu có.
    try {
      final idx = _friendships.indexWhere((f) =>
          f.status == FriendshipStatus.pending &&
          f.userOne?.userId == from.userId &&
          f.userTwo?.userId == to.userId);
      if (idx != -1) {
        _friendships.removeAt(idx);
        notifyListeners();
        return true; // chỉ local
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Chấp nhận lời mời đến tôi qua backend
  Future<bool> acceptFriendRequestRemote({
    required String jwt,
    required Friendship pending,
    required User current,
  }) async {
    try {
      final api = FriendshipsApi(jwt);
      // Determine sender robustly as the "other" user in the pending pair
      final isCurrentUserOne = pending.userOne?.userId == current.userId;
      final otherUser = isCurrentUserOne ? pending.userTwo : pending.userOne;
      final senderUsername = otherUser?.username ?? '';
      if (senderUsername.isEmpty) return false;
      final ok = await api.accept(senderUsername);
      if (ok) {
        final index = _friendships.indexWhere((f) => f.friendshipId == pending.friendshipId);
        if (index != -1) {
          _friendships[index] = _friendships[index].copyWith(status: FriendshipStatus.accepted);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('acceptFriendRequestRemote error: $e');
      return false;
    }
  }

  /// Từ chối lời mời đến tôi qua backend
  Future<bool> rejectFriendRequestRemote({
    required String jwt,
    required Friendship pending,
    required User current,
  }) async {
    try {
      final api = FriendshipsApi(jwt);
      // Determine sender robustly as the "other" user in the pending pair
      final isCurrentUserOne = pending.userOne?.userId == current.userId;
      final otherUser = isCurrentUserOne ? pending.userTwo : pending.userOne;
      final senderUsername = otherUser?.username ?? '';
      if (senderUsername.isEmpty) return false;
      final ok = await api.reject(senderUsername);
      if (ok) {
        _friendships.removeWhere((f) => f.friendshipId == pending.friendshipId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('rejectFriendRequestRemote error: $e');
      return false;
    }
  }

  /// Hủy kết bạn qua backend
  Future<bool> unfriendRemote({
    required String jwt,
    required User current,
    required User target,
  }) async {
    try {
      final api = FriendshipsApi(jwt);
      final ok = await api.unfriend(target.username);
      if (ok) {
        _friendships.removeWhere((f) {
          final isPair = (f.userOne?.userId == current.userId && f.userTwo?.userId == target.userId) ||
              (f.userTwo?.userId == current.userId && f.userOne?.userId == target.userId);
        
          return isPair && f.status == FriendshipStatus.accepted;
        });
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('unfriendRemote error: $e');
      return false;
    }
  }

  /// Chấp nhận lời mời
  Future<void> acceptFriendRequest(String friendshipId) async {
    final index = _friendships.indexWhere((f) => f.friendshipId == friendshipId);
    if (index == -1) return;
    _friendships[index] =
        _friendships[index].copyWith(status: FriendshipStatus.accepted);
    notifyListeners();
  }

  /// Chặn bạn bè
  Future<void> blockFriendship(String friendshipId) async {
    final index = _friendships.indexWhere((f) => f.friendshipId == friendshipId);
    if (index == -1) return;
    _friendships[index] =
        _friendships[index].copyWith(status: FriendshipStatus.blocked);
    notifyListeners();
  }

  /// Bỏ chặn bạn bè
  Future<void> unblockFriendship(String friendshipId) async {
    final index = _friendships.indexWhere((f) => f.friendshipId == friendshipId);
    if (index == -1) return;
    _friendships[index] =
        _friendships[index].copyWith(status: FriendshipStatus.accepted);
    notifyListeners();
  }

  /// Huỷ kết bạn 
  Future<void> removeFriendship(String friendshipId) async {
    _friendships.removeWhere((f) => f.friendshipId == friendshipId);
    notifyListeners();
  }

  // ✅ Xóa toàn bộ dữ liệu đã fetch liên quan đến bạn bè (accepted, pending, blocked)
  void clearAll() {
    _friendships.clear();
    _loading = false;
    notifyListeners();
  }

  /// Đồng bộ danh sách pending (incoming + sent) từ backend
  Future<void> loadRequestsRemote({
    required String jwt,
    required String currentUserId,
  }) async {
    try {
      final api = FriendshipsApi(jwt);
      final data = await api.listRequests();

      List<Friendship> parseList(List<dynamic> rawList) {
        return rawList.map((e) {
          final m = e as Map<String, dynamic>;
          // Hỗ trợ cả 2 dạng: có nested userOne/userTwo hoặc DTO phẳng từ backend
          if (m.containsKey('userOne') || m.containsKey('userTwo')) {
            return Friendship.fromJson(m);
          }

          // DTO phẳng: FriendshipResponse { userOneId, userOneUsername, userOneName, ... }
          String id = (m['friendshipId'] ?? '').toString();
          String statusStr = (m['status'] ?? '').toString();
          DateTime createdAt;
          try {
            createdAt = DateTime.parse(m['createdAt'].toString());
          } catch (_) {
            createdAt = DateTime.now();
          }

          FriendshipStatus status;
          switch (statusStr.toUpperCase()) {
            case 'ACCEPTED':
              status = FriendshipStatus.accepted;
              break;
            case 'BLOCKED':
              status = FriendshipStatus.blocked;
              break;
            default:
              status = FriendshipStatus.pending;
          }

          User makeUser({required String id, required String username, required String name}) {
            final now = DateTime.now();
            return User(
              userId: id,
              phoneNumber: '',
              username: username,
              email: '',
              fullName: name,
              profilePictureUrl: null,
              passwordHash: '',
              subscriptionStatus: SubscriptionStatus.FREE,
              subscriptionExpiresAt: null,
              accountStatus: AccountStatus.ACTIVE,
              createdAt: now,
              updatedAt: now,
            );
          }

          final u1 = makeUser(
            id: (m['userOneId'] ?? '').toString(),
            username: (m['userOneUsername'] ?? '').toString(),
            name: (m['userOneName'] ?? '').toString(),
          );
          final u2 = makeUser(
            id: (m['userTwoId'] ?? '').toString(),
            username: (m['userTwoUsername'] ?? '').toString(),
            name: (m['userTwoName'] ?? '').toString(),
          );

          return Friendship(
            friendshipId: id,
            userOne: u1,
            userTwo: u2,
            status: status,
            createdAt: createdAt,
          );
        }).toList();
      }

      final incomingRaw = (data['incoming'] as List<dynamic>? ?? []);
      final sentRaw = (data['sent'] as List<dynamic>? ?? []);
      final incoming = parseList(incomingRaw);
      final sent = parseList(sentRaw);

      // Xóa pending cũ liên quan đến currentUser
      _friendships.removeWhere((f) =>
          f.status == FriendshipStatus.pending &&
          ((f.userTwo?.userId == currentUserId) || (f.userOne?.userId == currentUserId)));

      // Thêm pending mới
      _friendships.addAll(incoming);
      _friendships.addAll(sent);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('loadRequestsRemote error: $e');
    }
  }

  /// Lấy danh sách bạn bè đã chấp nhận
  List<User> get acceptedFriends {
    return _friendships
        .where((f) => f.status == FriendshipStatus.accepted)
        .expand((f) => [f.userOne, f.userTwo]) // Lấy cả 2 người
        .where((u) => u != null)
        .cast<User>()
        .toList();
  } 
}
