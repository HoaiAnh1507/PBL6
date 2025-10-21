import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/friendship_model.dart';

class ChatViewModel extends ChangeNotifier {
  final List<User> _users = [];
  final List<Friendship> _friendships = [];

  List<User> get users => List.unmodifiable(_users);
  List<Friendship> get friendships => List.unmodifiable(_friendships);

  ChatViewModel() {
    _loadMockData();
  }

  void _loadMockData() {
    // ---- Fake Users ----
    final now = DateTime.now();
    final user1 = User(
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
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );

    final user2 = User(
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
      createdAt: now.subtract(const Duration(days: 25)),
      updatedAt: now,
    );

    final user3 = User(
      userId: 'u3',
      phoneNumber: '0900000003',
      username: 'rin',
      email: 'rin@example.com',
      fullName: 'Nguyen Thi Rin',
      profilePictureUrl: 'https://i.pravatar.cc/150?img=3',
      passwordHash: 'hash3',
      subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null,
      accountStatus: AccountStatus.ACTIVE,
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now,
    );

    final user4 = User(
      userId: 'u4',
      phoneNumber: '0900000004',
      username: 'khoi',
      email: 'khoi@example.com',
      fullName: 'Le Van Khoi',
      profilePictureUrl: 'https://i.pravatar.cc/150?img=4',
      passwordHash: 'hash4',
      subscriptionStatus: SubscriptionStatus.GOLD,
      subscriptionExpiresAt: now.add(const Duration(days: 60)),
      accountStatus: AccountStatus.ACTIVE,
      createdAt: now.subtract(const Duration(days: 18)),
      updatedAt: now,
    );

    final user5 = User(
      userId: 'u5',
      phoneNumber: '0900000005',
      username: 'hcon',
      email: 'hcon@example.com',
      fullName: 'Pham Huu Con',
      profilePictureUrl: 'https://i.pravatar.cc/150?img=5',
      passwordHash: 'hash5',
      subscriptionStatus: SubscriptionStatus.FREE,
      subscriptionExpiresAt: null,
      accountStatus: AccountStatus.SUSPENDED,
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now,
    );

    _users.addAll([user1, user2, user3, user4, user5]);

    // ---- Fake Friendships ----
    _friendships.addAll([
      Friendship(
        friendshipId: 'f1',
        userOne: user1,
        userTwo: user2,
        status: FriendshipStatus.accepted,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Friendship(
        friendshipId: 'f2',
        userOne: user1,
        userTwo: user3,
        status: FriendshipStatus.pending,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Friendship(
        friendshipId: 'f3',
        userOne: user1,
        userTwo: user4,
        status: FriendshipStatus.accepted,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Friendship(
        friendshipId: 'f4',
        userOne: user1,
        userTwo: user5,
        status: FriendshipStatus.blocked,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    ]);

    notifyListeners();
  }

  // ✅ Lấy danh sách bạn bè (đã accepted)
  List<User> getAcceptedFriends(String userId) {
    final accepted = _friendships.where(
      (f) =>
          f.status == FriendshipStatus.accepted &&
          (f.userOne?.userId == userId || f.userTwo?.userId == userId),
    );

    return accepted.map((f) {
      return f.userOne?.userId == userId ? f.userTwo! : f.userOne!;
    }).toList();
  }

  // ✅ Lấy danh sách lời mời kết bạn (pending)
  List<Friendship> getFriendRequests(String userId) {
    return _friendships.where(
      (f) =>
          f.status == FriendshipStatus.pending &&
          f.userTwo?.userId == userId,
    ).toList();
  }

  // ✅ Chấp nhận lời mời
  void acceptFriendRequest(String friendshipId) {
    final index = _friendships.indexWhere((f) => f.friendshipId == friendshipId);
    if (index != -1) {
      _friendships[index] =
          _friendships[index].copyWith(status: FriendshipStatus.accepted);
      notifyListeners();
    }
  }

  // ✅ Chặn bạn
  void blockFriend(String friendshipId) {
    final index = _friendships.indexWhere((f) => f.friendshipId == friendshipId);
    if (index != -1) {
      _friendships[index] =
          _friendships[index].copyWith(status: FriendshipStatus.blocked);
      notifyListeners();
    }
  }
}
