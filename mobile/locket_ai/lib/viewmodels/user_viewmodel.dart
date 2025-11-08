import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserViewModel extends ChangeNotifier {
  final List<User> _users = [];
  User? _currentUser;

  List<User> get users => List.unmodifiable(_users);
  User? get currentUser => _currentUser;

  UserViewModel() {
    _loadMockData();
  }

  void _loadMockData() {
    final now = DateTime.now();

    _users.addAll([
      User(
        userId: 'u0',
        phoneNumber: '0900000000',
        username: 'me',
        email: 'me@example.com',
        fullName: 'Tôi',
        profilePictureUrl: 'https://i.pravatar.cc/150?img=5',
        passwordHash: 'me',
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
        createdAt: now.subtract(const Duration(days: 30)),
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
        createdAt: now.subtract(const Duration(days: 25)),
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
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
      ),
    ]);

    notifyListeners();
  }

  // ✅ Login
  void login(String userId) {
    final found = _users.firstWhere(
      (u) => u.userId == userId,
      orElse: () => throw Exception("Không tìm thấy user $userId"),
    );
    _currentUser = found;
    notifyListeners();
  }

  // ✅ Set current user từ Auth (thêm vào danh sách nếu chưa có)
  void setCurrentUser(User user) {
    final idx = _users.indexWhere((u) => u.userId == user.userId);
    if (idx == -1) {
      _users.insert(0, user);
    } else {
      _users[idx] = user;
    }
    _currentUser = user;
    notifyListeners();
  }

  // ✅ Logout
  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // ✅ Lấy user theo ID
  User? getUserById(String userId) {
    return _users.firstWhere(
      (u) => u.userId == userId,
    );
  }
}
