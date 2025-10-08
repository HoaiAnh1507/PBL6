import 'dart:io';
import 'package:flutter/material.dart';

class CaptureOverlay extends StatefulWidget {
  final String imagePath;
  final Function(String caption) onPost;

  const CaptureOverlay({Key? key, required this.imagePath, required this.onPost}) : super(key: key);

  @override
  State<CaptureOverlay> createState() => _CaptureOverlayState();
}

class _CaptureOverlayState extends State<CaptureOverlay> {
  final TextEditingController _c = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, sc) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: sc,
            children: [
              Center(child: Container(height: 4, width: 60, color: Colors.white30)),
              const SizedBox(height: 12),
              AspectRatio(aspectRatio: 3/4, child: Image.file(File(widget.imagePath), fit: BoxFit.cover)),
              const SizedBox(height: 12),
              TextField(
                controller: _c,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Viết caption...',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => widget.onPost(_c.text),
                      child: const Text('Đăng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
