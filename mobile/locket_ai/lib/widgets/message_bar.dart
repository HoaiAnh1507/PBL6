import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final FocusNode focusNode;

  const MessageBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      margin: const EdgeInsets.only(bottom: 5, left: 15, right: 15),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 6, 6, 6).withOpacity(0.7),
        borderRadius: BorderRadius.circular(40),
        
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              autofocus: false,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                hintText: "Send a message...",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send, color: Colors.white),
          )
        ],
      ),
    );
  }
}