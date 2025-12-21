import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/core/constants/colors.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';
import 'package:locket_ai/widgets/async_avatar.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/post_model.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ChatRoomView extends StatefulWidget {
  final String friendId;
  final String friendName;

  const ChatRoomView({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // ✅ Add ScrollController
  bool _isLoadingMore = false; // ✅ Loading state for pagination
  bool _hasMoreMessages = true; // ✅ Flag to check if there are more messages
  
  static const double _avatarLift = 3; // nhích lên nhẹ để hở đáy
  static const double _avatarInset = 3; // thu nhỏ đường kính để hở đỉnh

  // Lấy ID người dùng hiện tại từ AuthViewModel
  String _currentUserId(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    return authVM.currentUser!.userId;
  }

  @override
  void initState() {
    super.initState();
    
    // ✅ Setup scroll listener for infinite scrolling
    _scrollController.addListener(_onScroll);
    
    // After first frame, mark latest incoming unread message as read
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final chatVM = Provider.of<ChatViewModel>(context, listen: false);
        final authVM = Provider.of<AuthViewModel>(context, listen: false);
        final currentUserId = _currentUserId(context);
        final conv = chatVM.getConversation(currentUserId, widget.friendId);
        final unreadIds = (conv?.messages ?? [])
            .where((m) => m.sender?.userId != currentUserId && m.read == false)
            .map((m) => m.messageId)
            .toList();
        final jwt = authVM.jwtToken;
        if (jwt != null && jwt.isNotEmpty && unreadIds.isNotEmpty) {
          for (final id in unreadIds) {
            await chatVM.markMessageReadRemote(jwt: jwt, messageId: id);
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// ✅ Scroll listener to trigger load more when scrolling UP (reverse list)
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final currentPosition = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;
    
    // Threshold: Load when 300px from TOP (because list is reversed)
    const threshold = 300.0;
    
    // Trigger when scrolling UP and near the top
    if (maxScroll - currentPosition < threshold && 
        !_isLoadingMore && 
        _hasMoreMessages) {
      debugPrint('[ChatRoom] 📍 Triggered load more messages at $currentPosition/$maxScroll');
      _loadMoreMessages();
    }
  }

  /// ✅ Load older messages
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;
    
    setState(() => _isLoadingMore = true);

    try {
      final chatVM = Provider.of<ChatViewModel>(context, listen: false);
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      final currentUserId = _currentUserId(context);
      final jwt = authVM.jwtToken;
      
      if (jwt == null || jwt.isEmpty) {
        debugPrint('[ChatRoom] No JWT token available');
        return;
      }

      // Get current messages and find oldest message ID (cursor)
      final messages = chatVM.getMessagesWith(currentUserId, widget.friendId);
      if (messages.isEmpty) {
        debugPrint('[ChatRoom] No messages to paginate from');
        return;
      }

      // Sort by time to find oldest
      final sorted = List.of(messages)..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      final oldestMessageId = sorted.first.messageId;

      debugPrint('[ChatRoom] Loading more messages before: $oldestMessageId');

      // Load older messages
      await chatVM.loadRemoteMessagesForPair(
        jwt: jwt,
        currentUserId: currentUserId,
        friendId: widget.friendId,
        beforeMessageId: oldestMessageId,
        limit: 25,
      );

      // Check if we got new messages
      final newMessages = chatVM.getMessagesWith(currentUserId, widget.friendId);
      if (newMessages.length == messages.length) {
        // No new messages loaded
        _hasMoreMessages = false;
        debugPrint('[ChatRoom] 🏁 No more messages to load');
      } else {
        debugPrint('[ChatRoom] ✅ Loaded ${newMessages.length - messages.length} more messages');
      }
    } catch (e) {
      debugPrint('[ChatRoom] ❌ Error loading more messages: $e');
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatHeaderLabel(DateTime dt) {
    final now = DateTime.now();
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (_isSameDay(dt, now)) {
      return 'Today, $timeStr';
    }
    if (_isSameDay(dt, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday, $timeStr';
    }
    final diffDays = now.difference(dt).inDays;
    if (diffDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayStr = weekdays[dt.weekday - 1];
      return '$dayStr, $timeStr';
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = months[dt.month - 1];
    final dayStr = dt.day.toString().padLeft(2, '0');
    // Hiển thị dạng "MMM dd, hh:mm" cho thời gian > 1 tuần
    return '$monthStr $dayStr, $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final chatVM = Provider.of<ChatViewModel>(context);
    final currentUserId = _currentUserId(context);
    // Nếu chưa có tin nhắn nhưng có JWT → cố gắng nạp hội thoại từ backend
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final jwt = authVM.jwtToken;
    final initialMessages = chatVM.getMessagesWith(currentUserId, widget.friendId);
    if ((initialMessages.isEmpty) && jwt != null && jwt.isNotEmpty) {
      // Nếu chưa có tin nhắn: ưu tiên nạp chi tiết hội thoại cho cặp này
      chatVM.loadRemoteMessagesForPair(
        jwt: jwt,
        currentUserId: currentUserId,
        friendId: widget.friendId,
      );
    }
    // Sắp xếp tin nhắn theo thời gian tăng dần (cũ → mới)
    final messages = List.of(initialMessages)..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    // Lấy thông tin bạn bè để hiển thị username dưới fullname
    final conv = chatVM.getConversation(currentUserId, widget.friendId);
    final friendUser = conv?.userOne.userId == currentUserId ? conv?.userTwo : conv?.userOne;
    final friendUsername = friendUser?.username;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.friendName,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                friendUsername != null && friendUsername.isNotEmpty ? '@$friendUsername' : '',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          // Vuốt từ trái sang phải (primaryVelocity > 0) thì quay lại ChatListView
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          color: Colors.black,
          child: Column(
          children: [
            // Danh sách tin nhắn
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Text(
                        "Start a conversation!",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController, // ✅ Add controller
                      // Neo danh sách ở dưới, trôi từ dưới lên
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: messages.length + (_isLoadingMore ? 1 : 0), // ✅ Add loading indicator
                      itemBuilder: (context, i) {
                        // ✅ Show loading indicator at the top (index 0 when reversed)
                        if (i == messages.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.pinkAccent,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        }
                        
                        // Chỉ số theo thứ tự thời gian
                        final idx = messages.length - 1 - i;
                        final msg = messages[idx];
                        final prevMsg = idx > 0 ? messages[idx - 1] : null;
                        final nextMsg = idx < messages.length - 1 ? messages[idx + 1] : null; // tin nhắn mới hơn
                        final showHeader = prevMsg == null ||
                            msg.sentAt.difference(prevMsg.sentAt).inMinutes >= 60;
                        final isMine = msg.sender?.userId == currentUserId;
                        final avatarUrl = (msg.sender?.profilePictureUrl != null &&
                                msg.sender!.profilePictureUrl!.isNotEmpty)
                            ? msg.sender!.profilePictureUrl!
                            : 'https://i.pravatar.cc/150?u=${msg.sender?.userId ?? 'unknown'}';

                        // Bubble nội dung tin nhắn
                        final bubble = Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            gradient: isMine ? instagramGradient : null,
                            color: isMine ? null : Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            msg.content,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        );
                        return Column(
                          crossAxisAlignment:
                              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (showHeader)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: Center(
                                  child: Text(
                                    _formatHeaderLabel(msg.sentAt),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            if (msg.repliedToPost != null) ...[
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: ChatPostEmbed(
                                    post: msg.repliedToPost!,
                                    alignRight: isMine,
                                  ),
                                ),
                              ),
                            ],
                            if (isMine)
                              Align(
                                alignment: Alignment.centerRight,
                                child: bubble,
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end, // căn đáy avatar với đáy bubble
                                children: [
                                  // Tính chiều cao bubble 1 dòng: padding (10 * 2) + chiều cao text
                                  Builder(
                                    builder: (context) {
                                      final textStyle = GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 15,
                                      );
                                      final tp = TextPainter(
                                        text: TextSpan(text: 'Hg', style: textStyle),
                                        maxLines: 1,
                                        textDirection: TextDirection.ltr,
                                      );
                                      tp.layout();
                                      final singleLineBubbleHeight = tp.height + 20; // 10 trên + 10 dưới
                                      final avatarRadius = singleLineBubbleHeight / 2 - _avatarInset;
                                      final avatarDiameter = singleLineBubbleHeight - 2 * _avatarInset;
                                      final avatarVisible = nextMsg == null ||
                                          (nextMsg.sender?.userId != msg.sender?.userId) ||
                                          (nextMsg.sentAt.difference(msg.sentAt).inMinutes >= 60);

                                      if (avatarVisible) {
                                        return Transform.translate(
                                          offset: const Offset(0, -_avatarLift),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4), // khớp margin của bubble
                                            child: AsyncAvatar(
                                              url: avatarUrl,
                                              radius: avatarRadius,
                                              fallbackKey: msg.sender?.userId,
                                            ),
                                          ),
                                        );
                                      } else {
                                        // Placeholder để giữ indent trái đồng nhất khi ẩn avatar
                                        return SizedBox(width: avatarDiameter);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(child: bubble),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
            ),

            // Thanh nhập tin nhắn
            SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade800, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: "Nhập tin nhắn...",
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade900,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide:
                                BorderSide(color: Colors.grey.shade800),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFFDD2A7B), // lấy sắc hồng từ instagramGradient
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final text = _controller.text.trim();
                        if (text.isEmpty) return;
                        final authVM = Provider.of<AuthViewModel>(context, listen: false);
                        final jwt = authVM.jwtToken;
                        if (jwt != null && jwt.isNotEmpty) {
                          chatVM.sendMessageRemote(
                            jwt: jwt,
                            currentUserId: currentUserId,
                            friendId: widget.friendId,
                            content: text,
                          );
                        } else {
                          chatVM.sendMessage(currentUserId, widget.friendId, text);
                        }
                        _controller.clear();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          gradient: instagramGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class ChatPostEmbed extends StatefulWidget {
  final Post post;
  final bool alignRight;
  const ChatPostEmbed({super.key, required this.post, required this.alignRight});

  @override
  State<ChatPostEmbed> createState() => _ChatPostEmbedState();
}

class _ChatPostEmbedState extends State<ChatPostEmbed> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.post.mediaType == MediaType.VIDEO) _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final url = widget.post.mediaUrl;
      _videoController = url.startsWith('http')
          ? VideoPlayerController.network(url)
          : VideoPlayerController.asset(url);
      await _videoController!.initialize();
      // Đồng bộ hành vi với PostItem: tự chạy, lặp lại, ẩn điều khiển
      // Mute để đảm bảo autoplay hoạt động ổn định trên web.
      await _videoController!.setVolume(0.0);
      await _videoController!.setLooping(true);
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        showControls: false,
      );
      _videoController!.play();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth - 24; // dùng toàn bộ bề ngang nội dung (vuông như PostItem)
    // Bo góc và tỉ lệ giống PostItem (vuông, bo 40)
    final radius = 40.0;
    final caption = post.userEditedCaption?.isNotEmpty == true
        ? post.userEditedCaption
        : post.generatedCaption;

    Widget media;
    if (post.mediaType == MediaType.PHOTO) {
      final isNetwork = post.mediaUrl.startsWith('http');
      media = isNetwork
          ? Builder(
              builder: (context) {
                final authVM = Provider.of<AuthViewModel>(context, listen: false);
                final userVM = Provider.of<UserViewModel>(context, listen: false);
                final jwt = authVM.jwtToken;
                final future = (jwt != null && jwt.isNotEmpty)
                    ? userVM.resolveDisplayUrl(jwt: jwt, url: post.mediaUrl)
                    : Future<String?>.value(post.mediaUrl);
                return FutureBuilder<String?>(
                  future: future,
                  builder: (context, snapshot) {
                    final resolved = snapshot.data ?? post.mediaUrl;
                    return Image.network(
                      resolved,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.pinkAccent),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
                        );
                      },
                    );
                  },
                );
              },
            )
          : Image.asset(
              post.mediaUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
    } else {
      media = _chewieController != null
          ? FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _chewieController!.videoPlayerController.value.size.width,
                height: _chewieController!.videoPlayerController.value.size.height,
                child: Chewie(controller: _chewieController!),
              ),
            )
          : Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              ),
            );
    }

    final avatarUrl = (post.user.profilePictureUrl != null &&
            post.user.profilePictureUrl!.isNotEmpty)
        ? post.user.profilePictureUrl!
        : 'https://i.pravatar.cc/150?u=${post.user.userId}';

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: maxWidth,
          height: maxWidth, // vuông như PostItem
          child: Stack(
            children: [
              Positioned.fill(child: media),
              Positioned(
                top: 14,
                left: 25,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AsyncAvatar(
                        url: avatarUrl,
                        radius: 12,
                        fallbackKey: post.user.userId,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        post.user.username,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _timeAgo(post.createdAt),
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Caption sát đáy media để dễ đọc, giữ style giống FeedView
              if (caption != null && caption.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 15,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        color: Colors.black.withOpacity(0.2),
                        child: Text(
                          caption,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            decoration: TextDecoration.none,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
