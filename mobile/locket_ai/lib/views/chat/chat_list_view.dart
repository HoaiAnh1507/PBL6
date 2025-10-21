import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';
import 'chat_room_view.dart';

class ChatListView extends StatelessWidget {
  final String currentUserId; // ví dụ: 'u1' (Tuan)
  const ChatListView({Key? key, required this.currentUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ChatViewModel>(context);
    final friends = vm.getAcceptedFriends(currentUserId);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Chats"),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: friends.isEmpty
            ? const Center(
                child: Text(
                  "Bạn chưa có bạn bè nào.",
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.separated(
                itemCount: friends.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white24),
                itemBuilder: (context, i) {
                  final u = friends[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(u.profilePictureUrl ?? 'https://i.pravatar.cc/150?img=1'),
                    ),
                    title: Text(
                      u.fullName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "@${u.username}",
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatRoomView(userName: u.fullName),
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
