import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CaptureOverlay extends StatefulWidget {
  final String imagePath;
  final Function(String caption) onPost;
  final bool isVideo;

  const CaptureOverlay({
    Key? key,
    required this.imagePath,
    required this.onPost,
    this.isVideo = false,
  }) : super(key: key);

  @override
  State<CaptureOverlay> createState() => _CaptureOverlayState();
}

class _CaptureOverlayState extends State<CaptureOverlay> {
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.file(File(widget.imagePath));
    await _videoController!.initialize();
    _videoController!
      ..setLooping(true)
      ..play();
    setState(() {});
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Widget _buildMediaPreview() {
    if (widget.isVideo) {
      if (_videoController == null || !_videoController!.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    }

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Image.file(
        File(widget.imagePath),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildCaptionInput() => TextField(
        controller: _captionController,
        style: const TextStyle(color: Colors.white),
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Viết caption...',
          hintStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  Widget _buildActionButtons(BuildContext context) => Row(
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
              onPressed: () => widget.onPost(_captionController.text),
              child: const Text('Đăng'),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 60,
                  color: Colors.white30,
                ),
              ),
              const SizedBox(height: 12),
              _buildMediaPreview(),
              const SizedBox(height: 12),
              _buildCaptionInput(),
              const SizedBox(height: 12),
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }
}
