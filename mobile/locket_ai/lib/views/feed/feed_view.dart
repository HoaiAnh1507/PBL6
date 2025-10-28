import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/widgets/base_footer.dart';
import 'package:locket_ai/widgets/base_header.dart';
import 'package:locket_ai/widgets/message_bar.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../core/constants/background.dart';
import '../feed/post_item.dart';
import '../../models/user_model.dart';

class FeedView extends StatefulWidget {
  final PageController verticalController;
  final User currentUser;
  final FocusNode messageFocus;

  const FeedView({
    super.key,
    required this.verticalController,
    required this.currentUser,
    required this.messageFocus,
  });

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final ScrollController _scrollCtrl = ScrollController();
  final PageController _pageCtrl = PageController();
  final TextEditingController _messageCtrl = TextEditingController(); 
  final FocusNode _messageFocus = FocusNode();

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _messageFocus.addListener(() {
      setState(() {});
    });
  }

  Widget _buildHeader() {
    return BaseHeader(
      horizontalController: widget.verticalController,
      count: 5,
      label: 'Friends',
      onTap: _showFriendsSheet
    );
  }

  void _showFriendsSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
    // Unfocus again after modal is dismissed to prevent message bar from popping up
    _messageFocus.unfocus();
  }

  Widget _buildMessageBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: MessageBar(
        controller: _messageCtrl,
        focusNode:  _messageFocus,
        onSend: () {
          final vm = Provider.of<FeedViewModel>(context, listen: false);
          if (vm.posts.isEmpty) return;

          final post = vm.posts[_currentIndex];
          final username = post.user.username; 

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sent message to $username'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );

          _messageCtrl.clear();
          _messageFocus.unfocus();
        },
      ),
    );
  }

  Widget _buildFooter() {
    return BaseFooter(
      verticalController: widget.verticalController,
      messageController: _messageCtrl,
      onSend: () {}
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<FeedViewModel>(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false, 
        body: Stack(
          children: [
            const Positioned.fill(child: AnimatedGradientBackground()),
            if (vm.loading)
              const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              )
            else if (vm.posts.isEmpty)
              Center(
                child: Text(
                  'No moments shared yet',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      decoration: TextDecoration.none),
                ),
              )
            else
              PageView.builder(
                controller: _pageCtrl,
                scrollDirection: Axis.vertical,
                itemCount: vm.posts.length,
                physics: _messageFocus.hasFocus
                  ? const NeverScrollableScrollPhysics() 
                  : const BouncingScrollPhysics(), 
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (_, index) {
                  final post = vm.posts[index];
                  return GestureDetector(
                    onTap: () {
                      if (_messageFocus.hasFocus) {
                        _messageFocus.unfocus(); 
                      }
                    },
                    child: SingleChildScrollView(
                      controller: _scrollCtrl,
                      child: SizedBox(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height,
                        child: PostItem(
                          post: post,
                          currentUser: widget.currentUser,
                        ),
                      ),
                    ),
                  );
                },
              ),

            Align(
              alignment: Alignment.topCenter,
              child: _buildHeader(),
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: _buildMessageBar(),
              )
            ),

            Align(
              alignment: Alignment.bottomCenter,
              child: _buildFooter(),
            ),
          ],
        ),
      )
    ); 
  }
}
