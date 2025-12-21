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
  
  // ✅ Infinite scrolling state
  bool isLoadingMore = false;
  bool hasMorePosts = true;
  String? oldestPostId; // Cursor = ID của post CŨ NHẤT
  final ScrollController scrollController = ScrollController();

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

  FeedViewModel() {
    _setupScrollListener();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  /// Setup scroll listener for infinite scrolling (scroll DOWN to load older posts)
  void _setupScrollListener() {
    scrollController.addListener(() {
      if (!scrollController.hasClients) return;
      
      final currentPosition = scrollController.position.pixels;
      final maxScroll = scrollController.position.maxScrollExtent;
      
      // Threshold: Load when 300px from bottom
      const threshold = 300.0;
      
      // Trigger load more: near bottom + not loading + has more posts
      if (maxScroll - currentPosition < threshold && 
          !isLoadingMore && 
          !loading &&
          hasMorePosts) {
        debugPrint('[FeedVM] 📍 Triggered load more at $currentPosition/$maxScroll');
        _loadMorePosts();
      }
    });
  }

  /// Gán dependencies
  void setDependencies(UserViewModel userVM, FriendshipViewModel friendshipVM) {
    this.userVM = userVM;
    this.friendshipVM = friendshipVM;
  }

  // Sample feed đã bị loại bỏ.

  /// Tải feed từ backend và gán vào `posts`
  /// All: bài tôi đăng + bài người khác chia sẻ cho tôi (do backend lọc theo recipients)
  /// ✅ Load initial posts (without cursor)
  Future<void> loadRemoteFeed({required String jwt, required User current}) async {
    if (loading) return;
    
    loading = true;
    hasMorePosts = true;
    oldestPostId = null;
    notifyListeners();

    try {
      final api = PostsApi(jwt: jwt);
      final raw = await api.listFeed(limit: 20); // Load 20 posts initially
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
          } catch (e) {
            debugPrint('[FeedVM] Error mapping post: $e');
          }
        }
      }

      posts = mapped;
      
      // Set cursor to oldest post ID (last in list)
      if (posts.isNotEmpty) {
        oldestPostId = posts.last.postId;
      }
      
      // Check if there might be more posts
      hasMorePosts = posts.length >= 20;
      
      debugPrint('[FeedVM] ✅ Loaded ${posts.length} initial posts, hasMore=$hasMorePosts, cursor=$oldestPostId');
    } catch (e) {
      debugPrint('[FeedVM] ❌ Error loading feed: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// ✅ Load more posts (when scrolling down) - private method called by scroll listener
  Future<void> _loadMorePosts() async {
    if (isLoadingMore || !hasMorePosts || oldestPostId == null) return;
    
    isLoadingMore = true;
    notifyListeners();

    try {
      // Note: We need JWT token here - should be passed from caller or stored
      // For now, this is a placeholder - you'll need to get JWT from AuthViewModel
      debugPrint('[FeedVM] ⚠️ _loadMorePosts needs JWT token - implement JWT access');
      
      // TODO: Implement proper JWT access
      // final api = PostsApi(jwt: jwt);
      // final raw = await api.listFeed(beforePostId: oldestPostId, limit: 20);
      // ... process and append posts
      
    } catch (e) {
      debugPrint('[FeedVM] ❌ Error loading more posts: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  /// ✅ Public method to load more posts (can be called with JWT)
  Future<void> loadMorePostsWithJwt(String jwt) async {
    if (isLoadingMore || !hasMorePosts || oldestPostId == null) return;
    
    isLoadingMore = true;
    notifyListeners();

    try {
      final api = PostsApi(jwt: jwt);
      final raw = await api.listFeed(beforePostId: oldestPostId, limit: 20);
      debugPrint('[FeedVM] loadMorePosts returned ${raw.length} items');

      if (raw.isEmpty) {
        hasMorePosts = false;
        debugPrint('[FeedVM] 🏁 No more posts to load');
        return;
      }

      final mapped = <Post>[];
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          try {
            if (item.containsKey('postId') && item.containsKey('user')) {
              final normalized = Map<String, dynamic>.from(item);
              if (!normalized.containsKey('generatedCaption') && normalized['caption'] != null) {
                normalized['generatedCaption'] = normalized['caption'];
              }
              mapped.add(Post.fromJson(normalized));
              continue;
            }

            // Fallback mapping (same as above)
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
          } catch (e) {
            debugPrint('[FeedVM] Error mapping post in loadMore: $e');
          }
        }
      }

      // ✅ MERGE: Add older posts to END of list
      posts.addAll(mapped);
      
      // Update cursor to new oldest post
      if (mapped.isNotEmpty) {
        oldestPostId = mapped.last.postId;
      }
      
      // Check if there might be more
      hasMorePosts = mapped.length >= 20;
      
      debugPrint('[FeedVM] ✅ Loaded ${mapped.length} more posts. Total: ${posts.length}, hasMore=$hasMorePosts');
    } catch (e) {
      debugPrint('[FeedVM] ❌ Error loading more posts: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  /// OLD implementation - kept for reference only
  /// @deprecated Use loadRemoteFeed instead
  // ignore: unused_element
  Future<void> _loadRemoteFeedOld_reference({required String jwt, required User current}) async {
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

  // ✅ Xóa toàn bộ dữ liệu đã fetch cho feed (posts + trạng thái filter + pagination state)
  void clearAll() {
    posts.clear();
    loading = false;
    isLoadingMore = false;
    hasMorePosts = true;
    oldestPostId = null;
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
        if (friendId == null) {
          filtered = const [];
        } else {
          final isAccepted = acceptedFriends.any((u) => u.userId == friendId);
          if (!isAccepted) {
            filtered = const [];
          } else {
            filtered = posts.where((p) => p.user.userId == friendId);
          }
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
