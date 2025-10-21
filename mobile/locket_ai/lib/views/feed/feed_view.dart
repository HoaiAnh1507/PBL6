import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../feed/post_item.dart';
import '../../core/constants/background.dart';

List<Post> demoPosts = [
  Post(
    id: '1',
    author: 'Alice',
    caption: 'Chào buổi sáng!',
    type: PostType.image,
    filePath: 'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?fit=crop&w=800&q=80', 
    createdAt: DateTime.now(),
  ),
  Post(
    id: '2',
    author: 'Bob',
    caption: 'Một khoảnh khắc đẹp',
    type: PostType.video,
    filePath: 'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
    createdAt: DateTime.now(),
  ),
  Post(
    id: '3',
    author: 'Charlie',
    caption: 'Thử nghiệm Locket clone!',
    type: PostType.image,
    filePath: 'https://images.unsplash.com/photo-1517816743773-6e0fd518b4a6?fit=crop&w=800&q=80',
    createdAt: DateTime.now(),
  ),
];

class FeedView extends StatefulWidget {
  final List<Post> posts;
  final VoidCallback? onScrollUpAtTop;

  const FeedView({Key? key, required this.posts, this.onScrollUpAtTop})
      : super(key: key);

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final PageController _pageCtrl = PageController();

  List<Post> get _posts => widget.posts.isEmpty ? demoPosts : widget.posts;

  @override
  Widget build(BuildContext context) {
    if (_posts.isEmpty) {
      return const Center(
        child: Text(
          'No posts yet',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return Stack(
      children: [
        const Positioned.fill(child: AnimatedGradientBackground()),
        PageView.builder(
          controller: _pageCtrl,
          scrollDirection: Axis.vertical,
          itemCount: widget.posts.length,
          itemBuilder: (_, index) {
            final post = widget.posts[index];
            return SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: PostItem(post: post),
            );
          },
          onPageChanged: (index) {
            if (index == 0 && widget.onScrollUpAtTop != null) {
              widget.onScrollUpAtTop!();
            }
          },
        ),
      ],
    );
  }
}
