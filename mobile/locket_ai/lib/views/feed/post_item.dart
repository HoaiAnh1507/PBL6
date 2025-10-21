import 'package:flutter/material.dart';
import '../../models/post.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class PostItem extends StatefulWidget {
  final Post post;
  const PostItem({Key? key, required this.post}) : super(key: key);

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  VideoPlayerController? _v;
  ChewieController? _chewie;

  @override
  void initState() {
    super.initState();
    if (widget.post.type == PostType.video) _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final path = widget.post.filePath;
      if (path.startsWith('http')) {
        _v = VideoPlayerController.network(path);
      } else {
        _v = VideoPlayerController.asset(path);
      }
      await _v!.initialize();
      _v!.setLooping(true);
      _chewie = ChewieController(
        videoPlayerController: _v!,
        autoPlay: true,
        looping: true,
        showControls: false,
      );
      _v!.play();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _v?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Background image / video
          Positioned(
            top: 130,
            left: 7,
            right: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: SizedBox(
                width: screenWidth - 14, // trừ padding 2 bên
                height: screenWidth, // giữ vuông như CameraPreview
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: screenWidth - 14,
                    height: screenHeight * 0.8, // cùng chiều cao như camera
                    child: widget.post.type == PostType.image
                        ? Image.network(widget.post.filePath, fit: BoxFit.cover)
                        : (_chewie != null
                            ? Chewie(controller: _chewie!)
                            : Container(color: Colors.black)),
                  ),
                ),
              ),
            ),
          ),

          // Overlay gradient
          Positioned(
            top: 130,
            left: 7,
            right: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: screenWidth - 14,
                height: screenWidth,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black54],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Caption + author
          Positioned(
            left: 27,
            bottom: 40,
            right: 27,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.author,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black54,
                        offset: Offset(1, 1),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                if (widget.post.caption != null &&
                    widget.post.caption!.isNotEmpty)
                  Text(
                    widget.post.caption!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      height: 1.3,
                      shadows: const [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.black45,
                          offset: Offset(1, 1),
                        )
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
