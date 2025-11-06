import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/core/constants/colors.dart';
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
  static const double _avatarLift = 3; // nhích lên nhẹ để hở đáy
  static const double _avatarInset = 3; // thu nhỏ đường kính để hở đỉnh

  // Lấy ID người dùng hiện tại từ AuthViewModel
  String _currentUserId(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    return authVM.currentUser!.userId;
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
    // Sắp xếp tin nhắn theo thời gian tăng dần (cũ → mới)
    final messages = List.of(
      chatVM.getMessagesWith(currentUserId, widget.friendId),
    )..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.friendName,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
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
                      // Neo danh sách ở dưới, trôi từ dưới lên
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
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
                                            child: CircleAvatar(
                                              radius: avatarRadius,
                                              backgroundImage: NetworkImage(avatarUrl),
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

                        chatVM.sendMessage(
                            currentUserId, widget.friendId, text);
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
          ? Image.network(
              post.mediaUrl,
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
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(avatarUrl),
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
