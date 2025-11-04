import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/colors.dart';
import '../../widgets/gradient_icon.dart';
import '../../widgets/app_header.dart';

class CaptureOverlay extends StatefulWidget {
  final String imagePath;
  final Function(String caption) onPost;
  final bool isVideo;
  final VoidCallback? onCancel;

  const CaptureOverlay({
    Key? key,
    required this.imagePath,
    required this.onPost,
    this.onCancel,
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

  Widget _buildMediaPreview(BuildContext context) {
    final size = MediaQuery.of(context).size.width;

    return Positioned(
      top: 130,
      left: 7,
      right: 7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          width: size,
          height: size,
          child: Image.file(
            File(widget.imagePath),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureControls(BuildContext context) {
    return Positioned(
      bottom: 180,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Cancel button
          GestureDetector(
            onTap: widget.onCancel,
            child: const GradientIcon(icon: Icons.cancel_outlined, size: 30),
          ),

          // Upload button
          GestureDetector(
            onTap: () => widget.onPost(_captionController.text),
            child: Container(
              height: 90,
              width: 90,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: instagramGradient,
              ),
              child: const Center(
                child: Icon(Icons.send, color: Colors.white, size: 40),
              ),
            ),
          ),

          // AI suggest caption
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI suggest caption sẽ phát triển sau')),
              );
            },
            child: const GradientIcon(icon: Icons.auto_fix_high, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionInput(BuildContext context) {
    return Positioned(
      bottom: 300,
      left: 20,
      right: 20,
      child: TextField(
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
      ),
    );
  }

  Widget _buildHeader() {
    return AppHeader(
      onLeftTap: widget.onCancel ?? () {},
      onRightTap: () {},
      friendsSection: const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildHeader(),
        _buildMediaPreview(context),
        _buildCaptureControls(context),
        _buildCaptionInput(context),
      ],
    );
  }
}
