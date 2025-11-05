import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/core/constants/colors.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

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
      body: Container(
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
    );
  }
}
