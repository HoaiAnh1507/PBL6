# HƯỚNG DẪN IMPLEMENT INFINITE SCROLLING CHO FEED

## ✅ Đã hoàn thành Backend

### API Endpoints mới:

```
GET /api/posts/feed
GET /api/posts/feed?beforePostId=post-123&limit=20
```

### Database Query Methods (PostRepository):

```java
// Load N posts mới nhất
findTopNPostsForUser(user, limit)

// Load N posts cũ hơn thời điểm X
findPostsForUserBeforeTime(user, beforeTime, limit)
```

---

## 📱 Hướng dẫn Mobile (Flutter)

### Bước 1: Tạo FeedViewModel

```dart
class FeedViewModel extends ChangeNotifier {
  // 1. Danh sách posts hiển thị
  List<Post> posts = [];
  
  // 2. Các flags
  bool isLoadingInitial = false;
  bool isLoadingMore = false;
  bool hasMorePosts = true;
  
  // 3. Cursor = ID của post CŨ NHẤT đang có
  String? oldestPostId;
  
  // 4. ScrollController
  final ScrollController scrollController = ScrollController();
  
  FeedViewModel() {
    _init();
  }
  
  void _init() {
    _setupScrollListener();
    loadInitialPosts();
  }
  
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
```

---

### Bước 2: Setup Scroll Listener

```dart
void _setupScrollListener() {
  scrollController.addListener(() {
    final currentPosition = scrollController.position.pixels;
    final maxScroll = scrollController.position.maxScrollExtent;
    
    // Threshold: Load khi còn cách cuối list 300px
    const threshold = 300.0;
    
    // Điều kiện trigger: Scroll gần cuối + Không đang load + Còn posts
    if (maxScroll - currentPosition < threshold && 
        !isLoadingMore && 
        !isLoadingInitial &&
        hasMorePosts) {
      
      print('📍 Triggered load more at $currentPosition/$maxScroll');
      loadMorePosts();
    }
  });
}
```

**Giải thích:**
- Feed scroll **XUỐNG** (khác với Chat scroll lên)
- `maxScroll - currentPosition < 300`: Còn cách cuối 300px
- Khi user scroll gần cuối → Load thêm posts cũ hơn

---

### Bước 3: Load Posts Lần Đầu

```dart
Future<void> loadInitialPosts() async {
  if (isLoadingInitial) return;
  
  isLoadingInitial = true;
  notifyListeners();
  
  try {
    // Gọi API lần đầu (không có cursor)
    final response = await ApiService.getFeed(limit: 20);
    
    posts = response.posts;
    
    // Lưu cursor = ID của post CŨ NHẤT (cuối list)
    if (posts.isNotEmpty) {
      oldestPostId = posts.last.postId;
    }
    
    hasMorePosts = posts.length >= 20;
    
    print('✅ Loaded ${posts.length} initial posts');
    
  } catch (e) {
    print('❌ Error loading posts: $e');
  } finally {
    isLoadingInitial = false;
    notifyListeners();
  }
}
```

**API Request:**
```
GET /api/posts/feed?limit=20
```

**Response:** 20 posts MỚI NHẤT
```json
[
  {"postId": "post-1", "caption": "Latest", "createdAt": "2025-12-20T10:00:00"},
  {"postId": "post-2", "caption": "Recent", "createdAt": "2025-12-20T09:55:00"},
  ...
  {"postId": "post-20", "caption": "Older", "createdAt": "2025-12-20T08:00:00"}
]
```

---

### Bước 4: Load Thêm Posts (Scroll Down)

```dart
Future<void> loadMorePosts() async {
  if (isLoadingMore || !hasMorePosts) return;
  
  isLoadingMore = true;
  notifyListeners();
  
  try {
    // Gọi API với cursor
    final response = await ApiService.getFeed(
      beforePostId: oldestPostId,
      limit: 20,
    );
    
    if (response.posts.isEmpty) {
      hasMorePosts = false;
      print('🏁 No more posts to load');
      
    } else {
      // MERGE: Thêm posts CŨ vào CUỐI list
      posts.addAll(response.posts);
      
      // Update cursor
      oldestPostId = response.posts.last.postId;
      
      hasMorePosts = response.posts.length >= 20;
      
      print('✅ Loaded ${response.posts.length} more posts');
      print('📊 Total posts: ${posts.length}');
    }
    
  } catch (e) {
    print('❌ Error loading more: $e');
  } finally {
    isLoadingMore = false;
    notifyListeners();
  }
}
```

