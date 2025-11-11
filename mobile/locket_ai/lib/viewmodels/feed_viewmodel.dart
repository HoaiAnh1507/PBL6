import 'package:flutter/material.dart';
import 'package:locket_ai/models/friendship_model.dart';
import 'package:locket_ai/models/user_model.dart';
import '../models/post_model.dart';
import 'user_viewmodel.dart';
import 'friendship_viewmodel.dart';
import 'package:locket_ai/services/posts_api.dart';

class FeedViewModel extends ChangeNotifier {
  late UserViewModel userVM;
  late FriendshipViewModel friendshipVM;
  
  List<Post> posts = [];
  bool loading = false;
  bool _hasLoadedSamples = false;

  FeedViewModel();

  /// Gán dependencies
  void setDependencies(UserViewModel userVM, FriendshipViewModel friendshipVM) {
    this.userVM = userVM;
    this.friendshipVM = friendshipVM;
    // Chỉ tải dữ liệu mẫu một lần, tránh ghi đè bài đăng người dùng
    if (!_hasLoadedSamples && posts.isEmpty) {
      loadSamplePosts();
    }
  }

  /// Tải danh sách post giả lập
  Future<void> loadSamplePosts() async {

    loading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // Giả lập API

    final users = userVM.users;

    posts = [
      Post(
        postId: 'p1',
        user: users.firstWhere((u) => u.userId == 'u1'),
        mediaType: MediaType.PHOTO,
        mediaUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        generatedCaption: 'Cảnh hoàng hôn tuyệt đẹp 🌇',
        captionStatus: CaptionStatus.COMPLETED,
        userEditedCaption: 'Thật yên bình sau một ngày dài.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Post(
        postId: 'p2',
        user: users.firstWhere((u) => u.userId == 'u3'),
        mediaType: MediaType.VIDEO,
        mediaUrl: 'https://media.istockphoto.com/id/1158647615/vi/video/c%E1%BA%ADn-c%E1%BA%A3nh-kh%C3%A1ch-h%C3%A0ng-n%E1%BB%AF-kh%C3%B4ng-th%E1%BB%83-nh%E1%BA%ADn-ra-khi-ch%E1%BB%8Dn-m%E1%BA%ABu-m%C3%A0u-t%E1%BA%A1i-c%E1%BB%ADa-h%C3%A0ng-s%C6%A1n.mp4?s=mp4-640x640-is&k=20&c=OYu9bqJ2XuUZt0FcNVbeHXo05w9UmSv2gC481Ik2KuM=',
        generatedCaption: 'Một ngày năng động cùng bạn bè 🎥',
        captionStatus: CaptionStatus.COMPLETED,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Post(
        postId: 'p3',
        user: users.firstWhere((u) => u.userId == 'u2'),
        mediaType: MediaType.PHOTO,
        mediaUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
        generatedCaption: 'Một góc cà phê chill ☕',
        captionStatus: CaptionStatus.COMPLETED,
        userEditedCaption: 'Buổi sáng bắt đầu với năng lượng tích cực!',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];

    loading = false;
    _hasLoadedSamples = true;
    notifyListeners();
  }

  /// Tải feed từ backend và gán vào `posts`
  Future<void> loadRemoteFeed({required String jwt, required User current}) async {
    loading = true;
    notifyListeners();

    try {
      final api = PostsApi(jwt: jwt);
      final raw = await api.listPosts();

      final mapped = <Post>[];
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          try {
            // Ưu tiên parse theo Post.fromJson nếu cấu trúc chuẩn
            if (item.containsKey('postId') && item.containsKey('user')) {
              mapped.add(Post.fromJson(item));
              continue;
            }

            // Fallback: map thủ công với các khóa phổ biến
            final userJson = (item['user'] ?? item['author'] ?? {}) as Map<String, dynamic>;
            Map<String, dynamic> normalizedUser = {
              'userId': userJson['userId'] ?? userJson['id'] ?? (item['userId'] ?? item['authorId'] ?? 'unknown'),
              'phoneNumber': userJson['phoneNumber'] ?? '',
              'username': userJson['username'] ?? userJson['name'] ?? 'unknown',
              'email': userJson['email'] ?? '',
              'fullName': userJson['fullName'] ?? userJson['username'] ?? 'unknown',
              'profilePictureUrl': userJson['profilePictureUrl'] ?? userJson['avatarUrl'] ?? userJson['avatar'],
              'passwordHash': userJson['passwordHash'] ?? '',
              'subscriptionStatus': userJson['subscriptionStatus'] ?? 'FREE',
              'subscriptionExpiresAt': userJson['subscriptionExpiresAt'],
              'accountStatus': userJson['accountStatus'] ?? 'ACTIVE',
              'createdAt': userJson['createdAt'] ?? DateTime.now().toIso8601String(),
              'updatedAt': userJson['updatedAt'] ?? DateTime.now().toIso8601String(),
            };

            final typeStr = (item['mediaType'] ?? item['type'] ?? 'PHOTO').toString().toUpperCase();
            final statusStr = (item['captionStatus'] ?? item['status'] ?? 'PENDING').toString().toUpperCase();
            final createdStr = item['createdAt'] ?? item['created_at'] ?? DateTime.now().toIso8601String();

            final post = Post(
              postId: item['postId']?.toString() ?? item['id']?.toString() ?? 'unknown',
              user: User.fromJson(normalizedUser),
              mediaType: MediaType.values.firstWhere(
                (e) => e.name == typeStr,
                orElse: () => MediaType.PHOTO,
              ),
              mediaUrl: item['mediaUrl']?.toString() ?? item['url']?.toString() ?? item['contentUrl']?.toString() ?? '',
              generatedCaption: item['generatedCaption']?.toString() ?? item['caption']?.toString(),
              captionStatus: CaptionStatus.values.firstWhere(
                (e) => e.name == statusStr,
                orElse: () => CaptionStatus.PENDING,
              ),
              userEditedCaption: item['userEditedCaption']?.toString(),
              createdAt: DateTime.tryParse(createdStr) ?? DateTime.now(),
            );
            mapped.add(post);
          } catch (_) {
            // Bỏ qua bài đăng lỗi cấu trúc
          }
        }
      }

      posts = mapped;
    } finally {
      loading = false;
      _hasLoadedSamples = true; // Tránh tải sample ghi đè
      notifyListeners();
    }
  }

  void addPost(Post post) {
    posts.insert(0, post);
    notifyListeners();
  }

  void removePost(String postId) {
    posts.removeWhere((p) => p.postId == postId);
    notifyListeners();
  }

  /// Lấy danh sách post hiển thị cho currentUser (post của bản thân + bạn bè)
  List<Post> getVisiblePosts({required User currentUser}) {
    // Lấy những quan hệ mà currentUser là một trong hai bên và đã accepted
    final friends = friendshipVM.friendships
        .where((f) =>
            f.status == FriendshipStatus.accepted &&
            (f.userOne?.userId == currentUser.userId ||
            f.userTwo?.userId == currentUser.userId))
        .map((f) {
          // Trả về user còn lại trong quan hệ
          return f.userOne?.userId == currentUser.userId ? f.userTwo : f.userOne;
        })
        .toList();

    // Tạo tập ID được phép hiển thị: currentUser + bạn bè
    final allowedIds = <String>{currentUser.userId, ...friends.map((u) => u!.userId)};

    // Lọc posts theo ID
    return posts.where((p) => allowedIds.contains(p.user.userId)).toList();
  }

}
