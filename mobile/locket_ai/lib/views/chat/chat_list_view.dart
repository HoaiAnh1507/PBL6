import 'package:flutter/material.dart';
import 'chat_room_view.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';

class ChatListView extends StatelessWidget {
  const ChatListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ChatViewModel>(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView.builder(
          itemCount: vm.friends.length,
          itemBuilder: (context, i) {
            final u = vm.friends[i];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(u.name, style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatRoomView(userName: u.name))),
            );
          },
        ),
      ),
    );
  }
}
