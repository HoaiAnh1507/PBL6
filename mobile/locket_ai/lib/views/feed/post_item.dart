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
      _v!.play();
      _chewie = ChewieController(videoPlayerController: _v!, autoPlay: true, looping: true, showControls: false);
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
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.post.type == PostType.image)
          Image.network(widget.post.filePath, fit: BoxFit.cover)
        else if (_chewie != null)
          Chewie(controller: _chewie!)
        else
          Container(color: Colors.grey.shade900),
        Positioned(
          left: 16,
          bottom: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.post.author, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (widget.post.caption != null)
                SizedBox(width: 300, child: Text(widget.post.caption!, style: const TextStyle(color: Colors.white70))),
            ],
          ),
        ),
      ],
    );
  }
}
