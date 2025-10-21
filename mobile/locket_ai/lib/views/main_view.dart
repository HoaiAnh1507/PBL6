import 'package:flutter/material.dart';
import 'camera/camera_view.dart';
import 'chat/chat_list_view.dart';
import 'settings/settings_view.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  final PageController _hCtrl = PageController(initialPage: 1);

  @override
  void dispose() {
    _hCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _hCtrl,
      scrollDirection: Axis.horizontal,
      children: [
        const SettingsView(),
        CameraView(horizontalController: _hCtrl), 
        const ChatListView(currentUserId: ''),
      ],
    );
  }
}
