import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:locket_ai/views/feed/feed_view.dart';
import 'package:locket_ai/views/camera/camera_view.dart';
import 'package:locket_ai/views/chat/chat_list_view.dart';
import 'package:locket_ai/views/settings/settings_view.dart';
import '../../viewmodels/auth_viewmodel.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final PageController _hCtrl = PageController(initialPage: 1);
  final PageController _vCtrl = PageController(initialPage: 0);
  final FocusNode _messageFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _messageFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
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
      return const Center(
        child: Text("Không có người dùng đăng nhập."),
      );
    }

    return GestureDetector(
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
                CameraView(horizontalController: _vCtrl),
                FeedView(
                  currentUser: currentUser,
                  messageFocus: _messageFocus,
                ),
              ],
            ),

            ChatListView(currentUserId: currentUser.userId),
          ],
        ),
      ),
    );
  }
}
