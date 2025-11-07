import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/core/constants/colors.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import 'chat_room_view.dart';

class ChatListView extends StatelessWidget {
  final String currentUserId; // ví dụ: 'u1'

  const ChatListView({super.key, required this.currentUserId});

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
        child: Consumer2<ChatViewModel, UserViewModel>(
          builder: (context, chatVM, userVM, _) {
            final friends = chatVM.getAcceptedFriends(currentUserId);

            // Sắp xếp bạn bè theo thời gian tin nhắn gần nhất (mới nhất lên trước)
            final sortedFriends = List.of(friends)
              ..sort((a, b) {
                final latestA = chatVM.getLatestMessage(currentUserId, a.userId)?.sentAt;
                final latestB = chatVM.getLatestMessage(currentUserId, b.userId)?.sentAt;

                if (latestA == null && latestB == null) return 0;
                if (latestA == null) return 1; // A không có tin → sau B
                if (latestB == null) return -1; // B không có tin → sau A
                return latestB.compareTo(latestA); // mới nhất trước
              });

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
                final latestMessage = chatVM.getLatestMessage(currentUserId, user.userId);

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
                        // Nếu chưa có tin nhắn → dùng DateTime.now()
                        latestMessage == null
                            ? ''
                            : _formatTime(latestMessage.sentAt),
                        style: GoogleFonts.poppins(
                          color: Color.fromARGB(179, 130, 130, 130),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    // Nếu chưa có tin nhắn → hiển thị "Start a conversation"
                    latestMessage?.content ?? 'Start a conversation',
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