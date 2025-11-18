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

  // Filter state for FeedView
  FeedFilterType _filterType = FeedFilterType.all;
  User? _selectedFriend;

  FeedFilterType get filterType => _filterType;
  User? get selectedFriend => _selectedFriend;

  String get filterLabel {
    switch (_filterType) {
      case FeedFilterType.all:
        return 'All';
      case FeedFilterType.me:
        return 'Me';
      case FeedFilterType.friend:
        return _selectedFriend?.username ?? _selectedFriend?.fullName ?? 'friend';
    }
  }

  void setFilterAll() {
    _filterType = FeedFilterType.all;
    _selectedFriend = null;
    notifyListeners();
  }

  void setFilterMe() {
    _filterType = FeedFilterType.me;
    _selectedFriend = null;
    notifyListeners();
  }

  void setFilterFriend(User friend) {
    _filterType = FeedFilterType.friend;
    _selectedFriend = friend;
    notifyListeners();
  }

  FeedViewModel();

  /// Gán dependencies
  void setDependencies(UserViewModel userVM, FriendshipViewModel friendshipVM) {
    this.userVM = userVM;
    this.friendshipVM = friendshipVM;
  }

  // Sample feed đã bị loại bỏ.

  /// Kiểm tra một item post từ API có hiển thị cho người dùng hay không,
  /// dựa trên các trường recipients phổ biến. Nếu không có trường recipients → coi là public.
  bool _isVisibleToUser(Map<String, dynamic> item, String currentUserId) {
    // Tác giả luôn thấy bài của chính mình
    final authorId = (item['user'] is Map && (item['user']['userId'] != null))
        ? item['user']['userId'].toString()
        : (item['authorId']?.toString());
    if (authorId != null && authorId == currentUserId) return true;

    // 1) recipientIds: ["id1", "id2"]
    if (item['recipientIds'] is List) {
      final ids = (item['recipientIds'] as List).map((e) => e.toString()).toList();
      if (ids.isEmpty) return true; // rỗng → public
      return ids.contains(currentUserId);
    }

    // 2) postRecipients: [{ recipient: { userId: "..." } }, ...]
    if (item['postRecipients'] is List) {
      final list = (item['postRecipients'] as List)
          .whereType<Map>()
          .map((e) => e['recipient'])
          .whereType<Map>()
          .map((r) => r['userId']?.toString())
          .whereType<String>()
          .toList();
      if (list.isEmpty) return true; // rỗng → public
      return list.contains(currentUserId);
    }

    // 3) recipients: có thể là list id hoặc list user
    if (item['recipients'] is List) {
      final rec = item['recipients'] as List;
      if (rec.isEmpty) return true; // rỗng → public
      // nếu là list id
      final ids = rec.where((e) => e is String || e is num).map((e) => e.toString()).toList();
      if (ids.isNotEmpty) return ids.contains(currentUserId);
      // nếu là list user
      final userIds = rec
          .whereType<Map>()
          .map((u) => u['userId']?.toString())
          .whereType<String>()
          .toList();
      if (userIds.isNotEmpty) return userIds.contains(currentUserId);
    }

    // Không có trường recipients → coi là public
    return true;
  }

  /// Tải feed từ backend và gán vào `posts`
  /// All: bài tôi đăng + bài người khác chia sẻ cho tôi (do backend lọc theo recipients)
  Future<void> loadRemoteFeed({required String jwt, required User current}) async {
    loading = true;
    notifyListeners();

    try {
      final api = PostsApi(jwt: jwt);
      final raw = await api.listFeed();
      debugPrint('[FeedVM] listFeed returned ${raw.length} items for user=${current.userId}');

      final mapped = <Post>[];
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          try {
            // Ưu tiên parse theo Post.fromJson nếu cấu trúc chuẩn
            if (item.containsKey('postId') && item.containsKey('user')) {
              // Chuẩn hóa caption key: backend dùng 'caption'
              final normalized = Map<String, dynamic>.from(item);
              if (!normalized.containsKey('generatedCaption') && normalized['caption'] != null) {
                normalized['generatedCaption'] = normalized['caption'];
              }
              mapped.add(Post.fromJson(normalized));
              // Log key info for diagnostics
              debugPrint('[FeedVM] Mapped post ${normalized['postId']} by ${normalized['user']?['username'] ?? normalized['user']?['userId']}');
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
            debugPrint('[FeedVM] Fallback mapped post ${post.postId} by ${post.user.username}');
          } catch (_) {
            // Bỏ qua bài đăng lỗi cấu trúc
          }
        }
      }

      posts = mapped;
      debugPrint('[FeedVM] Final mapped posts: ${posts.length}');
    } finally {
      loading = false;
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

  // ✅ Xóa toàn bộ dữ liệu đã fetch cho feed (posts + trạng thái filter)
  void clearAll() {
    posts.clear();
    loading = false;
    _filterType = FeedFilterType.all;
    _selectedFriend = null;
    notifyListeners();
  }

  /// Lấy danh sách post hiển thị cho currentUser (post của bản thân + bạn bè)
  List<Post> getVisiblePosts({required User currentUser}) {
    // Tính danh sách bạn bè đã accepted
    final acceptedFriends = friendshipVM.friendships
        .where((f) =>
            f.status == FriendshipStatus.accepted &&
            (f.userOne?.userId == currentUser.userId || f.userTwo?.userId == currentUser.userId))
        .map((f) => f.userOne?.userId == currentUser.userId ? f.userTwo : f.userOne)
        .whereType<User>()
        .toList();

    bool isAcceptedWithAuthor(String authorId) {
      return acceptedFriends.any((u) => u.userId == authorId);
    }

    Iterable<Post> filtered;
    switch (_filterType) {
      case FeedFilterType.all:
        // 'All' chỉ hiển thị: bài của tôi hoặc bài của bạn bè đã ACCEPTED
        filtered = posts.where((p) =>
          p.user.userId == currentUser.userId || isAcceptedWithAuthor(p.user.userId)
        );
        break;
      case FeedFilterType.me:
        filtered = posts.where((p) => p.user.userId == currentUser.userId);
        break;
      case FeedFilterType.friend:
        final friendId = _selectedFriend?.userId;
        final isAccepted = friendId != null && acceptedFriends.any((u) => u.userId == friendId);
        if (!isAccepted || friendId == null) {
          filtered = const [];
        } else {
          filtered = posts.where((p) => p.user.userId == friendId);
        }
        break;
    }

    // Sắp xếp theo thời gian mới nhất trước
    final sorted = filtered.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

}

enum FeedFilterType { all, me, friend }
