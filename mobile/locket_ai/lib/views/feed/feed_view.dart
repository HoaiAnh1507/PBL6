import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/feed_viewmodel.dart';
import 'post_item.dart';

class FeedView extends StatefulWidget {
  const FeedView({Key? key}) : super(key: key);

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<FeedViewModel>(context);
    if (vm.loading) return const Center(child: CircularProgressIndicator());
    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: vm.posts.length,
      itemBuilder: (context, index) {
        final p = vm.posts[index];
        return PostItem(post: p);
      },
    );
  }
}
