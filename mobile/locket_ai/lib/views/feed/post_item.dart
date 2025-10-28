import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/models/user_model.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:intl/intl.dart';
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

  String _getTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";
    return DateFormat('MMM d, yyyy').format(createdAt);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final user = post.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final caption = post.userEditedCaption?.isNotEmpty == true
        ? post.userEditedCaption
        : post.generatedCaption;

    final timeText = _getTimeAgo(post.createdAt);

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Ảnh hoặc video nền
          Positioned(
            top: 190,
            left: 7,
            right: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: screenWidth - 14,
                height: screenWidth,
                color: Colors.black,
                child: post.mediaType == MediaType.PHOTO
                  ? Image.network(
                      post.mediaUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.pinkAccent),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54, size: 40),
                        );
                      },
                    )
                  : (_chewie != null
                      ? FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: _chewie!.videoPlayerController.value.size.width,
                            height: _chewie!.videoPlayerController.value.size.height,
                            child: Chewie(controller: _chewie!),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))),
              ),
            ),
          ),

          // Caption đè lên phần dưới của ảnh
          if (caption != null && caption.isNotEmpty)
            Positioned(
              top: 190 + screenWidth - 60,
              left: 0,
              right: 0,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    color: Colors.black.withOpacity(0.2),
                    child: Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        decoration: TextDecoration.none,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),

          // Avatar + tên người dùng + thời gian
          Positioned(
            top: 190 + screenWidth + 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                    user.profilePictureUrl ?? 'https://i.pravatar.cc/150?img=1',
                  ),
                  radius: 13,
                ),
                const SizedBox(width: 10),
                Text(
                  user.username,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "$timeText",
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(179, 99, 99, 99),
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
