import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class FeedViewModel extends ChangeNotifier {
  List<Post> posts = [];
  bool loading = false;

  FeedViewModel() {
    loadSamplePosts();
  }

  Future<void> loadSamplePosts() async {
    loading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // giả lập API

    // Danh sách user giả (đầy đủ theo model User)
    final users = [
      User(
        userId: '1',
        phoneNumber: '0901234567',
        username: 'tuan.it',
        email: 'tuan@example.com',
        fullName: 'Nguyen Tuan',
        profilePictureUrl: 'https://randomuser.me/api/portraits/men/31.jpg',
        passwordHash: 'hashed_pw_1',
        subscriptionStatus: SubscriptionStatus.GOLD,
        subscriptionExpiresAt: DateTime.now().add(const Duration(days: 30)),
        accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
        updatedAt: DateTime.now(),
      ),
      User(
        userId: '2',
        phoneNumber: '0902345678',
        username: 'hieu.dev',
        email: 'hieu@example.com',
        fullName: 'Tran Hieu',
        profilePictureUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
        passwordHash: 'hashed_pw_2',
        subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null,
        accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now().subtract(const Duration(days: 50)),
        updatedAt: DateTime.now(),
      ),
      User(
        userId: '3',
        phoneNumber: '0903456789',
        username: 'rinny',
        email: 'rin@example.com',
        fullName: 'Pham Rin',
        profilePictureUrl: 'https://randomuser.me/api/portraits/women/21.jpg',
        passwordHash: 'hashed_pw_3',
        subscriptionStatus: SubscriptionStatus.GOLD,
        subscriptionExpiresAt: DateTime.now().add(const Duration(days: 60)),
        accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        updatedAt: DateTime.now(),
      ),
      User(
        userId: '4',
        phoneNumber: '0904567890',
        username: 'khoi.design',
        email: 'khoi@example.com',
        fullName: 'Le Khoi',
        profilePictureUrl: 'https://randomuser.me/api/portraits/men/45.jpg',
        passwordHash: 'hashed_pw_4',
        subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null,
        accountStatus: AccountStatus.ACTIVE,
        createdAt: DateTime.now().subtract(const Duration(days: 70)),
        updatedAt: DateTime.now(),
      ),
    ];

    // Danh sách bài viết giả
    posts = [
      Post(
        postId: 'p1',
        user: users[0],
        mediaType: MediaType.PHOTO,
        mediaUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        generatedCaption: 'Cảnh hoàng hôn tuyệt đẹp 🌇',
        captionStatus: CaptionStatus.COMPLETED,
        userEditedCaption: 'Thật yên bình sau một ngày dài.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Post(
        postId: 'p2',
        user: users[2],
        mediaType: MediaType.VIDEO,
        mediaUrl: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
        generatedCaption: 'Một ngày năng động cùng bạn bè 🎥',
        captionStatus: CaptionStatus.COMPLETED,
        userEditedCaption: null,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Post(
        postId: 'p3',
        user: users[1],
        mediaType: MediaType.PHOTO,
        mediaUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
        generatedCaption: 'Một góc cà phê chill ☕',
        captionStatus: CaptionStatus.COMPLETED,
        userEditedCaption: 'Buổi sáng bắt đầu với năng lượng tích cực!',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];

    loading = false;
    notifyListeners();
  }

  void addPost(Post post) {
    posts.insert(0, post);
    notifyListeners();
  }

  void removePost(String postId) {
    posts.removeWhere((p) => p.postId == postId);
    notifyListeners();
  }
}
