import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/colors.dart';
import '../../widgets/gradient_icon.dart';

class CapturePreviewPage extends StatefulWidget {
  final String imagePath;
  final bool isVideo;
  final Function(String caption) onPost;

  const CapturePreviewPage({
    super.key,
    required this.imagePath,
    this.isVideo = false,
    required this.onPost,
  });

  @override
  State<CapturePreviewPage> createState() => _CapturePreviewPageState();
}

class _CapturePreviewPageState extends State<CapturePreviewPage> {
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _videoController = VideoPlayerController.file(File(widget.imagePath))
        ..initialize().then((_) {
          setState(() => _isVideoInitialized = true);
          _videoController!.setLooping(true);
          _videoController!.play();
        });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Positioned(
          top: 60,
          left: 30,
          right: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Text(
                'Send to...',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  try {
                    File(widget.imagePath);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File đã được lưu (demo)')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi tải file: $e')),
                    );
                  }
                },
                child: const Icon(Icons.download, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),

        // Ảnh hoặc video preview
        Positioned(
          top: 130,
          left: 7,
          right: 7,
          child: SizedBox(
            width: size,
            height: size,
            child: widget.isVideo
                ? _isVideoInitialized
                    ? GestureDetector(
                        onTap: () {
                          if (_videoController!.value.isPlaying) {
                            _videoController!.pause();
                          } else {
                            _videoController!.play();
                          }
                          setState(() {});
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: SizedBox(
                                width: size,
                                height: size,
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoController!.value.size.width,
                                    height: _videoController!.value.size.height,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                ),
                              ),
                            ),
                            if (!_videoController!.value.isPlaying)
                              const Icon(Icons.play_circle_fill,
                                  color: Colors.white, size: 80),
                          ],
                        ),
                      )
                    : const Center(child: CircularProgressIndicator())
                : ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.cover,
                      width: size,
                      height: size,
                    ),
                  ),
          ),
        ),

        // Các nút bên dưới
        Positioned(
          bottom: 180,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const GradientIcon(icon: Icons.cancel_outlined, size: 30),
              ),
              GestureDetector(
                onTap: () {
                  widget.onPost(_captionController.text);
                  Navigator.pop(context);
                },
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
        ),
      ],
    );
  }
}
