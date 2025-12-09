import 'package:flutter/material.dart';
import 'package:locket_ai/viewmodels/feed_viewmodel.dart';
import 'package:locket_ai/viewmodels/ai_caption_viewmodel.dart';
import 'package:locket_ai/views/auth/login_view.dart';
import 'package:provider/provider.dart';
import 'package:locket_ai/views/feed/feed_view.dart';
import 'package:locket_ai/views/camera/camera_view.dart';
import 'package:locket_ai/views/chat/chat_list_view.dart';
import 'package:locket_ai/views/settings/settings_view.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/friendship_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final PageController _hCtrl = PageController(initialPage: 1);
  final PageController _vCtrl = PageController(initialPage: 0);
  final FocusNode _messageFocus = FocusNode();
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _messageFocus.addListener(() => setState(() {}));

    // Ngay sau khi vào MainView (đăng nhập thành công), tiền tải dữ liệu chat
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_bootstrapped) return;
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      final friendshipVM = Provider.of<FriendshipViewModel>(context, listen: false);
      final chatVM = Provider.of<ChatViewModel>(context, listen: false);
      final feedVM = Provider.of<FeedViewModel>(context, listen: false);
      final aiCaptionVM = Provider.of<AICaptionViewModel>(context, listen: false);

      final current = authVM.currentUser;
      final jwt = authVM.jwtToken;

      if (current != null) {
        if (jwt != null && jwt.isNotEmpty) {
          try {
            await friendshipVM.loadFriendsRemote(jwt: jwt, current: current);
          } catch (_) {}
          try {
            await chatVM.loadRemoteConversations(jwt: jwt, currentUserId: current.userId);
          } catch (_) {}
          try {
            await chatVM.prefetchAllMessagesForCurrentUser(jwt: jwt, currentUserId: current.userId);
          } catch (_) {}
          try {
            await feedVM.loadRemoteFeed(jwt: jwt, current: current);
          } catch (_) {}
        } else {
          // Không dùng mock khi chưa có JWT. Bỏ qua nạp dữ liệu.
        }
      }

      // ✨ Listen for navigation requests from AI Caption ViewModel
      aiCaptionVM.addListener(_handleAICaptionNavigation);

      _bootstrapped = true;
    });
  }

  void _handleAICaptionNavigation() {
    final aiCaptionVM = Provider.of<AICaptionViewModel>(context, listen: false);
    if (aiCaptionVM.shouldNavigateToCapture) {
      // Switch to feed view when user wants to return to capture preview
      if (_vCtrl.hasClients) {
        _vCtrl.animateToPage(
          1, // FeedView
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      aiCaptionVM.acknowledgeNavigation();
    }
  }

  @override
  void dispose() {
    final aiCaptionVM = Provider.of<AICaptionViewModel>(context, listen: false);
    aiCaptionVM.removeListener(_handleAICaptionNavigation);
    _hCtrl.dispose();
    _vCtrl.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final currentUser = authVM.currentUser;
    final isKeyboardOpen = _messageFocus.hasFocus;

    if (currentUser == null) {
      return const LoginView();
    }

    return WillPopScope(
      onWillPop: () async {
        final page = (_hCtrl.hasClients ? _hCtrl.page : 1.0) ?? 1.0;
        final idx = page.round();
        if (idx == 0 || idx == 2) {
          await _hCtrl.animateToPage(
            1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
          return false; // chặn thoát app, chuyển về CameraView
        }
        return true; // ở CameraView thì để hành vi mặc định
      },
      child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _messageFocus.unfocus(),
      onPanDown: (_) => _messageFocus.unfocus(),
      child: AbsorbPointer(
        absorbing: isKeyboardOpen,
        child: PageView(
          controller: _hCtrl,
          scrollDirection: Axis.horizontal,
          physics: isKeyboardOpen
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          children: [
            const SettingsView(),

            PageView(
              controller: _vCtrl,
              scrollDirection: Axis.vertical,
              physics: isKeyboardOpen
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              children: [
                CameraView(verticalController: _vCtrl, horizontalController: _hCtrl),
                FeedView(
                  horizontalController: _hCtrl,
                  verticalController: _vCtrl,
                  currentUser: currentUser,
                  messageFocus: _messageFocus,
                ),
              ],
            ),

            ChatListView(currentUserId: currentUser.userId),
          ],
        ),
      ),
      ),
    );
  }
}
