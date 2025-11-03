import 'package:flutter/foundation.dart';
import '../models/friendship_model.dart';
import '../models/user_model.dart';

class FriendshipViewModel extends ChangeNotifier {
  final List<Friendship> _friendships = [];
  bool _loading = false;

  bool get loading => _loading;
  List<Friendship> get friendships => List.unmodifiable(_friendships);

  /// Tải danh sách bạn bè (mock data)
  Future<void> loadFriendships(User currentUser) async {
    _loading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final now = DateTime.now();

      // Dữ liệu user giả
      final users = [
        User(
          userId: 'u0',
          phoneNumber: '0900000000',
          username: 'me',
          email: 'me@example.com',
          fullName: 'Tôi',
          profilePictureUrl: 'https://i.pravatar.cc/150?img=5',
          passwordHash: 'hashed_pw_me',
          subscriptionStatus: SubscriptionStatus.FREE,
          subscriptionExpiresAt: null,
          accountStatus: AccountStatus.ACTIVE,
          createdAt: now,
          updatedAt: now,
        ),
        User(
          userId: 'u1',
          phoneNumber: '0900000001',
          username: 'tuan',
          email: 'tuan@example.com',
          fullName: 'Nguyen Van Tuan',
          profilePictureUrl: 'https://i.pravatar.cc/150?img=1',
          passwordHash: 'hash1',
          subscriptionStatus: SubscriptionStatus.FREE,
          subscriptionExpiresAt: null,
          accountStatus: AccountStatus.ACTIVE,
          createdAt: now,
          updatedAt: now,
        ),
        User(
          userId: 'u2',
          phoneNumber: '0900000002',
          username: 'hieu',
          email: 'hieu@example.com',
          fullName: 'Tran Van Hieu',
          profilePictureUrl: 'https://i.pravatar.cc/150?img=2',
          passwordHash: 'hash2',
          subscriptionStatus: SubscriptionStatus.GOLD,
          subscriptionExpiresAt: now.add(const Duration(days: 15)),
          accountStatus: AccountStatus.ACTIVE,
          createdAt: now,
          updatedAt: now,
        ),
        User(
          userId: 'u3',
          phoneNumber: '0900000003',
          username: 'rin',
          email: 'rin@example.com',
          fullName: 'Nguyen Thi Rin',
          profilePictureUrl: 'https://i.pravatar.cc/150?img=3',
          passwordHash: 'hash3',
          subscriptionStatus: SubscriptionStatus.FREE,
          subscriptionExpiresAt: null,
          accountStatus: AccountStatus.SUSPENDED,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      _friendships.clear();

      // Nếu currentUser là u0 → tạo quan hệ accepted với 3 user còn lại
      for (final friend in users.where((u) => u.userId != 'u0')) {
        _friendships.add(
          Friendship(
            friendshipId: 'f_${currentUser.userId}_${friend.userId}',
            userOne: users.firstWhere((u) => u.userId == 'u0'),
            userTwo: friend,
            status: FriendshipStatus.accepted,
            createdAt: now,
          ),
        );
      }

      // Thêm quan hệ riêng giữa u1 và u2
      final u1 = users.firstWhere((u) => u.userId == 'u1');
      final u2 = users.firstWhere((u) => u.userId == 'u2');

      _friendships.add(
        Friendship(
          friendshipId: 'f_u1_u2',
          userOne: u1,
          userTwo: u2,
          status: FriendshipStatus.accepted,
          createdAt: now,
        ),
      );

    } catch (e) {
      if (kDebugMode) print('Error loading friendships: $e');
    }

    _loading = false;
    notifyListeners();
  }

  /// Gửi lời mời kết bạn
  Future<void> sendFriendRequest(User from, User to) async {
    final friendship = Friendship(
      friendshipId: DateTime.now().millisecondsSinceEpoch.toString(),
      userOne: from,
      userTwo: to,
      status: FriendshipStatus.pending,
      createdAt: DateTime.now(),
    );
    _friendships.add(friendship);
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
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