**API Request:**
```
GET /api/posts/feed?beforePostId=post-20&limit=20
```

**Response:** 20 posts CŨ HƠN post-20

---

### Bước 5: Xây Dựng UI

```dart
class FeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feed')),
      body: Consumer<FeedViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoadingInitial) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (viewModel.posts.isEmpty) {
            return Center(child: Text('No posts yet'));
          }
          
          return RefreshIndicator(
            onRefresh: viewModel.loadInitialPosts, // Pull to refresh
            child: ListView.builder(
              controller: viewModel.scrollController,
              
              // Tổng items = số posts + loading indicator
              itemCount: viewModel.posts.length + 
                         (viewModel.isLoadingMore ? 1 : 0),
              
              itemBuilder: (context, index) {
                // Loading indicator ở CUỐI list
                if (index == viewModel.posts.length) {
                  return _buildLoadingIndicator();
                }
                
                final post = viewModel.posts[index];
                return PostCard(post: post);
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
```

**Giải thích:**
- Không dùng `reverse: true` (Feed scroll xuống bình thường)
- Loading indicator ở **CUỐI list**
- `RefreshIndicator` để pull-to-refresh load posts mới

---

### Bước 6: API Service

```dart
class ApiService {
  static const baseUrl = 'https://api.locketai.com';
  
  static Future<FeedResponse> getFeed({
    String? beforePostId,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/api/posts/feed')
        .replace(queryParameters: {
          if (beforePostId != null) 'beforePostId': beforePostId,
          'limit': limit.toString(),
        });
    
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${getJwtToken()}',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      final posts = data.map((json) => Post.fromJson(json)).toList();
      return FeedResponse(posts: posts);
    } else {
      throw Exception('Failed to load feed: ${response.statusCode}');
    }
  }
}

class FeedResponse {
  final List<Post> posts;
  FeedResponse({required this.posts});
}
```

---

## 🔄 Workflow Tổng Quan

```
1. User mở FeedScreen
   ↓
2. FeedViewModel._init()
   ↓
3. _setupScrollListener() ← Đăng ký
   ↓
4. loadInitialPosts() ← Load 20 posts mới nhất
   ↓
5. API: GET /feed?limit=20
   ↓
6. UI hiển thị 20 posts
   ↓
7. User scroll XUỐNG (đọc posts cũ hơn)
   ↓
8. Scroll listener: maxScroll - current < 300px
   ↓
9. loadMorePosts() ← Load 20 posts tiếp
   ↓
10. API: GET /feed?beforePostId=post-20&limit=20
    ↓
11. MERGE: posts.addAll(olderPosts)
    ↓
12. UI update: Hiện 40 posts (20 mới + 20 cũ)
    ↓
13. Lặp lại 7-12 khi scroll tiếp
```

---

## 📊 So sánh Feed vs Chat

| Khía cạnh | Feed | Chat |
|-----------|------|------|
| **Scroll direction** | Xuống (down) | Lên (up) |
| **ListView reverse** | `false` | `true` |
| **Cursor position** | Post CŨ NHẤT (last) | Message CŨ NHẤT (first) |
| **Load trigger** | Gần CUỐI list | Gần ĐẦU list |
| **Merge method** | `posts.addAll()` | `messages.insertAll(0, ...)` |
| **Loading indicator** | Ở CUỐI | Ở ĐẦU |

---

## ✅ Checklist Implementation

- [ ] Tạo FeedViewModel với ScrollController
- [ ] Setup scroll listener với threshold 300px
- [ ] Implement loadInitialPosts() (không có cursor)
- [ ] Implement loadMorePosts() (có cursor)
- [ ] Build UI với ListView.builder
- [ ] Thêm loading indicator ở cuối list
- [ ] Thêm RefreshIndicator (pull to refresh)
- [ ] Test scroll xuống
- [ ] Test edge cases (empty, no more posts)
- [ ] Thêm error handling

---

## 🎯 Kết quả

- ✅ Load nhanh: Chỉ 20 posts mỗi lần
- ✅ Smooth scrolling: Không giật lag
- ✅ Tiết kiệm tài nguyên: Không load hết
- ✅ UX tốt: Infinite scrolling tự nhiên
- ✅ Scalable: Hoạt động tốt với 10K+ posts

**Tổng kết:** Áp dụng **Lazy Loading + Infinite Scrolling + Cursor-based API** giống Chat, chỉ khác scroll direction! 🚀
