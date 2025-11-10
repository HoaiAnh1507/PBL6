import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/core/constants/colors.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/friendship_viewmodel.dart';
import 'chat_room_view.dart';

class ChatListView extends StatefulWidget {
  final String currentUserId; // ví dụ: 'u1'

  const ChatListView({super.key, required this.currentUserId});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Sau khi build lần đầu, nạp danh sách bạn bè từ backend và chuẩn bị dữ liệu chat
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_initialized) return;
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      final friendshipVM = Provider.of<FriendshipViewModel>(context, listen: false);
      final chatVM = Provider.of<ChatViewModel>(context, listen: false);

      final current = authVM.currentUser;
      final jwt = authVM.jwtToken;

      if (current != null) {
        if (jwt != null && jwt.isNotEmpty) {
          await friendshipVM.loadFriendsRemote(jwt: jwt, current: current);
          await chatVM.loadRemoteConversations(jwt: jwt, currentUserId: current.userId);
        } else {
          // Fallback: dùng mock nếu chưa có JWT
          await friendshipVM.loadFriendships(current);
          // Sau khi có danh sách bạn bè, tạo conversations/mock tin nhắn tương ứng
          chatVM.loadDataForCurrentUser();
        }
      }

      if (mounted) setState(() => _initialized = true);
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      // Hiển thị dạng "MMM dd, yyyy"
      // Ví dụ: Nov 03, 2025
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final monthStr = months[dateTime.month - 1];
      return '$monthStr ${dateTime.day.toString().padLeft(2, '0')}, ${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Messengers',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer3<ChatViewModel, UserViewModel, FriendshipViewModel>(
          builder: (context, chatVM, userVM, friendshipVM, _) {
            final friends = chatVM.getAcceptedFriends(widget.currentUserId);

            // Sắp xếp bạn bè theo thời gian tin nhắn gần nhất (mới nhất lên trước)
            final sortedFriends = List.of(friends)
              ..sort((a, b) {
                final msgA = chatVM.getLatestMessage(widget.currentUserId, a.userId);
                final msgB = chatVM.getLatestMessage(widget.currentUserId, b.userId);
                final convA = chatVM.getConversation(widget.currentUserId, a.userId);
                final convB = chatVM.getConversation(widget.currentUserId, b.userId);
                final latestA = msgA?.sentAt ?? convA?.lastMessageAt;
                final latestB = msgB?.sentAt ?? convB?.lastMessageAt;

                if (latestA == null && latestB == null) return 0;
                if (latestA == null) return 1; // A không có tin → sau B
                if (latestB == null) return -1; // B không có tin → sau A
                return latestB.compareTo(latestA); // mới nhất trước
              });

            if (friendshipVM.loading && friends.isEmpty) {
              return Center(
                child: Text(
                  'Đang tải bạn bè...',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              );
            }

            if (friends.isEmpty) {
              return Center(
                child: Text(
                  'No friends yet.',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: sortedFriends.length,
              itemBuilder: (context, index) {
                final user = sortedFriends[index];
                final latestMessage = chatVM.getLatestMessage(widget.currentUserId, user.userId);
                final conv = chatVM.getConversation(widget.currentUserId, user.userId);
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatRoomView(
                          friendId: user.userId,
                          friendName: user.fullName,
                        ),
                      ),
                    );
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(1.2),
                    decoration: BoxDecoration(
                      gradient: instagramGradient,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: NetworkImage(
                        (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                            ? user.profilePictureUrl!
                            : 'https://i.pravatar.cc/150?u=${user.userId}',
                      ),
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        user.username,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        // Nếu chưa có tin nhắn → fallback lastMessageAt từ conversation
                        latestMessage != null
                            ? _formatTime(latestMessage.sentAt)
                            : (conv?.lastMessageAt != null ? _formatTime(conv!.lastMessageAt!) : ''),
                        style: GoogleFonts.poppins(
                          color: Color.fromARGB(179, 130, 130, 130),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    // Nếu chưa có tin nhắn: hiển thị gợi ý
                    latestMessage?.content ?? (conv?.lastMessageAt != null ? 'New activity' : 'Start a conversation'),
                    style: GoogleFonts.poppins(
                      color: Color.fromARGB(179, 130, 130, 130),
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Color.fromARGB(179, 130, 130, 130),
                    fontWeight: FontWeight.w500,
                    size: 16,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}