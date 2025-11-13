import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        margin: const EdgeInsets.only(bottom: 8, left: 15, right: 15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white12),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.3),
          //     blurRadius: 16,
          //     offset: const Offset(0, 6),
          //   ),
          // ],
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
      ),
    );
  }
}