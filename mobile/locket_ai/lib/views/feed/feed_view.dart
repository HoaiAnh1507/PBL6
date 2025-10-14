import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/feed_viewmodel.dart';
import 'post_item.dart';

class FeedView extends StatefulWidget {
  final VoidCallback? onScrollUpAtTop;  // add callback

  const FeedView({Key? key, this.onScrollUpAtTop}) : super(key: key);

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<FeedViewModel>(context);
    if (vm.loading) return const Center(child: CircularProgressIndicator());
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is OverscrollNotification) {
          if (notification.overscroll < 0 && notification.metrics.pixels <= 0) {
            // User is scrolling up beyond the first post
            widget.onScrollUpAtTop?.call();
            return true;
          }
        }
        return false;
      },
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: vm.posts.length,
        itemBuilder: (context, index) {
          final p = vm.posts[index];
          return PostItem(post: p);
        },
      ),
    );
  }
}
