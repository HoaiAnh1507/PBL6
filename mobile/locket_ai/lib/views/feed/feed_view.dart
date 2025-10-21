import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../core/constants/background.dart';
import '../feed/post_item.dart';
import '../../models/user_model.dart';

class FeedView extends StatefulWidget {
  final User currentUser;
  final Future<void> Function() onScrollUpAtTop;

  const FeedView({
    Key? key,
    required this.currentUser,
    required this.onScrollUpAtTop,
  }) : super(key: key);

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final ScrollController _scrollCtrl = ScrollController();
  final PageController _pageCtrl = PageController();

  @override
  void initState() {
    super.initState();

    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels <= 0 &&
          _scrollCtrl.position.userScrollDirection == ScrollDirection.forward) {
        // 👇 Gọi callback khi người dùng kéo lên đầu danh sách
        widget.onScrollUpAtTop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<FeedViewModel>(context);

    return Stack(
      children: [
        const Positioned.fill(child: AnimatedGradientBackground()),

        if (vm.loading)
          const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          )
        else if (vm.posts.isEmpty)
          const Center(
            child: Text(
              'Không có bài viết nào',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          )
        else
          PageView.builder(
            controller: _pageCtrl,
            scrollDirection: Axis.vertical,
            itemCount: vm.posts.length,
            itemBuilder: (_, index) {
              final post = vm.posts[index];
              return SingleChildScrollView(
                controller: _scrollCtrl,
                child: SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height,
                  child: PostItem(
                    post: post,
                    currentUser: widget.currentUser,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
