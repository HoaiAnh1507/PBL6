import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import 'chat_room_view.dart';

class ChatListView extends StatelessWidget {
  final String currentUserId; // ví dụ: 'u1'

  const ChatListView({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: SafeArea(
        child: Consumer2<ChatViewModel, UserViewModel>(
          builder: (context, chatVM, userVM, _) {
            final friends = chatVM.getAcceptedFriends(currentUserId);

            if (friends.isEmpty) {
              return const Center(
                child: Text(
                  "Bạn chưa có bạn bè nào.",
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.separated(
              itemCount: friends.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white24),
              itemBuilder: (context, index) {
                final user = friends[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[800],
                    backgroundImage: NetworkImage(
                      (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                          ? user.profilePictureUrl!
                          : 'https://i.pravatar.cc/150?u=${user.userId}',
                    ),
                  ),
                  title: Text(
                    user.fullName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "@${user.username}",
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
