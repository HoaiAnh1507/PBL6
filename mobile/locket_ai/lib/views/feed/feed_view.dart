import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/widgets/base_footer.dart';
import 'package:locket_ai/widgets/base_header.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../core/constants/background.dart';
import '../feed/post_item.dart';
import '../../models/user_model.dart';

class FeedView extends StatefulWidget {
  final PageController verticalController;
  final User currentUser;

  const FeedView({
    super.key,
    required this.verticalController,
    required this.currentUser,
  });

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final ScrollController _scrollCtrl = ScrollController();
  final PageController _pageCtrl = PageController();

  @override
  void initState() {
    super.initState();
  }

  Widget _buildHeader() {
    return BaseHeader(
      horizontalController: widget.verticalController,
      count: 5,
      label: 'Friends',
      onTap: _showFriendsSheet
    );
  }

  void _showFriendsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.8),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 16),
          Text('Your friends',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...List.generate(
            5,
            (i) => ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAEAEA),
                  child: Icon(Icons.person, color: Colors.white)),
              title: Text('Friend ${i + 1}',
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFooter() {
    return BaseFooter(
      verticalController: widget.verticalController,
    );
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

          _buildHeader(),
          _buildFooter(),
      ],
    );
  }
}
