import 'package:flutter/material.dart';
import 'package:locket_ai/models/user_model.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/post_model.dart';

class PostItem extends StatefulWidget {
  final Post post;
  final User? currentUser;

  const PostItem({Key? key, required this.post, this.currentUser}) : super(key: key);

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  VideoPlayerController? _v;
  ChewieController? _chewie;

  @override
  void initState() {
    super.initState();
    if (widget.post.mediaType == MediaType.VIDEO) _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final path = widget.post.mediaUrl;
      _v = path.startsWith('http')
          ? VideoPlayerController.network(path)
          : VideoPlayerController.asset(path);
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
    final post = widget.post;
    final user = post.user;
    final screenWidth = MediaQuery.of(context).size.width;

    final caption = post.userEditedCaption?.isNotEmpty == true
        ? post.userEditedCaption
        : post.generatedCaption;

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Ảnh hoặc video nền
          Positioned(
            top: 130,
            left: 7,
            right: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: SizedBox(
                width: screenWidth - 14,
                height: screenWidth,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: screenWidth - 14,
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: post.mediaType == MediaType.PHOTO
                        ? Image.network(post.mediaUrl, fit: BoxFit.cover)
                        : (_chewie != null
                            ? Chewie(controller: _chewie!)
                            : Container(color: Colors.black)),
                  ),
                ),
              ),
            ),
          ),

          // Hiệu ứng mờ gradient overlay
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

          // Hiển thị thông tin người đăng và caption
          Positioned(
            left: 27,
            bottom: 80,
            right: 27,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + tên người đăng
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(user.profilePictureUrl ?? 'https://i.pravatar.cc/150?img=1'),
                      radius: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      user.fullName,
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
                  ],
                ),
                const SizedBox(height: 6),
                if (caption != null && caption.isNotEmpty)
                  Text(
                    caption,
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
