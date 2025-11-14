import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/viewmodels/auth_viewmodel.dart';
import 'package:locket_ai/widgets/base_footer.dart';
import 'package:locket_ai/core/constants/colors.dart';
import 'package:locket_ai/widgets/base_header.dart';
import 'package:locket_ai/widgets/message_bar.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/friendship_viewmodel.dart';
import '../../models/friendship_model.dart';
import '../../widgets/async_avatar.dart';
import '../feed/post_item.dart';
import '../../models/user_model.dart';

class FeedView extends StatefulWidget {
  final PageController horizontalController;
  final PageController verticalController;
  final User currentUser;
  final FocusNode messageFocus;

  const FeedView({
    super.key,
    required this.horizontalController,
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
  bool _listenersAttached = false;

  @override
  void dispose() {
    if (_listenersAttached) {
      widget.verticalController.removeListener(_onPagePositionChanged);
      widget.horizontalController.removeListener(_onPagePositionChanged);
    }
    _scrollCtrl.dispose();
    _pageCtrl.dispose();
    _messageCtrl.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _messageFocus.addListener(() {
      setState(() {});
    });

    // Gắn listener vào cả 2 PageController để reset filter về All khi rời FeedView
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_listenersAttached) {
        widget.verticalController.addListener(_onPagePositionChanged);
        widget.horizontalController.addListener(_onPagePositionChanged);
        _listenersAttached = true;
      }
      // Đảm bảo lần đầu vào, nhãn là 'All'
      final feedVm = Provider.of<FeedViewModel>(context, listen: false);
      if (feedVm.filterType != FeedFilterType.all) {
        feedVm.setFilterAll();
      }
    });
  }

  void _onPagePositionChanged() {
    if (!mounted) return;
    final feedVm = Provider.of<FeedViewModel>(context, listen: false);
    final hPage = widget.horizontalController.hasClients
        ? (widget.horizontalController.page ?? 1.0).round()
        : 1;
    final vPage = widget.verticalController.hasClients
        ? (widget.verticalController.page ?? 0.0).round()
        : 0;
    final isFeedVisible = (hPage == 1 && vPage == 1);
    if (!isFeedVisible && feedVm.filterType != FeedFilterType.all) {
      // Rời FeedView: reset filter về mặc định All
      feedVm.setFilterAll();
    }
  }

  Widget _buildHeader() {
    final friendshipVM = Provider.of<FriendshipViewModel>(context);
    final friendsCount = _acceptedFriendsCount(friendshipVM);
    final feedVm = Provider.of<FeedViewModel>(context);
    return BaseHeader(
      horizontalController: widget.horizontalController,
      count: friendsCount,
      label: feedVm.filterLabel,
      showCount: false,
      onTap: _showFriendsSheet,
    );
  }

  void _showFriendsSheet() async {
    final friendshipVM = Provider.of<FriendshipViewModel>(context, listen: false);
    final feedVm = Provider.of<FeedViewModel>(context, listen: false);
    final current = widget.currentUser;

    // Build accepted friends list
    final acceptedUsers = friendshipVM.friendships
        .where((f) => f.status == FriendshipStatus.accepted &&
            (f.userOne?.userId == current.userId || f.userTwo?.userId == current.userId))
        .map((f) => f.userOne?.userId == current.userId ? f.userTwo : f.userOne)
        .whereType<User>()
        .toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withOpacity(0.85),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Your friends',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),

                // Option: All (match avatar size)
                ListTile(
                  leading: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.public, color: Colors.white70, size: 20),
                  ),
                  title: Text('All', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  onTap: () {
                    feedVm.setFilterAll();
                    Navigator.of(context).pop();
                  },
                ),
                // Option: me
                ListTile(
                  leading: AsyncAvatar(url: current.profilePictureUrl, radius: 20, fallbackKey: current.userId),
                  title: Text('Me', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  onTap: () {
                    feedVm.setFilterMe();
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(color: Colors.white24),

                // List accepted friends
                ...acceptedUsers.map((u) => ListTile(
                      leading: AsyncAvatar(url: u.profilePictureUrl, radius: 20, fallbackKey: u.userId),
                      title: Text(u.fullName.isNotEmpty ? u.fullName : '@${u.username}',
                          style: GoogleFonts.poppins(color: Colors.white)),
                      subtitle: Text('@${u.username}', style: GoogleFonts.poppins(color: Colors.white54)),
                      onTap: () {
                        feedVm.setFilterFriend(u);
                        Navigator.of(context).pop();
                      },
                    )),
              ],
            ),
          ),
        ),
      ),
    );
    // Unfocus again after modal is dismissed to prevent message bar from popping up
    _messageFocus.unfocus();
  }

  int _acceptedFriendsCount(FriendshipViewModel friendshipVM) {
    final current = widget.currentUser;
    final friends = friendshipVM.friendships
        .where((f) => f.status == FriendshipStatus.accepted &&
            (f.userOne?.userId == current.userId || f.userTwo?.userId == current.userId))
        .map((f) => f.userOne?.userId == current.userId ? f.userTwo : f.userOne)
        .whereType<User>()
        .length;
    return friends;
  }

  Widget _buildMessageBar(bool isOwner) {
    final feedVm = Provider.of<FeedViewModel>(context, listen: false);
    if (feedVm.posts.isEmpty) return const SizedBox.shrink();
    final post = feedVm.posts[_currentIndex];
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: MessageBar(
        controller: _messageCtrl,
        focusNode: _messageFocus,
        postId: post.postId,
        isOwner: isOwner,
        ownerUsername: post.user.username,
        onSend: () {
          if (isOwner) return; // owner mode has no sending
          final chatVm = Provider.of<ChatViewModel>(context, listen: false);
          final authVm = Provider.of<AuthViewModel>(context, listen: false);
          final content = _messageCtrl.text.trim();
          if (content.isEmpty) return;

          final jwt = authVm.jwtToken;
          if (jwt != null && jwt.isNotEmpty) {
            chatVm
                .sendMessageWithPostRemote(
                  jwt: jwt,
                  currentUserId: widget.currentUser.userId,
                  repliedPost: post,
                  content: content,
                )
                .then((ok) {
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sent a message to ${post.user.username} with the post'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to send message. Please try again.'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            });
          }

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
    final feedVm = Provider.of<FeedViewModel>(context);
    final posts = feedVm.getVisiblePosts(currentUser: widget.currentUser);
    final bool isOwnPost = posts.isNotEmpty &&
        _currentIndex >= 0 &&
        _currentIndex < posts.length &&
        posts[_currentIndex].user.userId == widget.currentUser.userId;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false, 
        body: Stack(
          children: [
            // const Positioned.fill(child: AnimatedGradientBackground()),
            if (feedVm.loading)
              const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              )
            else if (posts.isEmpty)
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
                itemCount: posts.length,
                physics: _messageFocus.hasFocus
                  ? const NeverScrollableScrollPhysics() 
                  : const BouncingScrollPhysics(), 
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  // Nếu lướt tới bài của chính mình thì ẩn và hạ input
                  if (index >= 0 && index < posts.length) {
                    final post = posts[index];
                    if (post.user.userId == widget.currentUser.userId) {
                      _messageFocus.unfocus();
                    }
                  }
                },
                itemBuilder: (_, index) {
                  final post = posts[index];
                  
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: (posts.isEmpty)
                      ? const SizedBox.shrink()
                      : _buildMessageBar(isOwnPost),
                  ),
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