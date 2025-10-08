import 'package:flutter/material.dart';

class ChatRoomView extends StatefulWidget {
  final String userName;
  const ChatRoomView({Key? key, required this.userName}) : super(key: key);

  @override
  State<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final TextEditingController _c = TextEditingController();
  final List<String> messages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.userName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, i) => ListTile(title: Text(messages[messages.length - 1 - i])),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _c)),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (_c.text.trim().isEmpty) return;
                      setState(() {
                        messages.add(_c.text.trim());
                        _c.clear();
                      });
                    },
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
