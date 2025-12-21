import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/viewmodels/auth_viewmodel.dart';
import 'package:locket_ai/viewmodels/ai_caption_viewmodel.dart';
import 'package:locket_ai/widgets/base_footer.dart';
import 'package:locket_ai/core/constants/colors.dart';
import 'package:locket_ai/widgets/base_header.dart';
import 'package:locket_ai/widgets/message_bar.dart';
import 'package:locket_ai/widgets/ai_caption_progress_banner.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/friendship_viewmodel.dart';
import '../../models/friendship_model.dart';
import '../../widgets/async_avatar.dart';
import '../feed/post_item.dart';
import '../../models/user_model.dart';
import '../../services/reports_api.dart';
import '../../services/posts_api.dart';

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

  void _showPostMenu() {
    final feedVm = Provider.of<FeedViewModel>(context, listen: false);
    if (feedVm.posts.isEmpty || _currentIndex < 0 || _currentIndex >= feedVm.posts.length) return;
    
    final post = feedVm.posts[_currentIndex];
    final isOwnPost = post.user.userId == widget.currentUser.userId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isOwnPost)
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.redAccent),
                title: Text(
                  'Report Post',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(post.postId);
                },
              ),
            if (isOwnPost)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(
                  'Delete Post',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(post.postId);
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: Colors.white70),
              title: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Post',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost(postId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final feedVm = Provider.of<FeedViewModel>(context, listen: false);
    final jwt = authVm.jwtToken;
    
    if (jwt == null || jwt.isEmpty) {
      _showMessage('You must be logged in to delete posts', isError: true);
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const CircularProgressIndicator(color: Colors.pinkAccent),
        ),
      ),
    );

    try {
      final postsApi = PostsApi(jwt: jwt);
      final success = await postsApi.deletePost(postId: postId);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        _showMessage('Post deleted successfully');
        // Refresh feed để cập nhật danh sách posts
        await feedVm.loadRemoteFeed(jwt: jwt, current: widget.currentUser);
        // Reset về index 0 nếu cần
        if (_currentIndex >= feedVm.posts.length && feedVm.posts.isNotEmpty) {
          _pageCtrl.jumpToPage(0);
          setState(() => _currentIndex = 0);
        }
      } else {
        _showMessage('Failed to delete post. Please try again.', isError: true);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      _showMessage('Error deleting post: ${e.toString()}', isError: true);
    }
  }

  void _showReportDialog(String postId) {
    final reasonController = TextEditingController();
    final reportReasons = [
      'Spam or misleading',
      'Harassment or bullying',
      'Hate speech',
      'Violence or dangerous content',
      'Nudity or sexual content',
      'False information',
      'Other',
    ];
    
    String selectedReason = reportReasons[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Report Post',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why are you reporting this post?',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ...reportReasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                  value: reason,
                  groupValue: selectedReason,
                  activeColor: Colors.pinkAccent,
                  onChanged: (value) {
                    setState(() => selectedReason = value!);
                  },
                )).toList(),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Additional details (optional)',
                    hintStyle: GoogleFonts.poppins(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _submitReport(postId, selectedReason, reasonController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Submit Report', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport(String postId, String reason, String additionalDetails) async {
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    final jwt = authVm.jwtToken;
    
    if (jwt == null || jwt.isEmpty) {
      _showMessage('You must be logged in to report posts', isError: true);
      return;
    }

    try {
      final reportsApi = ReportsApi(jwt: jwt);
      final fullReason = additionalDetails.isNotEmpty 
          ? '$reason - $additionalDetails' 
          : reason;
      
      final result = await reportsApi.createReport(
        postId: postId,
        reason: fullReason,
      );

      if (result != null) {
        _showMessage('Report submitted successfully. Thank you for helping keep our community safe.');
      } else {
        _showMessage('Failed to submit report. Please try again.', isError: true);
      }
    } catch (e) {
      _showMessage('Error submitting report: ${e.toString()}', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
      onSend: () {},
      onMenuTap: _showPostMenu,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedVm = Provider.of<FeedViewModel>(context);
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
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
                itemCount: posts.length + (feedVm.isLoadingMore ? 1 : 0), // Add loading indicator
                physics: _messageFocus.hasFocus
                  ? const NeverScrollableScrollPhysics() 
                  : const BouncingScrollPhysics(), 
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  
                  // ✅ Trigger load more when approaching the end (within last 3 items)
                  if (index >= posts.length - 3 && 
                      !feedVm.isLoadingMore && 
                      feedVm.hasMorePosts &&
                      authVm.jwtToken != null) {
                    debugPrint('[FeedView] 📍 Approaching end, loading more posts...');
                    feedVm.loadMorePostsWithJwt(authVm.jwtToken!);
                  }
                  
                  // Nếu lướt tới bài của chính mình thì ẩn và hạ input
                  if (index >= 0 && index < posts.length) {
                    final post = posts[index];
                    if (post.user.userId == widget.currentUser.userId) {
                      _messageFocus.unfocus();
                    }
                  }
                },
                itemBuilder: (_, index) {
                  // ✅ Show loading indicator at the end
                  if (index == posts.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: Colors.pinkAccent),
                      ),
                    );
                  }
                  
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

            // ✨ AI Caption Progress Banner
            Consumer<AICaptionViewModel>(
              builder: (context, aiCaptionVM, _) {
                if (!aiCaptionVM.hasActiveJob) {
                  return const SizedBox.shrink();
                }
                
                final job = aiCaptionVM.currentJob!;
                
                return Positioned(
                  top: 110, // Below header
                  left: 0,
                  right: 0,
                  child: AICaptionProgressBanner(
                    status: job.status,
                    onTap: () {
                      // ✨ Simply pop to return to CapturePreviewPage underneath
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
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