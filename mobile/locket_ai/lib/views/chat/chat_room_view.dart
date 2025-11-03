import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_viewmodel.dart';

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

  // ⚠️ Giả lập user hiện tại (vì chưa có login)
  final String currentUserId = "current_user";

  @override
  Widget build(BuildContext context) {
    final chatVM = Provider.of<ChatViewModel>(context);
    final messages = chatVM.getMessagesWith(currentUserId, widget.friendId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friendName),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      "Hãy gửi tin nhắn đầu tiên!",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[messages.length - 1 - i];
                      final isMine = msg.sender?.userId == currentUserId;

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Colors.blueAccent.withOpacity(0.8)
                                : Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            msg.content,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Nhập tin nhắn...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;

                      chatVM.sendMessage(currentUserId, widget.friendId, text);
                      _controller.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
