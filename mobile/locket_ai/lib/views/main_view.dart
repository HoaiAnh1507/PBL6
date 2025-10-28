import 'package:flutter/material.dart';
import 'package:locket_ai/models/user_model.dart';
import 'package:locket_ai/views/feed/feed_view.dart';
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
  final PageController _vCtrl = PageController(initialPage: 0);

  @override
  void dispose() {
    _hCtrl.dispose();
    _vCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _hCtrl,
      scrollDirection: Axis.horizontal,
      children: [
        const SettingsView(),
        PageView(
          controller: _vCtrl,
          scrollDirection: Axis.vertical,
          children: [
            CameraView(horizontalController: _vCtrl), 
            FeedView(
              verticalController: _vCtrl,
              currentUser: User(
                userId: '0',
                phoneNumber: '0900000000',
                username: 'me',
                email: 'me@example.com',
                fullName: 'Tôi',
                profilePictureUrl: 'https://i.pravatar.cc/150?img=5',
                passwordHash: 'hashed_pw_me',
                subscriptionStatus: SubscriptionStatus.FREE,
                subscriptionExpiresAt: null,
                accountStatus: AccountStatus.ACTIVE,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              )
            )
          ]
        ),
        
        const ChatListView(currentUserId: ''),
        
      ],
    );
  }
}
